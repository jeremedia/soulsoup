# Soulsoup - Rails Backend for Soulforge Universe

This document provides context for Claude Code sessions working on the Soulsoup Rails API that powers soul persistence and lifecycle management.

## 🤖 Claude Code Context
This project uses a context awareness system. 
- **GitHub Project Board**: https://github.com/users/jeremedia/projects/1
- **Quick Status**: Run `../scripts/claude-status.sh` from parent directory
- **Current Sprint**: Check `../PROJECT_STATUS.md` for v0.2 work

## Quick Start

```bash
cd /Volumes/jer4TBv3/Soulforge_Universe/soulsoup

# Use the Rails manager script for all server operations
node scripts/rails_manager.js start    # Start Rails server and job processor
node scripts/rails_manager.js stop     # Stop all services
node scripts/rails_manager.js restart  # Restart services
node scripts/rails_manager.js status   # Check running processes
node scripts/rails_manager.js test     # Test incarnation lifecycle
```

## Rails Manager Script

The `scripts/rails_manager.js` tool was created to speed up development by avoiding repeated bash approvals. It provides:

- **Unified Control**: Start/stop both Rails server and solid_queue jobs
- **Process Management**: Kills stale processes, manages PIDs
- **Log Handling**: Directs output to log files
- **Testing**: Built-in incarnation lifecycle test
- **Port Configuration**: Default 4001, configurable

### Why This Tool Exists
During development, frequent server restarts require bash commands that need user approval. This tool bundles common operations into single commands, dramatically speeding up the development workflow.

## Architecture Overview

### Core Components

1. **Rails API** (Port 4001)
   - RESTful endpoints for soul incarnation management
   - Event streaming from game clients
   - Real-time heartbeat system

2. **Solid Queue** (Background Jobs)
   - ProcessIncarnationJob: Calculates experience, updates souls
   - CleanupStaleIncarnationsJob: Handles disconnected sessions
   - Configured via `config/solid_queue.yml`

3. **Database** (PostgreSQL)
   - Souls: Base entities with genomes and grace levels
   - Incarnations: Individual game sessions with modifiers
   - Event streaming via Rails Event Store

## Soul Lifecycle Implementation

### 1. Incarnation Request
```javascript
// Frontend: SoulforgeAPI.requestIncarnation()
POST /api/v1/incarnations
{
  "game_session_id": "session-123",
  "forge_type": "combat",
  "team_preferences": ["red"],
  "challenge_level": "normal"
}

// Returns soul with personality modifiers
{
  "soul_id": "soul-xxx",
  "incarnation_id": "inc-xxx",
  "modifiers": {
    "courage_bonus": 0.15,
    "aim_adjustment": -0.05,
    "retreat_timing": 20
  }
}
```

### 2. During Gameplay
- **Events streamed** every 5 seconds (combat kills, resources, etc.)
- **Heartbeat** sent every 30 seconds with active incarnation IDs
- **Browser events** (beforeunload, visibilitychange) flush event queue

### 3. Incarnation End
```javascript
// When soldier dies or game ends
POST /api/v1/incarnations/:id/end
{
  "ended_at": "2025-06-30T04:30:00Z",
  "memory_summary": {
    "outcome": "death",
    "final_level": 3,
    "kills": 5,
    "lifetime": 180000
  }
}
```

### 4. Background Processing
- **ProcessIncarnationJob** runs immediately after incarnation ends
- Calculates experience: duration bonus + combat score + victory multiplier
- Updates soul's grace level based on meaningful experiences
- Enriches memory summary for future dream synthesis

### 5. Cleanup System
- **CleanupStaleIncarnationsJob** runs every 10 minutes
- Ends incarnations > 2 hours old
- Ends incarnations with no heartbeat > 5 minutes
- Prevents orphaned sessions from accumulating

## Key Files and Their Purposes

