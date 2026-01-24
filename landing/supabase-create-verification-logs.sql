-- KitTicker: Create verification_logs table
-- Run this in Supabase SQL Editor

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

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_verification_logs_code ON verification_logs(code);
CREATE INDEX IF NOT EXISTS idx_verification_logs_created_at ON verification_logs(created_at);

-- Enable RLS
ALTER TABLE verification_logs ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert logs (anonymous users)
DROP POLICY IF EXISTS "Anyone can insert logs" ON verification_logs;
CREATE POLICY "Anyone can insert logs" ON verification_logs
  FOR INSERT WITH CHECK (true);

-- Allow anyone to read logs (for analytics)
DROP POLICY IF EXISTS "Anyone can read logs" ON verification_logs;
CREATE POLICY "Anyone can read logs" ON verification_logs
  FOR SELECT USING (true);

SELECT 'verification_logs table created successfully' as status;
