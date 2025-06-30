class Api::V1::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def heartbeat
    session_id = params[:id]
    incarnation_ids = params[:incarnation_ids] || []
    
    # Update heartbeat for all active incarnations in this session
    updated_count = 0
    
    incarnation_ids.each do |incarnation_id|
      incarnation = Incarnation.active.find_by(incarnation_id: incarnation_id)
      next unless incarnation
      
      incarnation.update!(last_heartbeat_at: Time.current)
      updated_count += 1
    end
    
    # Return any incarnations that should be ended
    # (e.g., if the game has a time limit or other conditions)
    incarnations_to_end = check_for_incarnations_to_end(session_id)
    
    render json: {
      session_id: session_id,
      updated_count: updated_count,
      incarnations_to_end: incarnations_to_end
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
end