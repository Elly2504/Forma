-- KitTicker Product Codes Database Schema
-- Run this in Supabase SQL Editor
-- Last Updated: 2026-01-18 (Phase 7: Normalized Schema Architecture)

-- ============================================
-- ⚠️ IMPORTANT: EXECUTION ORDER
-- If you get column errors, run this file in 3 parts:
-- Part 1: Lines 1-500 (CREATE TABLE + ALTER TABLE)
-- Part 2: Lines 501-1000 (SEED DATA)
-- Part 3: Lines 1001+ (Additional tables and queries)
-- ============================================

-- ============================================
-- REFERENCE TABLES: Normalized Architecture
-- ============================================

-- TABLE: Leagues
CREATE TABLE IF NOT EXISTS leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  country TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: Manufacturers
CREATE TABLE IF NOT EXISTS manufacturers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  code_format_regex TEXT,  -- e.g., '^\d{6}-\d{3}$' for Nike
  validation_rules JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: Teams
CREATE TABLE IF NOT EXISTS teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  league_id UUID REFERENCES leagues(id),
  country TEXT NOT NULL,
  short_code TEXT,  -- e.g., 'MUFC', 'AFC'
  validation_config JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: Team Manufacturer Eras (which manufacturer for which period)
CREATE TABLE IF NOT EXISTS team_manufacturer_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  manufacturer_id UUID NOT NULL REFERENCES manufacturers(id) ON DELETE CASCADE,
  start_year INTEGER NOT NULL,
  end_year INTEGER,  -- NULL means current
  notes TEXT,
  UNIQUE(team_id, manufacturer_id, start_year)
);

-- TABLE: Team Sponsor Eras (which sponsor for which period)
CREATE TABLE IF NOT EXISTS team_sponsor_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  sponsor_name TEXT NOT NULL,
  sponsor_type TEXT DEFAULT 'shirt',  -- 'shirt', 'sleeve', 'training'
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  UNIQUE(team_id, sponsor_name, start_year)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_teams_league ON teams(league_id);
CREATE INDEX IF NOT EXISTS idx_team_eras_team ON team_manufacturer_eras(team_id);
CREATE INDEX IF NOT EXISTS idx_team_sponsors_team ON team_sponsor_eras(team_id);

-- ============================================
-- SEED DATA: Reference Tables
-- ============================================

-- Leagues
INSERT INTO leagues (name, country) VALUES
  ('Premier League', 'England'),
  ('La Liga', 'Spain'),
  ('Serie A', 'Italy'),
  ('Bundesliga', 'Germany'),
  ('Ligue 1', 'France')
ON CONFLICT (name) DO NOTHING;

-- Manufacturers
INSERT INTO manufacturers (name, code_format_regex, validation_rules) VALUES
  ('Nike', '^\d{6}(-\d{3})?$', '{"color_suffix_validation": true, "suffix_colors": {"6": "red", "0": "black", "1": "white", "4": "blue"}}'),
  ('Adidas', '^[A-Z]{1,2}\d{4,5}$', '{"tier_validation": true, "technologies": ["ClimaCool", "AEROREADY", "HEAT.RDY"]}'),
  ('Puma', '^\d{6}-\d{2}$', '{}'),
  ('Umbro', '^\d{5}(-U)?$', '{}'),
  ('New Balance', '^\w{6,10}$', '{}')
ON CONFLICT (name) DO NOTHING;

-- Teams (Manchester United as pilot)
INSERT INTO teams (name, country, short_code) 
SELECT 'Manchester United', 'England', 'MUFC'
WHERE NOT EXISTS (SELECT 1 FROM teams WHERE name = 'Manchester United');

-- Manchester United Manufacturer Eras
INSERT INTO team_manufacturer_eras (team_id, manufacturer_id, start_year, end_year, notes)
SELECT t.id, m.id, 1975, 2002, 'Long-term Umbro era'
FROM teams t, manufacturers m
WHERE t.name = 'Manchester United' AND m.name = 'Umbro'
ON CONFLICT DO NOTHING;

INSERT INTO team_manufacturer_eras (team_id, manufacturer_id, start_year, end_year, notes)
SELECT t.id, m.id, 2002, 2015, 'Nike era - Total 90, Dri-FIT'
FROM teams t, manufacturers m
WHERE t.name = 'Manchester United' AND m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO team_manufacturer_eras (team_id, manufacturer_id, start_year, end_year, notes)
SELECT t.id, m.id, 2015, NULL, 'Current Adidas partnership'
FROM teams t, manufacturers m
WHERE t.name = 'Manchester United' AND m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- Manchester United Sponsor Eras
INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'Sharp', 1982, 2000 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'Vodafone', 2000, 2006 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'AIG', 2006, 2010 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'Aon', 2010, 2014 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'Chevrolet', 2014, 2021 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'TeamViewer', 2021, 2024 FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

INSERT INTO team_sponsor_eras (team_id, sponsor_name, start_year, end_year)
SELECT id, 'Snapdragon', 2024, NULL FROM teams WHERE name = 'Manchester United'
ON CONFLICT DO NOTHING;

-- ============================================
-- TABLE: Product Codes (with FK support)
-- ============================================
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES teams(id);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS manufacturer_id UUID REFERENCES manufacturers(id);

-- Populate FKs from existing text columns
UPDATE product_codes pc SET 
  team_id = (SELECT id FROM teams WHERE name = pc.team),
  manufacturer_id = (SELECT id FROM manufacturers WHERE name = pc.brand)
WHERE pc.team_id IS NULL OR pc.manufacturer_id IS NULL;

-- Create FK indexes
CREATE INDEX IF NOT EXISTS idx_product_codes_team_id ON product_codes(team_id);
CREATE INDEX IF NOT EXISTS idx_product_codes_manufacturer_id ON product_codes(manufacturer_id);

-- ============================================
-- ORIGINAL TABLE 1: Product Codes (Verified Database)
-- ============================================
CREATE TABLE IF NOT EXISTS product_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  brand TEXT NOT NULL,
  team TEXT,
  season TEXT,
  kit_type TEXT,
  variant TEXT,  -- 'replica', 'player_issue', 'authentic' etc.
  verified BOOLEAN DEFAULT true,
  verification_source TEXT DEFAULT 'community', -- 'official', 'community', 'ai'
  lookup_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_product_codes_code ON product_codes(code);
CREATE INDEX IF NOT EXISTS idx_product_codes_brand ON product_codes(brand);
CREATE INDEX IF NOT EXISTS idx_product_codes_team ON product_codes(team);

-- Enable RLS (Row Level Security)
ALTER TABLE product_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read product codes
DROP POLICY IF EXISTS "Anyone can read product codes" ON product_codes;
CREATE POLICY "Anyone can read product codes" ON product_codes
  FOR SELECT USING (true);

-- Policy: Only authenticated users can insert (for future community contributions)
DROP POLICY IF EXISTS "Authenticated users can insert" ON product_codes;
CREATE POLICY "Authenticated users can insert" ON product_codes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- TABLE 2: Blacklist Codes (Known Fakes)
-- ============================================
CREATE TABLE IF NOT EXISTS blacklist_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL,
  brand TEXT NOT NULL,
  reason TEXT NOT NULL,
  legitimate_use TEXT,  -- e.g., "Only valid for 2018 Colombia kits"
  reported_count INTEGER DEFAULT 1,
  severity TEXT DEFAULT 'high',  -- 'high', 'medium', 'low'
  verified BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(code, brand)
);

-- Create index for blacklist lookups
CREATE INDEX IF NOT EXISTS idx_blacklist_codes_code ON blacklist_codes(code);

-- Enable RLS for blacklist_codes
ALTER TABLE blacklist_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read blacklist codes
DROP POLICY IF EXISTS "Anyone can read blacklist codes" ON blacklist_codes;
CREATE POLICY "Anyone can read blacklist codes" ON blacklist_codes
  FOR SELECT USING (true);

-- ============================================
-- TABLE 3: Code Format Patterns (Brand Rules)
-- ============================================
CREATE TABLE IF NOT EXISTS code_format_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand TEXT NOT NULL,
  pattern TEXT NOT NULL,  -- Regex pattern
  description TEXT,
  era_start INTEGER,  -- Year this format started
  era_end INTEGER,    -- Year this format ended (null = current)
  example TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(brand, pattern)
);

-- Enable RLS
ALTER TABLE code_format_patterns ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read format patterns" ON code_format_patterns;
CREATE POLICY "Anyone can read format patterns" ON code_format_patterns
  FOR SELECT USING (true);

