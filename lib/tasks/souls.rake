namespace :souls do
  desc "Generate names for existing souls that don't have them"
  task generate_names: :environment do
    souls_without_names = Soul.where(first_name: nil)
    
    puts "Found #{souls_without_names.count} souls without names..."
    
    souls_without_names.find_each do |soul|
      soul.generate_personal_info
      puts "Generated name for soul #{soul.soul_id}: #{soul.full_name}"
    end
    
    puts "Done! All souls now have names."
  end
  
  desc "Generate personal info for souls that don't have it"
  task populate_personal_info: :environment do
    souls_without_names = Soul.where(first_name: nil)
    
    puts "Found #{souls_without_names.count} souls without personal info"
    
    progress = 0
    total = souls_without_names.count
    
    souls_without_names.find_each do |soul|
      begin
        soul.generate_personal_info
        progress += 1
        
        if progress % 100 == 0
          puts "Processed #{progress}/#{total} souls..."
        end
      rescue => e
        puts "Error processing soul #{soul.soul_id}: #{e.message}"
      end
    end
    
    puts "✅ Personal info generation complete!"
    puts "#{total} souls now have names, appearances, and voices"
  end
  
  desc "Show souls with missing personal info"
  task check_personal_info: :environment do
    without_names = Soul.where(first_name: nil).count
    without_appearance = Soul.where(appearance_traits: nil).count
    without_voice = Soul.where(voice_characteristics: nil).count
    
    puts "Souls missing personal info:"
    puts "  Without names: #{without_names}"
    puts "  Without appearance: #{without_appearance}" 
    puts "  Without voice: #{without_voice}"
    puts "  Total souls: #{Soul.count}"
  end
  
  desc "Create test souls with various traits"
  task create_test_souls: :environment do
    5.times do |i|
      soul = Soul.create!
      puts "Created soul ##{i + 1}: #{soul.display_name} (#{soul.soul_id})"
    end
  end
end