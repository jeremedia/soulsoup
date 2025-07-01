class CombatForge < Forge
  def default_settings
    {
      min_participants: 2,
      max_teams: 5,
      session_duration: 300, # 5 minutes
      concurrent_sessions: 3,
      victory_conditions: {
        'elimination' => 'Last team standing wins',
        'objectives' => 'First to complete objectives',
        'time_limit' => 'Most kills when time expires'
      },
      teams: ['red', 'blue', 'green', 'yellow', 'pink'],
      weapons: ['rifle', 'pistol', 'grenade'],
      map_size: 'medium'
    }
  end
  
  def default_teams
    ['red', 'blue', 'green', 'yellow', 'pink']
  end
  
  def team_colors
    {
      'red' => '#ff4444',
      'blue' => '#4444ff', 
      'green' => '#44ff44',
      'yellow' => '#ffff44',
      'pink' => '#ff55ff'
    }
  end
  
  def can_add_team?(team_name)
    available_teams.include?(team_name)
  end
  
  def available_teams
    default_settings[:teams] - []
  end
  
  def max_participants_per_team
    max_participants / [max_teams || 2, 1].max
  end
end