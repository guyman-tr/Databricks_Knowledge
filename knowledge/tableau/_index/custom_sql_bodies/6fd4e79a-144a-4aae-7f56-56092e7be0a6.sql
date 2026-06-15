SELECT DISTINCT  -- distinct required due to duplicates for customized full-workbook subscriptions
    bj.args ,
    bj.id                                               AS "Job Id" ,
    bj.luid                                             AS "Job LUID" ,
    bj.job_name                                         AS "Job Name" ,
    bj.progress                                         AS "Progress" ,
    bj.finish_code                                      AS "Finish Code" ,
    bj.priority                                         AS "Priority" ,
    bj.notes                                            AS "Notes" ,
    bj.created_at                                       AS "Created At" ,
    bj.started_at                                       AS "Started At" ,
    bj.completed_at                                     AS "Completed At" ,
    GREATEST(
        bj.created_at ,
        bj.started_at ,
        bj.completed_at
    )                                                   AS "Increment Date" ,
    NOW()                                               AS "Current Datetime" ,
    bj.site_id                                          AS "Site Id" ,
    bj.backgrounder_id                                  AS "Backgrounder Id" ,
    bj.created_on_worker                                AS "Created On Worker" ,
    bj.processed_on_worker                              AS "Processed On Worker" ,
    bj.correlation_id                                   AS "Correlation Id" ,
    bj.creator_id                                       AS "Creator Id" ,
    bj.run_now                                          AS "Run Now" ,
    COALESCE(t.id, sub.task_id)                         AS "Task Id" ,
    t.consecutive_failure_count                         AS "Consecutive Failure Count" ,
    COALESCE(t.state, sub.state, da.suspend_state)      AS "Task State (orig)" ,
    sub.id                                              AS "Subscription Id" ,
    REPLACE(
        COALESCE(da_cv.repository_url, da_v.repository_url, 
                    d.repository_url, w.repository_url, 
                    sub.view_url, sub.workbook_url,
                    m_w.repository_url, m_d.repository_url,
                    f.name, m_f.name),
        '/sheets',
        '')                                             AS "Item Repository Url" ,
    COALESCE(da_w.project_id, d.project_id, 
             w.project_id, f.project_id,
             m_w.project_id, m_d.project_id, 
             m_f.project_id, sub.project_id)            AS "Item Project Id" ,
    COALESCE(da.creator_id, d.owner_id, w.owner_id, 
            f.owner_id, sub.owner_id, m_f.owner_id,
             m_w.owner_id, m_d.owner_id)                AS "Item Owner Id" ,
    COALESCE(da.id, d.id, w.id, f.id, sub.view_id, sub.workbook_id,
             m_w.id, m_d.id, m_f.id)                    AS "Item Id" ,
    COALESCE(da.luid, d.luid, w.luid, sub.view_luid, sub.workbook_luid,
            f.luid, m_f.luid, m_w.luid, m_d.luid)
                                                        AS "Item LUID" ,
    COALESCE(da.title, d.name, w.name, f.name, sub.item_name, 
            sub.subject, bj.title)                      AS "Item Name" ,
    COALESCE(sub.item_type, sub.content_type, 
            bj.subtitle,
                (CASE
                    WHEN da.id IS NOT NULL
			THEN 'Data Alert'
                    ELSE NULL
                END))                                   AS "Item Type" ,
    d.is_certified                                      AS "Item Is Certified" ,
    data_connections.id                                 AS "Data Connection Id" ,
    sub.user_id                                         AS "Subscriber Id" ,
    sub.user_name                                       AS "Subscriber Sysname" ,
    sub.subject                                         AS "Subscription Subject" ,
    COALESCE(sub.workbook_id)                           AS "Subscription Workbook Id" ,
    sub.workbook_name                                   AS "Subscription Workbook Name" ,
    sub.schedule_id                                     AS "Subscription Schedule Id" ,
    CASE
        WHEN sub.customized_view_id IS NULL THEN false  
        ELSE TRUE
    END                                                 AS "Subscribed to Custom View" , -- subscription to a full workbook based on a customized view creates extra records we have to ditch :(
    da.notification_interval_in_minutes                 AS "Data Alert Notification Interval (minutes)" ,
    da.last_checked                                     AS "Data Alert Last Checked At"
FROM background_jobs bj
    LEFT JOIN tasks t
        ON bj.correlation_id = t.id
            AND bj.job_name IN ('Refresh Extracts','Increment Extracts', 'Run Flow')
    LEFT JOIN
        (
        -- this subquery is necessary because full-workbook subscriptions on customized views create records for each view in the workbook being subscribed to :(
        SELECT DISTINCT
            t.id                          AS "task_id" ,
            t.state                       AS "state" ,
            s.id                          AS "id" ,
            s2.schedule_id                AS "schedule_id" ,
            COALESCE(s_v.name, s_w.name)  AS "item_name" ,
            CASE
                WHEN s_v.id IS NOT NULL
                    THEN 'View'
                WHEN s_w.id IS NOT NULL
                    THEN 'Workbook'
                ELSE NULL
            END                           AS "item_type" ,
            s_v.id                        AS "view_id" ,
            s_v.luid                      AS "view_luid" ,
            s_v.repository_url            AS "view_url" ,
            COALESCE(
                    s_w.repository_url ,
                    sv_w.repository_url
                    )                     AS "workbook_url" ,
            COALESCE(s_w.id ,
                    sv_w.id
                     )                    AS "workbook_id" ,
            COALESCE(s_w.luid ,
                    sv_w.luid
                     )                    AS "workbook_luid" ,
            s_w.id                        AS "workbook_subscription_id" ,
            COALESCE(s_v.owner_id, sv_w.owner_id)
                                          AS "owner_id" ,
            COALESCE(s_w.name, sv_w.name) AS "workbook_name" ,
            s.content_type ,
            s.subject ,
            s.user_id ,
            s.user_name ,
            s.customized_view_id ,
            COALESCE(sv_w.project_id,
                     s_w.project_id)      AS "project_id"
        FROM _subscriptions s
            INNER JOIN subscriptions s2         --this is ONLY being joined to obtain the schedule_id, because it's not present in the _subscriptions view >:-|
                ON s.id = s2.id
            LEFT JOIN tasks t
                ON  s.id = t.obj_id
                    AND t.type = 'SingleSubscriptionTask'
            LEFT JOIN views s_v
                ON s.view_url = REPLACE(s_v.repository_url, 'sheets/','')
            LEFT JOIN workbooks sv_w
                ON s_v.workbook_id = sv_w.id
            LEFT JOIN workbooks s_w
                ON s.workbook_url = s_w.repository_url
        ) AS sub
            ON bj.correlation_id = COALESCE(sub.task_id, sub.id) -- Sorry, I know this is crappy. It allows for an annoying data change change between 10.3 and subsequent versions.
                AND bj.job_name = 'Subscription Notifications'
    LEFT JOIN flow_run_specs frs
        ON (t.obj_id = frs.id AND t.obj_type = 'FlowRunSpec')
    LEFT JOIN flows f
        ON frs.flow_id = f.id
    LEFT JOIN datasources d
        ON (t.obj_id = d.id AND t.obj_type = 'Datasource')
    LEFT JOIN data_alerts da
        ON (bj.job_name = 'Check If Data Alert Condition Is True'
            AND da.id = CAST(SUBSTRING(bj.args from '---\n-\s[a-z]*\n-\s([0-9]*)\n') AS INT)) -- this is the only place the ID is stored >:-|
    LEFT JOIN _customized_views da_cv
        ON da.customized_view_id = da_cv.id
    LEFT JOIN views da_v
        ON da.view_id = da_v.id
    LEFT JOIN workbooks da_w
        ON da.workbook_id = da_w.id
    LEFT JOIN
        (
        -- used just to get the proper ID value for published datasource hyperlinks
        SELECT MIN(dc.id) AS "id", dc.datasource_id
        FROM data_connections AS dc
            INNER JOIN datasources AS dc_d
                ON dc.datasource_id = dc_d.id
                    AND dc_d.connectable = true
        GROUP BY dc.datasource_id
        ) AS data_connections
            ON d.id = data_connections.datasource_id
    LEFT JOIN workbooks w
        ON (t.obj_id = w.id AND t.obj_type = 'Workbook')
            OR w.id = sub.workbook_subscription_id
    LEFT JOIN workbooks m_w --missing workbooks
        ON t.id IS NULL
            AND bj.subtitle = 'Workbook'
            AND bj.title = m_w.name
            AND bj.site_id = m_w.site_id
    LEFT JOIN datasources m_d --missing datasources
        ON t.id IS NULL
            AND bj.subtitle = 'Datasource'
            AND bj.title = m_d.name
            AND bj.site_id = m_d.site_id
            AND m_d.connectable = true
    LEFT JOIN flows m_f --missing flows
        ON t.id IS NULL
            AND bj.subtitle = 'Flow'
            AND bj.title = m_f.name
            AND bj.site_id = m_f.site_id

-- OPTIONAL: If the data source is too slow, add an integer parameter, then edit the name below and remove the "--" from the line. This will filter the data to just that many days ago.
--WHERE age(bj.created_at) <= INTERVAL '<[Parameters.Your Parameter Name]> days' -- this parameter filter exists only for efficiency