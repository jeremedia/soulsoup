class Api::V1::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def heartbeat
    session_id = params[:id]
    incarnation_ids = params[:incarnation_ids] || []
    forge_session_id = params[:forge_session_id]
    team_stats = params[:team_stats]
    
    # Update heartbeat for all active incarnations in this session
    updated_count = 0
    
    incarnation_ids.each do |incarnation_id|
      incarnation = Incarnation.active.find_by(incarnation_id: incarnation_id)
      next unless incarnation
      
      incarnation.update!(last_heartbeat_at: Time.current)
      updated_count += 1
    end
    
    # Process team statistics and check for victory conditions
    victory_result = nil
    if forge_session_id.present? && team_stats.present?
      forge_session = ForgeSession.find_by(session_id: forge_session_id)
      if forge_session && forge_session.active?
        # Update team statistics in session data
        forge_session.session_data["team_stats"] = team_stats
        forge_session.session_data["last_stats_update"] = Time.current.iso8601
        forge_session.save!
        
        # Check for victory conditions
        victory_result = check_victory_conditions(forge_session, team_stats)
        
        if victory_result
          Rails.logger.info "Victory detected for team #{victory_result[:winner]} in session #{forge_session_id}"
          forge_session.end_session!(victory_result)
        end
      end
    end
    
    # Return any incarnations that should be ended
    # (e.g., if the game has a time limit or other conditions)
    incarnations_to_end = check_for_incarnations_to_end(session_id)
    
    render json: {
      session_id: session_id,
      updated_count: updated_count,
      incarnations_to_end: incarnations_to_end,
      victory: victory_result
    }
  rescue => e
    Rails.logger.error "Heartbeat failed: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
  
  private
  
  def check_for_incarnations_to_end(session_id)
    # This could check for various conditions:
    # - Game time limits
    # - Inactivity timeouts
    # - Admin-forced endings
    # For now, return empty array
    []
  end
  
  def check_victory_conditions(forge_session, team_stats)
    return nil unless team_stats.is_a?(Array)
    
    # Get victory condition from session settings
    victory_condition = forge_session.session_data.dig("settings", "victory_condition") || "elimination"
    
    case victory_condition
    when "elimination"
      # Check if only one team has units or bases alive
      teams_alive = team_stats.select { |stat| 
        (stat["units_alive"].to_i > 0) || (stat["bases_alive"].to_i > 0)
      }
      
      if teams_alive.length == 1
        winning_team = teams_alive.first["team"]
        return {
          winner: winning_team,
          condition: "elimination",
          final_stats: team_stats,
          duration: forge_session.duration
        }
      end
    when "time_limit"
      # Check if session duration exceeded
      max_duration = forge_session.session_data.dig("settings", "max_duration") || 1800 # 30 minutes default
      if forge_session.duration && forge_session.duration > max_duration
        # Find team with most kills
        winning_team = team_stats.max_by { |stat| stat["kills"].to_i }
        return {
          winner: winning_team["team"],
          condition: "time_limit",
          final_stats: team_stats,
          duration: forge_session.duration
        }
      end
    end
    
    nil
  end
end