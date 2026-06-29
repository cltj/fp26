-- Migration 008: Remove activity_scores table (now calculated on-the-fly)
-- 
-- Scores are now calculated dynamically from:
-- - activity_fotball (fotball points)
-- - activity_predictions (orakel points) 
-- - activity_fc26 (fc26 placement points)
--
-- This eliminates sync issues and ensures scores are always accurate.

DROP TABLE IF EXISTS activity_scores;

-- Also clean up unused columns in activity_fotball
-- (activity_id and exercise_id pointed to deleted tables)
ALTER TABLE activity_fotball DROP COLUMN IF EXISTS activity_id;
ALTER TABLE activity_fotball DROP COLUMN IF EXISTS exercise_id;
