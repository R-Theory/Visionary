-- Visionary Database Initialization
-- PostgreSQL schema setup for development environment

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search
CREATE EXTENSION IF NOT EXISTS "vector";   -- For embeddings (if using pgvector)

-- ================================
-- Core Tables (Placeholder Schema)
-- ================================

-- Media files tracking
CREATE TABLE IF NOT EXISTS media_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    s3_bucket VARCHAR(100) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    upload_user_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Media-specific metadata
    duration_seconds INTEGER,  -- For audio/video
    page_count INTEGER,        -- For documents
    metadata JSONB
);

-- TTS cache for audio files
CREATE TABLE IF NOT EXISTS tts_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_hash VARCHAR(64) UNIQUE NOT NULL,  -- SHA256 of text content
    text_content TEXT NOT NULL,
    voice_settings JSONB NOT NULL,
    s3_bucket VARCHAR(100) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0
);

-- Knowledge base chunks (for RAG)
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_file_id UUID REFERENCES media_files(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    chunk_text TEXT NOT NULL,
    chunk_metadata JSONB,
    embedding VECTOR(1536),  -- Adjust dimension as needed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Background job tracking
CREATE TABLE IF NOT EXISTS job_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    celery_task_id VARCHAR(255) UNIQUE NOT NULL,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    user_id VARCHAR(100),
    input_data JSONB,
    result_data JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ================================
-- Indexes for Performance
-- ================================

CREATE INDEX IF NOT EXISTS idx_media_files_user_created ON media_files(upload_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_media_files_content_type ON media_files(content_type);

CREATE INDEX IF NOT EXISTS idx_tts_cache_hash ON tts_cache(content_hash);
CREATE INDEX IF NOT EXISTS idx_tts_cache_expires ON tts_cache(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_source ON knowledge_chunks(source_file_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding ON knowledge_chunks USING ivfflat (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_job_status_type_status ON job_status(job_type, status);
CREATE INDEX IF NOT EXISTS idx_job_status_user_created ON job_status(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_status_celery_task ON job_status(celery_task_id);

-- ================================
-- Functions & Triggers
-- ================================

-- Auto-update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply auto-update triggers
DROP TRIGGER IF EXISTS update_media_files_updated_at ON media_files;
CREATE TRIGGER update_media_files_updated_at
    BEFORE UPDATE ON media_files
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_status_updated_at ON job_status;
CREATE TRIGGER update_job_status_updated_at
    BEFORE UPDATE ON job_status
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ================================
-- Development Data (Optional)
-- ================================

-- Insert sample data for development
INSERT INTO media_files (filename, content_type, file_size, s3_bucket, s3_key, upload_user_id) VALUES
('sample.pdf', 'application/pdf', 1048576, 'visionary-media', 'documents/sample.pdf', 'dev-user-1'),
('test-audio.mp3', 'audio/mpeg', 2097152, 'visionary-media', 'audio/test-audio.mp3', 'dev-user-1')
ON CONFLICT DO NOTHING;

-- Sample TTS cache entry
INSERT INTO tts_cache (content_hash, text_content, voice_settings, s3_bucket, s3_key, duration_seconds) VALUES
('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'Hello, this is a test of the text-to-speech system.', '{"voice": "natural", "speed": 1.0}', 'visionary-tts-cache', 'tts/sample-hello.mp3', 3)
ON CONFLICT (content_hash) DO NOTHING;

COMMIT;
