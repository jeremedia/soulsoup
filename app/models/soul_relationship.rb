class SoulRelationship < ApplicationRecord
  belongs_to :soul
  belongs_to :related_soul, class_name: "Soul"
  
  # Validations
  validates :relationship_type, presence: true, inclusion: { 
    in: %w[alliance vendetta mentor student rival friend] 
  }
  validates :strength, numericality: { in: 0.0..1.0 }
  validates :soul_id, uniqueness: { scope: :related_soul_id }
  validate :no_self_relationships
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :create_reciprocal_relationship
  after_update :update_reciprocal_relationship
  after_destroy :destroy_reciprocal_relationship
  
  # Scopes
  scope :strong, -> { where('strength > ?', 0.7) }
  scope :vendettas, -> { where(relationship_type: 'vendetta') }
  scope :alliances, -> { where(relationship_type: 'alliance') }
  scope :active, -> { where('last_interaction_at > ?', 1.week.ago) }
  
  # Instance methods
  def strengthen!(amount = 0.1)
    new_strength = [strength + amount, 1.0].min
    update!(strength: new_strength, last_interaction_at: Time.current)
  end
  
  def weaken!(amount = 0.1)
    new_strength = [strength - amount, 0.0].max
    if new_strength < 0.1
      destroy!
    else
      update!(strength: new_strength)
    end
  end
  
  def reciprocal_relationship
    SoulRelationship.find_by(
      soul_id: related_soul_id,
      related_soul_id: soul_id
    )
  end
  
  private
  
  def set_defaults
    self.strength ||= 0.5
    self.formed_at ||= Time.current
    self.last_interaction_at ||= Time.current
  end
  
  def no_self_relationships
    errors.add(:related_soul_id, "can't be the same as soul") if soul_id == related_soul_id
  end
  
  def create_reciprocal_relationship
    return if reciprocal_relationship.present?
    
    SoulRelationship.create!(
      soul_id: related_soul_id,
      related_soul_id: soul_id,
      relationship_type: reciprocal_type,
      strength: strength,
      formed_at: formed_at,
      last_interaction_at: last_interaction_at
    )
  end
  
  def update_reciprocal_relationship
    reciprocal = reciprocal_relationship
    return unless reciprocal
    
    reciprocal.update_columns(
      strength: strength,
      last_interaction_at: last_interaction_at
    )
  end
  
  def destroy_reciprocal_relationship
    reciprocal_relationship&.destroy
  end
  
  def reciprocal_type
    case relationship_type
    when "mentor" then "student"
    when "student" then "mentor"
    else relationship_type
    end
  end
end