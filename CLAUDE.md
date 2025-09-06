# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Visionary is a knowledge management and media processing application being planned and designed. The project is currently in the architectural planning phase with comprehensive documentation in the `my-notes/` directory.

## Core Architecture

The application follows a multi-pillar architecture:

- **Media Library**: PDF/video/audio processing with streaming and per-page TTS functionality
- **Knowledge Manager**: Content ingestion → chunking → embeddings → retrieval integrated with chat
- **Study Page**: Flashcards, AI podcast generation, study analytics, and quizzes
- **Email Manager**: Provider integrations with AI classification, summarization, and smart folders

## Development Environment

This project uses a Dev Container setup with markdown-focused tooling:

- **Container**: Based on `mcr.microsoft.com/devcontainers/base:bullseye`
- **VS Code Extensions**: Markdown All-in-One, Code Spell Checker, MarkdownLint, Markdown Preview Enhanced
- **Development Flow**: BMAD-method workflow with AI agents, documented in `my-notes/Dev Process/`

## Key Commands

Currently no build/test commands are defined as this is a planning-phase repository. The primary workflow involves:

- Working with Obsidian vault in `my-notes/` directory
- Using Dev Container for consistent markdown editing environment
- Following BMAD workflow patterns for AI-assisted development

## Project Structure

```
.devcontainer/          # Dev Container configuration
.github/               # GitHub workflows (planned)
.vscode/              # VS Code workspace settings
my-notes/             # Obsidian vault with comprehensive documentation
├── Vision/           # App-specific documentation
│   ├── 01-Overview/  # WebUI and system overview
│   ├── 02-Product/   # User manual and controls
│   ├── 03-Engineering/ # System architecture
│   ├── 04-API/       # API endpoints documentation
│   ├── 05-Features/  # Feature implementation plans
│   └── 06-Project/   # BMAD applied, roadmaps
├── Dev Process/      # Shared development methodology
│   ├── 01-Env & Tooling/ # Development stack guidance
│   ├── 02-AI Workflow/   # BMAD overview and implementation
│   ├── 03-Conventions/   # Code and documentation standards
│   └── 04-Templates/     # ADR, feature plan, checklist templates
├── docs/             # Technical documentation and guides
├── Tags/             # Tag management
└── 99-Archive/       # Archived/outdated content
```

## Development Methodology

This project follows the BMAD (Bootstrap-Model-Agent-Documentation) methodology:

1. **Bootstrap**: Use `pnpm dlx bmad-method@latest install` for project scaffolding
2. **Model**: Structured documentation in `docs/AGENTS.md` (when implementation begins)
3. **Agent**: AI-assisted development with clear rails and constraints
4. **Documentation**: Comprehensive planning docs in `my-notes/` Obsidian vault

## Next Implementation Phase

Based on ROADMAP.md, the next development slice focuses on:
- Media vertical: PDF viewer + cached TTS + presigned content access via unified Files API
- Storage: S3/MinIO with bucket and presign TTL configuration
- Queue: Celery/RQ/Arq for TTS jobs with Redis backend
- Frontend: Custom tab/micro-frontend approach

## Key References

- **Roadmap**: `ROADMAP.md` - Current development priorities and milestones
- **Architecture**: `my-notes/Vision/03-Engineering/Parallel Systems.md` (referenced content)
- **Feature Plans**: `my-notes/Vision/05-Features/` directory
- **Development Stack**: `my-notes/Dev Process/01-Env & Tooling/Dev Stack.md`
- **BMAD Methodology**: `my-notes/Dev Process/02-AI Workflow/BMAD Overview.md`
