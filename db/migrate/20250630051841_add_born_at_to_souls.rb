class AddBornAtToSouls < ActiveRecord::Migration[8.0]
  def change
    add_column :souls, :born_at, :datetime
    
    # Set born_at for existing souls to their created_at time
    reversible do |dir|
      dir.up do
        execute "UPDATE souls SET born_at = created_at WHERE born_at IS NULL"
      end
    end
  end
end
