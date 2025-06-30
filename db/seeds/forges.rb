puts "Creating forges..."

# Create Combat Forge
combat_forge = CombatForge.create!(
  name: "Arena of Valor",
  description: "Souls clash in tactical combat, learning courage through battle",
  max_participants: 12,
  settings: {
    min_participants: 4,
    max_teams: 4,
    session_duration: 300,
    concurrent_sessions: 3
  }
)

puts "✅ Created #{combat_forge.name} (ID: #{combat_forge.id})"

# Create a test forge session with souls
test_session = ForgeSession.create!(
  forge: combat_forge,
  status: 'waiting'
)

puts "✅ Created test session: #{test_session.session_id}"

# Add some souls to the session
red_souls = Soul.limit(3)
blue_souls = Soul.offset(3).limit(3)

red_souls.each do |soul|
  test_session.incarnations.create!(
    soul: soul,
    team: 'red',
    forge_type: 'combat',
    game_session_id: test_session.session_id,
    started_at: Time.current,
    modifiers: soul.compute_modifiers_for_forge('combat')
  )
end

blue_souls.each do |soul|
  test_session.incarnations.create!(
    soul: soul,
    team: 'blue', 
    forge_type: 'combat',
    game_session_id: test_session.session_id,
    started_at: Time.current,
    modifiers: soul.compute_modifiers_for_forge('combat')
  )
end

puts "✅ Added 6 souls to the session (3 red, 3 blue)"