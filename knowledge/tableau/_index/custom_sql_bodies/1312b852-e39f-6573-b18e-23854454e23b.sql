SELECT
    u.id                AS user_id,
    COALESCE (
        COUNT(h.id) ,
        0
    )                   AS web_edit_events
FROM users u
    LEFT JOIN http_requests h
        ON u.id = h.user_id
            AND h.controller LIKE '%author%'
GROUP BY
    u.id