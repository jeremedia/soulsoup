# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create some initial souls for testing
puts "Creating initial souls..."

10.times do |i|
  soul = Soul.create!(
    total_incarnations: 0,
    current_grace_level: 0.0,
    base_traits: {
      temperament: %w[calm aggressive balanced curious].sample,
      learning_style: %w[experiential analytical social solitary].sample,
      conflict_resolution: %w[aggressive diplomatic avoidant collaborative].sample,
      leadership_tendency: %w[leader follower independent situational].sample
    }
  )
  
  puts "Created soul #{soul.soul_id} with genome traits:"
  puts "  Courage: #{soul.genome['courage'].round(2)}"
  puts "  Empathy: #{soul.genome['empathy'].round(2)}"
  puts "  Strategic thinking: #{soul.genome['strategic_thinking'].round(2)}"
end

puts "\nSeeding complete! Created #{Soul.count} souls."