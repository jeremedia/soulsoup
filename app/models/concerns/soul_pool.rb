module SoulPool
  extend ActiveSupport::Concern

  class_methods do
    # Pre-create a pool of souls for faster incarnation requests
    def ensure_soul_pool(size: 50)
      current_count = Soul.count
      needed = size - current_count
      
      if needed > 0
        Rails.logger.info "Creating #{needed} souls for pool"
        
        # Bulk create souls for efficiency
        souls_data = needed.times.map do
          {
            soul_id: "soul-#{Nanoid.generate}",
            total_incarnations: 0,
            current_grace_level: 0.0,
            created_at: Time.current,
            updated_at: Time.current
          }
        end
        
        # Insert all at once
        Soul.insert_all(souls_data)
        
        # Initialize genomes in background
        Soul.where(genome: nil).find_each do |soul|
          SoulInitializationJob.perform_later(soul)
        end
      end
    end
    
    # Find an available soul efficiently
    def find_available
      # Use a more efficient query
      Soul
        .joins("LEFT JOIN incarnations ON incarnations.soul_id = souls.id AND incarnations.ended_at IS NULL")
        .where("incarnations.id IS NULL")
        .order("souls.total_incarnations ASC")
        .first
    end
  end
end