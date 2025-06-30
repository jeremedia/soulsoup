# Soulsoup API Performance Documentation

## Overview

The Soulsoup API backend has been optimized to handle the burst of ~20 concurrent soul incarnation requests that occur when the Soulforge game starts up.

## Key Optimizations

### 1. Threading Configuration
```bash
# Start Rails with optimized thread pool
RAILS_MAX_THREADS=10 WEB_CONCURRENCY=2 rails server -p 4001
```
- 10 threads per worker (up from default 3)
- 2 worker processes for better concurrency
- Can handle 20 concurrent requests effectively

### 2. Database Optimizations

#### Indexes Added
```ruby
# Indexes for finding available souls quickly
add_index :incarnations, [:soul_id, :ended_at]
add_index :incarnations, [:game_session_id, :ended_at]
add_index :soul_relationships, [:soul_id, :related_soul_id], unique: true
add_index :souls, :current_grace_level
```

#### Soul Pool Management
```bash
# Create soul pool to avoid creating souls during gameplay
rails souls:create_pool COUNT=100

# Check soul statistics
rails souls:stats

# Clean up stuck incarnations
rails souls:cleanup
```

### 3. Concurrency Handling

#### Row-Level Locking
```ruby
def incarnate!(forge_type:, game_session_id:)
  with_lock do
    # Prevents same soul being assigned to multiple incarnations
    if incarnations.active.exists?
      raise ActiveRecord::RecordInvalid.new(self), "Soul already has active incarnation"
    end
    
    incarnations.create!(...)
  end
end
```

#### Retry Logic
The controller automatically retries up to 3 times if a soul conflict occurs:
```ruby
rescue ActiveRecord::RecordInvalid => e
  if e.message.include?("Soul already has active incarnation") && retries < 3
    retries += 1
    retry
  end
end
```

### 4. API Changes

#### Route Update
- Changed from `/api/v1/incarnations/request` to `/api/v1/incarnations`
- Fixed Rails reserved method name conflict (`request` → `create`)

#### Frontend Integration
```javascript
// SoulforgeAPI.js updated with:
- 5-second timeout to prevent hanging
- Proper error handling with offline fallback
- Concurrent request support
```

## Performance Metrics

### Before Optimization
- Rails server hanging on startup burst
- Stack overflow errors
- 100% CPU usage
- Unable to handle 20 concurrent requests

### After Optimization
- All 20 concurrent requests handled successfully
- Average response time: ~700ms per request
- No hanging or timeouts
- Proper soul reuse preventing database bloat

## Testing

### Burst Test Command
```bash
for i in {1..20}; do
  curl -s -X POST http://localhost:4001/api/v1/incarnations \
    -H "Content-Type: application/json" \
    -d '{"game_session_id": "test-'$i'", "forge_type": "combat"}' &
done
wait
```

### Load Testing Results
- 20 concurrent requests: ✅ Success
- Soul uniqueness maintained: ✅ Each request gets unique soul
- Database consistency: ✅ No duplicate active incarnations
- Error recovery: ✅ Retry logic handles conflicts

## Future Improvements

1. **Connection Pooling**: Increase database pool size for more concurrent connections
2. **Caching**: Cache available souls in Redis for faster lookups
3. **WebSockets**: Consider ActionCable for real-time soul updates
4. **Background Jobs**: Move soul computation to background jobs

## Monitoring

Key metrics to monitor:
- Active incarnation count
- Soul pool availability
- Request response times
- Retry frequency
- Database connection pool usage