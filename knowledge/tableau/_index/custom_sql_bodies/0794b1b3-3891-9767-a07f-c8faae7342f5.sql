-- 1A. Extract Refresh Summary (Last 30 Days) - WITH READABLE LABELS
SELECT 
    DATE_TRUNC('day', bj.started_at) AS refresh_date,
    -- Readable job type for UI display
    bj.job_name,
    COUNT(*) AS total_refreshes,
    COUNT(CASE WHEN bj.finish_code = 0 THEN 1 END) AS successful_refreshes,
    COUNT(CASE WHEN bj.finish_code = 1 THEN 1 END) AS failed_refreshes,
    COUNT(CASE WHEN bj.finish_code IS NULL AND bj.started_at IS NOT NULL THEN 1 END) AS running_refreshes,
    COUNT(CASE WHEN bj.started_at IS NULL THEN 1 END) AS pending_refreshes,
    ROUND(
        100.0 * COUNT(CASE WHEN bj.finish_code = 0 THEN 1 END) / NULLIF(COUNT(*), 0), 
        2
    ) AS success_rate_pct,
    ROUND(AVG(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at))), 1) AS avg_duration_seconds
FROM public.background_jobs bj
WHERE bj.job_name IN (
    'Refresh Extracts',
    'Increment Extracts',
    'Create Extracts from Web Authoring'
)
AND bj.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', bj.started_at), bj.job_name
ORDER BY refresh_date DESC