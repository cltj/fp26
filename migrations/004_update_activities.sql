-- Migration 004: Update activities table
-- Updates activity names and display order for the redesigned home page

-- First, ensure we have the correct activities with proper names
-- The order is: 1. quiz, 2. fotball, 3. fc26, 4. orakel

-- Update existing activities or insert if not present
-- We use UPSERT-like behavior with ON CONFLICT

-- Delete old activity names that are being renamed
DELETE FROM activities WHERE activity_name IN ('ballbinge', 'ressurser', 'analyse');

-- Update or insert the 4 main activities with correct display order
INSERT INTO activities (activity_name, is_active, display_order)
VALUES 
  ('quiz', false, 1),
  ('fotball', false, 2),
  ('fc26', false, 3),
  ('orakel', false, 4)
ON CONFLICT (activity_name) 
DO UPDATE SET display_order = EXCLUDED.display_order;

-- Verify the activities
SELECT * FROM activities ORDER BY display_order;
