# Soulsoup Performance Tuning Guide

## Quick Fix for Slow Responses

If the Rails server is responding slowly to game requests, restart it with these environment variables:

```bash
# Stop the current server (Ctrl+C)

# Start with more threads and workers
RAILS_MAX_THREADS=10 WEB_CONCURRENCY=2 rails server
```

## Configuration Changes Made

### 1. Puma Configuration (`config/puma.rb`)
- Increased default threads from 3 to 10
- Added 2 workers for development (processes requests in parallel)
- This handles more concurrent soul requests

### 2. Database Pool (`config/database.yml`)
- Increased connection pool from 5 to 10
- Matches the thread count to prevent connection exhaustion

### 3. Timeout Settings (`config/initializers/timeout.rb`)
- Added 5-second timeout for requests
- Prevents slow requests from blocking threads

## Additional Optimizations

### For Development

```bash
# Run with explicit settings
RAILS_MAX_THREADS=15 WEB_CONCURRENCY=3 rails server
```

### For Production

```bash
# Even more threads and workers
RAILS_ENV=production RAILS_MAX_THREADS=20 WEB_CONCURRENCY=4 rails server
```

## Monitoring Performance

Watch the Rails logs for:
- Request queue times
- Database query times
- Thread pool exhaustion warnings

```ruby
# In rails console, check active connections:
ActiveRecord::Base.connection_pool.stat
```

## Database Optimizations

Add indexes for common queries:

```ruby
# Generate migration
rails generate migration AddIndexesToSoulsAndIncarnations

# In the migration:
add_index :incarnations, [:soul_id, :ended_at]
add_index :incarnations, [:game_session_id, :ended_at]
add_index :souls, :current_grace_level
```

## API Response Optimizations

1. **Use includes to prevent N+1 queries**:
   ```ruby
   soul = Soul.includes(:incarnations, :soul_relationships).find_by(soul_id: params[:id])
   ```

2. **Cache soul lookups**:
   ```ruby
   Rails.cache.fetch("soul/#{soul_id}", expires_in: 5.minutes) do
     Soul.find_by(soul_id: soul_id)
   end
   ```

3. **Batch event processing**:
   The current implementation processes events one by one. Consider:
   ```ruby
   # In EventsController
   ActiveRecord::Base.transaction do
     events.each { |event| process_event(event) }
   end
   ```

## Frontend Optimizations

In `SoulforgeAPI.js`, consider:
- Increasing batch interval if needed (currently 5 seconds)
- Adding request retry logic with exponential backoff
- Implementing request queuing to prevent overwhelming the server

## Testing Performance

```bash
# Simple load test
ab -n 100 -c 10 http://localhost:4001/api/v1/souls

# Watch server logs
tail -f log/development.log | grep "Completed"
```

## When to Scale Further

If you're still seeing issues:
1. Consider using Redis for caching
2. Move to Sidekiq for background job processing
3. Use PostgreSQL connection pooling (PgBouncer)
4. Deploy with proper production server (not just `rails server`)