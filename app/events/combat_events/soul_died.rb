module CombatEvents
  class SoulDied < BaseEvent
    def incarnation_id
      data[:incarnation_id]
    end
    
    def killer_incarnation_id
      data[:killer_incarnation_id]
    end
    
    def context
      data[:context] || {}
    end
  end
end