SELECT
    tasks.id                                            AS "Job Id" ,
    tasks.job_name                                      AS "Job Name" ,
    tasks.progress                                      AS "Progress" ,
    tasks.finish_code                                   AS "Finish Code" ,
    tasks.priority                                      AS "Priority" ,
    tasks.notes                                         AS "Notes" ,
    tasks.created_at                                    AS "Created At" ,
    tasks.started_at                                    AS "Started At" ,
    tasks.completed_at                                  AS "Completed At",
    tasks.backgrounder_id                               AS "Backgrounder Id",
    tasks.created_on_worker                             AS "Created On Worker" ,
    tasks.processed_on_worker                           AS "Processed On Worker" ,
    current_timestamp                                   AS "Current Datetime" ,
    tasks.site_id                                       AS "Site Id" ,
    s.name                                              AS "Site Name" ,
    tasks.subtitle                                      AS "Item Type" ,
    tasks.item_id                                       AS "Item Id" ,
    tasks.item_name                                     AS "Item Name" ,
    tasks.repository_url                                AS "Item Repository Url" ,
    tasks.project_id                                    AS "Item Project Id" ,
    tasks.owner_id                                      AS "Item Owner Id" ,
    su_own.name                                         AS "Item Owner Name" ,
    su_own.friendly_name                                AS "Item Owner Friendly Name" ,
    p.name                                              AS "Project Name"
FROM
    (
    SELECT
        bj.id ,
        bj.job_name ,
        bj.progress ,
        bj.finish_code ,
        bj.priority ,
        bj.notes ,
        bj.created_at ,
        bj.started_at ,
        bj.completed_at ,
        bj.site_id ,
        bj.subtitle ,
        bj.backgrounder_id ,
        bj.created_on_worker ,
        bj.processed_on_worker ,
        COALESCE(d.repository_url, w.repository_url)        AS "repository_url" ,
        COALESCE(d.project_id, w.project_id)                AS "project_id" ,
        COALESCE(d.owner_id, w.owner_id)                    AS "owner_id" ,
        COALESCE(dc.id, w.id)                               AS "item_id" ,
        COALESCE(d.name, w.name)                            AS "item_name"
    FROM background_jobs bj
        LEFT JOIN datasources d
            ON bj.title = d.name
                AND bj.subtitle = 'Datasource'
        LEFT JOIN data_connections dc
            ON d.id = dc.owner_id
		AND dc.owner_type = 'Datasource'
        LEFT JOIN workbooks w
            ON bj.title = w.name
                AND bj.subtitle = 'Workbook'
    ) AS tasks
    LEFT JOIN sites s
        ON tasks.site_id = s.id
    LEFT JOIN users u_own
        ON tasks.owner_id = u_own.id
    LEFT JOIN system_users su_own
        ON u_own.system_user_id = su_own.id
    LEFT JOIN projects p
        ON tasks.project_id = p.id