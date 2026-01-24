-- ============================================
-- KitTicker Supabase RLS Security Fix
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CRITICAL: API Keys (PRIVATE - No public access)
-- ============================================
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- Only service role can access api_keys (no anon access)
CREATE POLICY "api_keys_service_only" ON public.api_keys
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- 2. API Usage Logs (Private - user's own logs only)
-- ============================================
ALTER TABLE public.api_usage_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own usage logs
CREATE POLICY "api_usage_logs_own_only" ON public.api_usage_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Service role can insert logs
CREATE POLICY "api_usage_logs_service_insert" ON public.api_usage_logs
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- ============================================
-- 3. Digital Passports (Private - owner only)
-- ============================================
ALTER TABLE public.digital_passports ENABLE ROW LEVEL SECURITY;

-- Users can only see their own passports
CREATE POLICY "digital_passports_own_only" ON public.digital_passports
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own passports
CREATE POLICY "digital_passports_own_insert" ON public.digital_passports
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 4-16. Reference Tables (PUBLIC READ-ONLY)
-- These are lookup/reference tables - anyone can read
-- ============================================

-- code_format_patterns
ALTER TABLE public.code_format_patterns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "code_format_patterns_public_read" ON public.code_format_patterns
  FOR SELECT USING (true);

-- leagues
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "leagues_public_read" ON public.leagues
  FOR SELECT USING (true);

-- manufacturing_origin_eras
ALTER TABLE public.manufacturing_origin_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "manufacturing_origin_eras_public_read" ON public.manufacturing_origin_eras
  FOR SELECT USING (true);

-- valuation_tiers
ALTER TABLE public.valuation_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "valuation_tiers_public_read" ON public.valuation_tiers
  FOR SELECT USING (true);

-- size_format_eras
ALTER TABLE public.size_format_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "size_format_eras_public_read" ON public.size_format_eras
  FOR SELECT USING (true);

-- font_era_validation
ALTER TABLE public.font_era_validation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "font_era_validation_public_read" ON public.font_era_validation
  FOR SELECT USING (true);

-- technology_tier_mapping
ALTER TABLE public.technology_tier_mapping ENABLE ROW LEVEL SECURITY;
CREATE POLICY "technology_tier_mapping_public_read" ON public.technology_tier_mapping
  FOR SELECT USING (true);

-- jock_tag_eras
ALTER TABLE public.jock_tag_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "jock_tag_eras_public_read" ON public.jock_tag_eras
  FOR SELECT USING (true);

-- teams
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teams_public_read" ON public.teams
  FOR SELECT USING (true);

-- team_manufacturer_eras
ALTER TABLE public.team_manufacturer_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_manufacturer_eras_public_read" ON public.team_manufacturer_eras
  FOR SELECT USING (true);

-- manufacturers
ALTER TABLE public.manufacturers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "manufacturers_public_read" ON public.manufacturers
  FOR SELECT USING (true);

-- team_sponsor_eras
ALTER TABLE public.team_sponsor_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_sponsor_eras_public_read" ON public.team_sponsor_eras
  FOR SELECT USING (true);

-- sustainability_label_eras
ALTER TABLE public.sustainability_label_eras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sustainability_label_eras_public_read" ON public.sustainability_label_eras
  FOR SELECT USING (true);

-- ============================================
-- VERIFY: Check all tables have RLS enabled
-- ============================================
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
