-- 5B. User Login Activity
SELECT 
    su.friendly_name AS user_name,
    su.email,
    s.name AS site_name,
    COUNT(*) AS login_count,
    MIN(he.created_at) AS first_login,
    MAX(he.created_at) AS last_login,
    COUNT(DISTINCT DATE_TRUNC('day', he.created_at)) AS active_days
FROM public.historical_events he
JOIN public.historical_event_types het ON he.historical_event_type_id = het.type_id
JOIN public.hist_users hu ON he.hist_actor_user_id = hu.id
JOIN public.users u ON hu.user_id = u.id
JOIN public.system_users su ON u.system_user_id = su.id
JOIN public.sites s ON u.site_id = s.id
WHERE het.name = 'Login'
    AND he.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY su.friendly_name, su.email, s.name
ORDER BY login_count DESC