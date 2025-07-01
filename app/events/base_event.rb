class BaseEvent < RailsEventStore::Event
  def self.from_forge_payload(payload)
    # Convert ActionController::Parameters to hash first
    # Use to_unsafe_h to avoid permit requirements for nested parameters
    hash_payload = if payload.is_a?(ActionController::Parameters)
      payload.to_unsafe_h
    else
      payload
    end
    new(data: hash_payload.deep_symbolize_keys)
  end
end