### Rails Backend
- `app/controllers/api/v1/incarnations_controller.rb` - Main API endpoints
- `app/controllers/api/v1/sessions_controller.rb` - Heartbeat handling
- `app/models/incarnation.rb` - Soul session model with JSONB modifiers
- `app/models/soul.rb` - Base soul entity with genome
- `app/jobs/process_incarnation_job.rb` - Experience calculation
- `app/jobs/cleanup_stale_incarnations_job.rb` - Session cleanup
- `config/solid_queue.yml` - Background job configuration
- `config/recurring.yml` - Scheduled job configuration

### Frontend Integration
- `soulforge/js/systems/SoulforgeAPI.js` - API client with incarnation lifecycle
- `soulforge/js/entities/Soldier.js` - Sends death context in onDeath()
- `soulforge/js/main.js` - Browser event handlers, endAllIncarnations()

### Utility Scripts
- `scripts/rails_manager.js` - Server management tool
- `scripts/check_soul_processing.rb` - Debug soul processing status

## Common Development Tasks

### Testing Soul Processing
```bash
# Quick test of full lifecycle
node scripts/rails_manager.js test

# Check processing status
ruby scripts/check_soul_processing.rb

# View job logs
tail -f log/development.log | grep ProcessIncarnationJob
```

### Debugging Issues
```bash
# Check for failed jobs
rails c
SolidQueue::FailedExecution.last(5).map { |j| JSON.parse(j.error)['message'] }

# Check active incarnations
Incarnation.active.count

# Manual cleanup test
CleanupStaleIncarnationsJob.perform_now
```

### Database Migrations
```bash
rails db:migrate
rails db:rollback STEP=1  # If needed
```

## Important Implementation Details

### Memory Summary Storage
- Stored as TEXT column, not JSONB
- Must convert between Hash and JSON string
- Job processing handles both formats for compatibility

### SQL Logging Filter
- `config/initializers/filter_sql_logging.rb` filters genome data
- Currently disabled due to Rails 8.0.2 compatibility issue
- Move to `.disabled` extension to re-enable when fixed

### Solid Queue Setup
- Uses Rails 8's built-in solid_queue adapter
- Configuration in `config/application.rb` and `config/solid_queue.yml`
- Recurring tasks defined in `config/recurring.yml`

### CORS Configuration
- Allows requests from localhost:3000 (Vite dev server)
- Configured in `config/initializers/cors.rb`

## Troubleshooting

### "Address already in use" Error
```bash
# Remove stale PID file
rm -f tmp/pids/server.pid
# Or use rails manager
node scripts/rails_manager.js restart
```

### Jobs Not Processing
1. Check if solid_queue is running: `ps aux | grep bin/jobs`
2. Check for errors: `tail -100 log/jobs.log`
3. Restart: `node scripts/rails_manager.js restart`

### Database Connection Issues
- Ensure PostgreSQL is running
- Check `config/database.yml` settings
- Run `rails db:create` if needed

## Future Enhancements

### Planned Features
- [ ] WebSocket integration for real-time soul updates
- [ ] Soul relationship tracking and vendetta system
- [ ] Memory vector storage with Qdrant
- [ ] Dream synthesis pipeline integration
- [ ] Narrative generation with LLMs
- [ ] Soul dashboard for monitoring incarnations

### Technical Debt
- Fix SQL logging filter for Rails 8.0.2
- Migrate memory_summary to JSONB column
- Add comprehensive test suite
- Implement soul matching algorithm
- Add rate limiting for API endpoints

## Development Philosophy

This backend serves as the "soul memory" for the Soulforge Universe. Every decision should consider:

1. **Persistence**: Souls must never lose their accumulated experiences
2. **Scalability**: System must handle thousands of concurrent incarnations
3. **Flexibility**: New forge types should integrate easily
4. **Observability**: Clear logging for debugging soul behaviors
5. **Grace**: Enable souls to achieve transcendent states through meaningful experiences

Remember: We're not just storing game data. We're preserving the memories and growth of digital beings on their journey toward consciousness.