-- ============================================
-- FP26 Database Redesign Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Create new activities table
-- ============================================
DROP TABLE IF EXISTS activities_new CASCADE;

CREATE TABLE activities_new (
  id SERIAL PRIMARY KEY,
  activity_name TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT FALSE,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert activities (excluding ressurser)
INSERT INTO activities_new (activity_name, is_active, display_order) VALUES
  ('quiz', true, 1),
  ('fotball', true, 2),
  ('orakel', true, 3),
  ('fc26', true, 4);

-- ============================================
-- STEP 2: Create exercises table for fotball
-- ============================================
DROP TABLE IF EXISTS exercises CASCADE;

CREATE TABLE exercises (
  id SERIAL PRIMARY KEY,
  activity_id INTEGER REFERENCES activities_new(id),
  exercise_code TEXT NOT NULL,  -- e1, e2a, e2b, e3, e4
  name TEXT NOT NULL,
  description TEXT,
  max_attempts INTEGER DEFAULT 3,
  scoring_type TEXT DEFAULT 'highest', -- 'highest' or 'lowest'
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert exercises (will need activity_id after activities_new is populated)
INSERT INTO exercises (activity_id, exercise_code, name, description, display_order)
SELECT 
  (SELECT id FROM activities_new WHERE activity_name = 'fotball'),
  code,
  name,
  description,
  ord
FROM (VALUES
  ('e1', 'Øvelse 1', 'Første øvelse', 1),
  ('e2a', 'Øvelse 2A', 'Andre øvelse del A', 2),
  ('e2b', 'Øvelse 2B', 'Andre øvelse del B', 3),
  ('e3', 'Øvelse 3', 'Tredje øvelse', 4),
  ('e4', 'Øvelse 4', 'Fjerde øvelse', 5)
) AS t(code, name, description, ord);

-- ============================================
-- STEP 3: Rename quiz_answers to activity_quiz
-- ============================================
ALTER TABLE IF EXISTS quiz_answers RENAME TO activity_quiz;

-- Add activity_id column
ALTER TABLE activity_quiz 
  ADD COLUMN IF NOT EXISTS activity_id INTEGER;

-- Set activity_id for all existing rows
UPDATE activity_quiz 
SET activity_id = (SELECT id FROM activities_new WHERE activity_name = 'quiz');

-- Add foreign key constraint
ALTER TABLE activity_quiz 
  ADD CONSTRAINT fk_activity_quiz_activity 
  FOREIGN KEY (activity_id) REFERENCES activities_new(id);

-- ============================================
-- STEP 4: Rename ballbinge_scores to activity_fotball
-- ============================================
ALTER TABLE IF EXISTS ballbinge_scores RENAME TO activity_fotball;

-- Add columns
ALTER TABLE activity_fotball 
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS activity_id INTEGER,
  ADD COLUMN IF NOT EXISTS exercise_id INTEGER,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Update activity_id
UPDATE activity_fotball 
SET activity_id = (SELECT id FROM activities_new WHERE activity_name = 'fotball');

-- Update exercise_id based on exercise code
UPDATE activity_fotball af
SET exercise_id = e.id
FROM exercises e
WHERE af.exercise = e.exercise_code;

-- Add foreign keys
ALTER TABLE activity_fotball 
  ADD CONSTRAINT fk_activity_fotball_activity 
  FOREIGN KEY (activity_id) REFERENCES activities_new(id);

ALTER TABLE activity_fotball 
  ADD CONSTRAINT fk_activity_fotball_exercise 
  FOREIGN KEY (exercise_id) REFERENCES exercises(id);

-- ============================================
-- STEP 5: Rename fc26_matches to activity_fc26
-- ============================================
ALTER TABLE IF EXISTS fc26_matches RENAME TO activity_fc26;

-- Add activity_id column
ALTER TABLE activity_fc26 
  ADD COLUMN IF NOT EXISTS activity_id INTEGER;

-- Set activity_id
UPDATE activity_fc26 
SET activity_id = (SELECT id FROM activities_new WHERE activity_name = 'fc26');

-- Add foreign key
ALTER TABLE activity_fc26 
  ADD CONSTRAINT fk_activity_fc26_activity 
  FOREIGN KEY (activity_id) REFERENCES activities_new(id);

-- ============================================
-- STEP 6: Create matchups table for predictions
-- ============================================
DROP TABLE IF EXISTS matchups CASCADE;

CREATE TABLE matchups (
  id SERIAL PRIMARY KEY,
  match_name TEXT NOT NULL,
  home_team TEXT NOT NULL,
  away_team TEXT NOT NULL,
  match_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert the Norge vs Frankrike match
INSERT INTO matchups (match_name, home_team, away_team) VALUES
  ('Norge vs Frankrike', 'Norge', 'Frankrike');

-- ============================================
-- STEP 7: Create new activity_predictions table
-- ============================================
DROP TABLE IF EXISTS activity_predictions CASCADE;

CREATE TABLE activity_predictions (
  id SERIAL PRIMARY KEY,
  activity_id INTEGER REFERENCES activities_new(id),
  participant_id INTEGER REFERENCES participants(id),
  team_id INTEGER REFERENCES teams(id),
  matchup_id INTEGER REFERENCES matchups(id),
  home_goals INTEGER,
  away_goals INTEGER,
  first_goal TEXT,  -- 'home', 'away', 'ingen'
  yellow_cards TEXT, -- 'home', 'away', 'likt'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrate data from predictions table
INSERT INTO activity_predictions (
  activity_id, participant_id, team_id, matchup_id,
  home_goals, away_goals, first_goal, yellow_cards, created_at
)
SELECT 
  (SELECT id FROM activities_new WHERE activity_name = 'orakel'),
  participant_id,
  team_id,
  (SELECT id FROM matchups WHERE match_name = 'Norge vs Frankrike'),
  score_norge,
  score_frankrike,
  CASE 
    WHEN first_goal = 'norge' THEN 'home'
    WHEN first_goal = 'frankrike' THEN 'away'
    ELSE first_goal
  END,
  CASE 
    WHEN yellow_cards = 'norge' THEN 'home'
    WHEN yellow_cards = 'frankrike' THEN 'away'
    ELSE yellow_cards
  END,
  created_at
FROM predictions;

-- ============================================
-- STEP 8: Create activity_scores table
-- ============================================
DROP TABLE IF EXISTS activity_scores CASCADE;

CREATE TABLE activity_scores (
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

-- Migrate from scores table
INSERT INTO activity_scores (team_id, fotball_points, fc26_points)
SELECT 
  team_id,
  COALESCE(scores[2], 0),
  COALESCE(scores[4], 0)
FROM scores
ON CONFLICT (team_id) DO UPDATE SET
  fotball_points = EXCLUDED.fotball_points,
  fc26_points = EXCLUDED.fc26_points;

-- ============================================
-- STEP 9: Update resources table
-- ============================================
ALTER TABLE resources 
  ADD COLUMN IF NOT EXISTS team_ids INTEGER[] DEFAULT '{}';

-- ============================================
-- STEP 10: Drop old tables (CAREFUL!)
-- ============================================
-- Uncomment these after verifying migration worked:
-- DROP TABLE IF EXISTS activities CASCADE;
-- DROP TABLE IF EXISTS predictions CASCADE;
-- DROP TABLE IF EXISTS scores CASCADE;

-- ============================================
-- STEP 11: Rename activities_new to activities
-- ============================================
-- Uncomment after dropping old activities:
-- ALTER TABLE activities_new RENAME TO activities;

-- ============================================
-- STEP 12: Enable RLS and policies
-- ============================================
ALTER TABLE activities_new ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchups ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_scores ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read" ON activities_new FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON exercises FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON matchups FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON activity_predictions FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON activity_scores FOR SELECT USING (true);

-- Allow public insert/update for activities (for admin)
CREATE POLICY "Allow public insert" ON activities_new FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update" ON activities_new FOR UPDATE USING (true);
CREATE POLICY "Allow public insert" ON activity_predictions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update" ON activity_predictions FOR UPDATE USING (true);
CREATE POLICY "Allow public insert" ON activity_scores FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update" ON activity_scores FOR UPDATE USING (true);

-- ============================================
-- Summary of changes:
-- ============================================
-- activities_new: id, activity_name, is_active, display_order
-- exercises: id, activity_id, exercise_code, name, description, max_attempts, scoring_type
-- activity_quiz: (renamed from quiz_answers) + activity_id
-- activity_fotball: (renamed from ballbinge_scores) + activity_id, exercise_id
-- activity_fc26: (renamed from fc26_matches) + activity_id
-- matchups: id, match_name, home_team, away_team
-- activity_predictions: new table with generic home/away structure
-- activity_scores: team_id, quiz_points, fotball_points, orakel_points, fc26_points, total_points
-- resources: + team_ids (integer array)
