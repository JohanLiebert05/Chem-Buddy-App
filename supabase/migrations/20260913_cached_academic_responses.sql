-- Migration: 20260913_cached_academic_responses.sql
-- Description: Zero-token semantic academic response cache for Gemini 4-Key Orchestrator

CREATE TABLE IF NOT EXISTS public.cached_academic_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_hash VARCHAR(64) UNIQUE NOT NULL,
    normalized_query TEXT NOT NULL,
    prompt_category VARCHAR(50) DEFAULT 'general',
    model_version VARCHAR(50) NOT NULL,
    response_payload JSONB NOT NULL,
    hit_count INTEGER DEFAULT 1,
    tokens_saved INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

-- Index for instant sub-10ms lookup
CREATE INDEX IF NOT EXISTS idx_cached_academic_hash ON public.cached_academic_responses (query_hash);
CREATE INDEX IF NOT EXISTS idx_cached_academic_category ON public.cached_academic_responses (prompt_category);

-- RLS Policy: Anyone can read cached responses, service role can write
ALTER TABLE public.cached_academic_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on cached academic responses"
    ON public.cached_academic_responses
    FOR SELECT
    USING (true);

CREATE POLICY "Allow authenticated or service-role write on cached academic responses"
    ON public.cached_academic_responses
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow update hit_count on cached academic responses"
    ON public.cached_academic_responses
    FOR UPDATE
    USING (true);
