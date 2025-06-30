class CreateForgeSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :forge_sessions do |t|
      t.references :forge, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :status, default: 'waiting'
      t.datetime :started_at
      t.datetime :ended_at
      t.jsonb :teams, default: {}
      t.jsonb :session_data, default: {}

      t.timestamps
    end
    
    add_index :forge_sessions, :session_id, unique: true
    add_index :forge_sessions, :status
    add_index :forge_sessions, :started_at
  end
end
