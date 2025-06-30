class AddLastHeartbeatToIncarnations < ActiveRecord::Migration[8.0]
  def change
    add_column :incarnations, :last_heartbeat_at, :datetime
  end
end
