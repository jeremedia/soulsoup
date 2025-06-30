require "test_helper"

class Api::V1::IncarnationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure we have some souls in the pool
    5.times { Soul.create! }
  end

  test "should create incarnation for available soul" do
    soul = Soul.create!
    
    assert_difference -> { Incarnation.count }, 1 do
      post request_api_v1_incarnations_url, params: {
        game_session_id: "test-session-123",
        forge_type: "combat",
        team_preferences: ["Red"],
        challenge_level: "normal"
      }, as: :json
    end
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response["soul_id"].present?
    assert json_response["incarnation_id"].present?
    assert json_response["modifiers"].is_a?(Hash)
  end
  
  test "should reuse souls from pool" do
    # Create exactly one soul
    soul = Soul.create!
    
    # First request should use it
    post request_api_v1_incarnations_url, params: {
      game_session_id: "session-1",
      forge_type: "combat"
    }, as: :json
    
    first_soul_id = JSON.parse(response.body)["soul_id"]
    
    # End that incarnation
    Incarnation.find_by(soul_id: soul.id).update!(ended_at: Time.current)
    
    # Second request should reuse the same soul
    post request_api_v1_incarnations_url, params: {
      game_session_id: "session-2",
      forge_type: "combat"
    }, as: :json
    
    second_soul_id = JSON.parse(response.body)["soul_id"]
    
    assert_equal first_soul_id, second_soul_id
  end
  
  test "should handle concurrent requests" do
    threads = []
    results = []
    mutex = Mutex.new
    
    # Simulate 10 concurrent requests
    10.times do |i|
      threads << Thread.new do
        post request_api_v1_incarnations_url, params: {
          game_session_id: "session-#{i}",
          forge_type: "combat"
        }, as: :json
        
        mutex.synchronize do
          results << response.status
        end
      end
    end
    
    threads.each(&:join)
    
    # All should succeed
    assert results.all? { |status| status == 200 }
    
    # Should have created 10 incarnations
    assert_equal 10, Incarnation.count
  end
  
  test "should compute correct combat modifiers" do
    soul = Soul.create!
    # Set specific genome values for predictable modifiers
    soul.genome["courage"] = 0.8
    soul.genome["strategic_thinking"] = 0.7
    soul.genome["risk_tolerance"] = 0.3
    soul.save!
    
    post request_api_v1_incarnations_url, params: {
      game_session_id: "test-modifiers",
      forge_type: "combat"
    }, as: :json
    
    json_response = JSON.parse(response.body)
    modifiers = json_response["modifiers"]
    
    # courage_bonus = (0.8 - 0.5) * 0.3 = 0.09
    assert_in_delta 0.09, modifiers["courage_bonus"], 0.01
    
    # aim_adjustment = (0.7 - 0.5) * 0.15 = 0.03
    assert_in_delta 0.03, modifiers["aim_adjustment"], 0.01
    
    # retreat_timing = (0.3 - 0.5) * -100 = 20
    assert_in_delta 20, modifiers["retreat_timing"], 1
  end
end