-- ============================================
-- TABLE 4: Verification Log (Analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_checked TEXT NOT NULL,
  brand_filter TEXT,
  result_type TEXT NOT NULL,  -- 'verified', 'blacklisted', 'not_found', 'format_invalid'
  confidence_score DECIMAL(5,2),
  signals_used JSONB,
  ip_hash TEXT,  -- Hashed for privacy
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for analytics
CREATE INDEX IF NOT EXISTS idx_verification_logs_created ON verification_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_verification_logs_result ON verification_logs(result_type);

-- Enable RLS
ALTER TABLE verification_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow insert verification logs" ON verification_logs;
CREATE POLICY "Allow insert verification logs" ON verification_logs
  FOR INSERT WITH CHECK (true);

-- ============================================
-- TABLE 5: API Keys (B2B Access)
-- ============================================
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_prefix TEXT NOT NULL,           -- First 8 chars for display (kt_live_XXXX)
  key_hash TEXT UNIQUE NOT NULL,      -- SHA256 hash of full key
  owner_email TEXT NOT NULL,
  company_name TEXT,
  tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'starter', 'business', 'enterprise')),
  rate_limit INTEGER DEFAULT 100,     -- requests per hour
  monthly_quota INTEGER DEFAULT 1000,
  usage_this_month INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',        -- Custom fields for enterprise
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_email ON api_keys(owner_email);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage api keys" ON api_keys;
CREATE POLICY "Service role can manage api keys" ON api_keys
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- TABLE 6: API Usage Logs
-- ============================================
CREATE TABLE IF NOT EXISTS api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,             -- '/v1/codes/lookup', '/v1/verify' etc.
  method TEXT DEFAULT 'GET',
  request_params JSONB,
  response_status INTEGER,
  response_cached BOOLEAN DEFAULT false,
  latency_ms INTEGER,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_usage_created ON api_usage_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_api_usage_key ON api_usage_logs(api_key_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_endpoint ON api_usage_logs(endpoint);

ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage usage logs" ON api_usage_logs;
CREATE POLICY "Service role can manage usage logs" ON api_usage_logs
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- TABLE 7: Digital Product Passports (DPP)
-- ============================================
CREATE TABLE IF NOT EXISTS digital_passports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uid TEXT UNIQUE NOT NULL,           -- KT-2026-XXXXXX format
  product_code_id UUID REFERENCES product_codes(id),
  
  -- Ownership
  owner_email TEXT,
  owner_name TEXT,
  transfer_history JSONB DEFAULT '[]',
  
  -- Verification Status
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'failed', 'disputed')),
  verification_date TIMESTAMPTZ,
  verification_evidence JSONB,
  verified_by TEXT,                   -- 'ai', 'community', 'expert'
  
  -- Physical Carriers
  qr_code_url TEXT,
  nfc_tag_id TEXT,
  
  -- Metadata
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dpp_uid ON digital_passports(uid);
CREATE INDEX IF NOT EXISTS idx_dpp_product_code ON digital_passports(product_code_id);
CREATE INDEX IF NOT EXISTS idx_dpp_owner ON digital_passports(owner_email);

ALTER TABLE digital_passports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read verified passports" ON digital_passports;
CREATE POLICY "Anyone can read verified passports" ON digital_passports
  FOR SELECT USING (verification_status = 'verified');

DROP POLICY IF EXISTS "Authenticated users can create passports" ON digital_passports;
CREATE POLICY "Authenticated users can create passports" ON digital_passports
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- ALTER: Add B2B columns to product_codes
-- ============================================
-- DPP Compatibility
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS uid TEXT UNIQUE;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- Pricing Data
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_min DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_max DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS price_currency TEXT DEFAULT 'GBP';
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS price_confidence TEXT DEFAULT 'low' CHECK (price_confidence IN ('low', 'medium', 'high'));
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS last_price_update TIMESTAMPTZ;

-- Visual Attributes (for cross-validation)
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS primary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS secondary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS pattern TEXT;           -- 'solid', 'stripes', 'checkered' etc.
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS material_composition TEXT;

-- API Statistics
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS api_lookup_count INTEGER DEFAULT 0;

-- Create index for API lookups
CREATE INDEX IF NOT EXISTS idx_product_codes_uid ON product_codes(uid);

-- ============================================
-- FUNCTION: Generate DPP UID
-- ============================================
CREATE OR REPLACE FUNCTION generate_dpp_uid()
RETURNS TEXT AS $$
DECLARE
  year_part TEXT;
  random_part TEXT;
  new_uid TEXT;
BEGIN
  year_part := EXTRACT(YEAR FROM NOW())::TEXT;
  random_part := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
  new_uid := 'KT-' || year_part || '-' || random_part;
  RETURN new_uid;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Increment API lookup count
