-- KitTicker: Fix RLS Policies for Public Access
-- Run this in Supabase SQL Editor to fix 406 errors
-- Last Updated: 2026-01-19

-- ============================================
-- FIX: product_codes table RLS
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read product codes" ON product_codes;
DROP POLICY IF EXISTS "Public read access" ON product_codes;

-- Create new policy for public read access
CREATE POLICY "Public read access" ON product_codes
  FOR SELECT 
  TO anon, authenticated
  USING (true);

-- Verify RLS is enabled
ALTER TABLE product_codes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FIX: blacklist_codes table RLS
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read blacklist" ON blacklist_codes;
DROP POLICY IF EXISTS "Public read access" ON blacklist_codes;

-- Create new policy for public read access
CREATE POLICY "Public read access" ON blacklist_codes
  FOR SELECT 
  TO anon, authenticated
  USING (true);

-- Verify RLS is enabled
ALTER TABLE blacklist_codes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CREATE: verification_logs table
-- ============================================

CREATE TABLE IF NOT EXISTS verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL,
  brand TEXT,
  result_type TEXT NOT NULL,
  confidence_score INTEGER,
  signals_used JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_verification_logs_code ON verification_logs(code);
CREATE INDEX IF NOT EXISTS idx_verification_logs_created_at ON verification_logs(created_at);

-- Enable RLS
ALTER TABLE verification_logs ENABLE ROW LEVEL SECURITY;

-- Allow public insert
DROP POLICY IF EXISTS "Public insert access" ON verification_logs;
CREATE POLICY "Public insert access" ON verification_logs
  FOR INSERT 
  TO anon, authenticated
  WITH CHECK (true);

-- Allow public read
DROP POLICY IF EXISTS "Public read access" ON verification_logs;
CREATE POLICY "Public read access" ON verification_logs
  FOR SELECT 
  TO anon, authenticated
  USING (true);

-- ============================================
-- VERIFY: Check policies exist
-- ============================================

SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('product_codes', 'blacklist_codes', 'verification_logs');
