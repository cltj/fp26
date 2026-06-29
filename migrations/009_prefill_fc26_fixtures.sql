-- Migration: Pre-fill FC26 fixtures
-- This sets up the 6 round-robin matches for 4 teams
-- Teams are referenced by home_team_id and away_team_id

-- Clear existing FC26 data
DELETE FROM activity_fc26;

-- Insert the 6 matches (4 teams = 6 matches in round-robin)
-- The team_ids will be filled based on active teams
-- Match order: 1v2, 1v3, 1v4, 2v3, 2v4, 3v4

-- Get active team IDs ordered by id
WITH active_teams AS (
  SELECT id, team_name, ROW_NUMBER() OVER (ORDER BY id) as pos
  FROM teams
  WHERE is_active = true
  LIMIT 4
),
fixtures AS (
  SELECT 
    1 as match_num, 
    (SELECT id FROM active_teams WHERE pos = 1) as home_team_id,
    (SELECT id FROM active_teams WHERE pos = 2) as away_team_id
  UNION ALL
  SELECT 2, 
    (SELECT id FROM active_teams WHERE pos = 1),
    (SELECT id FROM active_teams WHERE pos = 3)
  UNION ALL
  SELECT 3, 
    (SELECT id FROM active_teams WHERE pos = 1),
    (SELECT id FROM active_teams WHERE pos = 4)
  UNION ALL
  SELECT 4, 
    (SELECT id FROM active_teams WHERE pos = 2),
    (SELECT id FROM active_teams WHERE pos = 3)
  UNION ALL
  SELECT 5, 
    (SELECT id FROM active_teams WHERE pos = 2),
    (SELECT id FROM active_teams WHERE pos = 4)
  UNION ALL
  SELECT 6, 
    (SELECT id FROM active_teams WHERE pos = 3),
    (SELECT id FROM active_teams WHERE pos = 4)
)
INSERT INTO activity_fc26 (match_num, home_team_id, away_team_id, home_score, away_score)
SELECT match_num, home_team_id, away_team_id, NULL, NULL
FROM fixtures
WHERE home_team_id IS NOT NULL AND away_team_id IS NOT NULL;
