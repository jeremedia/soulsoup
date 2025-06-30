class Api::V1::IncarnationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    start_time = Time.current
    Rails.logger.info "=== Incarnation Request Started ==="
    Rails.logger.info "Params: #{params.inspect}"
    
    # Use database transaction to prevent race conditions
    retries = 0
    response_data = nil
    
    begin
      response_data = Soul.transaction do
        # Find or create a soul for this incarnation
        soul_start = Time.current
        soul = find_or_create_soul_for_session
        Rails.logger.info "Soul acquisition took: #{(Time.current - soul_start) * 1000}ms"
        
        # Create new incarnation
        incarnation_start = Time.current
        incarnation = soul.incarnate!(
          forge_type: params[:forge_type] || 'combat',
          game_session_id: params[:game_session_id],
          forge_session_id: params[:forge_session_id]
        )
        Rails.logger.info "Incarnation creation took: #{(Time.current - incarnation_start) * 1000}ms"
        Rails.logger.info "Created incarnation: #{incarnation.incarnation_id}"
        
        # Build response
        response_start = Time.current
        data = {
          soul_id: soul.soul_id,
          incarnation_id: incarnation.incarnation_id,
          modifiers: incarnation.modifiers || {},
          personality_hints: incarnation.personality_hints || [],
          vendetta_souls: [] # Simplified for now
        }
        Rails.logger.info "Response building took: #{(Time.current - response_start) * 1000}ms"
        data
      end
    rescue ActiveRecord::RecordInvalid => e
      if e.message.include?("Soul already has active incarnation") && retries < 3
        retries += 1
        Rails.logger.info "Retrying incarnation request (attempt #{retries})"
        retry
      else
        raise
      end
    end
    
    Rails.logger.info "=== Total request time: #{(Time.current - start_time) * 1000}ms ==="
    render json: response_data
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation failed: #{e.message}"
    Rails.logger.error "Record errors: #{e.record.errors.full_messages.join(', ')}"
    render json: { error: e.message, details: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Incarnation request failed: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    render json: { error: e.message }, status: :internal_server_error
  end
  
  def end
    incarnation = Incarnation.find_by!(incarnation_id: params[:id])
    
    # Check if already ended
    if incarnation.ended_at.present?
      render json: { message: "Incarnation already ended" }, status: :ok
      return
    end
    
    # End the incarnation with provided summary
    incarnation.end_incarnation!(summary: params[:memory_summary])
    
    render json: {
      soul_id: incarnation.soul.soul_id,
      incarnation_id: incarnation.incarnation_id,
      duration: incarnation.duration,
      total_experience: incarnation.total_experience,
      message: "Incarnation ended successfully"
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Incarnation not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Failed to end incarnation: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
  
  private
  
  def find_or_create_soul_for_session
    # Try to find an available soul (not currently incarnated)
    Rails.logger.info "Looking for available soul..."
    Rails.logger.info "Total souls in database: #{Soul.count}"
    Rails.logger.info "Active incarnations: #{Incarnation.active.count}"
    
    query_start = Time.current
    
    # Find souls that don't have active incarnations
    # First try souls that have never been incarnated
    available_soul = Soul.where.not(id: Incarnation.active.select(:soul_id))
                         .left_joins(:incarnations)
                         .where(incarnations: { id: nil })
                         .order('souls.total_incarnations ASC')
                         .first
    
    # If no virgin souls, find one with only ended incarnations
    if available_soul.nil?
      available_soul = Soul.where.not(id: Incarnation.active.select(:soul_id))
                           .order('souls.total_incarnations ASC')
                           .first
    end
    
    Rails.logger.info "Soul query took: #{(Time.current - query_start) * 1000}ms"
    
    if available_soul.nil?
      # No available souls, create a new one
      Rails.logger.info "Creating new soul - no available souls in pool"
      create_start = Time.current
      new_soul = Soul.create!(
        total_incarnations: 0,
        current_grace_level: 0.0
      )
      Rails.logger.info "Soul creation took: #{(Time.current - create_start) * 1000}ms"
      Rails.logger.info "Created soul: #{new_soul.soul_id}"
      new_soul
    else
      Rails.logger.info "Reusing soul #{available_soul.soul_id} for new incarnation"
      available_soul
    end
  end
end