-- ============================================
CREATE OR REPLACE FUNCTION increment_api_lookup(p_code TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE product_codes 
  SET api_lookup_count = api_lookup_count + 1,
      lookup_count = lookup_count + 1
  WHERE code = p_code;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Check and update monthly API usage
-- ============================================
CREATE OR REPLACE FUNCTION check_api_quota(p_key_hash TEXT)
RETURNS TABLE (allowed BOOLEAN, remaining INTEGER, tier TEXT) AS $$
DECLARE
  v_key api_keys%ROWTYPE;
BEGIN
  SELECT * INTO v_key FROM api_keys WHERE key_hash = p_key_hash AND is_active = true;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 0, 'invalid'::TEXT;
    RETURN;
  END IF;
  
  IF v_key.usage_this_month >= v_key.monthly_quota THEN
    RETURN QUERY SELECT false, 0, v_key.tier;
    RETURN;
  END IF;
  
  -- Update usage
  UPDATE api_keys 
  SET usage_this_month = usage_this_month + 1,
      last_used_at = NOW()
  WHERE id = v_key.id;
  
  RETURN QUERY SELECT true, (v_key.monthly_quota - v_key.usage_this_month - 1), v_key.tier;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SEED DATA: Nike Codes (Expanded)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant) VALUES
  -- 2014-2016 Era
  ('638920-013', 'Nike', 'Paris Saint-Germain', '2015/16', 'Third', 'replica'),
  ('658894-106', 'Nike', 'England', '2014/16', 'Home', 'replica'),
  ('724006-612', 'Nike', 'Manchester United', '2014/15', 'Home', 'replica'),
  ('624141-105', 'Nike', 'Barcelona', '2014/15', 'Away', 'replica'),
  ('776929-480', 'Nike', 'Tottenham Hotspur', '2016/17', 'Home', 'replica'),
  ('847284-010', 'Nike', 'Paris Saint-Germain', '2016/17', 'Third', 'replica'),
  -- 2017-2018 Era  
  ('847268-480', 'Nike', 'Chelsea', '2017/18', 'Home', 'replica'),
  ('847261-100', 'Nike', 'Chelsea', '2017/18', 'Away', 'replica'),
  ('894430-100', 'Nike', 'England', '2018/20', 'Home', 'replica'),
  ('894430-010', 'Nike', 'England', '2018/20', 'Away', 'replica'),
  ('893869-455', 'Nike', 'France', '2018/20', 'Home', 'replica'),
  ('893872-100', 'Nike', 'France', '2018/20', 'Away', 'replica'),
  -- 2020-2021 Era
  ('CD0069-100', 'Nike', 'France', '2020/21', 'Away', 'replica'),
  ('CD0712-100', 'Nike', 'Croatia', '2020/21', 'Home', 'replica'),
  ('CK7828-100', 'Nike', 'Portugal', '2020/21', 'Home', 'replica'),
  ('CD0696-100', 'Nike', 'Netherlands', '2020/21', 'Home', 'replica'),
  ('CK5993-612', 'Nike', 'Liverpool', '2020/21', 'Home', 'replica'),
  ('CZ2627-010', 'Nike', 'PSG x Jordan', '2020/21', 'Fourth', 'replica'),
  ('CZ3984-100', 'Nike', 'England', '2022/23', 'Home', 'replica'),
  ('CZ3985-410', 'Nike', 'England', '2022/23', 'Away', 'replica'),
  -- 2022-2024 Era
  ('DN0697-410', 'Nike', 'Chelsea', '2022/23', 'Home', 'replica'),
  ('DX2541-433', 'Nike', 'France', '2022/23', 'Home', 'replica'),
  ('DX2615-100', 'Nike', 'Netherlands', '2022/23', 'Home', 'replica'),
  ('DX2528-657', 'Nike', 'Portugal', '2022/23', 'Home', 'replica'),
  ('DX2618-410', 'Nike', 'Croatia', '2022/23', 'Home', 'replica'),
  ('DX2534-433', 'Nike', 'Brazil', '2022/23', 'Home', 'replica'),
  ('FJ4266-410', 'Nike', 'Chelsea', '2024/25', 'Home', 'replica'),
  ('FJ4260-657', 'Nike', 'Liverpool', '2024/25', 'Home', 'replica')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SEED DATA: Adidas Codes (Expanded)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant) VALUES
  -- 2015-2017 Era
  ('AI5152', 'Adidas', 'Real Madrid', '2015/16', 'Home', 'replica'),
  ('M36158', 'Adidas', 'Bayern Munich', '2015/16', 'Home', 'replica'),
  ('AZ7569', 'Adidas', 'Real Madrid', '2016/17', 'Home', 'replica'),
  ('AI4631', 'Adidas', 'Manchester United', '2015/16', 'Home', 'replica'),
  ('AZ4684', 'Adidas', 'Bayern Munich', '2016/17', 'Home', 'replica'),
  -- 2017-2019 Era
  ('CG0040', 'Adidas', 'Manchester United', '2017/18', 'Home', 'replica'),
  ('CG0411', 'Adidas', 'Manchester United', '2017/18', 'Away', 'replica'),
  ('DW4433', 'Adidas', 'Bayern Munich', '2018/19', 'Home', 'replica'),
  ('DY7529', 'Adidas', 'Real Madrid', '2019/20', 'Home', 'replica'),
  ('EH6891', 'Adidas', 'Arsenal', '2019/20', 'Home', 'replica'),
  ('EH5811', 'Adidas', 'Arsenal', '2019/20', 'Away', 'replica'),
  -- 2020-2022 Era
  ('FM4714', 'Adidas', 'Manchester United', '2020/21', 'Home', 'replica'),
  ('GI6463', 'Adidas', 'Juventus', '2020/21', 'Home', 'replica'),
  ('FI4559', 'Adidas', 'Arsenal', '2020/21', 'Home', 'replica'),
  ('H31090', 'Adidas', 'Real Madrid', '2021/22', 'Home', 'replica'),
  ('H35899', 'Adidas', 'Manchester United', '2021/22', 'Home', 'replica'),
  ('GM4606', 'Adidas', 'Arsenal', '2021/22', 'Home', 'replica'),
  -- 2022-2024 Era
  ('HM8901', 'Adidas', 'Bayern Munich', '2022/23', 'Home', 'replica'),
  ('H22219', 'Adidas', 'Real Madrid', '2022/23', 'Home', 'replica'),
  ('H64062', 'Adidas', 'Manchester United', '2022/23', 'Home', 'replica'),
  ('HR3796', 'Adidas', 'Manchester United', '2023/24', 'Home', 'replica'),
  ('HY0632', 'Adidas', 'Arsenal', '2023/24', 'Home', 'replica'),
  ('IJ7809', 'Adidas', 'Bayern Munich', '2023/24', 'Home', 'replica'),
  ('IS7462', 'Adidas', 'Real Madrid', '2024/25', 'Home', 'replica'),
  ('IT9785', 'Adidas', 'Manchester United', '2024/25', 'Home', 'replica'),
  ('IU0247', 'Adidas', 'Arsenal', '2024/25', 'Home', 'replica'),
  -- National Teams
  ('HF1485', 'Adidas', 'Germany', '2022/23', 'Home', 'replica'),
  ('HF0635', 'Adidas', 'Spain', '2022/23', 'Home', 'replica'),
  ('HF0768', 'Adidas', 'Argentina', '2022/23', 'Home', 'replica'),
  ('HF0675', 'Adidas', 'Belgium', '2022/23', 'Home', 'replica')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SEED DATA: Puma Codes (Expanded)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant) VALUES
  ('736251-01', 'Puma', 'AC Milan', '2023/24', 'Home', 'replica'),
  ('759122-01', 'Puma', 'Manchester City', '2023/24', 'Home', 'replica'),
  ('765722-01', 'Puma', 'Borussia Dortmund', '2023/24', 'Home', 'replica'),
  ('757061-01', 'Puma', 'AC Milan', '2022/23', 'Home', 'replica'),
  ('765710-01', 'Puma', 'Manchester City', '2022/23', 'Home', 'replica'),
  ('769459-01', 'Puma', 'Borussia Dortmund', '2022/23', 'Home', 'replica'),
  ('759128-01', 'Puma', 'Marseille', '2022/23', 'Home', 'replica'),
  ('763295-01', 'Puma', 'AC Milan', '2021/22', 'Home', 'replica'),
  ('759220-01', 'Puma', 'Manchester City', '2021/22', 'Home', 'replica'),
  ('759057-01', 'Puma', 'Borussia Dortmund', '2021/22', 'Home', 'replica'),
  ('757108-01', 'Puma', 'Italy', '2022/23', 'Home', 'replica'),
  ('757096-01', 'Puma', 'Austria', '2022/23', 'Home', 'replica'),
  ('757100-01', 'Puma', 'Czech Republic', '2022/23', 'Home', 'replica')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SEED DATA: Umbro Codes (Expanded)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant) VALUES
  ('96281-U', 'Umbro', 'England', '1996', 'Home', 'replica'),
  ('93761-U', 'Umbro', 'Manchester United', '1992/94', 'Home', 'replica'),
  ('98491-U', 'Umbro', 'Manchester United', '1998/99', 'Home', 'replica'),
  ('99271-U', 'Umbro', 'Chelsea', '1999/00', 'Home', 'replica'),
  ('00561-U', 'Umbro', 'England', '2000/02', 'Home', 'replica'),
  ('02671-U', 'Umbro', 'Manchester United', '2000/02', 'Away', 'replica'),
  ('76781-U', 'Umbro', 'West Ham United', '2022/23', 'Home', 'replica'),
  ('78921-U', 'Umbro', 'Everton', '2022/23', 'Home', 'replica'),
  ('80124-U', 'Umbro', 'West Ham United', '2023/24', 'Home', 'replica'),
  ('80256-U', 'Umbro', 'Everton', '2023/24', 'Home', 'replica')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SEED DATA: Blacklist Codes (Known Fakes) - DEEP RESEARCH EXPANDED
