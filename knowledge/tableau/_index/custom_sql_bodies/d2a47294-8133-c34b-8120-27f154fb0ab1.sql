/*
Returns one row for combination of
    every datasource, workbook, view, project, metric, and collection across the Tableau Server instance
*/


SELECT
    content.id                                          AS "Id" ,
    content.luid                                        AS "LUID" ,
    content.name                                        AS "Name",
    content.repository_url                              AS "Repository URL" ,
    COALESCE(content.view_workbook_repository_url,
        content.repository_url)                         AS "Root Repository URL" ,
    COALESCE(subscriptions.subscription_count, 0)       AS "Subscription Count" ,
    content.created_at                                  AS "Created At" ,
    content.updated_at                                  AS "Updated At" ,
    content.first_published_at                          AS "First Published At" ,
    content.last_published_at                           AS "Last Published At" ,
    content.owner_id                                    AS "Owner Id" , 
    content.type                                        AS "Type",
    content.site_id                                     AS "Site Id" ,
    content.project_id                                  AS "Project Id" ,
    content.size                                        AS "Size" ,
    content.data_engine_extracts                        AS "Data Engine Extracts" ,
    content.refreshable_extracts                        AS "Refreshable Extracts" ,
    content.incrementable_extracts                      AS "Incrementable Extracts" ,
    content.extracts_refreshed_at                       AS "Extracts Refreshed At" ,
    content.extracts_incremented_at                     AS "Extracts Incremented At" ,
    content.extract_encryption_state                    AS "Extract Encryption State" ,
    CASE
       WHEN EXISTS
           (
           SELECT 1
           FROM tasks t
           WHERE t.type IN ('RefreshExtractTask','IncrementExtractTask')
               AND t.obj_id = content.id
               AND t.obj_type = content.type
           ) THEN true
        ELSE false
    END                                                 AS "Extracts Scheduled" ,
    content.revision                                    AS "Revision" ,
    content.content_version                             AS "Content Version" ,
    content.description                                 AS "Description" ,

    -- workbook stuff
    workbook_view_count                                 AS "Workbook View Count" ,
    workbook_display_tabs                               AS "Workbook Display Tabs" ,
    workbook_default_view_index                         AS "Workbook Default View Index" ,

    -- datasource stuff
    datasource_db_class                                 AS "Datasource DB Class" ,
    datasource_db_name                                  AS "Datasource DB Name" ,
    datasource_table_name                               AS "Datasource Table Name" ,
    datasource_connectable                              AS "Datasource Connectable" ,
    datasource_is_hierarchical                          AS "Datasource Is Hierarchical" ,
    datasource_is_certified                             AS "Datasource Is Certified" ,
    datasource_certification_note                       AS "Datasource Certification Note" ,
    datasource_certifier_user_id                        AS "Datasource Certifier User Id" ,

    -- view stuff
    view_locked                                         AS "View Locked" ,
    view_published                                      AS "View Published" ,
    view_workbook_id                                    AS "View Workbook Id" ,
    view_workbook_name                                  AS "View Workbook Name" ,
    view_workbook_repository_url                        AS "View Workbook Repository URL" ,
    view_index                                          AS "View Index" ,
    view_fields                                         AS "View Fields" ,
    view_title                                          AS "View Title" ,
    view_caption                                        AS "View Caption" ,
    view_sheet_id                                       AS "View Sheet Id" ,
    view_sheettype                                      AS "View Sheettype" ,

    -- metric stuff
    metric_view_id                                      AS "Metric View Id" ,
    metric_workbook_id                                  AS "Metric Workbook Id" ,

    -- collection stuff
    visibility                                          AS "Collection Visibility"
