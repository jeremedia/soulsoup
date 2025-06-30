class CreateSoulRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :soul_relationships do |t|
      t.references :soul, null: false, foreign_key: true
      t.references :related_soul, null: false, foreign_key: { to_table: :souls }
      t.string :relationship_type
      t.float :strength
      t.datetime :formed_at
      t.datetime :last_interaction_at

      t.timestamps
    end
    add_index :soul_relationships, :relationship_type
  end
end
