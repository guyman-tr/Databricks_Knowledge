SELECT
    COALESCE(ds.name, w.name)       AS content_name,
    COALESCE(ds.repository_url, w.repository_url) AS content_url,
 
    CASE
        WHEN e.datasource_id IS NOT NULL AND ds.parent_workbook_id IS NULL
            THEN 'Published Datasource'
        WHEN e.datasource_id IS NOT NULL AND ds.parent_workbook_id IS NOT NULL
            THEN 'Embedded Datasource'
        WHEN e.workbook_id IS NOT NULL
            THEN 'Workbook'
    END                             AS extract_type,
 
    su.friendly_name                AS owner_name,
    su.email                        AS owner_email,
    p.name                          AS project_name
 
FROM public.extracts e
 
LEFT JOIN public.datasources ds
    ON ds.id = e.datasource_id
 
LEFT JOIN public.workbooks w
    ON w.id = e.workbook_id
 
LEFT JOIN public.users u
    ON u.id = COALESCE(ds.owner_id, w.owner_id)
LEFT JOIN public.system_users su
    ON su.id = u.system_user_id
 
LEFT JOIN public.projects p
    ON p.id = COALESCE(ds.project_id, w.project_id)
 
ORDER BY
    project_name,
    extract_type,
    content_name