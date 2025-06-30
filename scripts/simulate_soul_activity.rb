#!/usr/bin/env ruby

# Script to simulate soul activity for testing real-time dashboard
require 'net/http'
require 'json'
require 'uri'

class SoulSimulator
  API_BASE = 'http://localhost:4001/api/v1'
  
  def initialize
    @session_id = "sim-session-#{Time.now.to_i}"
    @active_incarnations = []
  end
  
  def run
    puts "Starting soul activity simulation..."
    puts "Watch the dashboard at http://localhost:4001/"
    puts "Press Ctrl+C to stop"
    
    loop do
      begin
        # Create new incarnation
        if @active_incarnations.length < 5 && rand < 0.3
          create_incarnation
        end
        
        # End random incarnation
        if @active_incarnations.any? && rand < 0.2
          end_random_incarnation
        end
        
        # Send heartbeat
        if @active_incarnations.any? && rand < 0.5
          send_heartbeat
        end
        
        sleep rand(1..3)
      rescue Interrupt
        puts "\nStopping simulation..."
        end_all_incarnations
        break
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end
  
  private
  
  def create_incarnation
    uri = URI("#{API_BASE}/incarnations")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      game_session_id: @session_id,
      forge_type: %w[combat collaboration creation].sample,
      team_preferences: %w[red blue green yellow].sample(2),
      challenge_level: 'normal'
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200' || response.code == '201'
      data = JSON.parse(response.body)
      @active_incarnations << data
      puts "✨ Created incarnation: #{data['soul_id']} (#{data['incarnation_id']})"
    else
      puts "Failed to create incarnation: #{response.code} - #{response.body}"
    end
  end
  
  def end_random_incarnation
    incarnation = @active_incarnations.sample
    return unless incarnation
    
    uri = URI("#{API_BASE}/incarnations/#{incarnation['incarnation_id']}/end")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    outcome = rand < 0.7 ? 'death' : 'victory'
    kills = rand(0..15)
    level = [1 + kills / 3, 15].min
    
    request.body = {
      ended_at: Time.now.iso8601,
      memory_summary: {
        outcome: outcome,
        final_level: level,
        kills: kills,
        lifetime: rand(60000..300000),
        resources_gathered: rand(0..20)
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      @active_incarnations.delete(incarnation)
      puts "💀 Ended incarnation: #{incarnation['soul_id']} - #{outcome} (#{kills} kills)"
    end
  end
  
  def send_heartbeat
    return if @active_incarnations.empty?
    
    uri = URI("#{API_BASE}/sessions/#{@session_id}/heartbeat")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      incarnation_ids: @active_incarnations.map { |i| i['incarnation_id'] }
    }.to_json
    
    response = http.request(request)
    puts "💓 Heartbeat sent for #{@active_incarnations.length} incarnations" if response.code == '200'
  end
  
  def end_all_incarnations
    puts "Ending all active incarnations..."
    @active_incarnations.each do |incarnation|
      uri = URI("#{API_BASE}/incarnations/#{incarnation['incarnation_id']}/end")
      http = Net::HTTP.new(uri.host, uri.port)
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = {
        ended_at: Time.now.iso8601,
        memory_summary: { outcome: 'simulation_ended' }
      }.to_json
      
      http.request(request)
    end
  end
end

# Run the simulator
SoulSimulator.new.run