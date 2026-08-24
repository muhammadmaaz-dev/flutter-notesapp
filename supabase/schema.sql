-- =============================================================================
-- Noto Notes App - Anonymous User Analytics & Onboarding Tracking Schema
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/nyvtcwpjhijyhowubytz/sql
-- =============================================================================

-- 1. Create app_users table
CREATE TABLE IF NOT EXISTS public.app_users (
    id BIGSERIAL PRIMARY KEY,
    installation_id UUID UNIQUE NOT NULL,
    user_alias TEXT NOT NULL,
    country VARCHAR(10) NOT NULL DEFAULT 'Unknown',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    platform TEXT NOT NULL DEFAULT 'android'
);

-- Index for fast installation_id lookups
CREATE INDEX IF NOT EXISTS idx_app_users_installation_id ON public.app_users(installation_id);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;

-- 3. Stored Procedure / Function: register_or_sync_user
-- Performs atomic UPSERT on installation_id and assigns 'User <id>' alias
CREATE OR REPLACE FUNCTION public.register_or_sync_user(
    p_installation_id UUID,
    p_country TEXT DEFAULT 'Unknown',
    p_platform TEXT DEFAULT 'android'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- runs with elevated privileges to allow anonymous users to register
SET search_path = public
AS $$
DECLARE
    v_user public.app_users%ROWTYPE;
    v_new_id BIGINT;
    v_alias TEXT;
BEGIN
    -- Check if the installation already exists
    SELECT * INTO v_user
    FROM public.app_users
    WHERE installation_id = p_installation_id;

    IF FOUND THEN
        -- Update last_active_at and refresh metadata
        UPDATE public.app_users
        SET 
            last_active_at = timezone('utc'::text, now()),
            country = CASE WHEN p_country IS NOT NULL AND p_country <> '' AND p_country <> 'Unknown' THEN p_country ELSE country END,
            platform = CASE WHEN p_platform IS NOT NULL AND p_platform <> '' THEN p_platform ELSE platform END
        WHERE installation_id = p_installation_id
        RETURNING * INTO v_user;
    ELSE
        -- Generate next ID from sequence for user_alias
        v_new_id := nextval(pg_get_serial_sequence('public.app_users', 'id'));
        v_alias := 'User ' || v_new_id;

        INSERT INTO public.app_users (
            id,
            installation_id,
            user_alias,
            country,
            platform,
            joined_at,
            last_active_at
        ) VALUES (
            v_new_id,
            p_installation_id,
            v_alias,
            COALESCE(NULLIF(p_country, ''), 'Unknown'),
            COALESCE(NULLIF(p_platform, ''), 'android'),
            timezone('utc'::text, now()),
            timezone('utc'::text, now())
        )
        RETURNING * INTO v_user;
    END IF;

    RETURN jsonb_build_object(
        'id', v_user.id,
        'installation_id', v_user.installation_id,
        'user_alias', v_user.user_alias,
        'country', v_user.country,
        'platform', v_user.platform,
        'joined_at', v_user.joined_at,
        'last_active_at', v_user.last_active_at
    );
END;
$$;

-- 4. Stored Procedure / Function: update_last_active
CREATE OR REPLACE FUNCTION public.update_last_active(
    p_installation_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.app_users
    SET last_active_at = timezone('utc'::text, now())
    WHERE installation_id = p_installation_id;

    RETURN FOUND;
END;
$$;

-- 5. Grant Execution Permissions to anonymous & authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE public.app_users TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_or_sync_user(UUID, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_last_active(UUID) TO anon, authenticated;

-- 6. Row Level Security Policies
DROP POLICY IF EXISTS "Allow anon and auth read access" ON public.app_users;
CREATE POLICY "Allow anon and auth read access"
ON public.app_users
FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow anon and auth insert access" ON public.app_users;
CREATE POLICY "Allow anon and auth insert access"
ON public.app_users
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon and auth update access" ON public.app_users;
CREATE POLICY "Allow anon and auth update access"
ON public.app_users
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);
