-- Sessions from the last 14 days
SELECT 
    hr.session_id,
    hr.action, 
    hr.created_at, 
    hr.completed_at,
    su.name as session_username,
    v.name as view_name, 
    v.id as view_id, 
    v.owner_name, 
    w.id as workbook_id, 
    w.name as workbook_name, 
    w.project_name, 
    w.size / (1024^2) as workbook_size_mb, -- Using 1024 is more standard for MB
    EXTRACT(EPOCH FROM (hr.completed_at - hr.created_at)) as session_duration_seconds
FROM public._http_requests as hr
LEFT JOIN public._system_users as su on hr.user_id = su.id
LEFT JOIN public._views as v ON hr.currentsheet = v.view_url
JOIN public._workbooks as w ON v.workbook_id = w.id
WHERE hr.created_at >= (CURRENT_DATE - INTERVAL '14 day')