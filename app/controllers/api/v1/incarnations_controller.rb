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
    # For now, always create a new soul
    # Later we'll implement soul selection based on:
    # - Available souls not currently incarnated
    # - Match quality with requested team/challenge level
    # - Soul preferences and history
    
    Soul.create!(
      total_incarnations: 0,
      current_grace_level: 0.0
    )
  end
end