class Api::V1::IncarnationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def request
    # Find or create a soul for this incarnation
    soul = find_or_create_soul_for_session
    
    # Create new incarnation
    incarnation = soul.incarnate!(
      forge_type: params[:forge_type],
      game_session_id: params[:game_session_id]
    )
    
    # Build response
    render json: {
      soul_id: soul.soul_id,
      incarnation_id: incarnation.incarnation_id,
      modifiers: incarnation.modifiers,
      personality_hints: incarnation.personality_hints,
      vendetta_souls: soul.vendetta_souls.map(&:soul_id)
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  private
  
  def find_or_create_soul_for_session
    # Try to find an available soul (not currently incarnated)
    # First, find souls with no active incarnations
    available_soul = Soul
      .left_joins(:incarnations)
      .where("incarnations.id IS NULL OR incarnations.ended_at IS NOT NULL")
      .where.not(id: Incarnation.active.select(:soul_id))
      .order("souls.total_incarnations ASC, souls.created_at ASC")
      .first
    
    if available_soul.nil?
      # No available souls, create a new one
      Rails.logger.info "Creating new soul - no available souls in pool"
      Soul.create!(
        total_incarnations: 0,
        current_grace_level: 0.0
      )
    else
      Rails.logger.info "Reusing soul #{available_soul.soul_id} for new incarnation"
      available_soul
    end
  end
end