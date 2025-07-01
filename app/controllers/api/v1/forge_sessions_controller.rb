class Api::V1::ForgeSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    Rails.logger.info "=== ForgeSession Creation Request ==="
    Rails.logger.info "Params: #{params.inspect}"
    
    begin
      # Find the forge type
      forge_type = forge_session_params[:forge_type] || 'combat'
      forge = Forge.find_by(type: "#{forge_type.capitalize}Forge")
      
      unless forge
        return render json: { error: "Unknown forge type: #{forge_type}" }, status: :bad_request
      end
      
      # Create forge session with settings
      session_settings = build_session_settings(forge_session_params[:settings] || {})
      
      forge_session = forge.forge_sessions.create!(
        status: 'waiting',
        session_data: {
          settings: session_settings,
          created_via: 'api',
          game_session_id: forge_session_params[:game_session_id]
        }
      )
      
      Rails.logger.info "Created ForgeSession: #{forge_session.session_id}"
      
      render json: {
        forge_session_id: forge_session.session_id,
        session_id: forge_session.id,
        status: forge_session.status,
        forge_type: forge.forge_type,
        settings: session_settings,
        teams: forge_session.teams_list,
        max_participants: forge.max_participants,
        created_at: forge_session.created_at
      }
      
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "ForgeSession creation failed: #{e.message}"
      render json: { error: e.message, details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "ForgeSession creation error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      render json: { error: e.message }, status: :internal_server_error
    end
  end
  
  def show
    forge_session = ForgeSession.find_by!(session_id: params[:id])
    
    render json: {
      forge_session_id: forge_session.session_id,
      session_id: forge_session.id,
      status: forge_session.status,
      forge_type: forge_session.forge.forge_type,
      settings: forge_session.session_data&.dig('settings') || {},
      teams: forge_session.teams_list,
      started_at: forge_session.started_at,
      ended_at: forge_session.ended_at,
      duration: forge_session.duration,
      incarnations_count: forge_session.incarnations.count,
      active_incarnations_count: forge_session.incarnations.active.count,
      team_status: build_team_status(forge_session)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "ForgeSession not found" }, status: :not_found
  end
  
  def update
    forge_session = ForgeSession.find_by!(session_id: params[:id])
    
    # Update session data (for heartbeats, statistics, etc.)
    if params[:session_data].present?
      current_data = forge_session.session_data || {}
      updated_data = current_data.merge(params[:session_data])
      forge_session.update!(session_data: updated_data)
    end
    
    render json: { message: "Session updated successfully" }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "ForgeSession not found" }, status: :not_found
  rescue => e
    Rails.logger.error "ForgeSession update error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
  
  def start
    forge_session = ForgeSession.find_by!(session_id: params[:id])
    
    if forge_session.start_session!
      render json: {
        forge_session_id: forge_session.session_id,
        status: forge_session.status,
        started_at: forge_session.started_at,
        message: "Session started successfully"
      }
    else
      render json: { error: "Could not start session" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "ForgeSession not found" }, status: :not_found
  end
  
  def end
    forge_session = ForgeSession.find_by!(session_id: params[:id])
    
    outcome = {
      winner: params[:winner],
      reason: params[:reason] || 'Manual termination',
      ended_by: 'api',
      final_statistics: params[:statistics] || {}
    }
    
    if forge_session.end_session!(outcome)
      render json: {
        forge_session_id: forge_session.session_id,
        status: forge_session.status,
        ended_at: forge_session.ended_at,
        duration: forge_session.duration,
        outcome: outcome,
        message: "Session ended successfully"
      }
    else
      render json: { error: "Could not end session" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "ForgeSession not found" }, status: :not_found
  end
  
  private
  
  def forge_session_params
    params.permit(:forge_type, :game_session_id, settings: {})
  end
  
  def build_session_settings(settings_params)
    # Default settings for CombatForge
    default_settings = {
      max_duration: 300, # 5 minutes
      victory_condition: 'elimination',
      team_balance: 'auto',
      respawn_enabled: false,
      friendly_fire: false,
      map_size: 'medium',
      min_participants: 1 # Allow single-player sessions for testing
    }
    
    # Merge with provided settings
    default_settings.merge(settings_params.to_h)
  end
  
  def build_team_status(forge_session)
    status = {}
    forge_session.teams_list.each do |team|
      status[team] = {
        active_count: forge_session.active_team_incarnations(team).count,
        deceased_count: forge_session.deceased_team_incarnations(team).count,
        total_count: forge_session.team_incarnations(team).count
      }
    end
    status
  end
end