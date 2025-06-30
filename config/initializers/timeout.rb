# Set a reasonable timeout for API requests
# This prevents slow requests from blocking threads indefinitely

if defined?(Rack::Timeout)
  # 5 seconds should be plenty for soul requests
  Rack::Timeout.service_timeout = 5
  
  # Don't wait too long in the queue
  Rack::Timeout.wait_timeout = 5
end