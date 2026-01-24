-- KitTicker Schema Part 2: Seed Data
-- Run this AFTER Part 1 (tables) in Supabase SQL Editor
-- Last Updated: 2026-01-18

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

-- ============================================
-- Manchester United Manufacturer Eras
-- ============================================
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

-- ============================================
-- Manchester United Sponsor Eras
-- ============================================
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
-- Blacklist Codes (Known Fakes)
-- ============================================
INSERT INTO blacklist_codes (code, brand, reason, legitimate_use, severity) VALUES
  ('CW1526', 'Adidas', 'Known counterfeit code appearing on many fake Man Utd shirts', 'Only valid for 2018 Colombia national team', 'high'),
  ('P95985', 'Adidas', 'Generic swing tag code appearing on mass-produced fakes', NULL, 'high'),
  ('X21992', 'Adidas', 'Real Madrid Away code misused on Man Utd fakes', 'Only valid for Real Madrid kits', 'high'),
  ('AI4411', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('697265', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('B10751', 'Adidas', 'Generic code found on low-quality fakes', NULL, 'high'),
  ('AZ7565', 'Adidas', '2017/18 Third code misused on wrong seasons', 'Only valid for 2017/18 Third', 'medium'),
  ('ADIDAS JSY', 'Adidas', 'Generic tag text instead of specific product code', NULL, 'medium'),
  ('000000-000', 'Nike', 'Placeholder/test code appearing on fakes', NULL, 'high'),
  ('123456-789', 'Nike', 'Sequential test code pattern', NULL, 'high'),
  ('111111-111', 'Nike', 'Repeated digit pattern - obvious fake', NULL, 'high'),
  ('FAKE001', 'Generic', 'Test entry for development', NULL, 'low')
ON CONFLICT DO NOTHING;

-- ============================================
-- Product Codes: Nike Era (Sample)
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant) VALUES
  ('638920-013', 'Nike', 'Paris Saint-Germain', '2015/16', 'Third', 'replica'),
  ('658894-106', 'Nike', 'England', '2014/16', 'Home', 'replica'),
  ('724006-612', 'Nike', 'Manchester United', '2014/15', 'Home', 'replica'),
  ('624141-105', 'Nike', 'Barcelona', '2014/15', 'Away', 'replica'),
  ('776929-480', 'Nike', 'Tottenham Hotspur', '2016/17', 'Home', 'replica'),
  ('847284-010', 'Nike', 'Paris Saint-Germain', '2016/17', 'Third', 'replica'),
  ('847268-480', 'Nike', 'Chelsea', '2017/18', 'Home', 'replica'),
  ('847261-100', 'Nike', 'Chelsea', '2017/18', 'Away', 'replica'),
  ('894430-100', 'Nike', 'England', '2018/20', 'Home', 'replica'),
  ('894430-010', 'Nike', 'England', '2018/20', 'Away', 'replica')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- Product Codes: Manchester United Nike Era
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, primary_color, sponsor, technology) VALUES
  ('146814', 'Nike', 'Manchester United', '2006/07', 'Home', 'replica', 'red', 'AIG', 'Dri-FIT'),
  ('238347-623', 'Nike', 'Manchester United', '2007/09', 'Home', 'replica', 'red', 'AIG', 'Dri-FIT'),
  ('245433-010', 'Nike', 'Manchester United', '2007/08', 'Away', 'replica', 'black', 'AIG', 'Dri-FIT'),
  ('238348-010', 'Nike', 'Manchester United', '2007/08', 'Third', 'replica', 'white', 'AIG', 'Dri-FIT'),
  ('287000-403', 'Nike', 'Manchester United', '2008/09', 'Third', 'replica', 'blue', 'AIG', 'Dri-FIT'),
  ('287617-760', 'Nike', 'Manchester United', '2008/09', 'GK Home', 'replica', 'yellow', 'AIG', 'Dri-FIT'),
  ('355091-623', 'Nike', 'Manchester United', '2009/10', 'Home', 'replica', 'red', 'AIG', 'Dri-FIT'),
  ('355093-010', 'Nike', 'Manchester United', '2009/10', 'Away', 'replica', 'black', 'AIG', 'Dri-FIT'),
  ('355096-105', 'Nike', 'Manchester United', '2009/10', 'GK Home', 'replica', 'white', 'AIG', 'Dri-FIT'),
  ('382469-623', 'Nike', 'Manchester United', '2010/11', 'Home', 'replica', 'red', 'Aon', 'Dri-FIT'),
  ('382470-105', 'Nike', 'Manchester United', '2010/11', 'Away', 'replica', 'white', 'Aon', 'Dri-FIT'),
  ('382474-701', 'Nike', 'Manchester United', '2010/11', 'GK Third', 'replica', 'yellow', 'Aon', 'Dri-FIT'),
  ('423932-623', 'Nike', 'Manchester United', '2011/12', 'Home', 'replica', 'red', 'Aon', 'Dri-FIT'),
  ('479278-623', 'Nike', 'Manchester United', '2012/13', 'Home', 'replica', 'red', 'Aon', 'Dri-FIT'),
  ('479281-105', 'Nike', 'Manchester United', '2012/13', 'Away', 'replica', 'white', 'Aon', 'Dri-FIT'),
  ('532837-624', 'Nike', 'Manchester United', '2013/14', 'Home', 'replica', 'red', 'Aon', 'Dri-FIT'),
  ('532840-411', 'Nike', 'Manchester United', '2013/14', 'Away', 'replica', 'blue', 'Aon', 'Dri-FIT'),
  ('611031-624', 'Nike', 'Manchester United', '2014/15', 'Home', 'replica', 'red', 'Chevrolet', 'Dri-FIT'),
  ('611032-106', 'Nike', 'Manchester United', '2014/15', 'Away', 'replica', 'white', 'Chevrolet', 'Dri-FIT'),
  ('575280-703', 'Nike', 'Manchester United', '2014/15', 'Away', 'authentic', 'white', 'Chevrolet', 'Dri-FIT')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- Product Codes: Manchester United Adidas Era
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, sponsor, technology, label_position_era) VALUES
  ('AC1414', 'Adidas', 'Manchester United', '2015/16', 'Home', 'replica', 'replica', 'red', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('AI6720', 'Adidas', 'Manchester United', '2015/16', 'Away', 'replica', 'replica', 'white', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('AI6690', 'Adidas', 'Manchester United', '2015/16', 'Third', 'replica', 'replica', 'blue', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('BS1214', 'Adidas', 'Manchester United', '2017/18', 'Home', 'replica', 'replica', 'red', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('AZ7564', 'Adidas', 'Manchester United', '2017/18', 'Away', 'replica', 'replica', 'black', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('AZ7565', 'Adidas', 'Manchester United', '2017/18', 'Third', 'replica', 'replica', 'grey', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('CG0040', 'Adidas', 'Manchester United', '2018/19', 'Home', 'replica', 'replica', 'red', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('DW4539', 'Adidas', 'Manchester United', '2019/20', 'Home', 'replica', 'replica', 'red', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('ED7386', 'Adidas', 'Manchester United', '2019/20', 'Home', 'replica', 'replica', 'red', 'Chevrolet', 'ClimaCool', 'hip_tag'),
  ('ED7390', 'Adidas', 'Manchester United', '2019/20', 'Third', 'replica', 'replica', 'black', 'Chevrolet', 'Climalite', 'hip_tag'),
  ('GC7958', 'Adidas', 'Manchester United', '2020/21', 'Home', 'replica', 'replica', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('GC7957', 'Adidas', 'Manchester United', '2020/21', 'Home', 'authentic', 'authentic', 'red', 'TeamViewer', 'HEAT.RDY', 'neck_tag'),
  ('EE2377', 'Adidas', 'Manchester United', '2020/21', 'Away', 'authentic', 'authentic', 'green', 'TeamViewer', 'HEAT.RDY', 'neck_tag'),
  ('GM4621', 'Adidas', 'Manchester United', '2021/22', 'Home', 'replica', 'replica', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('GM4622', 'Adidas', 'Manchester United', '2021/22', 'Away', 'authentic', 'authentic', 'white', 'TeamViewer', 'HEAT.RDY', 'neck_tag'),
  ('H13881', 'Adidas', 'Manchester United', '2022/23', 'Home', 'replica', 'replica', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('IP1726', 'Adidas', 'Manchester United', '2023/24', 'Home', 'replica', 'replica', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('IP1728', 'Adidas', 'Manchester United', '2023/24', 'Home', 'authentic', 'authentic', 'red', 'TeamViewer', 'HEAT.RDY', 'neck_tag'),
  ('HR3675', 'Adidas', 'Manchester United', '2023/24', 'Away', 'replica', 'replica', 'green', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('IU1397', 'Adidas', 'Manchester United', '2024/25', 'Home', 'replica', 'replica', 'red', 'Snapdragon', 'AEROREADY', 'neck_tag'),
  ('JF1291', 'Adidas', 'Manchester United', '2024/25', 'Home', 'authentic', 'authentic', 'red', 'Snapdragon', 'HEAT.RDY', 'neck_tag'),
  ('IU1390', 'Adidas', 'Manchester United', '2024/25', 'Away', 'replica', 'replica', 'navy_blue', 'Snapdragon', 'AEROREADY', 'neck_tag'),
  ('IU1391', 'Adidas', 'Manchester United', '2024/25', 'Away', 'authentic', 'authentic', 'navy_blue', 'Snapdragon', 'HEAT.RDY', 'neck_tag')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- Training/Pre-Match Kits
-- ============================================
INSERT INTO product_codes (code, brand, team, season, kit_type, variant, tier, primary_color, sponsor, technology, label_position_era) VALUES
  ('FH8550', 'Adidas', 'Manchester United', '2020/21', 'Pre-Match', 'training', 'training', 'multi', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('GR3914', 'Adidas', 'Manchester United', '2021/22', 'Pre-Match', 'training', 'training', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('H56682', 'Adidas', 'Manchester United', '2022/23', 'Pre-Match', 'training', 'training', 'white', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('IA7242', 'Adidas', 'Manchester United', '2023/24', 'Pre-Match', 'training', 'training', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag'),
  ('IA8494', 'Adidas', 'Manchester United', '2023/24', 'Training', 'training', 'training', 'red', 'TeamViewer', 'AEROREADY', 'neck_tag')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- Valuation Tiers
-- ============================================
INSERT INTO valuation_tiers (tier_code, tier_name, category, example_description, condition_notes, price_min_gbp, price_max_gbp, price_min_usd, price_max_usd) VALUES
  ('A+', 'Rare Vintage', 'Vintage Original (Nadir)', '1992-1994 Newton Heath, Cantona signed', 'Excellent/Mint', 150, 300, 190, 380),
  ('A', 'Vintage Original', 'Classic Era', '1994-1999 Beckham, Treble season', 'Good/Very Good', 80, 150, 100, 190),
  ('B', 'Modern Authentic', 'Player/Match Spec', '2015-2024 HEAT.RDY, Player Issue', 'BNWT (Brand New With Tags)', 70, 110, 90, 140),
  ('B-', 'Modern Authentic Used', 'Player Spec 2nd Hand', '2015-2020 Adizero/Climachill', 'Used/Good', 40, 70, 50, 90),
  ('C', 'Modern Replica', 'Stadium/Fan Edition', '2015-Present AEROREADY', 'BNWT/Good', 30, 50, 40, 65),
  ('D', 'Counterfeit', 'Fake', 'Any era known fake', 'Any', 0, 15, 0, 20)
ON CONFLICT (tier_code) DO NOTHING;

-- ============================================
-- Size Format Eras
-- ============================================
INSERT INTO size_format_eras (format_type, start_year, end_year, example, notes) VALUES
  ('single_letter', 1992, 2010, 'L, M, S, XL', 'Pre-2010: Single letter sizing only'),
  ('dual_notation', 2010, NULL, 'L/G, M/M, S/P, XL/TG', 'Post-2010: English/French dual notation')
ON CONFLICT DO NOTHING;

-- ============================================
-- Manufacturing Origin Eras
-- ============================================
INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2009, 'Morocco', 'primary', 'Primary origin for Vodafone/AIG era replicas', 0.95
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2010, 2015, 'Indonesia', 'primary', 'Aon/Chevrolet era mass production', 0.90
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2002, 2010, 'China', 'suspicious', 'Early era China = likely fake', 0.30
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, 2019, 'Cambodia', 'primary', 'Primary origin for 2015-2019 replicas', 0.95
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, NULL, 'Vietnam', 'primary', 'Major Adidas production hub', 0.90
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO manufacturing_origin_eras (manufacturer_id, start_year, end_year, country, origin_type, notes, confidence)
SELECT m.id, 2015, 2019, 'China', 'suspicious', 'Adidas era China = likely fake', 0.25
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- ============================================
-- Technology Tier Mapping
-- ============================================
INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'AEROREADY', 'replica', 2019, NULL, 'Modern replica. NEVER on match shirts.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'HEAT.RDY', 'authentic', 2019, NULL, 'Modern authentic for match shirts.'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO technology_tier_mapping (manufacturer_id, technology, tier, start_year, end_year, notes)
SELECT m.id, 'Dri-FIT', 'replica', 2002, 2015, 'Standard Nike replica'
FROM manufacturers m WHERE m.name = 'Nike'
ON CONFLICT DO NOTHING;

-- ============================================
-- Sustainability Labels
-- ============================================
INSERT INTO sustainability_label_eras (manufacturer_id, label_name, start_year, end_year, is_mandatory, notes)
SELECT m.id, 'Primegreen', 2020, NULL, true, 'Missing on 2020+ = FAKE'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

INSERT INTO sustainability_label_eras (manufacturer_id, label_name, start_year, end_year, is_mandatory, notes)
SELECT m.id, 'End Plastic Waste', 2021, NULL, true, 'Three-loop logo required'
FROM manufacturers m WHERE m.name = 'Adidas'
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED DATA COMPLETE
-- ============================================
SELECT 'Part 2 Complete - Seed Data Loaded' as status;
SELECT 'Total Product Codes' as metric, COUNT(*) as count FROM product_codes;
SELECT 'Total Blacklist Codes' as metric, COUNT(*) as count FROM blacklist_codes;
