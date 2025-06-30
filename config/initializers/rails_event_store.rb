Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new
  
  # Event handlers will be subscribed here once they're created
  # Rails.configuration.event_store.tap do |store|
  #   # Combat Forge events
  #   store.subscribe(ForgeEventHandlers::CombatHandler, to: [
  #     CombatEvents::SoulKilled,
  #     CombatEvents::SoulDied,
  #     CombatEvents::ResourceGathered,
  #     CombatEvents::ObjectiveCaptured
  #   ])
  #   
  #   # General soul events
  #   store.subscribe(SoulEventHandlers::ExperienceHandler, to: [
  #     SoulEvents::ExperienceGained,
  #     SoulEvents::RelationshipFormed,
  #     SoulEvents::RelationshipChanged
  #   ])
  #   
  #   # Incarnation events
  #   store.subscribe(IncarnationEventHandlers::LifecycleHandler, to: [
  #     IncarnationEvents::Started,
  #     IncarnationEvents::Ended
  #   ])
  # end
end