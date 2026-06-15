/*
Return one row per user, assembling counts of owned content for each
*/


SELECT
    u.id                        AS user_id ,
    COALESCE(workbooks.workbooks_owned, 0)
                                AS workbooks_owned ,
    COALESCE(workbooks.workbooks_owned_size / 1024.0 / 1024.0, 0)
                                AS workbooks_owned_size ,
    COALESCE(flows.flows_owned, 0)
                                AS flows_owned ,
    COALESCE(flows.flows_owned_size / 1024.0 / 1024.0, 0)
                                AS flows_owned_size ,
    COALESCE(datasources.datasources_owned, 0)
                                AS datasources_owned ,
    COALESCE(datasources.datasources_owned_size / 1024.0 / 1024.0, 0)
                                AS datasources_owned_size ,
    COALESCE(datasources.certified_datasources_owned, 0)
                                AS certified_datasources_owned ,
    COALESCE(projects.projects_owned, 0)
                                AS projects_owned ,
    COALESCE(views.views_owned, 0)
                                AS views_owned ,
    COALESCE(metrics.metrics_owned, 0)
                                AS metrics_owned ,
    COALESCE(collections.collections_owned, 0)
                                AS collections_owned
FROM
    users AS u
    LEFT JOIN

        -- workbooks
        (
        SELECT
            w.owner_id             AS workbooks_owner_id ,
            SUM(w.size)            AS workbooks_owned_size ,
            COUNT(w.id)            AS workbooks_owned
        FROM workbooks w
        GROUP BY
            w.owner_id
        ) as workbooks
            ON u.id = workbooks.workbooks_owner_id

    -- data sources
    LEFT JOIN
        (
        SELECT
            d.owner_id             AS datasources_owner_id ,
            SUM(d.size)            AS datasources_owned_size ,
            COUNT(d.id)            AS datasources_owned ,
            COUNT(
                CASE
                    WHEN d.is_certified = true 
                        THEN d.id
                    ELSE NULL
                END
                )                AS certified_datasources_owned
        FROM datasources d
            WHERE d.connectable = true
        GROUP BY
            d.owner_id
        ) as datasources
            ON u.id = datasources.datasources_owner_id

    LEFT JOIN

        -- flows
        (
        SELECT
            f.owner_id             AS flows_owner_id ,
            SUM(f.size)            AS flows_owned_size ,
            COUNT(f.id)            AS flows_owned
        FROM flows f
        GROUP BY
            f.owner_id
        ) as flows
            ON u.id = flows.flows_owner_id

    -- projects
    LEFT JOIN
        (
        SELECT
            p.owner_id             AS projects_owner_id ,
            COUNT(p.id)            AS projects_owned
        FROM projects p
        GROUP BY
            p.owner_id
        ) as projects
            ON u.id = projects.projects_owner_id

    -- views
    LEFT JOIN
        (
        SELECT
            v.owner_id             AS views_owner_id ,
            COUNT(v.id)            AS views_owned
        FROM views v
        GROUP BY
            v.owner_id
        ) as views
            ON u.id = views.views_owner_id

    -- metrics
    LEFT JOIN
        (
        SELECT
            m.owner_id             AS metrics_owner_id ,
            COUNT(m.id)            AS metrics_owned
        FROM metrics m
        GROUP BY
            m.owner_id
        ) as metrics
            ON u.id = metrics.metrics_owner_id

    -- collections
    LEFT JOIN
        (
        SELECT
            a.owner_id             AS collections_owner_id ,
            COUNT(a.id)            AS collections_owned
        FROM asset_lists a
        WHERE a.list_type = 'collection'
        GROUP BY
            a.owner_id
        ) as collections
            ON u.id = collections.collections_owner_id