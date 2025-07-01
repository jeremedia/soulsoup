class CleanupStaleIncarnationsJob < ApplicationJob
  queue_as :maintenance
  
  def perform
    Rails.logger.info "[CleanupStaleIncarnationsJob] Starting cleanup of stale incarnations"
    
    stale_count = 0
    
    # Find incarnations that have been active for too long
    stale_incarnations = Incarnation.active
                                   .where("started_at < ?", 2.hours.ago)
                                   .includes(:soul)
    
    stale_incarnations.find_each do |incarnation|
      Rails.logger.info "[CleanupStaleIncarnationsJob] Ending stale incarnation #{incarnation.incarnation_id}"
      
      # End the incarnation with a timeout status
      incarnation.end_incarnation!(summary: {
        outcome: 'timeout',
        reason: 'Session exceeded maximum duration',
        duration_at_timeout: (Time.current - incarnation.started_at).to_i
      })
      
      stale_count += 1
    end
    
    # Also check for incarnations with no recent events
    orphaned_incarnations = find_orphaned_incarnations
    
    orphaned_incarnations.find_each do |incarnation|
      Rails.logger.info "[CleanupStaleIncarnationsJob] Ending orphaned incarnation #{incarnation.incarnation_id}"
      
      incarnation.end_incarnation!(summary: {
        outcome: 'disconnected',
        reason: 'No events received for extended period',
        last_event_minutes_ago: minutes_since_last_event(incarnation)
      })
      
      stale_count += 1
    end
    
    Rails.logger.info "[CleanupStaleIncarnationsJob] Completed cleanup. Ended #{stale_count} stale incarnations"
    
    # Also cleanup stale forge sessions
    cleanup_stale_forge_sessions
  end
  
  def cleanup_stale_forge_sessions
    Rails.logger.info "[CleanupStaleIncarnationsJob] Checking for stale forge sessions"
    
    sessions_ended = 0
    
    # Find active forge sessions with no active incarnations
    ForgeSession.active.find_each do |session|
      if session.incarnations.active.count == 0
        # Check if session has been empty for too long
        last_activity = session.session_data["last_stats_update"] || session.started_at || session.created_at
        last_activity_time = last_activity.is_a?(String) ? Time.parse(last_activity) : last_activity
        
        if last_activity_time < 10.minutes.ago
          Rails.logger.info "[CleanupStaleIncarnationsJob] Ending stale forge session #{session.session_id}"
          
          session.end_session!({
            winner: nil,
            condition: "abandoned",
            reason: "No active players for extended period"
          })
          
          sessions_ended += 1
        end
      end
    end
    
    Rails.logger.info "[CleanupStaleIncarnationsJob] Ended #{sessions_ended} stale forge sessions"
  end
  
  private
  
  def find_orphaned_incarnations
    # Find incarnations with no recent heartbeat or events
    Incarnation.active
               .where("last_heartbeat_at IS NULL OR last_heartbeat_at < ?", 5.minutes.ago)
               .where("started_at < ?", 5.minutes.ago)
  end
  
  def minutes_since_last_event(incarnation)
    ((Time.current - incarnation.updated_at) / 60).round
  end
end