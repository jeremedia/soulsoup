class CreateForges < ActiveRecord::Migration[8.0]
  def change
    create_table :forges do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.text :description
      t.integer :max_participants, default: 10
      t.boolean :active, default: true
      t.jsonb :settings, default: {}

      t.timestamps
    end
    
    add_index :forges, :type
    add_index :forges, :active
  end
end
