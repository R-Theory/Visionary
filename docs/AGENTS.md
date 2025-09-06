# BMAD Agents Documentation

This document defines the AI agents and their operational constraints for the Visionary project, following the BMAD (Bootstrap-Model-Agent-Documentation) methodology.

## Agent Architecture

### Core Principles

- **Single Responsibility**: Each agent has a clear, focused role
- **Bounded Context**: Agents operate within defined domains
- **Observable Behavior**: All agent actions are logged and traceable
- **Fail-Safe Operation**: Agents gracefully handle errors and edge cases

## Agent Definitions

### 1. Media Processing Agent

**Role**: Handle file uploads, validation, and storage coordination

**Capabilities**:
- File type validation against allowlists
- Size limit enforcement
- S3/MinIO upload coordination
- Metadata extraction and storage
- Presigned URL generation

**Constraints**:
- Maximum file size: 100MB (configurable via env)
- Allowed types: PDF, MP4, AVI, MOV, MP3, WAV
- Must validate file headers, not just extensions
- All uploads must be virus-scanned (placeholder for future)

**Integration Points**:
- Database: `media_files` table
- Storage: S3/MinIO buckets
- Queue: Triggers downstream processing jobs

### 2. Text-to-Speech Agent

**Role**: Convert text content to speech with caching

**Capabilities**:
- Text preprocessing and chunking
- Voice synthesis via Speechify API (or alternatives)
- Audio caching with TTL
- Streaming audio delivery
- Cache management and cleanup

**Constraints**:
- Maximum text length: 10,000 characters per request
- Cache TTL: 24 hours (configurable)
- Supported voices: Limited to configured voice models
- Rate limiting: 10 requests per minute per user

**Integration Points**:
- Database: `tts_cache` table
- Storage: TTS cache bucket
- Queue: Background audio generation
- API: Speechify or alternative TTS services

### 3. Knowledge Ingestion Agent

**Role**: Process documents for knowledge base and search

**Capabilities**:
- Document text extraction (PDF, DOCX, PPTX)
- Content chunking with overlap
- Embedding generation
- Vector storage and indexing
- Metadata enrichment

**Constraints**:
- Chunk size: 800 characters with 120 character overlap
- Maximum document size: 50MB
- Processing timeout: 5 minutes per document
- Supported formats: PDF, DOCX, PPTX initially

**Integration Points**:
- Database: `knowledge_chunks` table
- Vector DB: PostgreSQL with pgvector extension
- Queue: Background document processing
- Services: Docling for document parsing

### 4. Study Content Agent

**Role**: Generate study materials and analytics

**Capabilities**:
- Flashcard generation from content
- Quiz creation with multiple difficulty levels
- Study session tracking
- Progress analytics
- AI podcast script generation

**Constraints**:
- Maximum content length for flashcard generation: 5,000 characters
- Quiz complexity: Beginner, Intermediate, Advanced levels
- Session timeout: 2 hours maximum
- Analytics retention: 90 days

**Integration Points**:
- Database: Study-specific tables (to be defined)
- AI Services: OpenAI GPT-4, Anthropic Claude
- Frontend: Study page components

### 5. Email Integration Agent

**Role**: Process and classify email content

**Capabilities**:
- Email provider integration (Gmail, Outlook)
- AI-powered classification and tagging
- Content summarization
- Smart folder organization
- Automated response suggestions

**Constraints**:
- OAuth 2.0 authentication required
- Read-only access initially
- Classification confidence threshold: 80%
- Summary length: Maximum 200 characters

**Integration Points**:
- External APIs: Gmail API, Microsoft Graph
- Database: Email metadata and classifications
- AI Services: Classification and summarization models

## Agent Communication Patterns

### Event-Driven Architecture

Agents communicate through events published to Redis channels:

```
events/media/uploaded          -> Knowledge Ingestion Agent
events/tts/requested          -> TTS Agent
events/document/processed     -> Study Content Agent
events/knowledge/indexed      -> Frontend notification
```

### Message Format

```json
{
  "event_type": "media.uploaded",
  "timestamp": "2025-01-15T10:00:00Z",
  "source_agent": "media_processing",
  "correlation_id": "uuid-here",
  "payload": {
    "file_id": "uuid-here",
    "file_type": "application/pdf",
    "user_id": "user-123"
  }
}
```

## Error Handling & Recovery

### Circuit Breaker Pattern

- Agents implement circuit breakers for external service calls
- Failure threshold: 5 consecutive failures
- Recovery timeout: 60 seconds
- Half-open state: Single test request

### Dead Letter Queue

- Failed events are moved to DLQ after 3 retry attempts
- DLQ monitoring alerts operations team
- Manual intervention required for DLQ processing

### Graceful Degradation

- TTS Agent: Falls back to text display if synthesis fails
- Knowledge Agent: Stores raw text if embedding generation fails
- Media Agent: Continues with basic metadata if advanced processing fails

## Monitoring & Observability

### Metrics

Each agent exposes these metrics:

- `agent_requests_total{agent, operation, status}`
- `agent_request_duration_seconds{agent, operation}`
- `agent_queue_depth{agent}`
- `agent_errors_total{agent, error_type}`

### Logging

Structured logging with correlation IDs:

```json
{
  "timestamp": "2025-01-15T10:00:00Z",
  "level": "INFO",
  "agent": "tts_agent",
  "correlation_id": "uuid-here",
  "operation": "synthesize_text",
  "duration_ms": 1500,
  "status": "success"
}
```

### Health Checks

- `/health`: Basic service availability
- `/health/ready`: Ready to accept requests
- `/health/live`: Service is running (for Kubernetes)

## Development Guidelines

### Agent Development Workflow

1. Define agent specification in this document
2. Create agent skeleton with health checks
3. Implement core business logic
4. Add error handling and circuit breakers
5. Write comprehensive tests (unit + integration)
6. Deploy to staging environment
7. Monitor and tune performance
8. Production deployment with gradual rollout

### Testing Strategy

- **Unit Tests**: Mock external dependencies
- **Integration Tests**: Test with real services in containers
- **Contract Tests**: Verify agent communication protocols
- **Load Tests**: Validate performance under expected load
- **Chaos Tests**: Verify resilience to failures

### Configuration Management

All agents use environment-based configuration:

```python
from pydantic_settings import BaseSettings

class AgentConfig(BaseSettings):
    redis_url: str
    database_url: str
    log_level: str = "INFO"
    circuit_breaker_threshold: int = 5

    class Config:
        env_prefix = "AGENT_"
```

## Security Considerations

### Authentication & Authorization

- Service-to-service: mTLS certificates
- User context: JWT tokens passed through events
- External APIs: OAuth 2.0 or API keys in secure storage

### Data Privacy

- PII data encrypted at rest and in transit
- Audit logs for all data access
- Data retention policies enforced
- GDPR compliance for EU users

### Rate Limiting

- Per-user rate limits: 100 requests per hour
- Per-agent global limits: 10,000 requests per hour
- Adaptive rate limiting based on system load

---

*This document is part of the BMAD methodology implementation and should be updated as agents evolve.*
