-- 6A. Most Viewed Workbooks (Last 30 Days)
SELECT 
    hw.name AS workbook_name,
    hp.name AS project_name,
    su.friendly_name,
    hs.name AS site_name,
    COUNT(*) AS view_count,
    COUNT(DISTINCT he.hist_actor_user_id) AS unique_viewers,
    MAX(he.created_at) AS last_viewed
FROM public.historical_events he
JOIN public.historical_event_types het ON he.historical_event_type_id = het.type_id
JOIN public.hist_workbooks hw ON he.hist_workbook_id = hw.id
JOIN public.workbooks as wb ON hw.workbook_id = wb.id
JOIN public.system_users as su ON wb.owner_id = su.id
LEFT JOIN public.hist_projects hp ON he.hist_project_id = hp.id
LEFT JOIN public.hist_sites hs ON he.hist_target_site_id = hs.id
WHERE het.name IN ('Access View')
    AND he.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY hw.name, hp.name, su.friendly_name, hs.name
ORDER BY view_count DESC