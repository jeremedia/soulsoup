class ProcessIncarnationJob < ApplicationJob
  queue_as :soul_processing

  def perform(incarnation)
    # This job runs after an incarnation ends
    # It handles:
    # 1. Experience calculation
    # 2. Memory summary generation
    # 3. Grace level updates
    # Future: Dream synthesis, LoRA training, narrative generation
    
    Rails.logger.info "[ProcessIncarnationJob] Processing incarnation #{incarnation.incarnation_id}"
    
    # Skip if already processed
    return if incarnation.memory_summary.present? && incarnation.memory_summary['processed_at'].present?
    
    # Calculate experience based on events and duration
    experience_summary = calculate_experience_summary(incarnation)
    
    # Generate enhanced memory summary
    memory_summary = generate_memory_summary(incarnation, experience_summary)
    
    # Update incarnation with summary (convert hash to JSON string for text column)
    incarnation.update!(
      memory_summary: memory_summary.to_json,
      total_experience: experience_summary[:total_points]
    )
    
    # Update soul's grace level based on this incarnation
    update_soul_grace(incarnation.soul, experience_summary)
    
    Rails.logger.info "[ProcessIncarnationJob] Completed processing for incarnation #{incarnation.incarnation_id}"
  end
  
  private
  
  def calculate_experience_summary(incarnation)
    # Base experience from duration (longer lives = more experience)
    duration_seconds = incarnation.duration&.to_i || 0
    duration_minutes = duration_seconds / 60.0
    duration_bonus = Math.log(duration_minutes + 1) * 10 # Logarithmic scale
    
    # Get data from memory summary
    summary = if incarnation.memory_summary.is_a?(String)
      begin
        JSON.parse(incarnation.memory_summary)
      rescue JSON::ParserError
        {}
      end
    else
      incarnation.memory_summary || {}
    end
    
    # Calculate scores
    kills = (summary['kills'] || summary['final_kills'] || 0).to_i
    deaths = (summary['deaths'] || (summary['outcome'] == 'death' ? 1 : 0)).to_i
    resources = (summary['resources_gathered'] || 0).to_i
    
    combat_score = kills * 10 - deaths * 5
    resource_score = resources * 2
    cooperation_score = (summary['cooperation_events'] || 0).to_i * 15
    
    # Victory multiplier
    victory_multiplier = summary['outcome'] == 'victory' ? 1.5 : 1.0
    
    # Total experience
    total_points = (duration_bonus + combat_score + resource_score + cooperation_score) * victory_multiplier
    
    {
      duration_seconds: duration_seconds,
      duration_minutes: duration_minutes.round(2),
      duration_bonus: duration_bonus.round(2),
      kills: kills,
      deaths: deaths,
      resources_gathered: resources,
      combat_score: combat_score,
      resource_score: resource_score,
      cooperation_score: cooperation_score,
      victory_multiplier: victory_multiplier,
      total_points: total_points.round(2)
    }
  end
  
  def generate_memory_summary(incarnation, experience_summary)
    # Parse existing memory summary if it's a string
    base_summary = if incarnation.memory_summary.is_a?(String)
      begin
        JSON.parse(incarnation.memory_summary)
      rescue JSON::ParserError
        {}
      end
    else
      incarnation.memory_summary || {}
    end
    
    # Enhance the summary with calculated experience
    base_summary.merge(
      'experience_breakdown' => experience_summary,
      'processed_at' => Time.current.iso8601,
      'forge_type' => incarnation.forge_type,
      'duration_seconds' => incarnation.duration&.to_i || 0,
      'personality_expression' => analyze_personality_expression(incarnation)
    )
  end
  
  def analyze_personality_expression(incarnation)
    # Analyze how the soul's personality traits were expressed
    modifiers = incarnation.modifiers || {}
    
    {
      'courage_expressed' => modifiers['courage_bonus'].to_f > 0 ? 'bold' : 'cautious',
      'strategic_thinking' => modifiers['aim_adjustment'].to_f > 0 ? 'precise' : 'wild',
      'risk_assessment' => modifiers['retreat_timing'].to_f < 0 ? 'daring' : 'careful'
    }
  end
  
  def update_soul_grace(soul, experience_summary)
    # Grace increases based on meaningful experiences
    grace_increment = 0.0
    
    # Long life with positive impact
    if experience_summary[:duration_minutes] > 5 && experience_summary[:total_points] > 50
      grace_increment += 0.001
    end
    
    # Cooperation and helping others
    if experience_summary[:cooperation_score] > 20
      grace_increment += 0.002
    end
    
    # Victory through skill, not luck
    if experience_summary[:victory_multiplier] > 1 && experience_summary[:combat_score] > 30
      grace_increment += 0.001
    end
    
    # Cap grace level at 1.0
    new_grace = [soul.current_grace_level + grace_increment, 1.0].min
    
    # Update soul's grace level
    soul.update!(current_grace_level: new_grace)
    
    Rails.logger.info "[ProcessIncarnationJob] Soul #{soul.soul_id} grace: #{soul.current_grace_level} -> #{new_grace} (+#{grace_increment})"
  end
end