class ProcessIncarnationJob < ApplicationJob
  queue_as :default

  def perform(incarnation)
    # This job runs after an incarnation ends
    # It will eventually handle:
    # 1. Dream synthesis (RL training)
    # 2. Memory encoding to vector DB
    # 3. Narrative generation
    # 4. LoRA weight updates
    
    # For now, just log
    Rails.logger.info "Processing ended incarnation #{incarnation.incarnation_id}"
    
    # Update soul's grace level based on experience
    soul = incarnation.soul
    experience_contribution = incarnation.total_experience / 1000.0
    new_grace = [soul.current_grace_level + experience_contribution, 1.0].min
    
    soul.update!(current_grace_level: new_grace)
  end
end