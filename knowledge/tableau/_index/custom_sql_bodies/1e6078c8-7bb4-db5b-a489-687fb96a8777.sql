/*

Return usage statistics for each user--both what they are doing, and activity on their content
    (these two different concepts are combined in a single query for performance reasons)

*/

with access_counts as
(
    SELECT
        MAX(he.created_at)               AS last_event_date ,
        COUNT(he.id)                     AS activity_count ,

        -- raw access counts
        he.historical_event_type_id      AS event_type_id ,
        hu.user_id ,
        he.hist_datasource_id ,
        he.hist_view_id ,
        he.hist_workbook_id
    FROM historical_events he
        LEFT JOIN hist_users hu
            ON he.hist_actor_user_id = hu.id
    WHERE 
        he.historical_event_type_id IN (
            112,    --access datasource    
            84,     --access view
            93,     --publish workbook
            110,    --publish datasource
            120     --add comment
            )
        AND age(he.created_at) <= INTERVAL '30 days'
    GROUP BY
        hu.user_id ,
        he.historical_event_type_id ,
        he.hist_datasource_id ,
        he.hist_view_id ,
        he.hist_workbook_id
)


SELECT
    u.id                                                    AS user_id ,
    last_user_events.last_view_access_date ,
    last_user_events.last_datasource_access_date ,
    last_user_events.last_workbook_publish_date ,
    last_user_events.last_datasource_publish_date ,
    COALESCE(last_user_events.view_access_events, 0)
                                                            AS view_access_events ,
    COALESCE(last_user_events.datasource_access_events, 0)
                                                            AS datasource_access_events ,
    COALESCE(last_user_events.datasource_publish_events, 0)
                                                            AS datasource_publish_events ,
    COALESCE(last_user_events.workbook_publish_events, 0)
                                                            AS workbook_publish_events ,
    COALESCE(content_served.total_users_served_views, 0)
                                                            AS total_users_served_views ,
    COALESCE(content_served.total_users_served_datasources, 0)
                                                            AS total_users_served_datasources ,
    COALESCE(content_served.unique_users_served_views, 0)
                                                            AS unique_users_served_views ,
    COALESCE(content_served.unique_users_served_datasources, 0)
                                                            AS unique_users_served_datasources
FROM
        users AS u

        LEFT JOIN
            -- last_user_events
            (
            SELECT
                    ac.user_id                                          AS events_user_id ,
                    MAX(
                            CASE
                                    WHEN ac.event_type_id = 84
                                            THEN ac.last_event_date
                                    ELSE NULL
                            END
                            )                                           AS last_view_access_date ,
                    SUM(
                            CASE
                                    WHEN ac.event_type_id = 84
                                            THEN ac.activity_count
                                    ELSE 0
                            END
                            )                                           AS view_access_events ,
                    MAX(
                            CASE
                                    WHEN ac.event_type_id = 112
                                            THEN ac.last_event_date
                                    ELSE NULL
                            END
                            )                                           AS last_datasource_access_date ,
                    SUM(
                            CASE
                                    WHEN ac.event_type_id = 112
                                            THEN ac.activity_count
                                    ELSE 0
                            END
                            )                                           AS datasource_access_events ,
                    MAX(
                            CASE
                                    WHEN ac.event_type_id = 93
                                            THEN ac.last_event_date
                                    ELSE NULL
                            END
                            )                                           AS last_workbook_publish_date ,
                    SUM(
                            CASE
                                    WHEN ac.event_type_id = 93
                                            THEN ac.activity_count
                                    ELSE 0
                            END
                            )                                           AS workbook_publish_events ,
                    MAX(
                            CASE
                                    WHEN ac.event_type_id = 110
                                            THEN ac.last_event_date
                                    ELSE NULL
                            END
                            )                                           AS last_datasource_publish_date ,
                    SUM(
                            CASE
                                    WHEN ac.event_type_id = 110
                                            THEN ac.activity_count
                                    ELSE 0
                            END
                            )                                           AS datasource_publish_events
                            
            /* --this event never appears in historical_events at this time. :(
                    MAX(
                            CASE
                                    WHEN ac.event_type_id = 120
                                            THEN ac.last_event_date
                                    ELSE NULL
                            END
                            )                                           AS last_comment_date
            */
            FROM access_counts ac
            GROUP BY
                    ac.user_id
            ) AS last_user_events
                ON u.id = last_user_events.events_user_id

        LEFT JOIN
            (    -- content_served
                /*
                Total Served Views (Last 30 days)
                Total Served Data Sources (Last 30 days)
                Unique Users Served Views (Last 30 days)
                Unique Users Served Data Sources (Last 30 days)
                */

                -- workbook access counts
                SELECT
                    COALESCE(d.owner_id, v.owner_id, w.owner_id)    
                                                                        AS content_owner_id ,
                SUM(
                    CASE
                        WHEN ac.event_type_id = 84
                            THEN ac.activity_count
                        ELSE 0
                    END
                    )                                                   AS total_users_served_views ,
                SUM(
                    CASE
                        WHEN ac.event_type_id = 112
                            THEN ac.activity_count
                        ELSE 0
                    END
                    )                                                   AS total_users_served_datasources ,
                COUNT (
                    DISTINCT
                    CASE
                        WHEN ac.event_type_id = 84
                            THEN ac.user_id
                        ELSE NULL
                    END
                    )                                                   AS unique_users_served_views ,
                COUNT (
                    DISTINCT
                    CASE
                        WHEN ac.event_type_id = 112
                            THEN ac.user_id
                        ELSE NULL
                    END
                    )                                                   AS unique_users_served_datasources
                FROM access_counts ac
                   LEFT JOIN hist_views hv
                       ON ac.hist_view_id = hv.id
                   LEFT JOIN views v
                       ON hv.view_id = v.id
                   LEFT JOIN hist_workbooks hw
                       ON ac.hist_workbook_id = hw.id
                   LEFT JOIN workbooks w
                       ON hw.workbook_id = w.id
                   LEFT JOIN hist_datasources hd
                       ON ac.hist_datasource_id = hd.id
                   LEFT JOIN datasources d
                       ON hd.datasource_id = d.id
                GROUP BY
                    COALESCE(d.owner_id, v.owner_id, w.owner_id)
            ) AS content_served
                ON u.id = content_served.content_owner_id