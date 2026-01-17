-- KitTicker Product Codes Database Schema
-- Run this in Supabase SQL Editor

-- Product codes table
CREATE TABLE IF NOT EXISTS product_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  brand TEXT NOT NULL,
  team TEXT,
  season TEXT,
  kit_type TEXT,
  verified BOOLEAN DEFAULT true,
  lookup_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_product_codes_code ON product_codes(code);
CREATE INDEX IF NOT EXISTS idx_product_codes_brand ON product_codes(brand);

-- Enable RLS (Row Level Security)
ALTER TABLE product_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read product codes
CREATE POLICY "Anyone can read product codes" ON product_codes
  FOR SELECT USING (true);

-- Policy: Only authenticated users can insert (for future community contributions)
CREATE POLICY "Authenticated users can insert" ON product_codes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Seed data: Nike codes
INSERT INTO product_codes (code, brand, team, season, kit_type) VALUES
  ('638920-013', 'Nike', 'Paris Saint-Germain', '2015/16', 'Third'),
  ('658894-106', 'Nike', 'England', '2014/16', 'Home'),
  ('724006-612', 'Nike', 'Manchester United', '2014/15', 'Home'),
  ('624141-105', 'Nike', 'Barcelona', '2014/15', 'Away'),
  ('776929-480', 'Nike', 'Tottenham Hotspur', '2016/17', 'Home'),
  ('847284-010', 'Nike', 'Paris Saint-Germain', '2016/17', 'Third'),
  ('847268-480', 'Nike', 'Chelsea', '2017/18', 'Home'),
  ('894430-100', 'Nike', 'England', '2018/20', 'Home'),
  ('894430-010', 'Nike', 'England', '2018/20', 'Away'),
  ('CD0069-100', 'Nike', 'France', '2020/21', 'Away'),
  ('CD0712-100', 'Nike', 'Croatia', '2020/21', 'Home'),
  ('CK7828-100', 'Nike', 'Portugal', '2020/21', 'Home'),
  ('CD0696-100', 'Nike', 'Netherlands', '2020/21', 'Home'),
  ('CK5993-612', 'Nike', 'Liverpool', '2020/21', 'Home'),
  ('CZ2627-010', 'Nike', 'PSG x Jordan', '2020/21', 'Fourth')
ON CONFLICT (code) DO NOTHING;

-- Seed data: Adidas codes
INSERT INTO product_codes (code, brand, team, season, kit_type) VALUES
  ('IS7462', 'Adidas', 'Real Madrid', '2024/25', 'Home'),
  ('HR3796', 'Adidas', 'Manchester United', '2023/24', 'Home'),
  ('HY0632', 'Adidas', 'Arsenal', '2023/24', 'Home'),
  ('HM8901', 'Adidas', 'Bayern Munich', '2022/23', 'Home'),
  ('H31090', 'Adidas', 'Real Madrid', '2021/22', 'Home'),
  ('GI6463', 'Adidas', 'Juventus', '2020/21', 'Home'),
  ('FM4714', 'Adidas', 'Manchester United', '2020/21', 'Home'),
  ('EH6891', 'Adidas', 'Arsenal', '2019/20', 'Home'),
  ('DY7529', 'Adidas', 'Real Madrid', '2019/20', 'Home'),
  ('DW4433', 'Adidas', 'Bayern Munich', '2018/19', 'Home'),
  ('CG0040', 'Adidas', 'Manchester United', '2017/18', 'Home'),
  ('AZ7569', 'Adidas', 'Real Madrid', '2016/17', 'Home'),
  ('AI5152', 'Adidas', 'Real Madrid', '2015/16', 'Home'),
  ('M36158', 'Adidas', 'Bayern Munich', '2015/16', 'Home'),
  ('CW1526', 'Adidas', 'FAKE - Known Counterfeit', 'N/A', 'FAKE')
ON CONFLICT (code) DO NOTHING;

-- Seed data: Puma codes
INSERT INTO product_codes (code, brand, team, season, kit_type) VALUES
  ('736251-01', 'Puma', 'AC Milan', '2023/24', 'Home'),
  ('759122-01', 'Puma', 'Manchester City', '2023/24', 'Home'),
  ('765722-01', 'Puma', 'Borussia Dortmund', '2023/24', 'Home'),
  ('757061-01', 'Puma', 'AC Milan', '2022/23', 'Home'),
  ('765710-01', 'Puma', 'Manchester City', '2022/23', 'Home'),
  ('769459-01', 'Puma', 'Borussia Dortmund', '2022/23', 'Home'),
  ('759128-01', 'Puma', 'Marseille', '2022/23', 'Home'),
  ('763295-01', 'Puma', 'AC Milan', '2021/22', 'Home'),
  ('759220-01', 'Puma', 'Manchester City', '2021/22', 'Home'),
  ('759057-01', 'Puma', 'Borussia Dortmund', '2021/22', 'Home')
ON CONFLICT (code) DO NOTHING;

-- Seed data: Umbro codes
INSERT INTO product_codes (code, brand, team, season, kit_type) VALUES
  ('96281-U', 'Umbro', 'England', '1996', 'Home'),
  ('93761-U', 'Umbro', 'Manchester United', '1992/94', 'Home'),
  ('98491-U', 'Umbro', 'Manchester United', '1998/99', 'Home'),
  ('99271-U', 'Umbro', 'Chelsea', '1999/00', 'Home'),
  ('00561-U', 'Umbro', 'England', '2000/02', 'Home'),
  ('02671-U', 'Umbro', 'Manchester United', '2000/02', 'Away'),
  ('76781-U', 'Umbro', 'West Ham United', '2022/23', 'Home'),
  ('78921-U', 'Umbro', 'Everton', '2022/23', 'Home')
ON CONFLICT (code) DO NOTHING;

-- Verify insertion
SELECT brand, COUNT(*) as count FROM product_codes GROUP BY brand ORDER BY count DESC;
