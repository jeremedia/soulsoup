module CombatEvents
  class SoulKilled < BaseEvent
    def killer_incarnation_id
      data[:killer_incarnation_id]
    end
    
    def victim_incarnation_id
      data[:victim_incarnation_id]
    end
    
    def context
      data[:context] || {}
    end
    
    def weapon
      context[:weapon]
    end
    
    def range
      context[:range]
    end
  end
end