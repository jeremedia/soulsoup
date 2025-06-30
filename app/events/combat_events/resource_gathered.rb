module CombatEvents
  class ResourceGathered < BaseEvent
    def incarnation_id
      data[:incarnation_id]
    end
    
    def resource_type
      data[:resource_type]
    end
    
    def amount
      data[:amount] || 1
    end
    
    def context
      data[:context] || {}
    end
  end
end