FROM
    (
    SELECT
        w.id ,
        luid ,
        name ,
        repository_url ,
        created_at ,
        updated_at ,
        first_published_at ,
        last_published_at ,
        owner_id , 
        'Workbook'                                      AS type ,
        w.site_id ,
        w_pc.project_id ,
        size ,
        data_engine_extracts ,
        refreshable_extracts ,
        incrementable_extracts ,
        extracts_refreshed_at ,
        extracts_incremented_at ,
        extract_encryption_state ,
        revision ,
        content_version ,
        description ,
        
        -- workbook stuff
        view_count                                      AS workbook_view_count ,
        display_tabs                                    AS workbook_display_tabs ,
        default_view_index                              AS workbook_default_view_index ,

        -- datasource stuff
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view stuff
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,        
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM workbooks w
        LEFT JOIN projects_contents w_pc
            ON w.id = w_pc.content_id
                AND w.site_id = w_pc.site_id
                AND w_pc.content_type = 'workbook'
    UNION ALL
    SELECT
        d.id ,
        d.luid ,
        d.name ,
        d.repository_url ,
        d.created_at ,
        d.updated_at ,
        d.first_published_at ,
        d.last_published_at ,
        d.owner_id , 
        'Datasource'                                    AS type ,
        d.site_id ,
        d_pc.project_id ,
        d.size ,
        d.data_engine_extracts                          AS data_engine_extracts ,
        d.refreshable_extracts ,
        d.incrementable_extracts ,
        d.extracts_refreshed_at ,
        d.extracts_incremented_at ,
        d.extract_encryption_state ,
        d.revision ,
        d.content_version ,
        d.description ,
        
        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        d.db_class                                      AS datasource_db_class ,
        d.db_name                                       AS datasource_db_name ,
        d.table_name                                    AS datasource_table_name ,
        d.connectable                                   AS datasource_connectable ,
        d.is_hierarchical                               AS datasource_is_hierarchical ,
        d.is_certified                                  AS datasource_is_certified ,
        d.certification_note                            AS datasource_certification_note ,
        d.certifier_user_id                             AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM datasources d
        LEFT JOIN projects_contents d_pc
            ON d.id = d_pc.content_id
                AND d.site_id = d_pc.site_id
                AND d_pc.content_type = 'datasource'
    WHERE d.connectable = true
        AND d.parent_type IS NULL  -- DataRoles are being added to this table, this should ensure that they are excluded
    UNION ALL
    SELECT
        v.id ,
        v.luid ,
        v.name ,
        v.repository_url ,
        v.created_at ,
        v.updated_at ,
        v.first_published_at ,
        w_view.last_published_at ,
        v.owner_id , 
        'View'                                          AS type ,
        v.site_id ,
        w_view_pc.project_id ,
        NULL                                            AS size ,
        NULL                                            AS data_engine_extracts ,
        NULL                                            AS refreshable_extracts ,
        NULL                                            AS incrementable_extracts ,
        NULL                                            AS extracts_refreshed_at ,
        NULL                                            AS extracts_incremented_at ,
        NULL                                            AS extract_encryption_state ,
        v.revision ,
        NULL                                            AS content_version ,
        NULL                                            AS description ,
        
        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(v.locked AS boolean)                       AS view_locked ,
        v.published                                     AS view_published ,
        v.workbook_id                                   AS view_workbook_id ,
        w_view.name                                     AS view_workbook_name ,
        w_view.repository_url                           AS view_workbook_repository_url ,
        v.index                                         AS view_index ,
        v.fields                                        AS view_fields ,
        v.title                                         AS view_title ,
        v.caption                                       AS view_caption ,
        v.sheet_id                                      AS view_sheet_id ,
        v.sheettype                                     AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM views v
        INNER JOIN workbooks w_view
            ON v.workbook_id = w_view.id
        LEFT JOIN projects_contents w_view_pc
            ON w_view.id = w_view_pc.content_id
                AND w_view.site_id = w_view_pc.site_id
                AND w_view_pc.content_type = 'workbook'
    UNION ALL
    SELECT
        f.id ,
        luid ,
        name ,
        name                                            AS repository_url ,
        created_at ,
        updated_at ,
        NULL                                            AS first_published_at ,
        last_published_at ,
        owner_id , 
        'Flow'                                          AS type ,
        f.site_id ,
        f_pc.project_id ,
        size ,
        f.data_engine_extracts                          AS data_engine_extracts ,
        NULL                                            AS refreshable_extracts ,
        NULL                                            AS incrementable_extracts ,
        NULL                                            AS extracts_refreshed_at ,
        NULL                                            AS extracts_incremented_at ,
        extract_encryption_state ,
        NULL                                            AS revision ,
        content_version ,
        description ,

        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,        
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM flows f
        LEFT JOIN projects_contents f_pc
            ON f.id = f_pc.content_id
                AND f.site_id = f_pc.site_id
                AND f_pc.content_type = 'flow'
    UNION ALL
    SELECT
        m.id ,
        m.luid ,
        m.name ,
        m.name                                          AS repository_url ,
        m.created_at ,
        m.updated_at ,
        NULL                                            AS first_published_at ,
        m.updated_at                                    AS last_published_at ,
        m.owner_id , 
        'Metric'                                        AS type ,
        m.site_id ,
        m_pc.project_id ,
        NULL                                            AS size ,
        NULL                                            AS data_engine_extracts ,
        NULL                                            AS refreshable_extracts ,
        NULL                                            AS incrementable_extracts ,
        NULL                                            AS extracts_refreshed_at ,
        NULL                                            AS extracts_incremented_at ,
        NULL                                            AS extract_encryption_state ,
        NULL                                            AS revision ,
        NULL                                            AS content_version ,
        m.description ,
        
        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        v.id                                            AS metric_view_id ,
        v.workbook_id                                   AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM metrics m
        LEFT JOIN customized_views cv
            ON m.customized_view_id = cv.id
        LEFT JOIN views v
            ON cv.view_id = v.id
        LEFT JOIN projects_contents m_pc
            ON m.id = m_pc.content_id
                AND m.site_id = m_pc.site_id
                AND m_pc.content_type = 'metric'
    UNION ALL
    SELECT
        id ,
        luid ,
        name ,
        name                                            AS repository_url ,
        created_at ,
        updated_at ,
        NULL                                            AS first_published_at ,
        NULL                                            AS last_published_at ,
        owner_id , 
        'Project'                                       AS type ,
        site_id ,
        id                                              AS project_id ,
        NULL                                            AS size ,  -- ideally we'd sum up all the sizes of items it contains, but that's a lot of buck for very little bang
        NULL                                            AS data_engine_extracts ,
        NULL                                            AS refreshable_extracts ,
        NULL                                            AS incrementable_extracts ,
        NULL                                            AS extracts_refreshed_at ,
        NULL                                            AS extracts_incremented_at ,
        NULL                                            AS extract_encryption_state ,
        NULL                                            AS revision ,
        NULL                                            AS content_version ,
        description ,
        
        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        CAST(NULL AS varchar(255))                      AS visibility
    FROM projects
    UNION ALL
    SELECT
        id ,
        luid ,
        name ,
        name                                            AS repository_url ,
        created_timestamp                               AS created_at ,
        updated_at ,
        NULL                                            AS first_published_at ,
        NULL                                            AS last_published_at ,
        owner_id , 
        'Collection'                                    AS type ,
        site_id ,
        NULL                                            AS project_id ,
        NULL                                            AS size ,  -- ideally we'd sum up all the sizes of items it contains, but that's a lot of buck for very little bang
        NULL                                            AS data_engine_extracts ,
        NULL                                            AS refreshable_extracts ,
        NULL                                            AS incrementable_extracts ,
        NULL                                            AS extracts_refreshed_at ,
        NULL                                            AS extracts_incremented_at ,
        NULL                                            AS extract_encryption_state ,
        NULL                                            AS revision ,
        NULL                                            AS content_version ,
        description ,
        
        -- workbook-specific columns
        NULL                                            AS workbook_view_count ,
        NULL                                            AS workbook_display_tabs ,
        NULL                                            AS workbook_default_view_index ,

        -- datasource-specific columns
        NULL                                            AS datasource_db_class ,
        NULL                                            AS datasource_db_name ,
        NULL                                            AS datasource_table_name ,
        NULL                                            AS datasource_connectable ,
        NULL                                            AS datasource_is_hierarchical ,
        NULL                                            AS datasource_is_certified ,
        NULL                                            AS datasource_certification_note ,
        NULL                                            AS datasource_certifier_user_id ,

        -- view-specific columns
        CAST(NULL AS boolean)                           AS view_locked ,
        CAST(NULL AS boolean)                           AS view_published ,
        CAST(NULL AS integer)                           AS view_workbook_id ,
        CAST(NULL AS varchar(255))                      AS view_workbook_name ,
        CAST(NULL AS varchar(255))                      AS view_workbook_repository_url ,
        CAST(NULL AS integer)                           AS view_index ,
        NULL                                            AS view_fields ,
        NULL                                            AS view_title ,
        NULL                                            AS view_caption ,
        NULL                                            AS view_sheet_id ,
        NULL                                            AS view_sheettype ,

        -- metric-specific columns
        CAST(NULL AS integer)                           AS metric_view_id ,
        CAST(NULL AS integer)                           AS metric_workbook_id ,

        -- collection-specific columns
        visibility
    FROM asset_lists
    WHERE list_type = 'collection'

    ) AS content
    LEFT JOIN
        -- Subscription statistics
        (
        SELECT
            count(distinct id) AS subscription_count ,
            site_id ,
            view_url ,
            NULL               AS workbook_url
        FROM _subscriptions
        WHERE workbook_url IS NULL
        GROUP BY 
            site_id ,
            view_url
        UNION
        SELECT
            count(distinct id) AS subscription_count ,
            site_id ,
            NULL               AS view_url ,
            COALESCE(workbook_url, substr(view_url, 0, position('/' in view_url)))
                               AS workbook_url
        FROM _subscriptions
        GROUP BY 
            site_id ,
            COALESCE(workbook_url, substr(view_url, 0, position('/' in view_url)))
        ) AS subscriptions
            ON ((content.type = 'View' AND REPLACE(content.repository_url, '/sheets', '') = subscriptions.view_url)
                OR (content.type = 'Workbook' AND content.repository_url = subscriptions.workbook_url))
                AND content.site_id = subscriptions.site_id