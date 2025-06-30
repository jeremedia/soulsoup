class AddPersonalInfoToSouls < ActiveRecord::Migration[8.0]
  def change
    # Name fields
    add_column :souls, :first_name, :string
    add_column :souls, :middle_name, :string
    add_column :souls, :last_name, :string
    add_column :souls, :chosen_name, :string  # Name the soul chooses for itself
    add_column :souls, :title, :string        # Earned titles like "The Brave"
    
    # Visual/descriptive info
    add_column :souls, :portrait_seed, :string    # For generating consistent portraits
    add_column :souls, :appearance_traits, :jsonb  # Physical/visual characteristics
    add_column :souls, :voice_characteristics, :jsonb  # How they "speak"
    
    # Background/story
    add_column :souls, :origin_story, :text       # Generated backstory
    add_column :souls, :core_memories, :jsonb     # Key defining moments
    add_column :souls, :aspirations, :jsonb       # What drives them
    add_column :souls, :fears, :jsonb             # What they avoid
    
    # Metadata
    add_column :souls, :generation, :integer, default: 1  # Soul generation/era
    add_column :souls, :birth_forge, :string      # Which forge they first appeared in
    add_column :souls, :notable_achievements, :jsonb  # Hall of fame moments
    
    # Add indexes for searching
    add_index :souls, :first_name
    add_index :souls, :last_name
    add_index :souls, :chosen_name
    add_index :souls, :generation
  end
end
