-- Migration 002: Matchup table redesign
-- Run this in Supabase SQL Editor

-- =============================================
-- PART 1: Drop FK constraint, then table
-- =============================================

-- Drop the foreign key constraint first
ALTER TABLE activity_predictions DROP CONSTRAINT IF EXISTS activity_predictions_matchup_id_fkey;

-- Now we can drop the old table
DROP TABLE IF EXISTS matchups;

-- =============================================
-- PART 2: Create new matchup table
-- =============================================

-- Create new matchup table with two rows (home/away)
CREATE TABLE matchup (
  id SERIAL PRIMARY KEY,
  position TEXT NOT NULL CHECK (position IN ('home', 'away')),
  team_name TEXT NOT NULL,
  team_icon TEXT, -- Flag emoji
  match_kickoff TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(position)
);

-- Enable RLS
ALTER TABLE matchup ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow read access to all" ON matchup
  FOR SELECT USING (true);

CREATE POLICY "Allow admin insert" ON matchup
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow admin update" ON matchup
  FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Allow admin delete" ON matchup
  FOR DELETE USING (true);

-- Insert default data (Norge vs Frankrike)
INSERT INTO matchup (position, team_name, team_icon, match_kickoff)
VALUES 
  ('home', 'Norge', '🇳🇴', '2026-06-29 18:00:00+02'),
  ('away', 'Frankrike', '🇫🇷', '2026-06-29 18:00:00+02');

-- =============================================
-- PART 3: Drop matchup_id from activity_predictions (no longer needed)
-- =============================================

-- The matchup is now always the same (single match), so we don't need matchup_id
ALTER TABLE activity_predictions DROP COLUMN IF EXISTS matchup_id;

-- =============================================
-- PART 4: Verify
-- =============================================
SELECT * FROM matchup;
SELECT column_name FROM information_schema.columns WHERE table_name = 'activity_predictions';
