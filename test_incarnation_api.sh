#!/bin/bash

echo "Testing Soulsoup Incarnation API..."
echo "=================================="
echo

# Test 1: Basic request with timeout
echo "Test 1: Single incarnation request (5s timeout)"
time curl -X POST http://localhost:4001/api/v1/incarnations/request \
  -H "Content-Type: application/json" \
  -d '{
    "game_session_id": "test-session-123",
    "forge_type": "combat",
    "team_preferences": ["Red"],
    "challenge_level": "normal"
  }' \
  --max-time 5 \
  -w "\n\nResponse time: %{time_total}s\n" | jq .

echo
echo "Test 2: Check soul count"
echo "Running: rails runner 'puts \"Souls: #{Soul.count}, Active incarnations: #{Incarnation.active.count}\"'"

echo
echo "Test 3: Multiple concurrent requests"
for i in {1..5}; do
  curl -X POST http://localhost:4001/api/v1/incarnations/request \
    -H "Content-Type: application/json" \
    -d "{
      \"game_session_id\": \"concurrent-test-$i\",
      \"forge_type\": \"combat\"
    }" \
    --max-time 2 \
    -s -o /dev/null -w "Request $i: %{http_code} in %{time_total}s\n" &
done

wait
echo "All requests completed"

echo
echo "Check Rails logs for detailed timing information:"
echo "tail -n 50 log/development.log | grep '==='  "