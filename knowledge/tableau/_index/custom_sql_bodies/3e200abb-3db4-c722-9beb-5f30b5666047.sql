SELECT 
    bj.id AS job_id,
    -- Readable job type
    bj.job_name,
    bj.priority,
    bj.created_at,
    bj.started_at,
    bj.completed_at,
    -- Readable status
    CASE 
        WHEN bj.finish_code = 0 THEN 'Success'
        WHEN bj.finish_code = 1 THEN 'Failed'
        WHEN bj.finish_code = 2 THEN 'Cancelled'
        WHEN bj.started_at IS NOT NULL AND bj.completed_at IS NULL THEN 'Running'
        ELSE 'Pending'
    END AS status,
    ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)), 1) AS duration_seconds,
    -- Human readable duration
    CASE 
        WHEN EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)) < 60 
            THEN ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at))) || 's'
        WHEN EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)) < 3600 
            THEN ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)) / 60) || 'm ' ||
                 MOD(ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)))::int, 60) || 's'
        ELSE ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)) / 3600) || 'h ' ||
             MOD(ROUND(EXTRACT(EPOCH FROM (bj.completed_at - bj.started_at)) / 60)::int, 60) || 'm'
    END AS duration_display,
    bj.notes,
    COALESCE(w.name, ds.name, bj.job_name) AS content_name,
    CASE 
        WHEN w.id IS NOT NULL THEN 'Workbook'
        WHEN ds.id IS NOT NULL THEN 'Datasource'
        ELSE 'Unknown'
    END AS content_type,
    p.name AS project_name,
    s.name AS site_name,
    su.friendly_name AS owner_name
FROM public.background_jobs bj
LEFT JOIN public.tasks t ON bj.correlation_id = t.id
LEFT JOIN public.workbooks w ON t.obj_id = w.id AND t.obj_type = 'Workbook'
LEFT JOIN public.datasources ds ON t.obj_id = ds.id AND t.obj_type = 'Datasource'
LEFT JOIN public.projects p ON COALESCE(w.project_id, ds.project_id) = p.id
LEFT JOIN public.sites s ON COALESCE(w.site_id, ds.site_id, bj.site_id) = s.id
LEFT JOIN public.users u ON COALESCE(w.owner_id, ds.owner_id) = u.id
LEFT JOIN public.system_users su ON u.system_user_id = su.id
WHERE bj.job_name IN (
    'Refresh Extracts', 
    'Increment Extracts', 
    'Create Extracts',
    'Create Extracts from Web Authoring'
)
AND bj.created_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY bj.created_at DESC