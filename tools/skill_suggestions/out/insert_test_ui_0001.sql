INSERT INTO main.de_output.de_output_skills_automation_user_suggestions_agent (
  id,
  submitted_at,
  submitter,
  request_type,
  target_skill,
  title,
  body_text,
  volume_path,
  status,
  pr_url,
  processed_at,
  agent_notes
)
VALUES (
  'test-ui-0001',
  current_timestamp(),
  'guyman',
  'new_skill',
  NULL,
  'UI submission test row',
  'Anchored skill submission from deployed app path test.',
  '/Volumes/main/de_output/skills_automation_user_suggestions_agent_files/test-ui-0001/',
  'new',
  NULL,
  NULL,
  NULL
);
