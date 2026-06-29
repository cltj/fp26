-- Add support for multiple winners per quiz question
-- Run this migration in Supabase SQL Editor

-- Add winner_team_ids column as JSONB array
ALTER TABLE activity_quiz 
ADD COLUMN IF NOT EXISTS winner_team_ids JSONB DEFAULT '[]'::jsonb;

-- Migrate existing winner_team_id data to winner_team_ids array
UPDATE activity_quiz 
SET winner_team_ids = CASE 
  WHEN winner_team_id IS NOT NULL THEN jsonb_build_array(winner_team_id)
  ELSE '[]'::jsonb
END
WHERE winner_team_ids IS NULL OR winner_team_ids = '[]'::jsonb;
