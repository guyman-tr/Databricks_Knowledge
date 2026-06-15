SELECT
    bj.id                           AS job_id,
    s.name                          AS site_name,
    bj.job_name,
    bj.title                        AS content_name,
    bj.subtitle                     AS detail,
 
    -- Job lifecycle timestamps
    bj.created_at                   AS job_queued_at,
    bj.started_at                   AS job_started_at,
    bj.completed_at                 AS job_completed_at,
 
    -- Queue wait time (seconds)
    ROUND(
        EXTRACT(EPOCH FROM (bj.started_at - bj.created_at))
    , 0)                            AS queue_wait_seconds,
 
    -- Execution duration (seconds)
    ROUND(
        EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at))
    , 0)                            AS run_duration_seconds,
 
    -- Finish code (raw)
    bj.finish_code,
 
    -- Finish code (string representation)
    CASE bj.finish_code
        WHEN 0 THEN 'Success'
        WHEN 1 THEN 'Failed'
        WHEN 2 THEN 'Cancelled'
        ELSE 'Unknown (' || bj.finish_code::text || ')'
    END                             AS finish_code_str,
 
    -- Failure reason (populated when finish_code = 1)
    CASE
        WHEN bj.finish_code = 1 THEN bj.notes
        ELSE NULL
    END                             AS failure_reason,
 
    bj.progress
 
FROM public.background_jobs bj
 
LEFT JOIN public.sites s
    ON s.id = bj.site_id
 
WHERE bj.job_name IN (
    'Refresh Extracts',
    'Increment Extracts',
    'Create Extracts'
)