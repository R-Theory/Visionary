# Visionary — Roadmap

Purpose

- Capture the high-level pillars and the next shippable slice for Visionary.

Pillars

- Media Library: PDFs/videos/audio with fast viewing/streaming and per‑page "Listen".
- Knowledge Manager: ingestion → chunking → embeddings → retrieval integrated with chats.
- Study Page: flashcards, AI podcast generation, study analytics, quizzes.
- Email Manager: provider integrations with AI classification, summarization, smart folders.

Next Slice (recommended)

- Media vertical: PDF viewer + cached TTS + presigned content access via unified Files API.

Definition of Ready

- Storage chosen (S3/MinIO), bucket and presign TTL decided.
- Queue picked (Celery/RQ/Arq) for TTS jobs; Redis available.
- Frontend mount strategy agreed (custom tab/micro‑frontend; no core route surgery).
- Env documented in `.env.example` (storage, TTS).

Milestones

- M1: Presigned content endpoint + MIME/size allowlists (backend).
- M2: PDF viewer shell with per‑page "Listen" and cached audio (frontend).
- M3: Background TTS job + caching + simple status API.
- M4: Tests: backend unit for presign/ACL; Playwright E2E open → listen.

References

- Notes: `my-notes/Vision/INDEX.md`, `my-notes/Vision/05-Features/Implementing Features 1.md`.
