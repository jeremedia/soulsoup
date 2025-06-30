class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    # Index for finding available souls quickly
    add_index :incarnations, [:soul_id, :ended_at], name: 'index_incarnations_on_soul_and_ended'
    
    # Index for finding active incarnations by session
    add_index :incarnations, [:game_session_id, :ended_at], name: 'index_incarnations_on_session_and_ended'
    
    # Index for soul relationships
    add_index :soul_relationships, [:soul_id, :related_soul_id], unique: true, name: 'index_soul_relationships_unique'
    
    # Index for grace level (future feature)
    add_index :souls, :current_grace_level
  end
end