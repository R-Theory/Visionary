# ADR-002: TTS Service Selection and Architecture

## Context

Visionary requires text-to-speech functionality for PDF pages to enable listening while multitasking. The TTS solution must handle academic/technical content quality, support multiple languages, provide reasonable cost structure, and integrate with caching for performance.

**Background and forces at play:**
- Academic PDFs often contain technical terminology, equations, and complex sentence structures
- Users may process hundreds of pages per day (cost implications)
- Network reliability varies (offline capability desired)
- Quality expectations are high for extended listening sessions
- Integration must respect agent constraints: 10 req/min per user, 10K character limit

## Decision

Implement **Speechify API as primary** with **local TTS fallback architecture**:

1. **Primary**: Speechify API for high-quality synthesis
2. **Fallback**: Piper TTS (local) for offline/cost optimization  
3. **Cache layer**: 24-hour TTL per agent constraints
4. **Rate limiting**: Strict enforcement of 10 requests/minute per user

**Service Architecture:**
- TTS Agent handles all synthesis requests through unified interface
- Automatic fallback on API failures or rate limit exceeded
- Aggressive caching to minimize API calls and costs
- Background job processing to avoid blocking UI
- User preference for voice selection and fallback behavior

## Alternatives

### Option A: OpenAI TTS (Whisper-based)
**Pros:**
- High quality, natural-sounding voices
- Good handling of technical terminology
- Existing API integration patterns in codebase
- Reasonable pricing structure

**Cons:**
- Limited voice options compared to Speechify
- Less specialized for long-form content consumption
- API rate limits more restrictive
- No specific optimization for academic content

### Option B: Google Cloud Text-to-Speech
**Pros:**
- Excellent multilingual support
- WaveNet voices with high quality
- Good pricing for high volume
- Reliable enterprise SLA

**Cons:**
- More complex authentication setup
- Voice options not optimized for long listening
- Limited customization for academic content
- Higher implementation complexity

### Option C: Amazon Polly
**Pros:**
- AWS ecosystem integration
- Neural voices available
- Good pricing at scale
- SSML support for pronunciation

**Cons:**
- Voice quality not optimal for extended listening
- Limited academic content optimization
- More complex AWS integration required
- Neural voices have usage limits

### Option D: Local-only TTS (Piper/Coqui)
**Pros:**
- No API costs or rate limits
- Complete privacy and offline functionality
- Deterministic performance
- No external dependencies

**Cons:**
- Significantly lower voice quality
- Large model downloads required
- Higher compute resource usage
- Limited voice options

## Consequences

### Positive:
- **Quality**: Speechify provides voices optimized for long-form listening
- **Cost management**: Caching and rate limiting control API expenses
- **Reliability**: Local fallback ensures functionality during API outages
- **Performance**: Background processing doesn't block user interface
- **Flexibility**: Users can choose voice preferences and fallback behavior

### Negative:
- **Complexity**: Dual TTS system increases implementation and testing overhead
- **Resource usage**: Local TTS models require additional storage and compute
- **Cost unpredictability**: API usage may exceed estimates with heavy users
- **Maintenance burden**: Two TTS systems to maintain and optimize

### Follow-ups:
- Monitor API usage and costs in production, adjust caching strategy
- Implement user feedback system for voice quality and preference tuning
- Create cost alerting and usage analytics dashboard
- Plan transition strategy if primary service becomes unavailable
- Evaluate additional local TTS models (ElevenLabs, Tortoise) for quality improvement

## Status

**Accepted** - 2025-09-06

## Implementation Notes

**Agent Constraints (from docs/AGENTS.md):**
- Maximum text length: 10,000 characters per request (enforced before API calls)
- Rate limiting: 10 requests per minute per user (implemented with Redis)
- Cache TTL: 24 hours (configurable via environment)
- Circuit breaker: 5 failure threshold with 60-second recovery timeout

**Success Criteria:**
- [ ] TTS generation <30 seconds per page for typical academic content
- [ ] Cache hit rate >80% after initial generation
- [ ] Fallback activation <10 seconds when primary service fails
- [ ] Rate limiting prevents API cost overruns
- [ ] Voice quality acceptable for 30+ minute listening sessions

**Cost Management:**
- Budget alert at $100/month API usage
- Cache-first strategy to minimize API calls
- User education about rate limits and cost implications
- Analytics tracking to optimize caching and usage patterns

**Technical Integration:**
- Background Celery workers handle TTS job processing
- Redis stores job queue and rate limiting counters
- S3/MinIO stores cached audio files with TTL cleanup
- Frontend polling for job status with optimistic UI updates