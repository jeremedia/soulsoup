class ForgeSession < ApplicationRecord
  belongs_to :forge
  has_many :incarnations, dependent: :destroy
  
  # We'll access JSONB fields directly instead of using accessors for complex types
  
  validates :session_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[waiting active paused completed cancelled] }
  
  # Callbacks
  before_validation :generate_session_id, on: :create
  before_validation :initialize_teams, on: :create
  after_create_commit :broadcast_session_created
  after_update_commit :broadcast_session_updated
  
  # Scopes
  scope :active, -> { where(status: ['waiting', 'active']) }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }
  
  def active?
    %w[waiting active].include?(status)
  end
  
  def can_start?
    status == 'waiting' && incarnations.count >= min_participants
  end
  
  def should_auto_start?
    status == 'waiting' && incarnations.active.count > 0
  end
  
  def min_participants
    session_data&.dig('settings', 'min_participants') || forge.settings.dig('min_participants') || 2
  end
  
  def can_join?(team = nil)
    return false unless %w[waiting active].include?(status)
    return false if at_capacity?
    
    if team
      team_incarnations(team).count < max_per_team
    else
      true
    end
  end
  
  def start_session!
    return false unless can_start?
    
    update!(
      status: 'active',
      started_at: Time.current
    )
    
    broadcast_session_started
    true
  end
  
  def end_session!(outcome = {})
    return false unless active?
    
    update!(
      status: 'completed',
      ended_at: Time.current,
      session_data: session_data.merge(outcome: outcome)
    )
    
    # End all active incarnations
    incarnations.active.each do |incarnation|
      incarnation.end_incarnation!(summary: { 
        outcome: outcome.dig('winner') == incarnation.team ? 'victory' : 'defeat',
        session_outcome: outcome
      })
    end
    
    broadcast_session_ended
    
    # Queue job to process session rewards
    ProcessForgeSessionJob.perform_later(self)
    
    true
  end
  
  def team_incarnations(team)
    incarnations.where(team: team)
  end
  
  def active_team_incarnations(team)
    team_incarnations(team).active
  end
  
  def deceased_team_incarnations(team)
    team_incarnations(team).where.not(ended_at: nil)
  end
  
  def team_alive_count(team)
    active_team_incarnations(team).count
  end
  
  def team_dead_count(team)
    deceased_team_incarnations(team).count
  end
  
  def teams_list
    forge.respond_to?(:default_teams) ? forge.default_teams : ['red', 'blue']
  end
  
  def duration
    return nil unless started_at
    (ended_at || Time.current) - started_at
  end
  
  def at_capacity?
    incarnations.active.count >= forge.max_participants
  end
  
  def max_per_team
    forge.max_participants / teams_list.length
  end
  
  def winning_team
    return nil unless status == 'completed'
    session_data.dig('outcome', 'winner')
  end
  
  def team_data_for(team)
    {
      active: active_team_incarnations(team).includes(:soul).to_a,
      deceased: deceased_team_incarnations(team).includes(:soul).to_a
    }
  end
  
  private
  
  def generate_session_id
    self.session_id ||= "session-#{SecureRandom.hex(8)}"
  end
  
  def initialize_teams
    self.teams ||= {}
    teams_list.each do |team|
      self.teams[team] ||= []
    end
  end
  
  def broadcast_session_created
    broadcast_prepend_later_to "forge_sessions",
      target: "active_sessions",
      partial: "forge_sessions/session_row",
      locals: { session: self }
  end
  
  def broadcast_session_updated
    # Use broadcast_replace_later_to to avoid rendering during API requests
    broadcast_replace_later_to "forge_sessions",
      target: "session_#{id}",
      partial: "forge_sessions/session_row", 
      locals: { session: self }
      
    if saved_change_to_status?
      broadcast_session_status_change
    elsif saved_change_to_session_data?
      # Update team panels when team stats change (async to avoid API issues)
      teams_list.each do |team|
        broadcast_replace_later_to "forge_session_#{id}",
          target: "team_#{team}",
          partial: "forge_sessions/team_panel",
          locals: { session: self, team: team, team_data: team_data_for(team) }
      end
    end
  end
  
  def broadcast_session_started
    broadcast_update_to "forge_session_#{id}",
      target: "session_status",
      html: "Status: <span class='badge active'>Active</span>"
  end
  
  def broadcast_session_ended
    broadcast_update_to "forge_session_#{id}",
      target: "session_status", 
      html: "Status: <span class='badge ended'>Completed</span>"
  end
  
  def broadcast_session_status_change
    # Broadcast to the session detail page (async to avoid API issues)
    teams_list.each do |team|
      broadcast_replace_later_to "forge_session_#{id}",
        target: "team_#{team}",
        partial: "forge_sessions/team_panel",
        locals: { session: self, team: team, team_data: team_data_for(team) }
    end
  end
end
