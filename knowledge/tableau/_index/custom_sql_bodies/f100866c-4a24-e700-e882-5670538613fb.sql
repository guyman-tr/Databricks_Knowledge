/*
Returns usage statistic for each applicable publishable item in Tableau Server
*/

WITH access_counts AS
(
    SELECT
        MAX(he.created_at)           AS last_access_date ,

        -- raw access counts
        COUNT(1)                     AS access_count_all_days ,
        SUM
        (
        CASE
            WHEN age(he.created_at) <= INTERVAL '180 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_180_days ,
        SUM
        (
        CASE
            WHEN age(he.created_at) <= INTERVAL '90 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_90_days ,
        SUM
        (
        CASE
            WHEN age(he.created_at) <= INTERVAL '30 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_30_days ,
        SUM
        (
        CASE
            WHEN age(he.created_at) <= INTERVAL '10 days' THEN 1
            ELSE 0
        END
        )                           AS access_count_last_10_days ,
        hu.user_id ,
        he.hist_datasource_id ,
        he.hist_view_id ,
        he.hist_metric_id
    FROM historical_events AS he
        LEFT JOIN hist_users hu
            ON he.hist_actor_user_id = hu.id
    WHERE he.historical_event_type_id IN (
            112,    --access datasource
            170,    --access datasource remotely
            84,     --access view
            290,    --access summary viewdata
            292,    --access underlying viewdata
            87,     --access authoring view (web edit)
                      --NOTE: event is only recorded if an existing view is opened via web edit, or if there's a save action on a net-new workbook.
                        --This won't catch users who open web authoring to play with published data, but who don't/can't save their work.
                        --(Thanks to Ryan Stryker for documenting this in Slack :) )
            --93,     --publish workbook
            --110,    --publish datasource
            113,    --download data source
            165,    --download data source revision
            183,    --download flow
            302,    --download flow draft
            86,     --download view
            99,     --download workbook
            164,    --download workbook revision
            291,    --export summary viewdata
            293,    --export underlying viewdata
            --120,    --add comment
            --181,    --publish flow
            280    --access metric
            --279     --create metric
            )
    GROUP BY
        hu.user_id ,
        he.hist_datasource_id ,
        he.hist_view_id ,
        he.hist_metric_id
)


-- view, data source, and metrics access counts
SELECT *
FROM (
    SELECT
        COALESCE(hv.view_id,
            hd.datasource_id,
            hm.metric_id)                           AS item_id ,
        CASE
            WHEN ac.hist_view_id IS NOT NULL
                THEN 'View'
            WHEN ac.hist_datasource_id IS NOT NULL 
                THEN 'Datasource'
            WHEN ac.hist_metric_id IS NOT NULL 
                THEN 'Metric'
            ELSE NULL
        END                                         AS content_type ,
        MAX(ac.last_access_date)                    AS last_access_date ,
        SUM(ac.access_count_all_days)               AS access_count_all_days ,
        SUM(ac.access_count_last_180_days)          AS access_count_last_180_days ,
        SUM(ac.access_count_last_90_days)           AS access_count_last_90_days ,
        SUM(ac.access_count_last_30_days)           AS access_count_last_30_days ,
        SUM(ac.access_count_last_10_days)           AS access_count_last_10_days ,
        COUNT(DISTINCT ac.user_id)                  AS access_count_unique_all_days ,
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
        LEFT JOIN hist_metrics hm
           ON ac.hist_metric_id = hm.id
    GROUP BY
        item_id ,
        content_type
) AS content_metrics

    --join aggregated metric metrics (Like what I did there? I'll be here all night, folks...) to other content metrics (just views, really)
    LEFT JOIN (
        SELECT
            COUNT(DISTINCT  m_met.id)                           AS metric_count ,
            MAX(ac_met.last_access_date)                        AS metric_last_access_date ,
            SUM(ac_met.access_count_all_days)                   AS metric_access_count_all_days ,
            SUM(ac_met.access_count_last_180_days)              AS metric_access_count_last_180_days ,
            SUM(ac_met.access_count_last_90_days)               AS metric_access_count_last_90_days ,
            SUM(ac_met.access_count_last_30_days)               AS metric_access_count_last_30_days ,
            SUM(ac_met.access_count_last_10_days)               AS metric_access_count_last_10_days ,
            COUNT(DISTINCT ac_met.user_id)                      AS metric_access_count_unique_all_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_180_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_180_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_90_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_90_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_30_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_30_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_10_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_10_days ,
            v_met.id                                            AS metric_view_id
        FROM access_counts ac_met
            LEFT JOIN hist_metrics hm_met
               ON ac_met.hist_metric_id = hm_met.id
            LEFT JOIN metrics m_met
                ON hm_met.metric_id = m_met.id
            LEFT JOIN customized_views cv_met
                ON m_met.customized_view_id = cv_met.id
            LEFT JOIN views v_met
                ON cv_met.view_id = v_met.id
        WHERE ac_met.hist_metric_id IS NOT NULL --we only need the metrics data
        GROUP BY
            metric_view_id
    ) AS metric_metrics
        ON content_metrics.item_id = metric_metrics.metric_view_id
            AND content_metrics.content_type = 'View'

UNION

SELECT *
FROM (
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
        COUNT(DISTINCT ac.user_id)                  AS access_count_unique_all_days ,
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
) AS content_metrics

    --join aggregated metric metrics (Like what I did there? I'll be here all night, folks...) to other content metrics (just views, really)
    LEFT JOIN (
        SELECT
            COUNT(DISTINCT  m_met.id)                           AS metric_count ,
            MAX(ac_met.last_access_date)                        AS metric_last_access_date ,
            SUM(ac_met.access_count_all_days)                   AS metric_access_count_all_days ,
            SUM(ac_met.access_count_last_180_days)              AS metric_access_count_last_180_days ,
            SUM(ac_met.access_count_last_90_days)               AS metric_access_count_last_90_days ,
            SUM(ac_met.access_count_last_30_days)               AS metric_access_count_last_30_days ,
            SUM(ac_met.access_count_last_10_days)               AS metric_access_count_last_10_days ,
            COUNT(DISTINCT ac_met.user_id)                      AS metric_access_count_unique_all_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_180_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_180_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_90_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_90_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_30_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_30_days ,
            COUNT(
                DISTINCT CASE
                    WHEN ac_met.access_count_last_10_days > 0
                        THEN ac_met.user_id
                    ELSE NULL
                    END
            )                                                   AS metric_access_count_unique_last_10_days ,
            v_met.workbook_id                                   AS metric_workbook_id
        FROM access_counts ac_met
            LEFT JOIN hist_metrics hm_met
               ON ac_met.hist_metric_id = hm_met.id
            LEFT JOIN metrics m_met
                ON hm_met.metric_id = m_met.id
            LEFT JOIN customized_views cv_met
                ON m_met.customized_view_id = cv_met.id
            LEFT JOIN views v_met
                ON cv_met.view_id = v_met.id
        WHERE ac_met.hist_metric_id IS NOT NULL --we only need the metrics data
        GROUP BY
            metric_workbook_id
    ) AS metric_metrics
        ON content_metrics.item_id = metric_metrics.metric_workbook_id
            AND content_metrics.content_type = 'Workbook'