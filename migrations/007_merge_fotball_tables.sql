-- Migration 007: Merge activity_fotball_placements into activity_fotball
-- This consolidates two tables that stored the same data into one

-- Step 1: Add placement column to activity_fotball
ALTER TABLE activity_fotball 
  ADD COLUMN IF NOT EXISTS placement INTEGER;

-- Step 2: Migrate existing placement data from activity_fotball_placements
-- The old table used exercise without 'e' prefix (1, 2a, 2b, 3, 4)
-- The activity_fotball table uses 'e' prefix (e1, e2a, e2b, e3, e4)
UPDATE activity_fotball af
SET placement = p.placement
FROM activity_fotball_placements p
WHERE af.team_id = p.team_id 
  AND af.exercise = 'e' || p.exercise;

-- Step 3: Drop the redundant table
DROP TABLE IF EXISTS activity_fotball_placements;

-- Verify the result
SELECT * FROM activity_fotball ORDER BY exercise, placement;
