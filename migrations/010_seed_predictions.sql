-- Seed 8 orakel predictions from existing participants
-- First, clear any existing predictions
DELETE FROM activity_predictions;

-- Insert predictions for each participant with varied answers
INSERT INTO activity_predictions (
  activity_id, participant_id, team_id, 
  home_goals, away_goals, first_goal, yellow_cards,
  clean_sheet, haaland_scores, penalty
)
SELECT 
  (SELECT id FROM activities WHERE activity_name = 'orakel'),
  p.id,
  p.team_id,
  CASE (p.id % 8)
    WHEN 0 THEN 2
    WHEN 1 THEN 1
    WHEN 2 THEN 3
    WHEN 3 THEN 0
    WHEN 4 THEN 2
    WHEN 5 THEN 1
    WHEN 6 THEN 3
    WHEN 7 THEN 2
  END as home_goals,
  CASE (p.id % 8)
    WHEN 0 THEN 1
    WHEN 1 THEN 2
    WHEN 2 THEN 1
    WHEN 3 THEN 0
    WHEN 4 THEN 2
    WHEN 5 THEN 1
    WHEN 6 THEN 2
    WHEN 7 THEN 0
  END as away_goals,
  CASE (p.id % 3)
    WHEN 0 THEN 'home'
    WHEN 1 THEN 'away'
    ELSE 'ingen'
  END as first_goal,
  CASE (p.id % 3)
    WHEN 0 THEN 'home'
    WHEN 1 THEN 'away'
    ELSE 'likt'
  END as yellow_cards,
  CASE (p.id % 2)
    WHEN 0 THEN 'ja'
    ELSE 'nei'
  END as clean_sheet,
  CASE (p.id % 2)
    WHEN 0 THEN 'nei'
    ELSE 'ja'
  END as haaland_scores,
  CASE (p.id % 3)
    WHEN 0 THEN 'ja'
    ELSE 'nei'
  END as penalty
FROM participants p
WHERE p.team_id IS NOT NULL;

-- Show what was inserted
SELECT 
  p.participant,
  t.team_name,
  ap.home_goals,
  ap.away_goals,
  ap.first_goal,
  ap.yellow_cards,
  ap.clean_sheet,
  ap.haaland_scores,
  ap.penalty
FROM activity_predictions ap
JOIN participants p ON ap.participant_id = p.id
JOIN teams t ON ap.team_id = t.id
ORDER BY p.id;
