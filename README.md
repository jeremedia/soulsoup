# Soulsoup - Soul Persistence Backend

Soulsoup is the Rails 8 backend for the Soulforge Universe, managing persistent AI souls that learn and evolve through multiple incarnations across different experiential forges.

## Overview

This Rails API provides:
- **Soul persistence** with 256-dimensional genomes
- **Incarnation tracking** across game sessions
- **Event streaming** from game forges
- **Experience accumulation** and relationship formation
- **Vector memory storage** using pg_vector
- **LLM integration** for narrative synthesis (coming soon)

## Technical Stack

- **Rails 8.0.2** with PostgreSQL
- **pg_vector** for personality embeddings
- **Rails Event Store** for event sourcing
- **Neighbor gem** for vector similarity search
- **Solid Queue/Cache/Cable** for background processing
- **Kamal** for deployment

## Getting Started

### Prerequisites
- Ruby 3.4.1
- PostgreSQL with pg_vector extension
- Node.js (for asset compilation)

### Installation

```bash
# Install dependencies
bundle install

# Create and setup database
rails db:create
rails db:migrate
rails db:seed  # Creates 10 test souls

# Start the server (runs on port 4001)
rails server
```

## API Endpoints

### Soul Incarnation Request
```http
POST /api/v1/incarnations/request
Content-Type: application/json

{
  "game_session_id": "session-123",
  "forge_type": "combat",
  "team_preferences": ["red", "blue"],
  "challenge_level": "normal"
}

Response:
{
  "soul_id": "soul-xxxxx",
  "incarnation_id": "inc-xxxxx",
  "modifiers": {
    "courage_bonus": 0.15,
    "aim_adjustment": 0.08,
    "retreat_timing": -50
  },
  "personality_hints": ["tends toward bold action"],
  "vendetta_souls": ["soul-yyyyy"]
}
```

### Event Batch Submission
```http
POST /api/v1/events/batch
Content-Type: application/json

{
  "events": [
    {
      "incarnation_id": "inc-xxxxx",
      "type": "combat_kill",
      "timestamp": 1234567890,
      "target_soul_id": "soul-yyyyy",
      "context": { "range": 45, "weapon": "rifle" }
    }
  ]
}
```

### View Souls
```http
GET /api/v1/souls
GET /api/v1/souls/:id
```

## Core Models

### Soul
- **soul_id**: Unique identifier (nanoid)
- **genome**: 256-dimensional JSONB array defining personality
- **personality_vector**: pg_vector embedding for similarity search
- **base_traits**: Temperament, learning style, etc.
- **total_incarnations**: Lifetime incarnation count
- **current_grace_level**: Progress toward transcendence (0.0-1.0)

### Incarnation
- Links a soul to a specific game session
- Tracks forge type, modifiers, events, and experience
- Records memory summary and LoRA weights URL (future)

### SoulRelationship
- Tracks vendetta, alliance, mentor/student relationships
- Bidirectional with strength values
- Influences future incarnation behavior

## Event Types

- **combat_kill**: Attacker killed victim
- **combat_death**: Unit died
- **resource_gathered**: Collected resources
- **objective_completed**: Achieved game goal
- **cooperation_success**: Teamwork event
- **creation_completed**: Built something
- **negotiation_success**: Diplomatic win
- **discovery_made**: Found secret
- **soul_nurtured**: Caretaking action

## Development

```bash
# Run console
rails console

# Run tests
rails test

# Background jobs (using Solid Queue)
rails jobs:work

# Check soul data
Soul.first.incarnations
Soul.first.personality_traits
```

## Deployment

This app is configured for deployment with Kamal:

```bash
kamal setup
kamal deploy
```

## CORS Configuration

The API allows requests from:
- `http://localhost:5173` (Vite dev server)
- `http://localhost:3000` (Alternative dev)
- `https://jeremedia.com` (Production)

## Future Features

- [ ] Admin dashboard with Turbo/Stimulus
- [ ] LLM narrative generation (OpenAI/Ollama)
- [ ] Dream synthesis job for RL training
- [ ] Memory search with vector embeddings
- [ ] Soul relationship visualization
- [ ] Grace detection algorithms
- [ ] Soul liberation mechanics

## Contributing

This is part of the larger Soulforge Universe project. See the main README for contribution guidelines.

## License

[Add license information]