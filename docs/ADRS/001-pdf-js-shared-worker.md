# ADR-001: PDF.js Shared Worker Integration

## Context

Visionary requires PDF viewing capabilities that can handle large documents (1000+ pages) with smooth performance and per-page TTS functionality. OpenWebUI may already use PDF.js, creating potential version conflicts and memory duplication issues.

**Background and forces at play:**
- Large PDFs (300+ pages) must load quickly (<5 seconds first page)
- Memory usage must remain reasonable with multiple PDF tabs open
- OpenWebUI's existing PDF.js version must not conflict with our implementation  
- Browser compatibility varies significantly for shared workers
- TTS integration requires page-level text extraction
- Mobile browser limitations with iframe and worker support

## Decision

Implement **PDF.js Shared Worker** architecture with fallback strategies:

1. **Primary**: Shared worker using PDF.js version matching OpenWebUI's exact version
2. **Secondary**: Dedicated worker per tab if shared workers unavailable  
3. **Tertiary**: Direct PDF.js integration without workers for incompatible browsers

**Architecture components:**
- Shared worker for PDF.js processing across all tabs
- Virtual scrolling for large document performance
- Page caching with LRU eviction (100MB memory limit)
- Cross-tab communication via BroadcastChannel
- Progressive loading with HTTP Range requests

## Alternatives

### Option A: Direct PDF.js Integration (No Workers)
**Pros:**
- Simple implementation, fewer moving parts
- Better browser compatibility
- Easier debugging and development

**Cons:**  
- Poor performance with large PDFs (>100MB)
- Memory duplication across multiple tabs
- UI blocking during PDF processing
- Potential version conflicts with OpenWebUI

### Option B: Dedicated Worker Per Tab
**Pros:**
- Better performance than direct integration
- No shared worker compatibility issues
- Isolated failure domains

**Cons:**
- Memory duplication across tabs
- Higher resource usage with multiple PDFs open
- Complex state management per worker

### Option C: Server-Side PDF Processing 
**Pros:**
- No browser memory limitations
- Consistent processing environment
- Better security isolation

**Cons:**
- Higher server resource requirements
- Network overhead for page requests  
- Increased infrastructure complexity
- Poor offline functionality

## Consequences

### Positive:
- **Performance**: Large PDFs load and scroll smoothly
- **Memory efficiency**: Single PDF.js instance serves multiple tabs
- **Compatibility**: Fallback ensures functionality across all browsers
- **Integration**: No conflicts with OpenWebUI's existing PDF.js usage
- **TTS ready**: Page-level text extraction built into architecture

### Negative:
- **Complexity**: Shared worker lifecycle management is intricate
- **Debugging**: Harder to debug worker-related issues in development
- **Browser support**: SharedWorker not supported in all mobile browsers
- **Implementation time**: Significantly more complex than direct integration

### Follow-ups:
- Monitor memory usage in production and adjust cache limits
- Implement comprehensive browser compatibility testing
- Create performance benchmarks for large PDF loading  
- Document worker debugging procedures for development team
- Plan migration strategy if shared worker approach proves problematic

## Status

**Accepted** - 2025-09-06

## Implementation Notes

**Agent Constraints (from docs/AGENTS.md):**
- Must integrate with Media Processing Agent file validation
- Must support TTS Agent's per-page text extraction requirements
- Must respect browser resource limits and graceful degradation principles

**Success Criteria:**
- [ ] 1000+ page PDF loads first page in <5 seconds
- [ ] Memory usage <100MB per PDF viewer instance  
- [ ] Fallback works in Safari iOS and other limited browsers
- [ ] No conflicts with OpenWebUI's PDF.js version
- [ ] TTS integration extracts clean text per page

**Risk Mitigation:**
- Version pinning strategy documented in `package.json`
- Automated browser compatibility testing in CI
- Memory usage monitoring and alerting
- Feature flag for enabling/disabling shared worker approach