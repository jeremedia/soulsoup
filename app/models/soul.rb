class Soul < ApplicationRecord
  include Neighbor::Model
  include SoulPool
  
  # Associations
  has_many :incarnations, dependent: :destroy
  has_many :soul_relationships, dependent: :destroy
  has_many :related_souls, through: :soul_relationships
  
  # JSONB accessors for genome (256 floats defining base personality)
  jsonb_accessor :genome,
    courage: :float,
    empathy: :float,
    curiosity: :float,
    creativity: :float,
    patience: :float,
    strategic_thinking: :float,
    risk_tolerance: :float,
    social_orientation: :float
  
  # JSONB accessors for base traits
  jsonb_accessor :base_traits,
    temperament: :string,
    learning_style: :string,
    conflict_resolution: :string,
    leadership_tendency: :string
  
  # Vector for personality embeddings
  has_neighbors :personality_vector
  
  # Validations
  validates :soul_id, presence: true, uniqueness: true
  validates :genome, presence: true
  validates :total_incarnations, numericality: { greater_than_or_equal_to: 0 }
  validates :current_grace_level, numericality: { in: 0.0..1.0 }
  
  # Callbacks
  before_validation :generate_soul_id, on: :create
  before_validation :initialize_genome, on: :create
  before_validation :compute_personality_vector, if: :genome_changed?
  
  # Scopes
  scope :active, -> { joins(:incarnations).where(incarnations: { ended_at: nil }).distinct }
  scope :veterans, -> { where('total_incarnations > ?', 10) }
  scope :approaching_grace, -> { where('current_grace_level > ?', 0.8) }
  
  # Instance methods
  def current_incarnation
    incarnations.where(ended_at: nil).first
  end
  
  def incarnate!(forge_type:, game_session_id:)
    # Lock this soul record for update to prevent concurrent incarnations
    with_lock do
      # Double-check no active incarnation exists
      if incarnations.active.exists?
        Rails.logger.warn "Soul #{soul_id} already has active incarnation"
        raise ActiveRecord::RecordInvalid.new(self), "Soul already has active incarnation"
      end
      
      # Create new incarnation
      incarnations.create!(
        forge_type: forge_type,
        game_session_id: game_session_id,
        started_at: Time.current,
        modifiers: compute_modifiers_for_forge(forge_type)
      )
    end
  end
  
  def personality_traits
    {
      bold_vs_cautious: genome["courage"] - genome["risk_tolerance"],
      social_vs_solitary: genome["social_orientation"] - genome["patience"],
      creative_vs_analytical: genome["creativity"] - genome["strategic_thinking"],
      empathetic_vs_focused: genome["empathy"] - (1.0 - genome["curiosity"])
    }
  end
  
  def vendetta_souls
    soul_relationships
      .where(relationship_type: "vendetta")
      .includes(:related_soul)
      .map(&:related_soul)
  end
  
  def allied_souls
    soul_relationships
      .where(relationship_type: "alliance")
      .includes(:related_soul)
      .map(&:related_soul)
  end
  
  private
  
  def generate_soul_id
    self.soul_id ||= "soul-#{Nanoid.generate}"
  end
  
  def initialize_genome
    return if genome.present?
    
    Rails.logger.info "Initializing genome for soul #{soul_id}..."
    start_time = Time.current
    
    # Initialize 256-dimensional genome with random values
    self.genome = {}
    256.times do |i|
      self.genome["gene_#{i}"] = rand
    end
    
    # Map first 8 genes to named traits
    self.genome["courage"] = genome["gene_0"]
    self.genome["empathy"] = genome["gene_1"]
    self.genome["curiosity"] = genome["gene_2"]
    self.genome["creativity"] = genome["gene_3"]
    self.genome["patience"] = genome["gene_4"]
    self.genome["strategic_thinking"] = genome["gene_5"]
    self.genome["risk_tolerance"] = genome["gene_6"]
    self.genome["social_orientation"] = genome["gene_7"]
    
    Rails.logger.info "Genome initialization took: #{(Time.current - start_time) * 1000}ms"
  end
  
  def compute_personality_vector
    # This will be enhanced to use embeddings from the genome
    # For now, just use the first 256 genome values directly
    Rails.logger.info "Computing personality vector for soul #{soul_id}..."
    start_time = Time.current
    
    vector = 256.times.map { |i| genome["gene_#{i}"] || 0.0 }
    self.personality_vector = vector
    
    Rails.logger.info "Personality vector computation took: #{(Time.current - start_time) * 1000}ms"
  end
  
  def compute_modifiers_for_forge(forge_type)
    # Compute forge-specific modifiers based on personality
    base_modifiers = {}
    
    case forge_type
    when "combat"
      base_modifiers[:courage_bonus] = (genome["courage"] - 0.5) * 0.3
      base_modifiers[:aim_adjustment] = (genome["strategic_thinking"] - 0.5) * 0.15
      base_modifiers[:retreat_timing] = (genome["risk_tolerance"] - 0.5) * -100
    when "collaboration"
      base_modifiers[:cooperation_bonus] = (genome["empathy"] - 0.5) * 0.25
      base_modifiers[:communication_speed] = (genome["social_orientation"] - 0.5) * 0.2
    when "creation"
      base_modifiers[:innovation_rate] = (genome["creativity"] - 0.5) * 0.35
      base_modifiers[:persistence] = (genome["patience"] - 0.5) * 0.25
    end
    
    base_modifiers
  end
end