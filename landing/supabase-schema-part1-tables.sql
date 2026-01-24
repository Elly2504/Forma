-- KitTicker Schema Part 1: Tables and Structure
-- Run this FIRST in Supabase SQL Editor
-- Last Updated: 2026-01-18

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
  code_format_regex TEXT,
  validation_rules JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: Teams
CREATE TABLE IF NOT EXISTS teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  league_id UUID REFERENCES leagues(id),
  country TEXT NOT NULL,
  short_code TEXT,
  validation_config JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: Team Manufacturer Eras
CREATE TABLE IF NOT EXISTS team_manufacturer_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  manufacturer_id UUID NOT NULL REFERENCES manufacturers(id) ON DELETE CASCADE,
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  notes TEXT,
  UNIQUE(team_id, manufacturer_id, start_year)
);

-- TABLE: Team Sponsor Eras
CREATE TABLE IF NOT EXISTS team_sponsor_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  sponsor_name TEXT NOT NULL,
  sponsor_type TEXT DEFAULT 'shirt',
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  UNIQUE(team_id, sponsor_name, start_year)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_teams_league ON teams(league_id);
CREATE INDEX IF NOT EXISTS idx_team_eras_team ON team_manufacturer_eras(team_id);
CREATE INDEX IF NOT EXISTS idx_team_sponsors_team ON team_sponsor_eras(team_id);

-- ============================================
-- TABLE: Product Codes (Main Table)
-- ============================================
CREATE TABLE IF NOT EXISTS product_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  brand TEXT NOT NULL,
  team TEXT,
  season TEXT,
  kit_type TEXT,
  variant TEXT,
  verified BOOLEAN DEFAULT true,
  verification_source TEXT DEFAULT 'community',
  lookup_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_product_codes_code ON product_codes(code);
CREATE INDEX IF NOT EXISTS idx_product_codes_brand ON product_codes(brand);
CREATE INDEX IF NOT EXISTS idx_product_codes_team ON product_codes(team);

-- Enable RLS
ALTER TABLE product_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read product codes" ON product_codes;
CREATE POLICY "Anyone can read product codes" ON product_codes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert" ON product_codes;
CREATE POLICY "Authenticated users can insert" ON product_codes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- TABLE: Blacklist Codes
-- ============================================
CREATE TABLE IF NOT EXISTS blacklist_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL,
  brand TEXT NOT NULL,
  reason TEXT NOT NULL,
  legitimate_use TEXT,
  reported_count INTEGER DEFAULT 1,
  severity TEXT DEFAULT 'medium',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blacklist_code ON blacklist_codes(code);

-- ============================================
-- TABLE: Code Format Patterns
-- ============================================
CREATE TABLE IF NOT EXISTS code_format_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand TEXT NOT NULL,
  pattern TEXT NOT NULL,
  pattern_name TEXT,
  era_start INTEGER,
  era_end INTEGER,
  description TEXT
);

-- ============================================
-- TABLE: API Keys
-- ============================================
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_hash TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  owner_email TEXT NOT NULL,
  tier TEXT DEFAULT 'free',
  monthly_quota INTEGER DEFAULT 100,
  usage_this_month INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ
);

-- ============================================
-- TABLE: API Usage Logs
-- ============================================
CREATE TABLE IF NOT EXISTS api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID REFERENCES api_keys(id),
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER,
  response_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: Digital Passports
-- ============================================
CREATE TABLE IF NOT EXISTS digital_passports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uid TEXT UNIQUE NOT NULL,
  product_code_id UUID REFERENCES product_codes(id),
  owner_id UUID,
  verification_status TEXT DEFAULT 'verified',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- All ALTER TABLE statements
-- ============================================
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES teams(id);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS manufacturer_id UUID REFERENCES manufacturers(id);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS primary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS secondary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_min DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS estimated_price_max DECIMAL(10,2);
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS price_currency TEXT DEFAULT 'GBP';
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS api_lookup_count INTEGER DEFAULT 0;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_type TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_position TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS era_start_year INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS era_end_year INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS code_format TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS country_of_manufacture TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS technology TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS sponsor TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS expected_colors JSONB;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS tier TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_position_era TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS color_suffix TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS expected_suffix_digit INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS production_window_start INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS production_window_end INTEGER;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS alternate_codes JSONB DEFAULT '[]';
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_material TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_font TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS date_code TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS visual_description TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS is_known_clone BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_product_codes_team_id ON product_codes(team_id);
CREATE INDEX IF NOT EXISTS idx_product_codes_manufacturer_id ON product_codes(manufacturer_id);

-- ============================================
-- Additional Reference Tables
-- ============================================

-- Manufacturing Origin Eras
CREATE TABLE IF NOT EXISTS manufacturing_origin_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  country TEXT NOT NULL,
  origin_type TEXT DEFAULT 'primary',
  notes TEXT,
  confidence DECIMAL(3,2) DEFAULT 0.90,
  UNIQUE(manufacturer_id, start_year, country)
);

CREATE INDEX IF NOT EXISTS idx_origin_eras_manufacturer ON manufacturing_origin_eras(manufacturer_id);

-- Valuation Tiers
CREATE TABLE IF NOT EXISTS valuation_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_code TEXT UNIQUE NOT NULL,
  tier_name TEXT NOT NULL,
  category TEXT NOT NULL,
  example_description TEXT,
  condition_notes TEXT,
  price_min_gbp DECIMAL(10,2),
  price_max_gbp DECIMAL(10,2),
  price_min_usd DECIMAL(10,2),
  price_max_usd DECIMAL(10,2)
);

-- Size Format Eras
CREATE TABLE IF NOT EXISTS size_format_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  format_type TEXT NOT NULL,
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  example TEXT,
  notes TEXT
);

-- Font Era Validation
CREATE TABLE IF NOT EXISTS font_era_validation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  font_style TEXT NOT NULL,
  label_texture TEXT,
  notes TEXT
);

-- Technology Tier Mapping
CREATE TABLE IF NOT EXISTS technology_tier_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  technology TEXT NOT NULL,
  tier TEXT NOT NULL,
  start_year INTEGER,
  end_year INTEGER,
  notes TEXT,
  UNIQUE(manufacturer_id, technology, tier)
);

-- Jock Tag Eras
CREATE TABLE IF NOT EXISTS jock_tag_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  tag_type TEXT NOT NULL,
  visual_description TEXT,
  authentic_indicator TEXT,
  notes TEXT
);

-- Sustainability Labels
CREATE TABLE IF NOT EXISTS sustainability_label_eras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer_id UUID REFERENCES manufacturers(id),
  label_name TEXT NOT NULL,
  start_year INTEGER NOT NULL,
  end_year INTEGER,
  is_mandatory BOOLEAN DEFAULT true,
  notes TEXT
);

-- ============================================
-- SCHEMA COMPLETE - Run Part 2 for seed data
-- ============================================
SELECT 'Part 1 Complete - Tables Created' as status;
