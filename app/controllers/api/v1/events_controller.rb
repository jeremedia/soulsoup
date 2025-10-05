class Api::V1::EventsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def batch
    events = params[:events] || []
    processed_count = 0
    errors = []
    
    events.each do |event_data|
      begin
        process_event(event_data)
        processed_count += 1
      rescue => e
        errors << { event: event_data, error: e.message }
      end
    end
    
    render json: {
      processed: processed_count,
      total: events.length,
      errors: errors
    }
  end
  
  private
  
  def process_event(event_data)
    # Skip offline incarnations (they're not in the database)
    incarnation_id = event_data[:incarnation_id]
    if incarnation_id.to_s.include?('offline')
      Rails.logger.debug "Skipping offline incarnation event: #{incarnation_id}"
      return
    end

    # Convert ActionController::Parameters to hash to avoid permit issues
    event_hash = event_data.is_a?(ActionController::Parameters) ? event_data.to_unsafe_h : event_data
    context_hash = event_hash[:context].is_a?(ActionController::Parameters) ? event_hash[:context].to_unsafe_h : event_hash[:context]

    # Find the incarnation
    incarnation = Incarnation.find_by!(incarnation_id: incarnation_id)

    # Store the raw event in Rails Event Store
    event = build_event_from_type(event_hash[:type], event_hash)
    Rails.configuration.event_store.publish(event)

    # Apply immediate effects - pass converted hash
    incarnation.apply_experience_event(event_hash[:type], context_hash)

    # Handle relationship effects
    handle_relationship_effects(incarnation, event_hash)
  end
  
  def build_event_from_type(type, data)
    case type
    when "combat_kill"
      CombatEvents::SoulKilled.from_forge_payload(data)
    when "combat_death"  
      CombatEvents::SoulDied.from_forge_payload(data)
    when "resource_gathered"
      CombatEvents::ResourceGathered.from_forge_payload(data)
    else
      BaseEvent.from_forge_payload(data.merge(event_type: type))
    end
  end
  
  def handle_relationship_effects(incarnation, event_data)
    return unless event_data[:type] == "combat_kill" && event_data[:target_soul_id]
    
    # Find the target soul
    target = Soul.find_by(soul_id: event_data[:target_soul_id])
    return unless target
    
    # Create or strengthen vendetta
    relationship = incarnation.soul.soul_relationships.find_or_create_by(
      related_soul: target
    ) do |r|
      r.relationship_type = "vendetta"
    end
    
    relationship.strengthen!(0.2)
  end
end