-- ============================================
INSERT INTO blacklist_codes (code, brand, reason, legitimate_use, severity) VALUES
  -- High-Profile Cloned Codes
  ('CW1526', 'Adidas', 'Known counterfeit code used across multiple fake kits including Man Utd, Juventus, Bayern, Arsenal', 'Only valid for 2018 Colombia Home/Away kits', 'high'),
  ('P95985', 'Adidas', 'Generic swing tag code, appears as "ADIDAS JSY" instead of team-specific text. Found on thousands of fakes.', NULL, 'high'),
  ('X21992', 'Adidas', 'Real Madrid Away code frequently found on fake Manchester United shirts', 'Only valid for Real Madrid kits', 'high'),
  
  -- Generic/Factory Fake Codes
  ('AI4411', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('697265', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('B10751', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('ADIDAS JSY', 'Adidas', 'Generic tag text - authentic tags show team abbreviations like "MUFC 3 JSY"', NULL, 'medium'),
  
  -- Nike Fake Patterns
  ('000000-000', 'Nike', 'Placeholder/test code found on counterfeits', NULL, 'high'),
  ('123456-789', 'Nike', 'Sequential test code found on counterfeits', NULL, 'high'),
  ('111111-111', 'Nike', 'Repeated digit pattern found on counterfeits', NULL, 'high'),
  
  -- Test Entry
  ('FAKE001', 'Generic', 'Test entry for development', NULL, 'low')
ON CONFLICT (code, brand) DO NOTHING;

-- ============================================
-- ALTER: Add is_known_clone Flag for Legitimate Cloned Codes
-- ============================================
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS is_known_clone BOOLEAN DEFAULT false;
COMMENT ON COLUMN product_codes.is_known_clone IS 'True if this legitimate code is frequently cloned on fakes (e.g., 611031-624 for 2014/15 Chevrolet shirt)';

-- Mark known frequently-cloned codes
UPDATE product_codes SET is_known_clone = true WHERE code IN (
  '611031-624',  -- 2014-15 Nike Home (HEAVILY COUNTERFEITED due to first Chevrolet)
  'CG0040',      -- 2018-19 Adidas Home (popular season)
  'H64062',      -- 2022-23 Adidas Home
  'IP1726'       -- 2023-24 Adidas Home
);

-- ============================================
-- SEED DATA: Code Format Patterns
-- ============================================
INSERT INTO code_format_patterns (brand, pattern, description, era_start, era_end, example) VALUES
  ('Nike', '^[A-Z]{2}\\d{4}-\\d{3}$', 'Modern Nike code: 2 letters + 4 digits + dash + 3 digits', 2018, NULL, 'CZ3984-100'),
  ('Nike', '^\\d{6}-\\d{3}$', 'Legacy Nike code: 6 digits + dash + 3 digits', 2010, 2020, '638920-013'),
  ('Adidas', '^[A-Z]{2}\\d{4}$', 'Modern Adidas code: 2 letters + 4 digits', 2015, NULL, 'IS7462'),
  ('Adidas', '^[A-Z]\\d{5}$', 'Legacy Adidas code: 1 letter + 5 digits', 2010, 2018, 'M36158'),
  ('Puma', '^\\d{6}-\\d{2}$', 'Puma code: 6 digits + dash + 2 digits', 2015, NULL, '736251-01'),
  ('Umbro', '^\\d{5}-U$', 'Umbro code: 5 digits + U suffix', 1990, NULL, '96281-U')
ON CONFLICT (brand, pattern) DO NOTHING;

-- ============================================
-- ALTER: Add Enhanced Tracking Columns
-- ============================================

-- Label Type Tracking
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_type TEXT;       -- 'swing_tag', 'inner_label', 'jock_tag', 'hologram'
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_position TEXT;   -- 'collar', 'hem', 'side_seam'

-- Era Tracking
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS era_start_year INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS era_end_year INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS code_format TEXT;      -- '6-digit', '6-3-digit', '2L4D'

-- Manufacturing Details
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS country_of_manufacture TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS technology TEXT;       -- 'Dri-FIT', 'AEROREADY', 'ClimaCool'

-- Cross-Validation Fields
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS sponsor TEXT;          -- 'Vodafone', 'AIG', 'Chevrolet'
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS expected_colors JSONB; -- ['red', 'white']

-- ============================================
-- SEED DATA: Manchester United - Nike Era (2002-2015)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, era_start_year, era_end_year) VALUES
  -- 2003-2004 Season
  ('112577', 'Nike', 'Manchester United', '2003/04', 'Away', 'replica', 'white', 'black', 'Vodafone', 'Dri-FIT', '6-digit', 2003, 2004),
  
  -- 2004-2005 / 2005-2006 Season
  ('118834', 'Nike', 'Manchester United', '2004/05', 'Home', 'replica', 'red', 'white', 'Vodafone', 'Dri-FIT', '6-digit', 2004, 2006),
  
  -- 2005-2006 Season
  ('195597-400', 'Nike', 'Manchester United', '2005/06', 'Away', 'replica', 'blue', 'white', 'Vodafone', 'Dri-FIT', '6-3-digit', 2005, 2006),
  
  -- 2007-2008 Season
  ('237924-666', 'Nike', 'Manchester United', '2007/08', 'Home', 'replica', 'red', 'white', 'AIG', 'Dri-FIT', '6-3-digit', 2007, 2008),
  ('238347-010', 'Nike', 'Manchester United', '2007/08', 'Away', 'replica', 'white', 'black', 'AIG', 'Dri-FIT', '6-3-digit', 2007, 2008),
  
  -- 2009-2010 Season
  ('355091-623', 'Nike', 'Manchester United', '2009/10', 'Home', 'replica', 'red', 'white', 'AIG', 'Dri-FIT', '6-3-digit', 2009, 2010),
  ('355094-010', 'Nike', 'Manchester United', '2009/10', 'Away', 'replica', 'black', 'white', 'AIG', 'Dri-FIT', '6-3-digit', 2009, 2010),
  
  -- 2011-2012 Season
  ('423933-623', 'Nike', 'Manchester United', '2011/12', 'Home', 'replica', 'red', 'white', 'AON', 'Dri-FIT', '6-3-digit', 2011, 2012),
  ('423935-403', 'Nike', 'Manchester United', '2011/12', 'Away', 'replica', 'royal_blue', 'black', 'AON', 'Dri-FIT', '6-3-digit', 2011, 2012),
  ('423932-623', 'Nike', 'Manchester United', '2011/12', 'Home', 'replica', 'red', 'white', 'AON', 'Dri-FIT', '6-3-digit', 2011, 2012),
  
  -- 2013-2014 Season
  ('532837-624', 'Nike', 'Manchester United', '2013/14', 'Home', 'replica', 'red', 'white', 'AON', 'Dri-FIT', '6-3-digit', 2013, 2014),
  ('532838-411', 'Nike', 'Manchester United', '2013/14', 'Away', 'replica', 'dark_blue', 'black', 'AON', 'Dri-FIT', '6-3-digit', 2013, 2014)
ON CONFLICT (code) DO UPDATE SET
  primary_color = EXCLUDED.primary_color,
  secondary_color = EXCLUDED.secondary_color,
  sponsor = EXCLUDED.sponsor,
  technology = EXCLUDED.technology,
  code_format = EXCLUDED.code_format,
  era_start_year = EXCLUDED.era_start_year,
  era_end_year = EXCLUDED.era_end_year;

-- ============================================
-- SEED DATA: Manchester United - Adidas Era (2015-2024)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, era_start_year, era_end_year) VALUES
  -- 2015-2016 Season (First Adidas Season)
  ('AC1414', 'Adidas', 'Manchester United', '2015/16', 'Home', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 2015, 2016),
  ('AI6363', 'Adidas', 'Manchester United', '2015/16', 'Away', 'replica', 'white', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 2015, 2016),
  ('AC1445', 'Adidas', 'Manchester United', '2015/16', 'Third', 'replica', 'blue', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 2015, 2016),
  
  -- 2016-2017 Season
  ('AI6720', 'Adidas', 'Manchester United', '2016/17', 'Home', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 2016, 2017),
  ('AI6704', 'Adidas', 'Manchester United', '2016/17', 'Away', 'replica', 'white', 'blue', 'Chevrolet', 'ClimaCool', '2L4D', 2016, 2017),
  ('AI6690', 'Adidas', 'Manchester United', '2016/17', 'Third', 'replica', 'navy_blue', 'gold', 'Chevrolet', 'ClimaCool', '2L4D', 2016, 2017),
  
  -- 2017-2018 Season
  ('BS1214', 'Adidas', 'Manchester United', '2017/18', 'Home', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 2017, 2018),
  ('BS1217', 'Adidas', 'Manchester United', '2017/18', 'Away', 'replica', 'white', 'grey', 'Chevrolet', 'ClimaCool', '2L4D', 2017, 2018),
  ('AZ7565', 'Adidas', 'Manchester United', '2017/18', 'Third', 'replica', 'grey', 'pink', 'Chevrolet', 'ClimaCool', '2L4D', 2017, 2018),
  
  -- 2018-2019 Season
  ('CG0040', 'Adidas', 'Manchester United', '2018/19', 'Home', 'replica', 'red', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 2018, 2019),
  ('CG0038', 'Adidas', 'Manchester United', '2018/19', 'Away', 'replica', 'pink', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 2018, 2019),
  ('DP6022', 'Adidas', 'Manchester United', '2018/19', 'Third', 'replica', 'navy_blue', 'navy_blue', 'Chevrolet', 'ClimaCool', '2L4D', 2018, 2019),
  
  -- 2020-2021 Season
  ('FM4714', 'Adidas', 'Manchester United', '2020/21', 'Home', 'replica', 'red', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 2020, 2021),
  
  -- 2021-2022 Season
  ('H35899', 'Adidas', 'Manchester United', '2021/22', 'Home', 'replica', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 2021, 2022),
  
  -- 2022-2023 Season
  ('H64062', 'Adidas', 'Manchester United', '2022/23', 'Home', 'replica', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 2022, 2023),
  
  -- 2023-2024 Season
  ('HR3796', 'Adidas', 'Manchester United', '2023/24', 'Home', 'replica', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 2023, 2024),
  
  -- 2024-2025 Season
  ('IT9785', 'Adidas', 'Manchester United', '2024/25', 'Home', 'replica', 'red', 'white', 'Snapdragon', 'AEROREADY', '2L4D', 2024, 2025)
ON CONFLICT (code) DO UPDATE SET
  primary_color = EXCLUDED.primary_color,
  secondary_color = EXCLUDED.secondary_color,
  sponsor = EXCLUDED.sponsor,
  technology = EXCLUDED.technology,
  code_format = EXCLUDED.code_format,
  era_start_year = EXCLUDED.era_start_year,
  era_end_year = EXCLUDED.era_end_year;

-- ============================================
-- UPDATE: Add Nike Format Pattern for Early Era
-- ============================================
INSERT INTO code_format_patterns (brand, pattern, description, era_start, era_end, example) VALUES
  ('Nike', '^\d{6}$', 'Early Nike code: 6 digits only (no color suffix)', 2002, 2006, '118834')
ON CONFLICT (brand, pattern) DO NOTHING;

-- ============================================
-- ALTER: Add Deep Research Cross-Validation Columns
-- ============================================

-- Color Suffix Validation (Critical for Nike 2006+ era)
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS color_suffix TEXT;     -- '623', '010', '403' etc.
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS expected_suffix_digit INTEGER; -- 6=red, 0=black, 1=white, 4=blue

-- Production Window Validation
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS production_window_start INTEGER; -- Year production started
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS production_window_end INTEGER;   -- Year production ended

-- Alternate Codes (Factory codes, early production variants)
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS alternate_codes JSONB DEFAULT '[]'; -- ['F40901DHA', 'F41104DHA']

-- Label Details (from deep research)
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_material TEXT;    -- 'satin', 'woven', 'printed'
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_font TEXT;        -- 'blocky_sans', 'condensed_modern'
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS date_code TEXT;         -- 'HO06', '04/07-06/07'

-- Visual Description (for human verification)
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS visual_description TEXT;

-- ============================================
-- SEED DATA: Manchester United Nike Era - DEEP RESEARCH (2002-2015)
-- ============================================

-- Early Nike Phase (2002-2006): Dual-Label Era
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, era_start_year, era_end_year, visual_description, label_material, alternate_codes) VALUES
  -- 2002-2004 Home
  ('184947', 'Nike', 'Manchester United', '2002/04', 'Home', 'replica', 'red', 'white', 'Vodafone', 'Cool Motion', '6-digit', 2002, 2004, 'Red, mesh sides, black/white cuffs', 'satin', '["F40901DHA"]'),
  
  -- 2002-2003 Away/Third (Reversible)
  ('184955', 'Nike', 'Manchester United', '2002/03', 'Away', 'replica', 'white', 'gold', 'Vodafone', 'Cool Motion', '6-digit', 2002, 2003, 'White reversible to gold', 'satin', '[]'),
  ('184955-400', 'Nike', 'Manchester United', '2002/03', 'Third', 'replica', 'blue', 'silver', 'Vodafone', 'Cool Motion', '6-3-digit', 2002, 2003, 'Blue with silver sponsor', 'satin', '[]'),
  
  -- 2003-2005 Third
  ('112679-100', 'Nike', 'Manchester United', '2003/05', 'Third', 'replica', 'white', 'black', 'Vodafone', 'Cool Motion', '6-3-digit', 2003, 2005, 'White with black/red horizontal stripes', 'satin', '[]')
