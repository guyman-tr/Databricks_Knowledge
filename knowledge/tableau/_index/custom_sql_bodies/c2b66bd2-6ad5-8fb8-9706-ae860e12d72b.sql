SELECT
    u.id                        AS user_id,
    COALESCE (
        COUNT(h.id) ,
        0
    )                           AS web_edit_events
FROM users u
    LEFT JOIN http_requests h
        ON u.id = h.user_id
            AND h.controller LIKE '%author%'
WHERE NOT EXISTS (
    SELECT 1 
    FROM historical_event_types
    WHERE type_id = 87
    )
GROUP BY
    u.id
UNION ALL
SELECT
    u.id                        AS user_id,
    CAST(NULL AS INT)           AS web_edit_events
FROM users u
WHERE EXISTS (
    SELECT 1 
    FROM historical_event_types
    WHERE type_id = 87
    )