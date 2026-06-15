/*
Returns one row for combination of
    every datasource, workbooks, or workbook view in the Tableau Server instance
    and
    Users with permissions to view the metadata on said content

The permissions column is used as a data source filter against the current Server user to enforce
    row-level access restrictions.

Cardinality defined by:
    "Repository URL"
    "View Workbook Repository URL"
    "Project Access System Name"

*/


with access_counts as
(
    SELECT
        MAX(he.created_at)           AS last_access_date ,

        -- raw access counts
        COUNT(1)                     AS access_count_all_days ,
        SUM
        (
        CASE
            WHEN max_date.max_event_date - he.created_at <= INTERVAL '180 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_180_days ,
        SUM
        (
        CASE
            WHEN max_date.max_event_date - he.created_at <= INTERVAL '90 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_90_days ,
        SUM
        (
        CASE
            WHEN max_date.max_event_date - he.created_at <= INTERVAL '30 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_30_days ,
        SUM
        (
        CASE
            WHEN max_date.max_event_date - he.created_at <= INTERVAL '10 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_10_days ,
        hu.user_id ,
        he.hist_datasource_id ,
        he.hist_view_id
    FROM historical_events he
        INNER JOIN (
            SELECT      MAX(created_at) AS max_event_date
            FROM        historical_events
        ) AS max_date
            ON 1 = 1
        LEFT JOIN hist_users hu
            ON he.hist_actor_user_id = hu.id
    WHERE he.historical_event_type_id IN (112, 84)
    GROUP BY
        hu.user_id ,
        he.hist_datasource_id ,
        he.hist_view_id
)


-- view and data source access counts
SELECT
    COALESCE(hv.view_id,
        hd.datasource_id)                       AS item_id ,
    CASE
        WHEN ac.hist_view_id IS NOT NULL
            THEN 'View'
        WHEN ac.hist_datasource_id IS NOT NULL 
            THEN 'Datasource'
        ELSE NULL
    END                                         AS content_type ,
    MAX(ac.last_access_date)                    AS last_access_date ,
    SUM(ac.access_count_all_days)               AS access_count_all_days ,
    SUM(ac.access_count_last_180_days)          AS access_count_last_180_days ,
    SUM(ac.access_count_last_90_days)           AS access_count_last_90_days ,
    SUM(ac.access_count_last_30_days)           AS access_count_last_30_days ,
    SUM(ac.access_count_last_10_days)           AS access_count_last_10_days ,
    COUNT(DISTINCT ac.user_id)       AS access_count_unique_all_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_180_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_180_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_90_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_90_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_30_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_30_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_10_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_10_days
FROM access_counts ac
   LEFT JOIN hist_views hv
       ON ac.hist_view_id = hv.id
   LEFT JOIN hist_datasources hd
       ON ac.hist_datasource_id = hd.id
GROUP BY
    item_id ,
    content_type

UNION

-- workbook access counts
SELECT
    v.workbook_id                               AS item_id ,
    'Workbook'                                  AS content_type ,
    MAX(ac.last_access_date)                    AS last_access_date ,
    SUM(ac.access_count_all_days)               AS access_count_all_days ,
    SUM(ac.access_count_last_180_days)          AS access_count_last_180_days ,
    SUM(ac.access_count_last_90_days)           AS access_count_last_90_days ,
    SUM(ac.access_count_last_30_days)           AS access_count_last_30_days ,
    SUM(ac.access_count_last_10_days)           AS access_count_last_10_days ,
    COUNT(DISTINCT ac.user_id)       AS access_count_unique_all_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_180_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_180_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_90_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_90_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_30_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_30_days ,
    COUNT(
        DISTINCT CASE
            WHEN ac.access_count_last_10_days > 0
                THEN ac.user_id
            ELSE NULL
            END
    )                                           AS access_count_unique_last_10_days
FROM access_counts ac
   INNER JOIN hist_views hv
       ON ac.hist_view_id = hv.id
   INNER JOIN views v
       ON hv.view_id = v.id
GROUP BY
    item_id ,
    content_type