-- Migration 008: Redesign activity_fotball table
-- New schema: id, team_id, activity_id, exercise_id, exercise_name, points

-- Step 1: Drop the old table
DROP TABLE IF EXISTS activity_fotball;

-- Step 2: Create new table with proper schema
CREATE TABLE activity_fotball (
  id SERIAL PRIMARY KEY,
  team_id INTEGER NOT NULL REFERENCES teams(id),
  activity_id INTEGER REFERENCES activities(id),
  exercise_id INTEGER NOT NULL,  -- 1, 2, 3, 4, 5
  exercise_name TEXT NOT NULL, -- 'Tverrlegger', 'Presisjon Runde 1', etc.
  points INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Create index for faster lookups
CREATE INDEX idx_activity_fotball_team ON activity_fotball(team_id);
CREATE INDEX idx_activity_fotball_exercise ON activity_fotball(exercise_id);

-- Step 4: Enable RLS
ALTER TABLE activity_fotball ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policies for public access
CREATE POLICY "Enable read access for all users" ON activity_fotball
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON activity_fotball
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON activity_fotball
  FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all users" ON activity_fotball
  FOR DELETE USING (true);
