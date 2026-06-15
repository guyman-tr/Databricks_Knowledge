-- Optimized Site Summary Dashboard with Role Lookup
WITH user_stats AS (
    SELECT 
        u.site_id,
        COUNT(*) AS total_users,
        COUNT(*) FILTER (WHERE sr.display_name = 'Creator') AS creators,
        COUNT(*) FILTER (WHERE sr.display_name = 'Explorer') AS explorers,
        COUNT(*) FILTER (WHERE sr.display_name = 'Viewer') AS viewers
    FROM public.users u
    JOIN (SELECT * FROM public.site_roles as sr WHERE sr.display_name != 'Unlicensed') sr 
        ON u.site_role_id = sr.id
    GROUP BY u.site_id
),
workbook_stats AS (
    SELECT 
        site_id,
        COUNT(*) AS workbook_count,
        ROUND(COALESCE(SUM(size), 0) / (1024.0 * 1024 * 1024), 2) AS workbooks_size_gb
    FROM public.workbooks
    GROUP BY site_id
),
datasource_stats AS (
    SELECT 
        site_id,
        COUNT(*) AS datasource_count,
        ROUND(COALESCE(SUM(size), 0) / (1024.0 * 1024 * 1024), 2) AS datasources_size_gb
    FROM public.datasources
    GROUP BY site_id
),
project_stats AS (
    SELECT 
        site_id,
        COUNT(*) AS project_count
    FROM public.projects
    GROUP BY site_id
)
SELECT 
    s.name AS site_name,
    COALESCE(u.total_users, 0) AS total_users,
    COALESCE(u.creators, 0) AS creators,
    COALESCE(u.explorers, 0) AS explorers,
    COALESCE(u.viewers, 0) AS viewers,
    COALESCE(w.workbook_count, 0) AS workbook_count,
    COALESCE(ds.datasource_count, 0) AS datasource_count,
    COALESCE(p.project_count, 0) AS project_count,
    COALESCE(w.workbooks_size_gb, 0) AS workbooks_size_gb,
    COALESCE(ds.datasources_size_gb, 0) AS datasources_size_gb
FROM public.sites s
LEFT JOIN user_stats u ON s.id = u.site_id
LEFT JOIN workbook_stats w ON s.id = w.site_id
LEFT JOIN datasource_stats ds ON s.id = ds.site_id
LEFT JOIN project_stats p ON s.id = p.site_id
ORDER BY COALESCE(u.total_users, 0) DESC