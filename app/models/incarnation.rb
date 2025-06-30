class Incarnation < ApplicationRecord
  belongs_to :soul, counter_cache: :total_incarnations
  
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
    self.memory_summary = summary if summary.present?
    save!
    
    # Trigger post-incarnation processing
    ProcessIncarnationJob.perform_later(self)
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
end