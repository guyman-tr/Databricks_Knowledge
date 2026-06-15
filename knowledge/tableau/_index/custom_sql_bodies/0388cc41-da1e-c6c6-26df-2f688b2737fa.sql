-- Views
SELECT
    v.id AS item_id , 
    REPLACE(hv.repository_url, '/sheets', '')
                AS repository_url,
    COALESCE (
        v.name ,
        hv.view_name
    )           AS item_name ,
    'View'      AS item_type ,
    v.owner_id ,
    v.site_id ,
    w.id        AS workbook_id ,
    w.project_id
FROM (
        SELECT
            repository_url ,
            MAX(view_id)        AS view_id ,
            MAX(view_name)      AS view_name
        FROM (
            SELECT
                repository_url ,
                view_id ,
                FIRST_VALUE(name)
                    OVER (PARTITION BY view_id ORDER BY id DESC)
                                    AS view_name
            FROM hist_views
            ) as hv
        GROUP BY repository_url

        UNION

        -- why is this query needed? Because for some reason, not all views records have a hist_views record.
        SELECT
            v.repository_url ,
            v.id                    AS view_id ,
            v.name                  AS view_name               
        FROM views v
    ) AS hv
    LEFT JOIN views v
        ON hv.view_id = v.id
    LEFT JOIN workbooks w
        ON v.workbook_id = w.id

UNION ALL

-- Workbooks
SELECT
    id AS item_id , 
    REPLACE(hw.repository_url, '/sheets', '')
                AS repository_url ,
    COALESCE (
        w.name ,
        hw.workbook_name
    )                   AS item_name ,
    'Workbook'          AS item_type ,
    owner_id ,
    site_id ,
    w.id                AS workbook_id ,
    project_id
FROM (
        SELECT
            repository_url ,
            MAX(workbook_id)    AS workbook_id ,
            MAX(workbook_name)  AS workbook_name
        FROM (
            SELECT
                repository_url ,
                workbook_id ,
                FIRST_VALUE(name)
                    OVER (PARTITION BY workbook_id ORDER BY id DESC)
                                    AS workbook_name
            FROM hist_workbooks
            ) as hw
        GROUP BY repository_url

        UNION

        -- why is this query needed? Because for some reason, not all workbooks records have a hist_workbooks record.
        SELECT
            w.repository_url ,
            w.id                AS workbook_id ,
            w.name              AS workbook_name
        FROM workbooks w
    ) AS hw
    LEFT JOIN workbooks w
        ON hw.workbook_id = w.id

UNION ALL

-- Data Sources
SELECT
    id AS item_id , 
    REPLACE(hd.repository_url, '/sheets', '') 
                                AS repository_url ,
    COALESCE (
        d.name ,
        hd.datasource_name
    )                           AS item_name ,
    'Data Source'               AS item_type ,
    owner_id ,
    site_id ,
    NULL                        AS workbook_id ,
    project_id
FROM (
        SELECT
            repository_url ,
            MAX(datasource_id)          AS datasource_id ,
            MAX(datasource_name)        AS datasource_name
        FROM (
            SELECT
                repository_url ,
                datasource_id ,
                FIRST_VALUE(name)
                    OVER (PARTITION BY datasource_id ORDER BY id DESC)
                                    AS datasource_name
            FROM hist_datasources
            ) as hd
        GROUP BY repository_url

        UNION

        -- why is this query needed? Because for some reason, not all datasources records have a hist_datasources record.
        SELECT
            d.repository_url ,
            d.id                        AS datasource_id ,
            d.name
        FROM datasources d
        WHERE d.connectable = True
    ) AS hd
    LEFT JOIN datasources d
        ON hd.datasource_id = d.id