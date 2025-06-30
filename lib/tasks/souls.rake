namespace :souls do
  desc "Create a pool of souls for incarnation"
  task create_pool: :environment do
    count = ENV['COUNT'] || 50
    count = count.to_i
    
    puts "Creating #{count} souls..."
    
    count.times do |i|
      Soul.create!(
        total_incarnations: 0,
        current_grace_level: 0.0
      )
      print '.' if i % 10 == 0
    end
    
    puts "\nCreated #{Soul.count} total souls"
    puts "Available souls: #{Soul.left_joins(:incarnations).where(incarnations: { id: nil }).count}"
  end
  
  desc "Show soul statistics"
  task stats: :environment do
    puts "Soul Statistics:"
    puts "----------------"
    puts "Total souls: #{Soul.count}"
    puts "Total incarnations: #{Incarnation.count}"
    puts "Active incarnations: #{Incarnation.active.count}"
    puts "Available souls: #{Soul.left_joins(:incarnations).where(incarnations: { id: nil }).count}"
    puts "Souls with incarnations: #{Soul.joins(:incarnations).distinct.count}"
  end
  
  desc "Clean up stuck incarnations"
  task cleanup: :environment do
    stuck = Incarnation.active.where("started_at < ?", 1.hour.ago)
    count = stuck.count
    
    if count > 0
      puts "Found #{count} stuck incarnations"
      stuck.update_all(ended_at: Time.current)
      puts "Cleaned up!"
    else
      puts "No stuck incarnations found"
    end
  end
end