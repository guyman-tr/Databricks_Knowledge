SELECT 
w.id AS workbook_id,
    w.name AS "Workbook Name",
w.size/(1024*1024) as workbook_size,
    su.friendly_name AS "Owner",
    p.name AS "Project Name",
    MAX(vs.time) AS "Last Day Viewed",
    CASE 
        WHEN MAX(vs.time) IS NULL THEN NULL
        ELSE CURRENT_DATE - CAST(MAX(vs.time) AS DATE) 
    END AS "Days Since Last Viewed",
dc.name as connection_name,
    dc.dbname,
    dc.dbclass AS "Connection Type",
    CASE 
        WHEN bool_or(dc.has_extract) = TRUE THEN 'Yes'
        ELSE 'No'
    END AS "Has Extract",
w.extracts_refreshed_at

FROM workbooks w
-- Joins to get the Owner's Full Name
JOIN users u ON w.owner_id = u.id
JOIN system_users su ON u.system_user_id = su.id
-- Join to get Project name
JOIN projects p ON w.project_id = p.id
-- Left Joins for usage stats (if never viewed, these return NULL)
LEFT JOIN views v ON v.workbook_id = w.id
LEFT JOIN views_stats vs ON vs.view_id = v.id
-- Join for Data Connections
LEFT JOIN data_connections dc ON (
    (dc.owner_type = 'Workbook' AND dc.owner_id = w.id)
)

GROUP BY 
w.id,
    w.name, 
w.size,
    su.friendly_name, 
    p.name,
dc.name,
dc.dbclass,
dbname,
w.extracts_refreshed_at
ORDER BY 
    "Last Day Viewed" DESC NULLS LAST