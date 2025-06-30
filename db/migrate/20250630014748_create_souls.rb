class CreateSouls < ActiveRecord::Migration[8.0]
  def change
    create_table :souls do |t|
      t.string :soul_id
      t.jsonb :genome
      t.vector :personality_vector, limit: 256
      t.jsonb :base_traits
      t.integer :total_incarnations
      t.float :current_grace_level

      t.timestamps
    end
    add_index :souls, :soul_id, unique: true
    add_index :souls, :total_incarnations
  end
end
