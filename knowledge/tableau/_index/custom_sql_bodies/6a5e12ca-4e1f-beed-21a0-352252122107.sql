-- 12B. Long Running Jobs (Currently Running + Completed in Last 30 Days)
SELECT 
    bj.id AS job_id,
    bj.job_name,
    bj.started_at,
    bj.completed_at,
    ROUND(EXTRACT(EPOCH FROM (COALESCE(bj.completed_at, NOW()) - bj.started_at)) / 60, 1) AS duration_minutes,
    CASE bj.finish_code
        WHEN 0 THEN 'Success'
        WHEN 1 THEN 'Failure'
        WHEN 2 THEN 'Cancelled'
        ELSE 'Running'
    END AS status,
    s.name AS site_name,
    bj.notes
FROM public.background_jobs bj
LEFT JOIN public.sites s ON bj.site_id = s.id
WHERE bj.started_at IS NOT NULL 
    AND EXTRACT(EPOCH FROM (COALESCE(bj.completed_at, NOW()) - bj.started_at)) > 900  -- Duration more than 30 minutes
    AND (bj.completed_at IS NULL OR bj.completed_at > NOW() - INTERVAL '30 days')  -- Currently running OR completed in last 30 days
ORDER BY bj.completed_at DESC