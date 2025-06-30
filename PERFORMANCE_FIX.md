# Quick Performance Fix

## The Problem

The `/api/v1/incarnations/request` endpoint was creating a brand new soul for EVERY request:
- 256 random numbers generated
- 256-element vector computed
- 2 database writes (Soul + Incarnation)
- This happens for every soldier spawn!

## Quick Fix

1. **Restart Rails with better config**:
   ```bash
   RAILS_MAX_THREADS=10 WEB_CONCURRENCY=2 rails server
   ```

2. **Pre-create a soul pool** (in Rails console):
   ```ruby
   # Create 100 souls in advance
   100.times do
     Soul.create!(
       total_incarnations: 0,
       current_grace_level: 0.0
     )
   end
   ```

3. **Clear any stuck incarnations**:
   ```ruby
   # End incarnations older than 1 hour
   Incarnation.active.where("started_at < ?", 1.hour.ago).each do |inc|
     inc.update!(ended_at: Time.current)
   end
   ```

## What Changed

The controller now:
1. **Reuses existing souls** instead of creating new ones
2. Only creates new souls when the pool is empty
3. Logs whether it's reusing or creating

## Monitoring

Watch the logs for:
```
Reusing soul soul-xxxxx for new incarnation
```
vs
```
Creating new soul - no available souls in pool
```

## Next Steps

1. Add background job to maintain soul pool
2. Add caching for soul lookups
3. Optimize genome initialization
4. Consider batch incarnation requests