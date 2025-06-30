class ForgeSessionsController < ApplicationController
  before_action :set_forge_session, only: [:show, :start, :end]
  
  def index
    @forge_sessions = ForgeSession.includes(:forge, :incarnations).recent.limit(50)
    @active_sessions = @forge_sessions.active
    @completed_sessions = @forge_sessions.completed
  end
  
  def show
    @incarnations = @forge_session.incarnations.includes(:soul).recent
    @teams = @forge_session.teams_list
    
    # Group incarnations by team and status
    @team_data = {}
    @teams.each do |team|
      @team_data[team] = {
        active: @forge_session.active_team_incarnations(team).includes(:soul),
        deceased: @forge_session.deceased_team_incarnations(team).includes(:soul)
      }
    end
  end
  
  def new
    @forge_session = ForgeSession.new
    @forges = Forge.all
  end
  
  def create
    @forge = Forge.find(params[:forge_session][:forge_id])
    @forge_session = @forge.forge_sessions.build(forge_session_params)
    
    if @forge_session.save
      redirect_to @forge_session, notice: 'Forge session created successfully.'
    else
      @forges = Forge.all
      render :new, status: :unprocessable_entity
    end
  end
  
  def start
    if @forge_session.start_session!
      redirect_to @forge_session, notice: 'Session started!'
    else
      redirect_to @forge_session, alert: 'Could not start session. Check minimum participants.'
    end
  end
  
  def end
    outcome = {
      winner: params[:winner],
      ended_by: 'admin',
      reason: params[:reason] || 'Manual termination'
    }
    
    if @forge_session.end_session!(outcome)
      redirect_to @forge_session, notice: 'Session ended successfully.'
    else
      redirect_to @forge_session, alert: 'Could not end session.'
    end
  end
  
  private
  
  def set_forge_session
    @forge_session = ForgeSession.find(params[:id])
  end
  
  def forge_session_params
    params.require(:forge_session).permit(:forge_id, :max_duration)
  end
end