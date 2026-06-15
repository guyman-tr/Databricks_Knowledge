-- 5A. Top Users by View Count (Last 30 Days)
SELECT 
    su.friendly_name AS user_name,
    su.email AS user_email,
    sr.display_name as site_role,
    --lr.name AS license_type,
    s.name AS site_name,
    COUNT(DISTINCT he.id) AS total_events,
    COUNT(DISTINCT CASE WHEN het.action_type = 'Access' THEN he.id END) AS view_count,
    COUNT(DISTINCT CASE WHEN het.action_type = 'Publish' THEN he.id END) AS publish_count,
    MAX(he.created_at) AS last_activity
FROM public.historical_events he
JOIN public.historical_event_types het ON he.historical_event_type_id = het.type_id
JOIN public.hist_users hu ON he.hist_actor_user_id = hu.id
JOIN public.users u ON hu.user_id = u.id
JOIN public.system_users su ON u.system_user_id = su.id
JOIN public.sites s ON u.site_id = s.id
JOIN public.site_roles as sr ON u.site_role_id = sr.id
--LEFT JOIN public.licensing_roles lr ON u.licensing_role_id = lr.id
WHERE he.created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND su.friendly_name IS NOT NULL
GROUP BY 
    su.friendly_name,
    su.email,
    sr.display_name,
    --lr.name,
    s.name
ORDER BY view_count DESC