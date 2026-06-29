-- ============================================
-- FP26 Database Redesign - SAFE VERSION
-- Run each section separately in Supabase SQL Editor
-- ============================================

-- ============================================
-- PART 1: New tables (safe to run first)
-- ============================================

-- 1A: Create new activities table with numeric ID
CREATE TABLE IF NOT EXISTS activities_v2 (
  id SERIAL PRIMARY KEY,
  activity_name TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT FALSE,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO activities_v2 (activity_name, is_active, display_order) VALUES
  ('quiz', true, 1),
  ('fotball', true, 2),
  ('orakel', true, 3),
  ('fc26', true, 4)
ON CONFLICT (activity_name) DO NOTHING;

-- 1B: Create exercises table
CREATE TABLE IF NOT EXISTS exercises (
  id SERIAL PRIMARY KEY,
  activity_id INTEGER REFERENCES activities_v2(id),
  exercise_code TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  max_attempts INTEGER DEFAULT 3,
  scoring_type TEXT DEFAULT 'highest',
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1C: Create matchups table
CREATE TABLE IF NOT EXISTS matchups (
  id SERIAL PRIMARY KEY,
  match_name TEXT NOT NULL,
  home_team TEXT NOT NULL,
  away_team TEXT NOT NULL,
  match_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1D: Create activity_scores table
CREATE TABLE IF NOT EXISTS activity_scores (
  team_id INTEGER PRIMARY KEY REFERENCES teams(id),
  quiz_points INTEGER DEFAULT 0,
  fotball_points INTEGER DEFAULT 0,
  orakel_points INTEGER DEFAULT 0,
  fc26_points INTEGER DEFAULT 0,
  total_points INTEGER GENERATED ALWAYS AS (
    COALESCE(quiz_points, 0) + 
    COALESCE(fotball_points, 0) + 
    COALESCE(orakel_points, 0) + 
    COALESCE(fc26_points, 0)
  ) STORED,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 2: Populate new tables
-- ============================================

-- 2A: Insert exercises
INSERT INTO exercises (activity_id, exercise_code, name, description, display_order)
SELECT 
  (SELECT id FROM activities_v2 WHERE activity_name = 'fotball'),
  code, name, description, ord
FROM (VALUES
  ('e1', 'Øvelse 1', 'Første øvelse', 1),
  ('e2a', 'Øvelse 2A', 'Andre øvelse del A', 2),
  ('e2b', 'Øvelse 2B', 'Andre øvelse del B', 3),
  ('e3', 'Øvelse 3', 'Tredje øvelse', 4),
  ('e4', 'Øvelse 4', 'Fjerde øvelse', 5)
) AS t(code, name, description, ord)
ON CONFLICT DO NOTHING;

-- 2B: Insert matchup
INSERT INTO matchups (match_name, home_team, away_team) VALUES
  ('Norge vs Frankrike', 'Norge', 'Frankrike')
ON CONFLICT DO NOTHING;

-- 2C: Migrate scores data
INSERT INTO activity_scores (team_id, fotball_points, fc26_points)
SELECT 
  team_id,
  COALESCE((scores->>1)::INTEGER, 0),
  COALESCE((scores->>3)::INTEGER, 0)
FROM scores
ON CONFLICT (team_id) DO UPDATE SET
  fotball_points = EXCLUDED.fotball_points,
  fc26_points = EXCLUDED.fc26_points;

-- ============================================
-- PART 3: Update existing tables
-- ============================================

-- 3A: Add activity_id to quiz_answers
ALTER TABLE quiz_answers 
  ADD COLUMN IF NOT EXISTS activity_id INTEGER;

UPDATE quiz_answers 
SET activity_id = (SELECT id FROM activities_v2 WHERE activity_name = 'quiz')
WHERE activity_id IS NULL;

-- 3B: Add activity_id to fc26_matches
ALTER TABLE fc26_matches 
  ADD COLUMN IF NOT EXISTS activity_id INTEGER;

UPDATE fc26_matches 
SET activity_id = (SELECT id FROM activities_v2 WHERE activity_name = 'fc26')
WHERE activity_id IS NULL;

-- 3C: Add columns to ballbinge_scores
ALTER TABLE ballbinge_scores 
  ADD COLUMN IF NOT EXISTS activity_id INTEGER,
  ADD COLUMN IF NOT EXISTS exercise_id INTEGER;

UPDATE ballbinge_scores 
SET activity_id = (SELECT id FROM activities_v2 WHERE activity_name = 'fotball')
WHERE activity_id IS NULL;

UPDATE ballbinge_scores bs
SET exercise_id = e.id
FROM exercises e
WHERE bs.exercise = e.exercise_code AND bs.exercise_id IS NULL;

-- 3D: Add team_ids array to resources
ALTER TABLE resources 
  ADD COLUMN IF NOT EXISTS team_ids INTEGER[] DEFAULT '{}';

-- ============================================
-- PART 4: Create activity_predictions (new structure)
-- ============================================

CREATE TABLE IF NOT EXISTS activity_predictions (
  id SERIAL PRIMARY KEY,
  activity_id INTEGER REFERENCES activities_v2(id),
  participant_id INTEGER REFERENCES participants(id),
  team_id INTEGER REFERENCES teams(id),
  matchup_id INTEGER REFERENCES matchups(id),
  home_goals INTEGER,
  away_goals INTEGER,
  first_goal TEXT,
  yellow_cards TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrate from predictions
INSERT INTO activity_predictions (
  activity_id, participant_id, team_id, matchup_id,
  home_goals, away_goals, first_goal, yellow_cards, created_at
)
SELECT 
  (SELECT id FROM activities_v2 WHERE activity_name = 'orakel'),
  p.participant_id,
  p.team_id,
  (SELECT id FROM matchups WHERE match_name = 'Norge vs Frankrike'),
  p.score_norge,
  p.score_frankrike,
  CASE 
    WHEN p.first_goal = 'norge' THEN 'home'
    WHEN p.first_goal = 'frankrike' THEN 'away'
    ELSE p.first_goal
  END,
  CASE 
    WHEN p.yellow_cards = 'norge' THEN 'home'
    WHEN p.yellow_cards = 'frankrike' THEN 'away'
    ELSE p.yellow_cards
  END,
  p.created_at
FROM predictions p
WHERE NOT EXISTS (
  SELECT 1 FROM activity_predictions ap 
  WHERE ap.participant_id = p.participant_id
);

-- ============================================
-- PART 5: Enable RLS
-- ============================================

ALTER TABLE activities_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchups ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_activities_v2" ON activities_v2 FOR SELECT USING (true);
CREATE POLICY "public_write_activities_v2" ON activities_v2 FOR ALL USING (true);
CREATE POLICY "public_read_exercises" ON exercises FOR SELECT USING (true);
CREATE POLICY "public_read_matchups" ON matchups FOR SELECT USING (true);
CREATE POLICY "public_all_predictions" ON activity_predictions FOR ALL USING (true);
CREATE POLICY "public_all_scores" ON activity_scores FOR ALL USING (true);

-- ============================================
-- PART 6: Rename tables (run after verifying)
-- ============================================
-- Run these ONLY after verifying all data migrated correctly:

-- ALTER TABLE quiz_answers RENAME TO activity_quiz;
-- ALTER TABLE ballbinge_scores RENAME TO activity_fotball;
-- ALTER TABLE fc26_matches RENAME TO activity_fc26;
-- DROP TABLE activities;
-- ALTER TABLE activities_v2 RENAME TO activities;
-- DROP TABLE predictions;
-- DROP TABLE scores;
