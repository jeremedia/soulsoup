class Incarnation < ApplicationRecord
  belongs_to :soul, counter_cache: :total_incarnations
  belongs_to :forge_session, optional: true
  
  # JSONB accessors for modifiers
  jsonb_accessor :modifiers,
    courage_bonus: :float,
    aim_adjustment: :float,
    retreat_timing: :float,
    cooperation_bonus: :float,
    communication_speed: :float,
    innovation_rate: :float,
    persistence: :float
  
  # Validations
  validates :incarnation_id, presence: true, uniqueness: true
  validates :forge_type, presence: true, inclusion: { 
    in: %w[combat collaboration creation diplomacy exploration caretaking] 
  }
  validates :game_session_id, presence: true
  validates :started_at, presence: true
  validates :events_count, numericality: { greater_than_or_equal_to: 0 }
  validates :total_experience, numericality: { greater_than_or_equal_to: 0 }
  
  # Callbacks
  before_validation :generate_incarnation_id, on: :create
  before_validation :set_defaults, on: :create
  after_create_commit :broadcast_incarnation_created
  after_update_commit :broadcast_incarnation_updated
  
  # Scopes
  scope :active, -> { where(ended_at: nil) }
  scope :completed, -> { where.not(ended_at: nil) }
  scope :by_forge, ->(forge) { where(forge_type: forge) }
  scope :recent, -> { order(started_at: :desc) }
  scope :long_lived, -> { where('ended_at - started_at > ?', 1.hour) }
  
  # Instance methods
  def active?
    ended_at.nil?
  end
  
  def duration
    return nil unless ended_at
    ended_at - started_at
  end
  
  def end_incarnation!(summary: nil)
    return if ended_at.present?
    
    self.ended_at = Time.current
    # Convert hash to JSON string if needed since memory_summary is text column
    self.memory_summary = summary.is_a?(Hash) ? summary.to_json : summary if summary.present?
    save!
    
    # Trigger post-incarnation processing
    ProcessIncarnationJob.perform_later(self)
  rescue => e
    Rails.logger.error "Failed to end incarnation #{incarnation_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
  
  def personality_hints
    hints = []
    
    if modifiers["courage_bonus"] && modifiers["courage_bonus"] > 0.1
      hints << "tends toward bold action"
    elsif modifiers["courage_bonus"] && modifiers["courage_bonus"] < -0.1
      hints << "favors cautious approaches"
    end
    
    if modifiers["cooperation_bonus"] && modifiers["cooperation_bonus"] > 0.1
      hints << "naturally collaborative"
    end
    
    if soul.soul_relationships.where(relationship_type: "vendetta").any?
      hints << "holds grudges"
    end
    
    hints
  end
  
  def apply_experience_event(event_type, context = {})
    # This will be called by the event processing system
    experience_gained = calculate_experience_for_event(event_type, context)
    increment!(:events_count)
    increment!(:total_experience, experience_gained)
  end
  
  def parsed_memory_summary
    return {} if memory_summary.blank?
    
    begin
      # Handle both JSON string and Hash
      if memory_summary.is_a?(String)
        JSON.parse(memory_summary)
      else
        memory_summary
      end
    rescue JSON::ParserError
      {}
    end
  end
  
  private
  
  def generate_incarnation_id
    self.incarnation_id ||= "inc-#{Nanoid.generate}"
  end
  
  def set_defaults
    self.events_count ||= 0
    self.total_experience ||= 0.0
    self.modifiers ||= {}
  end
  
  def calculate_experience_for_event(event_type, context)
    # Base experience values for different event types
    base_values = {
      "combat_kill" => 1.0,
      "combat_death" => 0.5,
      "resource_gathered" => 0.2,
      "objective_completed" => 2.0,
      "cooperation_success" => 1.5,
      "creation_completed" => 2.5,
      "negotiation_success" => 2.0,
      "discovery_made" => 3.0,
      "soul_nurtured" => 1.8
    }
    
    base = base_values[event_type] || 0.1
    
    # Apply context modifiers
    if context[:difficulty]
      base *= (1 + context[:difficulty] * 0.5)
    end
    
    if context[:against_vendetta_soul]
      base *= 1.5
    end
    
    base
  end
  
  def team_name
    team || 'unassigned'
  end
  
  def team_color
    return '#666' unless forge_session&.forge.respond_to?(:team_colors)
    forge_session.forge.team_colors[team] || '#666'
  end
  
  def teammates
    return Incarnation.none unless forge_session && team
    forge_session.team_incarnations(team).where.not(id: id)
  end
  
  def enemies
    return Incarnation.none unless forge_session && team
    forge_session.incarnations.where.not(team: team)
  end
  
  def broadcast_incarnation_created
    broadcast_prepend_later_to "incarnations",
      target: "recent_incarnations",
      partial: "dashboard/incarnation_row",
      locals: { incarnation: self }
      
    broadcast_dashboard_stats
    broadcast_team_update if forge_session
  end
  
  def broadcast_incarnation_updated
    broadcast_prepend_later_to "incarnations",
      target: "incarnation_#{id}",
      partial: "dashboard/incarnation_row",
      locals: { incarnation: self }
      
    broadcast_dashboard_stats if saved_change_to_ended_at?
    broadcast_team_update if forge_session && saved_change_to_ended_at?
  end
  
  def broadcast_team_update
    return unless forge_session.present?
    
    # Update the team display in the forge session
    # Note: We need to disable layout to prevent issues with nested partials
    broadcast_replace_later_to "forge_session_#{forge_session.id}",
      target: "team_#{team}",
      partial: "forge_sessions/team_panel",
      locals: { session: forge_session, team: team, team_data: forge_session.team_data_for(team) }
  end
  
  def broadcast_dashboard_stats
    stats = {
      total_souls: Soul.count,
      active_incarnations: Incarnation.active.count,
      total_incarnations: Incarnation.count,
      total_experience: Incarnation.sum(:total_experience),
      average_grace: Soul.average(:current_grace_level) || 0
    }
    
    broadcast_replace_later_to "souls_dashboard",
      target: "dashboard_stats",
      partial: "dashboard/stats",
      locals: { stats: stats }
  end
end