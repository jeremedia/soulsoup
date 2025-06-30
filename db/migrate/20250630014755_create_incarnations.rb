class CreateIncarnations < ActiveRecord::Migration[8.0]
  def change
    create_table :incarnations do |t|
      t.string :incarnation_id
      t.references :soul, null: false, foreign_key: true
      t.string :forge_type
      t.datetime :started_at
      t.datetime :ended_at
      t.string :game_session_id
      t.jsonb :modifiers
      t.integer :events_count
      t.float :total_experience
      t.text :memory_summary
      t.string :lora_weights_url

      t.timestamps
    end
    add_index :incarnations, :incarnation_id, unique: true
    add_index :incarnations, :forge_type
    add_index :incarnations, :ended_at
    add_index :incarnations, :game_session_id
  end
end