ON CONFLICT (code) DO UPDATE SET
  visual_description = EXCLUDED.visual_description,
  label_material = EXCLUDED.label_material,
  alternate_codes = EXCLUDED.alternate_codes;

-- Mid Nike Phase (2006-2010): 9-Digit Standard Established
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, color_suffix, expected_suffix_digit, production_window_start, production_window_end, visual_description) VALUES
  -- 2006-2007 Season
  ('146814', 'Nike', 'Manchester United', '2006/07', 'Home', 'replica', 'red', 'gold', 'AIG', 'Dri-FIT', '6-digit', NULL, NULL, 2006, 2007, 'Retro shield crest, gold trim'),
  
  -- 2007-2009 Home (Multi-season)
  ('238347-623', 'Nike', 'Manchester United', '2007/09', 'Home', 'replica', 'red', 'white', 'AIG', 'Dri-FIT', '6-3-digit', '623', 6, 2007, 2009, 'Red with white stripe on back, AIG sponsor'),
  
  -- 2007-2008 Away
  ('245433-010', 'Nike', 'Manchester United', '2007/08', 'Away', 'replica', 'black', 'blue', 'AIG', 'Dri-FIT', '6-3-digit', '010', 0, 2007, 2008, 'Black with "The Red Devils" patch'),
  
  -- 2007-2008 Third
  ('238348-010', 'Nike', 'Manchester United', '2007/08', 'Third', 'replica', 'white', 'red', 'AIG', 'Dri-FIT', '6-3-digit', '010', 0, 2007, 2008, 'White, often confused with 08/09'),
  
  -- 2008-2009 Third (40th Anniversary)
  ('287000-403', 'Nike', 'Manchester United', '2008/09', 'Third', 'replica', 'blue', 'white', 'AIG', 'Dri-FIT', '6-3-digit', '403', 4, 2008, 2009, 'Blue with 40th Anniversary embroidery'),
  
  -- 2009-2010 Season
  ('355091-623', 'Nike', 'Manchester United', '2009/10', 'Home', 'replica', 'red', 'black', 'AIG', 'Dri-FIT', '6-3-digit', '623', 6, 2009, 2010, 'Red with black "Chevron" V pattern'),
  ('355093-010', 'Nike', 'Manchester United', '2009/10', 'Away', 'replica', 'black', 'blue', 'AIG', 'Dri-FIT', '6-3-digit', '010', 0, 2009, 2010, 'Black with blue chevron')
ON CONFLICT (code) DO UPDATE SET
  color_suffix = EXCLUDED.color_suffix,
  expected_suffix_digit = EXCLUDED.expected_suffix_digit,
  production_window_start = EXCLUDED.production_window_start,
  production_window_end = EXCLUDED.production_window_end,
  visual_description = EXCLUDED.visual_description;

-- Late Nike Phase (2010-2015): Advanced Security Features
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, color_suffix, expected_suffix_digit, production_window_start, production_window_end, visual_description) VALUES
  -- 2010-2011 Season
  ('382469-623', 'Nike', 'Manchester United', '2010/11', 'Home', 'replica', 'red', 'white', 'Aon', 'Dri-FIT', '6-3-digit', '623', 6, 2010, 2011, 'Red with white collar, first Aon sponsor'),
  
  -- 2011-2012 Season
  ('423932-623', 'Nike', 'Manchester United', '2011/12', 'Home', 'replica', 'red', 'white', 'Aon', 'Dri-FIT', '6-3-digit', '623', 6, 2011, 2012, 'Red with black/white crew neck'),
  ('423935-403', 'Nike', 'Manchester United', '2011/12', 'Away', 'replica', 'blue', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '403', 4, 2011, 2012, 'Blue and black hoops'),
  
  -- 2012-2013 Season
  ('479278-623', 'Nike', 'Manchester United', '2012/13', 'Home', 'replica', 'red', 'white', 'Aon', 'Dri-FIT', '6-3-digit', '623', 6, 2012, 2013, 'Gingham check pattern'),
  
  -- 2013-2014 Season
  ('532837-624', 'Nike', 'Manchester United', '2013/14', 'Home', 'replica', 'red', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '624', 6, 2013, 2014, 'Button-down black collar (Moyes era)'),
  ('532850-411', 'Nike', 'Manchester United', '2013/14', 'Away', 'replica', 'navy_blue', 'navy_blue', 'Aon', 'Dri-FIT', '6-3-digit', '411', 4, 2013, 2014, 'Navy/Blue Gingham check'),
  
  -- 2014-2015 Season (Final Nike Season)
  ('611031-624', 'Nike', 'Manchester United', '2014/15', 'Home', 'replica', 'red', 'white', 'Chevrolet', 'Dri-FIT', '6-3-digit', '624', 6, 2014, 2015, 'First Chevrolet sponsor, white/black collar. HEAVILY COUNTERFEITED.')
ON CONFLICT (code) DO UPDATE SET
  color_suffix = EXCLUDED.color_suffix,
  expected_suffix_digit = EXCLUDED.expected_suffix_digit,
  production_window_start = EXCLUDED.production_window_start,
  production_window_end = EXCLUDED.production_window_end,
  visual_description = EXCLUDED.visual_description;

-- ============================================
-- Color Suffix Validation Reference
-- ============================================
COMMENT ON COLUMN product_codes.expected_suffix_digit IS 'Nike color suffix validation: 6=Red, 0=Black, 1=White, 4=Blue, 3=Navy, 2=Yellow';

-- ============================================
-- ALTER: Add Adidas Tier System (Deep Research)
-- ============================================
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS tier TEXT;            -- 'replica', 'authentic', 'player_issue'
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_position_era TEXT; -- 'hip_tag', 'neck_tag' (Adidas 2020+ shifted)

-- ============================================
-- SEED DATA: Manchester United - Adidas Era COMPREHENSIVE (2015-2024)
-- Deep Research: Including Goalkeeper kits and Authentic variants
-- ============================================

