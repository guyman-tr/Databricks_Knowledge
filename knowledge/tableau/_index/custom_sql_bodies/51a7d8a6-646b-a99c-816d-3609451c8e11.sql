-- Cuncurrent Session Summary
WITH hourly_sessions AS (
    SELECT 
        DATE_TRUNC('hour', created_at) AS hour,
        action,
        COUNT(DISTINCT session_id) AS concurrent_sessions,
        COUNT(DISTINCT user_id) AS concurrent_users
    FROM public.http_requests
    WHERE created_at >= NOW() - INTERVAL '7 days'
        AND session_id IS NOT NULL
        AND user_id IS NOT NULL
        --AND action = 'sessions'
    GROUP BY DATE_TRUNC('hour', created_at), action
    ORDER BY hour
)
SELECT 
    hour,
    action,
    concurrent_sessions,
    concurrent_users
FROM hourly_sessions