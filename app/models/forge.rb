class Forge < ApplicationRecord
  # STI base class for all forge types
  has_many :forge_sessions, dependent: :destroy
  has_many :incarnations, through: :forge_sessions
  
  # JSONB accessor for settings
  jsonb_accessor :settings,
    min_participants: :integer,
    max_teams: :integer,
    session_duration: :integer
  
  validates :type, presence: true
  validates :name, presence: true
  validates :max_participants, numericality: { greater_than: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(type: type) }
  
  def active_sessions
    forge_sessions.where(status: ['waiting', 'active'])
  end
  
  def can_start_session?
    active? && active_sessions.count < concurrent_session_limit
  end
  
  def concurrent_session_limit
    settings.dig('concurrent_sessions') || 1
  end
  
  # Override in subclasses
  def forge_type
    self.class.name.underscore.gsub('_forge', '')
  end
  
  def default_teams
    ['red', 'blue']
  end
end
