#!/usr/bin/env ruby
require "net/http"
require "json"
require "benchmark"

# Configuration
API_URL = "http://localhost:4001/api/v1/incarnations/request"
CONCURRENT_REQUESTS = 20  # Simulating initial game spawn

def make_request(session_num)
  uri = URI(API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 5
  http.read_timeout = 30
  
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = {
    game_session_id: "bench-session-#{session_num}",
    forge_type: "combat",
    team_preferences: ["Red", "Blue"].sample,
    challenge_level: "normal"
  }.to_json
  
  response = http.request(request)
  JSON.parse(response.body)
rescue => e
  puts "Request failed: #{e.message}"
  nil
end

puts "Testing Soulsoup Incarnation API Performance"
puts "=" * 50

# Test 1: Sequential requests
puts "\n1. Sequential Requests (#{CONCURRENT_REQUESTS} total):"
times = []
CONCURRENT_REQUESTS.times do |i|
  time = Benchmark.realtime do
    result = make_request(i)
    print "." if result
  end
  times << time
end
puts "\nAverage time: #{(times.sum / times.size * 1000).round(2)}ms"
puts "Total time: #{(times.sum * 1000).round(2)}ms"

# Test 2: Concurrent requests (simulating game start)
puts "\n2. Concurrent Requests (#{CONCURRENT_REQUESTS} threads):"
threads = []
results = []
mutex = Mutex.new

total_time = Benchmark.realtime do
  CONCURRENT_REQUESTS.times do |i|
    threads << Thread.new do
      result = make_request(1000 + i)
      mutex.synchronize do
        results << result if result
        print "."
      end
    end
  end
  
  threads.each(&:join)
end

puts "\nTotal time for #{CONCURRENT_REQUESTS} concurrent requests: #{(total_time * 1000).round(2)}ms"
puts "Average time per request: #{(total_time / CONCURRENT_REQUESTS * 1000).round(2)}ms"
puts "Successful requests: #{results.size}/#{CONCURRENT_REQUESTS}"

# Show a sample response
if results.any?
  puts "\nSample response:"
  puts JSON.pretty_generate(results.first)
end