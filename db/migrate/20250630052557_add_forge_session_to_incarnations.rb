class AddForgeSessionToIncarnations < ActiveRecord::Migration[8.0]
  def change
    add_reference :incarnations, :forge_session, null: true, foreign_key: true
    add_column :incarnations, :team, :string
    
    add_index :incarnations, :team
    add_index :incarnations, [:forge_session_id, :team]
  end
end
