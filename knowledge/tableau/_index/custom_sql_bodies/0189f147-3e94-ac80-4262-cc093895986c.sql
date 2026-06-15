SELECT
    w.name       AS workbook_name,
    w.workbook_url,
    

    -- Connection Type (New)
    dc.dbclass                      AS connection_type,
    dc.server                        AS source_server,
    
    -- IDs for joining to Task object
    w.id           AS workbook_id,
    
    su.friendly_name                 AS owner_name,
    p.name                           AS project_name,
    COALESCE(pp.name, p.name)                         AS parent_project_name,
    ROUND(e.size / (1024.0 * 1024.0), 2) AS extract_size_mb

FROM public.extracts e
LEFT JOIN public.datasources ds ON ds.id = e.datasource_id
LEFT JOIN public._workbooks w ON w.id = e.workbook_id
-- Join to get the connection details (e.g. SQL Server, Snowflake)
LEFT JOIN public.data_connections dc ON dc.owner_id = COALESCE(ds.id, w.id) 
    AND dc.has_extract = TRUE
LEFT JOIN public.users u ON u.id = COALESCE(ds.owner_id, w.owner_id)
LEFT JOIN public.system_users su ON su.id = u.system_user_id
LEFT JOIN public.projects p ON p.id = COALESCE(w.project_id, ds.project_id)
LEFT JOIN public.projects pp ON p.parent_project_id = pp.id