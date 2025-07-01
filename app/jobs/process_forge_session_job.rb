class ProcessForgeSessionJob < ApplicationJob
  queue_as :soul_processing
  
  def perform(forge_session)
    Rails.logger.info "[ProcessForgeSessionJob] Processing completed forge session #{forge_session.session_id}"
    
    # Skip if already processed
    return if forge_session.session_data["rewards_distributed"]
    
    # Get the final team stats
    final_stats = forge_session.session_data.dig("outcome", "final_stats") || 
                  forge_session.session_data["team_stats"] || []
    
    # Calculate team-based rewards
    winning_team = forge_session.session_data.dig("outcome", "winner")
    victory_condition = forge_session.session_data.dig("outcome", "condition")
    
    # Process each team's performance
    team_performances = analyze_team_performances(final_stats)
    
    # Distribute rewards to all incarnations that participated
    distribute_rewards(forge_session, team_performances, winning_team)
    
    # Mark as processed
    forge_session.session_data["rewards_distributed"] = true
    forge_session.session_data["processed_at"] = Time.current.iso8601
    forge_session.save!
    
    Rails.logger.info "[ProcessForgeSessionJob] Completed processing forge session #{forge_session.session_id}"
  end
  
  private
  
  def analyze_team_performances(final_stats)
    return {} unless final_stats.is_a?(Array)
    
    performances = {}
    
    final_stats.each do |team_stat|
      team = team_stat["team"]
      performances[team] = {
        kills: team_stat["kills"].to_i,
        final_units: team_stat["units_alive"].to_i,
        final_bases: team_stat["bases_alive"].to_i,
        # Calculate team score for ranking
        score: calculate_team_score(team_stat)
      }
    end
    
    # Rank teams by score
    ranked_teams = performances.sort_by { |_, perf| -perf[:score] }
    ranked_teams.each_with_index do |(team, perf), index|
      perf[:rank] = index + 1
    end
    
    performances
  end
  
  def calculate_team_score(team_stat)
    kills = team_stat["kills"].to_i
    units = team_stat["units_alive"].to_i
    bases = team_stat["bases_alive"].to_i
    
    # Score formula: kills + surviving units + (bases * 10)
    kills + units + (bases * 10)
  end
  
  def distribute_rewards(forge_session, team_performances, winning_team)
    # Process all incarnations that participated in this session
    forge_session.incarnations.includes(:soul).find_each do |incarnation|
      team_perf = team_performances[incarnation.team] || {}
      
      # Calculate bonus experience based on team performance
      bonus_exp = calculate_bonus_experience(incarnation, team_perf, winning_team)
      
      if bonus_exp > 0
        # Add bonus to existing experience
        current_exp = incarnation.total_experience || 0
        incarnation.update!(total_experience: current_exp + bonus_exp)
        
        # Update memory summary with session rewards
        update_memory_with_rewards(incarnation, bonus_exp, team_perf)
        
        # Additional grace bonus for winning team souls
        if incarnation.team == winning_team
          apply_victory_grace_bonus(incarnation.soul)
        end
        
        Rails.logger.info "[ProcessForgeSessionJob] Awarded #{bonus_exp} bonus exp to incarnation #{incarnation.incarnation_id}"
      end
    end
  end
  
  def calculate_bonus_experience(incarnation, team_performance, winning_team)
    base_bonus = 0
    
    # Participation bonus (just for being in the session)
    base_bonus += 10
    
    # Team rank bonus
    rank = team_performance[:rank] || 5
    base_bonus += (6 - rank) * 5 # 25 for 1st, 20 for 2nd, etc.
    
    # Victory bonus
    if incarnation.team == winning_team
      base_bonus += 50
    end
    
    # Team performance bonus
    if team_performance[:kills] > 10
      base_bonus += 10
    end
    
    # Survival bonus (if incarnation made it to the end)
    if incarnation.ended_at && incarnation.forge_session.ended_at
      if incarnation.ended_at >= incarnation.forge_session.ended_at - 1.minute
        base_bonus += 20
      end
    end
    
    base_bonus
  end
  
  def update_memory_with_rewards(incarnation, bonus_exp, team_performance)
    # Parse existing memory summary
    memory = if incarnation.memory_summary.is_a?(String)
      begin
        JSON.parse(incarnation.memory_summary)
      rescue JSON::ParserError
        {}
      end
    else
      incarnation.memory_summary || {}
    end
    
    # Add session rewards info
    memory["session_rewards"] = {
      "bonus_experience" => bonus_exp,
      "team_rank" => team_performance[:rank],
      "team_kills" => team_performance[:kills],
      "team_final_units" => team_performance[:final_units],
      "team_final_bases" => team_performance[:final_bases]
    }
    
    # Save updated memory
    incarnation.update!(memory_summary: memory.to_json)
  end
  
  def apply_victory_grace_bonus(soul)
    # Small grace bonus for being on winning team
    grace_bonus = 0.0005
    new_grace = [soul.current_grace_level + grace_bonus, 1.0].min
    
    soul.update!(current_grace_level: new_grace)
    
    Rails.logger.info "[ProcessForgeSessionJob] Victory grace bonus: Soul #{soul.soul_id} grace: #{soul.current_grace_level} -> #{new_grace}"
  end
end