-- 2015-2016 Season (First Adidas Season)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('AC1414', 'Adidas', 'Manchester United', '2015/16', 'Home', 'replica', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Real Red, White cuffs'),
  ('AI6363', 'Adidas', 'Manchester United', '2015/16', 'Away', 'replica', 'replica', 'white', 'red', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'White, Red trim'),
  ('AC1445', 'Adidas', 'Manchester United', '2015/16', 'Third', 'replica', 'replica', 'black', 'orange', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Black, flashy orange pattern'),
  ('AC1458', 'Adidas', 'Manchester United', '2015/16', 'GK Home', 'replica', 'replica', 'green', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Green goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2016-2017 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('AI6720', 'Adidas', 'Manchester United', '2016/17', 'Home', 'replica', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Half-and-half Hexagon red'),
  ('AI6704', 'Adidas', 'Manchester United', '2016/17', 'Away', 'replica', 'replica', 'blue', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Blue heather'),
  ('AI6690', 'Adidas', 'Manchester United', '2016/17', 'Third', 'replica', 'replica', 'white', 'grey', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'White, grey hex print'),
  ('S96152', 'Adidas', 'Manchester United', '2016/17', 'GK Home', 'replica', 'replica', 'black', 'green', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Black goalkeeper'),
  ('AP9135', 'Adidas', 'Manchester United', '2016/17', 'GK Away', 'replica', 'replica', 'green', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Green goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2017-2018 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('BS1214', 'Adidas', 'Manchester United', '2017/18', 'Home', 'replica', 'replica', 'red', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Red, button collar'),
  ('BS1217', 'Adidas', 'Manchester United', '2017/18', 'Away', 'replica', 'replica', 'black', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Black, 90-92 pattern tribute'),
  ('AZ7565', 'Adidas', 'Manchester United', '2017/18', 'Third', 'replica', 'replica', 'grey', 'pink', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Grey, Holy Trinity statue graphic'),
  ('AZ7556', 'Adidas', 'Manchester United', '2017/18', 'GK Home', 'replica', 'replica', 'black', 'green', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Black goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2018-2019 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('CG0040', 'Adidas', 'Manchester United', '2018/19', 'Home', 'replica', 'replica', 'red', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Red, black gradient stripes'),
  ('CG0038', 'Adidas', 'Manchester United', '2018/19', 'Away', 'replica', 'replica', 'pink', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Icey Pink'),
  ('DP6022', 'Adidas', 'Manchester United', '2018/19', 'Third', 'replica', 'replica', 'navy_blue', 'white', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Navy blue, Parley plastic'),
  ('DT6015', 'Adidas', 'Manchester United', '2018/19', 'GK Home', 'replica', 'replica', 'green', 'black', 'Chevrolet', 'ClimaCool', '2L4D', 'hip_tag', 'Green goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2019-2020 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('ED7386', 'Adidas', 'Manchester United', '2019/20', 'Home', 'replica', 'replica', 'red', 'black', 'Chevrolet', 'AEROREADY', '2L4D', 'hip_tag', 'Red, Shield crest'),
  ('ED7388', 'Adidas', 'Manchester United', '2019/20', 'Away', 'replica', 'replica', 'green', 'black', 'Chevrolet', 'AEROREADY', '2L4D', 'hip_tag', 'Snakeskin/Mosaic pattern'),
  ('ED7383', 'Adidas', 'Manchester United', '2019/20', 'GK Home', 'replica', 'replica', 'purple', 'black', 'Chevrolet', 'AEROREADY', '2L4D', 'hip_tag', 'Purple goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2020-2021 Season (Label position shift begins: hip_tag -> neck_tag)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('GC7958', 'Adidas', 'Manchester United', '2020/21', 'Home', 'replica', 'replica', 'red', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Red, yarn-style texture'),
  ('FM4290', 'Adidas', 'Manchester United', '2020/21', 'Home', 'authentic', 'authentic', 'red', 'black', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'Red, HEAT.RDY (Long Sleeve) AUTHENTIC'),
  ('EE2378', 'Adidas', 'Manchester United', '2020/21', 'Away', 'replica', 'replica', 'green', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Dark Green/Black (Earth)'),
  ('FM4236', 'Adidas', 'Manchester United', '2020/21', 'Third', 'replica', 'replica', 'black', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Black/White Zebra dazzle camo'),
  ('EE2392', 'Adidas', 'Manchester United', '2020/21', 'GK Home', 'replica', 'replica', 'orange', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Carbon/Orange goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2021-2022 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('H31447', 'Adidas', 'Manchester United', '2021/22', 'Home', 'replica', 'replica', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Red, clean design, TeamViewer'),
  ('GR3759', 'Adidas', 'Manchester United', '2021/22', 'Away', 'replica', 'replica', 'white', 'blue', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'White/Blue snowflake pattern'),
  ('GS2406', 'Adidas', 'Manchester United', '2021/22', 'Third', 'replica', 'replica', 'blue', 'yellow', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Blue/Black/Yellow'),
  ('GM4623', 'Adidas', 'Manchester United', '2021/22', 'GK Home', 'replica', 'replica', 'yellow', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Yellow goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2022-2023 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('H13889', 'Adidas', 'Manchester United', '2022/23', 'Home', 'authentic', 'authentic', 'red', 'white', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'Red, collar with triangles AUTHENTIC'),
  ('HE2981', 'Adidas', 'Manchester United', '2022/23', 'Third', 'replica', 'replica', 'lime', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Solar Slime Green'),
  ('H64059', 'Adidas', 'Manchester United', '2022/23', 'GK Home', 'replica', 'replica', 'blue', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Blue goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2023-2024 Season
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('IP1726', 'Adidas', 'Manchester United', '2023/24', 'Home', 'replica', 'replica', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Red, Rose geometric pattern'),
  ('IP1728', 'Adidas', 'Manchester United', '2023/24', 'Home', 'authentic', 'authentic', 'red', 'white', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'Red, HEAT.RDY AUTHENTIC'),
  ('HR3675', 'Adidas', 'Manchester United', '2023/24', 'Away', 'replica', 'replica', 'green', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Green/White stripes'),
  ('IP1741', 'Adidas', 'Manchester United', '2023/24', 'Third', 'replica', 'replica', 'white', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'White, Devil crest only'),
  ('IA7211', 'Adidas', 'Manchester United', '2023/24', 'GK Home', 'replica', 'replica', 'green', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Solar Green goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- 2024-2025 Season (Snapdragon era)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('IU1397', 'Adidas', 'Manchester United', '2024/25', 'Home', 'replica', 'replica', 'red', 'white', 'Snapdragon', 'AEROREADY', '2L4D', 'neck_tag', 'Red gradient, Snapdragon sponsor'),
  ('JF1291', 'Adidas', 'Manchester United', '2024/25', 'Home', 'authentic', 'authentic', 'red', 'white', 'Snapdragon', 'HEAT.RDY', '2L4D', 'neck_tag', 'Red, HEAT.RDY AUTHENTIC'),
  ('IU1390', 'Adidas', 'Manchester United', '2024/25', 'Away', 'replica', 'replica', 'navy_blue', 'white', 'Snapdragon', 'AEROREADY', '2L4D', 'neck_tag', 'Night Indigo (Blue)'),
  ('IU1391', 'Adidas', 'Manchester United', '2024/25', 'Away', 'authentic', 'authentic', 'navy_blue', 'white', 'Snapdragon', 'HEAT.RDY', '2L4D', 'neck_tag', 'Night Indigo AUTHENTIC'),
  ('JJ1383', 'Adidas', 'Manchester United', '2024/25', 'GK Home', 'replica', 'replica', 'purple', 'black', 'Snapdragon', 'AEROREADY', '2L4D', 'neck_tag', 'Purple goalkeeper')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, label_position_era = EXCLUDED.label_position_era, visual_description = EXCLUDED.visual_description;

-- ============================================
-- Verify Full Deep Research Integration
-- ============================================
SELECT 'Total Manchester United Codes' as summary, 
       brand, tier, COUNT(*) as count
FROM product_codes 
WHERE team = 'Manchester United'
GROUP BY brand, tier
ORDER BY brand, tier;

SELECT 'All Kits' as category, season, kit_type, code, tier, sponsor
FROM product_codes 
WHERE team = 'Manchester United'
ORDER BY season, kit_type, tier;

-- ============================================
-- REVERSE ENGINEERING: Additional Codes (Session 16)
-- Research-based additions from vintage shirt databases
-- ============================================

-- Nike Goalkeeper Kits (2007-2015)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, color_suffix, expected_suffix_digit, visual_description) VALUES
  ('287617-760', 'Nike', 'Manchester United', '2008/09', 'GK Home', 'replica', 'yellow', 'black', 'AIG', 'Dri-FIT', '6-3-digit', '760', 7, 'Yellow GK, Foster era'),
  ('355096-105', 'Nike', 'Manchester United', '2009/10', 'GK Home', 'replica', 'white', 'black', 'AIG', 'Dri-FIT', '6-3-digit', '105', 1, 'White GK, Van der Sar'),
  ('355115-105', 'Nike', 'Manchester United', '2009/10', 'GK Home', 'youth', 'white', 'black', 'AIG', 'Dri-FIT', '6-3-digit', '105', 1, 'White GK Youth'),
  ('382474-701', 'Nike', 'Manchester United', '2010/11', 'GK Third', 'replica', 'yellow', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '701', 7, 'Yellow GK Third')
ON CONFLICT (code) DO UPDATE SET visual_description = EXCLUDED.visual_description;

-- Nike Away Kits (2010-2015) - Missing from original
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, color_suffix, expected_suffix_digit, visual_description) VALUES
  ('382470-105', 'Nike', 'Manchester United', '2010/11', 'Away', 'replica', 'white', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '105', 1, 'White away with black trim'),
  ('383003-105', 'Nike', 'Manchester United', '2010/11', 'Away', 'replica', 'white', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '105', 1, 'White away alternate code'),
  ('382997-105', 'Nike', 'Manchester United', '2010/12', 'Away', 'long_sleeve', 'white', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '105', 1, 'White away LS version'),
  ('479281-105', 'Nike', 'Manchester United', '2012/13', 'Away', 'replica', 'white', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '105', 1, 'White Gingham away'),
  ('479282-105', 'Nike', 'Manchester United', '2012/13', 'Away', 'replica', 'white', 'black', 'Aon', 'Dri-FIT', '6-3-digit', '105', 1, 'White away alternate'),
  ('611032-106', 'Nike', 'Manchester United', '2014/15', 'Away', 'replica', 'white', 'black', 'Chevrolet', 'Dri-FIT', '6-3-digit', '106', 1, 'White away, first Chevrolet'),
  ('575280-703', 'Nike', 'Manchester United', '2014/15', 'Away', 'authentic', 'white', 'black', 'Chevrolet', 'Dri-FIT', '6-3-digit', '703', 7, 'White away AUTHENTIC')
ON CONFLICT (code) DO UPDATE SET visual_description = EXCLUDED.visual_description;

-- Nike 2008/09 Home/Away (Missing base codes)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, secondary_color, sponsor, technology, code_format, color_suffix, expected_suffix_digit, visual_description) VALUES
  ('287634-403', 'Nike', 'Manchester United', '2008/09', 'Third', 'replica', 'blue', 'white', 'AIG', 'Dri-FIT', '6-3-digit', '403', 4, 'Blue third, 40th anniversary')
ON CONFLICT (code) DO UPDATE SET visual_description = EXCLUDED.visual_description;

-- Adidas Authentic Variants (2020-2023) - HEAT.RDY versions
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('EE2377', 'Adidas', 'Manchester United', '2020/21', 'Away', 'authentic', 'authentic', 'green', 'black', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'Green away HEAT.RDY AUTHENTIC'),
  ('GC7957', 'Adidas', 'Manchester United', '2020/21', 'Home', 'authentic', 'authentic', 'red', 'black', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'Red home HEAT.RDY AUTHENTIC'),
  ('GM4622', 'Adidas', 'Manchester United', '2021/22', 'Away', 'authentic', 'authentic', 'white', 'blue', 'TeamViewer', 'HEAT.RDY', '2L4D', 'neck_tag', 'White/Blue away HEAT.RDY AUTHENTIC'),
  ('ED7390', 'Adidas', 'Manchester United', '2019/20', 'Third', 'replica', 'replica', 'black', 'gold', 'Chevrolet', 'Climalite', '2L4D', 'hip_tag', 'Black third, Climalite')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, technology = EXCLUDED.technology, visual_description = EXCLUDED.visual_description;

-- Adidas Training/Pre-Match Kits (2020-2024)
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, secondary_color, sponsor, technology, code_format, label_position_era, visual_description) VALUES
  ('FH8550', 'Adidas', 'Manchester United', '2020/21', 'Pre-Match', 'training', 'training', 'multi', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Pre-match warm-up top'),
  ('GR3914', 'Adidas', 'Manchester United', '2021/22', 'Pre-Match', 'training', 'training', 'red', 'white', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Pre-match training jersey'),
  ('H56682', 'Adidas', 'Manchester United', '2022/23', 'Pre-Match', 'training', 'training', 'white', 'red', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'White/Red pre-match'),
  ('HT4293', 'Adidas', 'Manchester United', '2022/23', 'Training', 'training', 'training', 'red', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Training jersey'),
  ('IA7242', 'Adidas', 'Manchester United', '2023/24', 'Pre-Match', 'training', 'training', 'red', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Red/Black pre-match'),
  ('IA8494', 'Adidas', 'Manchester United', '2023/24', 'Training', 'training', 'training', 'red', 'black', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'Training shirt 2023/24'),
  ('IA8492', 'Adidas', 'Manchester United', '2023/24', 'Training', 'training', 'training', 'white', 'red', 'TeamViewer', 'AEROREADY', '2L4D', 'neck_tag', 'White Tiro 23 training')
ON CONFLICT (code) DO UPDATE SET tier = EXCLUDED.tier, visual_description = EXCLUDED.visual_description;

-- ============================================
-- Final Count Verification
-- ============================================
SELECT 'FINAL COUNT' as status, COUNT(*) as total_codes
FROM product_codes 
WHERE team = 'Manchester United';

SELECT 'By Category' as status, kit_type, COUNT(*) as count
FROM product_codes 
WHERE team = 'Manchester United'
GROUP BY kit_type
ORDER BY count DESC;

-- ============================================
-- TABLE: Manufacturing Origin Eras (Deep Research)
-- Cross-validation: Country of manufacture vs Era
-- ============================================
CREATE TABLE IF NOT EXISTS manufacturing_origin_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  country TEXT NOT NULL,
  origin_type TEXT DEFAULT 'primary', -- 'primary', 'secondary', 'suspicious'
  notes TEXT,
  confidence DECIMAL(3,2) DEFAULT 0.90, -- How confident this origin is authentic
  UNIQUE(manufacturer_id, start_year, country)
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_origin_eras_manufacturer ON manufacturing_origin_eras(manufacturer_id);

-- ============================================
-- SEED DATA: Manufacturing Origins (Deep Research)
-- ============================================

-- Nike Era Manufacturing Origins
INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2009, 'Morocco', 'primary', 'Primary origin for Vodafone/AIG era replicas. Strong authenticity indicator.', 0.95
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2006, 'Portugal', 'primary', 'Early Nike era, high-quality European production.', 0.95
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2006, 'England', 'secondary', 'Rare UK production for early Nike era.', 0.98
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2007, 2015, 'Thailand', 'primary', 'Player Issue (Code 7) often from Thailand.', 0.85
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2010, 2015, 'Indonesia', 'primary', 'Aon/Chevrolet era mass production shifted to Indonesia.', 0.90
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2010, 'China', 'suspicious', 'Early era China origin is suspicious - most fakes are China origin.', 0.30
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2010, 'Vietnam', 'suspicious', 'Early era Vietnam is less common for replicas.', 0.50
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

-- Adidas Era Manufacturing Origins
INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, 2019, 'Cambodia', 'primary', 'Primary origin for 2015-2019 replicas. Strong authenticity.', 0.95
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, NULL, 'Vietnam', 'primary', 'Major Adidas production hub since 2015.', 0.90
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2020, NULL, 'Thailand', 'secondary', 'Thailand common but also heavily faked. Extra scrutiny needed.', 0.75
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, 2019, 'China', 'suspicious', 'China origin for Adidas era is suspicious - major fake source.', 0.25
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- Umbro Era (Limited data - visual verification focus)
INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 1992, 2002, 'England', 'primary', 'UK production for Umbro premium lines.', 0.95
FROM manufacturers m WHERE m.name = 'Umbro'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 1992, 2002, 'Portugal', 'secondary', 'Portuguese production for mass market.', 0.85
FROM manufacturers m WHERE m.name = 'Umbro'
ON CONFLICT DO NOTHING;

-- ============================================
-- COMMENT: Validation Logic for Production Origin
-- ============================================
COMMENT ON TABLE manufacturing_origin_eras IS 
'Cross-validation table for country_of_manufacture. 
If user inputs "Made in China" for a 2007 Nike shirt, 
system checks this table and flags as SUSPICIOUS (confidence 0.30).
Morocco 2007 = HIGH confidence (0.95).';

-- ============================================
-- Verify Origin Data
-- ============================================
SELECT 'Manufacturing Origins' as category, 
       m.name as manufacturer, 
       moe.country, 
       moe.start_year, 
       moe.end_year, 
       moe.origin_type,
       moe.confidence
FROM manufacturing_origin_eras moe
JOIN manufacturers m ON moe.manufacturer_id = m.id
ORDER BY m.name, moe.start_year;

-- ============================================
-- TABLE: Valuation Tiers (Deep Research - Bölüm 3)
-- Pricing data from sold listings analysis
-- ============================================
CREATE TABLE IF NOT EXISTS valuation_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_code TEXT UNIQUE NOT NULL, -- 'A+', 'A', 'B', 'B-', 'C', 'D'
  tier_name TEXT NOT NULL,
  category TEXT NOT NULL,
  example_description TEXT,
  condition_notes TEXT,
  price_min_gbp DECIMAL(10,2),
  price_max_gbp DECIMAL(10,2),
  price_min_usd DECIMAL(10,2),
  price_max_usd DECIMAL(10,2)
);

-- SEED DATA: Valuation Tiers
INSERT INTO valuation_tiers (tier_code, tier_name, category, example_description, condition_notes, price_min_gbp, price_max_gbp, price_min_usd, price_max_usd) VALUES
  ('A+', 'Rare Vintage', 'Vintage Original (Nadir)', '1992-1994 Newton Heath, Cantona signed', 'Excellent/Mint', 150, 300, 190, 380),
  ('A', 'Vintage Original', 'Classic Era', '1994-1999 Beckham, Treble season', 'Good/Very Good', 80, 150, 100, 190),
  ('B', 'Modern Authentic', 'Player/Match Spec', '2015-2024 HEAT.RDY, Player Issue', 'BNWT (Brand New With Tags)', 70, 110, 90, 140),
  ('B-', 'Modern Authentic Used', 'Player Spec 2nd Hand', '2015-2020 Adizero/Climachill', 'Used/Good', 40, 70, 50, 90),
  ('C', 'Modern Replica', 'Stadium/Fan Edition', '2015-Present AEROREADY', 'BNWT/Good', 30, 50, 40, 65),
  ('D', 'Counterfeit', 'Fake', 'Any era known fake', 'Any', 0, 15, 0, 20)
ON CONFLICT (tier_code) DO UPDATE SET 
  price_min_gbp = EXCLUDED.price_min_gbp,
  price_max_gbp = EXCLUDED.price_max_gbp;

-- ============================================
-- TABLE: Size Format Eras (Typography Validation)
-- L vs L/G transition detection
-- ============================================
CREATE TABLE IF NOT EXISTS size_format_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  format_type TEXT NOT NULL, -- 'single_letter', 'dual_notation'
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  example TEXT,
  notes TEXT
);

-- SEED DATA: Size Format Evolution
INSERT INTO size_format_eras (format_type, start_year, end_year, example, notes) VALUES
  ('single_letter', 1992, 2010, 'L, M, S, XL', 'Pre-2010: Single letter sizing only'),
  ('dual_notation', 2010, NULL, 'L/G, M/M, S/P, XL/TG', 'Post-2010: English/French dual notation for North America')
ON CONFLICT DO NOTHING;

-- ============================================
-- TABLE: Font Era Validation (Typography Fingerprint)
-- ============================================
CREATE TABLE IF NOT EXISTS font_era_validation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  font_style TEXT NOT NULL, -- 'blocky_sans', 'condensed', 'modern'
  label_texture TEXT, -- 'satin', 'paper', 'woven'
  notes TEXT
);

-- SEED DATA: Nike Font Eras
INSERT INTO font_era_validation (manufacturer_id, start_year, end_year, font_style, label_texture, notes)
SELECT m.id, 2002, 2010, 'blocky_sans', 'satin', 'Heavy blocky sans-serif font. Shiny satin label texture. Wide letter spacing.'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO font_era_validation (manufacturer_id, start_year, end_year, font_style, label_texture, notes)
SELECT m.id, 2010, 2015, 'condensed', 'paper', 'Futura Condensed variant. Matte paper-like stacked labels.'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

-- SEED DATA: Adidas Font Eras
INSERT INTO font_era_validation (manufacturer_id, start_year, end_year, font_style, label_texture, notes)
SELECT m.id, 2015, 2020, 'modern_clean', 'woven', 'Clean modern sans-serif. Hip tag location.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO font_era_validation (manufacturer_id, start_year, end_year, font_style, label_texture, notes)
SELECT m.id, 2020, NULL, 'modern_clean', 'woven', 'Neck tag location shift. Same font style.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- ============================================
-- TABLE: Technology Tier Validation
-- AEROREADY vs HEAT.RDY cross-check
-- ============================================
CREATE TABLE IF NOT EXISTS technology_tier_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  technology TEXT NOT NULL,
  tier TEXT NOT NULL, -- 'replica', 'authentic', 'player_issue'
  start_year INTEGER,
  end_year INTEGER,
  notes TEXT,
  UNIQUE(manufacturer_id, technology, tier)
);

-- SEED DATA: Adidas Technology Tiers
INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'ClimaCool', 'replica', 2015, 2019, 'Early Adidas era replica technology'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'AEROREADY', 'replica', 2019, NULL, 'Modern replica technology. NEVER used on match shirts.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'Climachill', 'authentic', 2015, 2019, 'Early authentic/player issue technology'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'HEAT.RDY', 'authentic', 2019, NULL, 'Modern authentic technology. Used on actual match shirts.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- SEED DATA: Nike Technology Tiers
INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'Dri-FIT', 'replica', 2002, 2015, 'Standard replica technology'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'NikeFIT Sphere', 'authentic', 2002, 2008, 'Early authentic technology with laser holes'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'Nike Pro Combat', 'authentic', 2008, 2015, 'Later authentic with T-bar reinforcement'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

-- ============================================
-- Jock Tag Evolution (Nike)
-- ============================================
CREATE TABLE IF NOT EXISTS jock_tag_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  tag_type TEXT NOT NULL, -- 'double_layer', 'oval_total90', 'rectangular'
  visual_description TEXT,
  authentic_indicator TEXT,
  notes TEXT
);

-- SEED DATA: Nike Jock Tag Evolution
INSERT INTO jock_tag_eras (manufacturer_id, start_year, end_year, tag_type, visual_description, authentic_indicator, notes)
SELECT m.id, 2002, 2004, 'double_layer', 'Grey/Silver dual layer', 'Clean print, correct placement', 'Early Nike era'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO jock_tag_eras (manufacturer_id, start_year, end_year, tag_type, visual_description, authentic_indicator, notes)
SELECT m.id, 2004, 2007, 'oval_total90', 'Iconic oval with 90 logo', 'Correct aspect ratio, proper placement at hem', 'Fakes often get aspect ratio wrong'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO jock_tag_eras (manufacturer_id, start_year, end_year, tag_type, visual_description, authentic_indicator, notes)
SELECT m.id, 2007, 2015, 'rectangular', 'Rectangular with serial numbers', 'Gold/Silver for Auth, plain for Replica', 'Authentic tags say "Engineered to exact specifications"'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

-- ============================================
-- VALIDATION RULE: Technology vs Claim
-- If user claims "Match Worn" but tech is AEROREADY = FAKE
-- ============================================
COMMENT ON TABLE technology_tier_mapping IS 
'Critical validation: If user claims "Match Worn" shirt but label shows AEROREADY technology, 
claim is INSTANTLY REFUTED. Match shirts are ALWAYS HEAT.RDY or Climachill.';

-- ============================================
-- Final Schema Verification
-- ============================================
SELECT 'Schema Tables' as category, tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('valuation_tiers', 'size_format_eras', 'font_era_validation', 'technology_tier_mapping', 'jock_tag_eras', 'manufacturing_origin_eras')
ORDER BY tablename;

-- ============================================
-- VALIDATION RULES: Price Anomaly Detection (Bölüm 4)
-- "Too Good To Be True" Algorithm
-- ============================================

-- Add price validation fields to product_codes
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_min DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_max DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS price_currency TEXT DEFAULT 'GBP';

COMMENT ON COLUMN product_codes.estimated_price_min IS 
'Minimum expected price for authentic item. If listed price < 40% of this, flag as SUSPICIOUS.
Example: 1999 Treble shirt min = £150. Listed at £40 = FAKE.';

-- ============================================
-- TABLE: Sustainability Labels (2020+)
-- Missing "Primegreen" or "End Plastic Waste" = Suspicious
-- ============================================
CREATE TABLE IF NOT EXISTS sustainability_label_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  label_name TEXT NOT NULL,
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  is_mandatory BOOLEAN DEFAULT true,
  notes TEXT
);

-- SEED DATA: Adidas Sustainability Labels
INSERT INTO sustainability_label_eras (manufacturer_id, label_name, start_year, end_year, is_mandatory, notes)
SELECT m.id, 'Primegreen', 2020, NULL, true, 'Recycled materials branding. Missing on 2020+ shirt = FAKE'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO sustainability_label_eras (manufacturer_id, label_name, start_year, end_year, is_mandatory, notes)
SELECT m.id, 'End Plastic Waste', 2021, NULL, true, 'Three-loop logo. Required on modern Adidas.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- ============================================
-- VALIDATION LOGIC: Deadstock Paradox Detection
-- High volume BNWT for 10+ year old shirts = Suspicious
-- ============================================
COMMENT ON TABLE product_codes IS 
'DEADSTOCK PARADOX: If database detects sudden surge of BNWT (Brand New With Tags) entries 
for vintage codes (10+ years old, e.g., 2008 Ronaldo), this indicates a NEW FAKE BATCH 
has entered the market, not a warehouse find. Use volume spikes as threat detection.';

-- ============================================
-- CROSS-VALIDATION MATRIX (Algorithm Flow)
-- ============================================
/*
LEVEL 1: Code Match
  └── Code found in DB → Continue
  └── Code NOT found → Check format pattern → Return "Unknown but plausible" or "Invalid format"

LEVEL 2: Context Validation
  ├── Check team matches code (AC1414 = Man Utd, not Colombia)
  ├── Check manufacturer era (Adidas 2008 Man Utd = IMPOSSIBLE)
  └── Check color suffix (623 = Red, if Blue shirt = FAKE)

LEVEL 3: Manufacturing Validation
  ├── Check country of origin vs era (Morocco 2007 = GOOD, China 2007 = SUSPICIOUS)
  ├── Check technology vs tier (AEROREADY + "Match Worn" claim = FAKE)
  └── Check size format (L/G on 1999 shirt = FAKE)

LEVEL 4: Visual Validation (Future)
  ├── Check font style vs era (Condensed font on 2004 shirt = FAKE)
  ├── Check jock tag type (Oval Total90 on 2012 shirt = FAKE)
  └── Check sustainability labels (No Primegreen on 2023 = SUSPICIOUS)

LEVEL 5: Price Validation
  └── Price < 40% of tier minimum = FLAG AS LIKELY FAKE
*/

-- ============================================
-- FINAL STATISTICS
-- ============================================
SELECT 'DATABASE SUMMARY' as report_type;

SELECT 'Product Codes' as category, COUNT(*) as count FROM product_codes WHERE team = 'Manchester United';
SELECT 'Blacklist Codes' as category, COUNT(*) as count FROM blacklist_codes;
SELECT 'Manufacturing Origins' as category, COUNT(*) as count FROM manufacturing_origin_eras;
SELECT 'Valuation Tiers' as category, COUNT(*) as count FROM valuation_tiers;
SELECT 'Technology Mappings' as category, COUNT(*) as count FROM technology_tier_mapping;
SELECT 'Font Era Rules' as category, COUNT(*) as count FROM font_era_validation;
SELECT 'Jock Tag Eras' as category, COUNT(*) as count FROM jock_tag_eras;
SELECT 'Sustainability Labels' as category, COUNT(*) as count FROM sustainability_label_eras;

-- Total tables in schema
SELECT 'TOTAL TABLES' as summary, COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public';

