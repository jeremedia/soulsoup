class BaseEvent < RailsEventStore::Event
  def self.from_forge_payload(payload)
    new(data: payload.deep_symbolize_keys)
  end
end