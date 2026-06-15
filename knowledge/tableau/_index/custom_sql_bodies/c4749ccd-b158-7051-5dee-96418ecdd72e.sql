SELECT 
    he.created_at AS event_time,
    het.name AS event_type,
    hs.name AS site_name,
    hu.name AS user_name,
    su.friendly_name as FriendlyName,
    COALESCE(hw.name, hds.name, hv.name) AS content_name,
    CASE 
        WHEN hw.id IS NOT NULL THEN 'Workbook'
        WHEN hds.id IS NOT NULL THEN 'Datasource'
        WHEN hv.id IS NOT NULL THEN 'View'
        ELSE 'Other'
    END AS content_type
FROM public.historical_events he
JOIN public.historical_event_types het ON he.historical_event_type_id = het.type_id
LEFT JOIN public.hist_sites hs ON he.hist_target_site_id = hs.id
LEFT JOIN public.hist_users hu ON he.hist_actor_user_id = hu.id
JOIN public.system_users su ON hu.email = su.email
LEFT JOIN public.hist_workbooks hw ON he.hist_workbook_id = hw.id
LEFT JOIN public.hist_datasources hds ON he.hist_datasource_id = hds.id
LEFT JOIN public.hist_views hv ON he.hist_view_id = hv.id
WHERE he.created_at >= NOW() - INTERVAL '30 days'
ORDER BY he.created_at DESC