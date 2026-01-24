-- KitTicker Quick Fix: Add Missing Columns
-- Run this BEFORE Part 2 if you get column errors
-- Last Updated: 2026-01-18

-- Add variant column if missing
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS variant TEXT;

-- Add other potentially missing columns
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS primary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS secondary_color TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS sponsor TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS technology TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS tier TEXT;
ALTER TABLE product_codes ADD COLUMN IF NOT EXISTS label_position_era TEXT;

-- Verify
SELECT column_name FROM information_schema.columns WHERE table_name = 'product_codes' ORDER BY ordinal_position;
