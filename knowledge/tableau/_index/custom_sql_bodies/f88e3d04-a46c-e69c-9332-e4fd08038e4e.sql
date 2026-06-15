SELECT
    t.obj_id                         AS task_object_id,
    t.id                             AS task_id,
    bj.id                            AS job_id,
    bj.job_name,
    
    -- Timestamps
    bj.created_at                    AS job_queued_at,
    bj.started_at                    AS job_started_at,
    bj.completed_at                  AS job_completed_at,
    
    -- Performance Metrics
    ROUND(EXTRACT(EPOCH FROM (bj.started_at - bj.created_at)), 0) AS queue_wait_seconds,
    ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)), 0) AS run_duration_seconds,

    -- Status Logic
    bj.finish_code,
    CASE bj.finish_code
        WHEN 0 THEN 'Success'
        WHEN 1 THEN 'Failed'
        WHEN 2 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS finish_code_str,

    -- Failure Reason Fix: Only show notes if the job actually failed
    CASE 
        WHEN bj.finish_code = 1 THEN bj.notes 
        ELSE NULL 
    END AS failure_reason

FROM public.tasks t
inner JOIN public.background_jobs bj ON t.id = bj.task_id
WHERE bj.job_name IN ('Refresh Extracts', 'Increment Extracts', 'Create Extracts')