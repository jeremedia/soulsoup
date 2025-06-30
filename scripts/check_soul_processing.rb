#!/usr/bin/env ruby

# Script to check if soul processing is working correctly
require_relative '../config/environment'

puts "=== Soul Processing Check ==="
puts

# Find recent incarnations
recent_incarnations = Incarnation.where.not(ended_at: nil).order(ended_at: :desc).limit(5)

puts "Recent Incarnations:"
recent_incarnations.each do |inc|
  soul = inc.soul
  summary = if inc.memory_summary.is_a?(String)
    begin
      JSON.parse(inc.memory_summary)
    rescue JSON::ParserError
      {}
    end
  else
    inc.memory_summary || {}
  end
  
  puts "\n#{'-' * 60}"
  puts "Incarnation ID: #{inc.incarnation_id}"
  puts "Soul ID: #{soul.soul_id}"
  puts "Duration: #{inc.duration&.round(2)} seconds"
  puts "Total Experience: #{inc.total_experience || 0}"
  puts "Soul Grace Level: #{soul.current_grace_level || 0}"
  puts "Memory Summary: #{summary.slice('outcome', 'final_level', 'kills', 'experience_breakdown')}"
  puts "Processed At: #{summary['processed_at'] || 'Not processed'}"
end

puts "\n#{'-' * 60}"

# Check for failed jobs
failed_jobs = SolidQueue::FailedExecution.order(created_at: :desc).limit(5)
if failed_jobs.any?
  puts "\nRecent Failed Jobs:"
  failed_jobs.each do |job|
    error = JSON.parse(job.error) rescue job.error
    puts "\nJob ID: #{job.job_id}"
    puts "Failed At: #{job.created_at}"
    puts "Error: #{error['message'] rescue error}"
  end
else
  puts "\nNo failed jobs found!"
end

# Check CleanupStaleIncarnationsJob
puts "\n#{'-' * 60}"
puts "Checking for stale incarnations..."
stale_incarnations = Incarnation.active
                               .where("started_at < ?", 2.hours.ago)
                               .count
orphaned_incarnations = Incarnation.active
                                  .where("last_heartbeat_at IS NULL OR last_heartbeat_at < ?", 5.minutes.ago)
                                  .where("started_at < ?", 5.minutes.ago)
                                  .count

puts "Stale incarnations (> 2 hours): #{stale_incarnations}"
puts "Orphaned incarnations (no heartbeat > 5 min): #{orphaned_incarnations}"

# Show recurring tasks
puts "\n#{'-' * 60}"
puts "Recurring Tasks:"
if defined?(SolidQueue::RecurringTask)
  SolidQueue::RecurringTask.all.each do |task|
    puts "- #{task.key}: #{task.schedule} (#{task.static? ? 'static' : 'dynamic'})"
  end
else
  puts "SolidQueue::RecurringTask not available"
end