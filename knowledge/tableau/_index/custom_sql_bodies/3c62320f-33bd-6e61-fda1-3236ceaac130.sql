/*
Return one row per user, assembling counts of consumed resources for each

X Subscriptions
X Alerts
X Scheduled Extract Refreshes
X Subscriptions To Content
    for workbooks and views that this user owns:
        how many unique users are subscribed to them?
        how many total subscriptions exist on them?
X Alerts on Content
    x for views that this user owns:
        x how many unique users are set up to receive alerts based on them?
        x how many total alerts exist on them?
*/


SELECT
    u.id                        AS user_id ,
    COALESCE(alerts_created.alerts_created, 0)
                                AS alerts_created ,
    COALESCE(alerts_subscribed.alerts_subscribed, 0)
                                AS alerts_subscribed ,
    COALESCE(alerts_created.alerts_others_subscribed, 0)
                                AS alerts_others_subscribed ,
    COALESCE(alerts_on_content.alerted_unique_users_on_content, 0)
                                AS alerted_unique_users_on_content ,
    COALESCE(alerts_on_content.alerts_total_on_content, 0)
                                AS alerts_total_on_content ,
    COALESCE(subscriptions_created.subscriptions_created, 0)
                                AS subscriptions_created ,
    COALESCE(subscriptions_subscribed_to.subscriptions_subscribed_to, 0)
                                AS subscriptions_subscribed_to ,
    COALESCE(scheduled_extracts_on_content.scheduled_extracts_count_on_content, 0)
                                AS scheduled_extracts_count_on_content ,
    COALESCE(subscriptions_on_content.subscriptions_total_on_content, 0)
                                AS subscriptions_total_on_content ,
    COALESCE(subscriptions_on_content.subscriptions_unique_subscribers_on_content, 0)
                                AS subscriptions_unique_subscribers_on_content

FROM 
    users AS u

    -- alerts created
    LEFT JOIN
    (
    SELECT
        da.creator_id            AS alerts_creator_id ,
        COUNT(DISTINCT da.id)    AS alerts_created ,
        COUNT(dar.id)            AS alerts_others_subscribed
    FROM data_alerts da
        LEFT JOIN data_alerts_recipients dar
            ON da.id = dar.data_alert_id
    GROUP BY
        da.creator_id
    ) as alerts_created
        ON u.id = alerts_created.alerts_creator_id

    -- alerts subscribed to
    LEFT JOIN
        (
        SELECT
            dar.recipient_id                    AS alerts_subscriber_id ,
            COUNT(DISTINCT dar.data_alert_id)
                                                AS alerts_subscribed
        FROM data_alerts_recipients dar
        GROUP BY
            dar.recipient_id
        ) as alerts_subscribed
            ON u.id = alerts_subscribed.alerts_subscriber_id

    -- alerts on content they own
    LEFT JOIN
        (
        SELECT
            v.owner_id                          AS alerts_on_content_owner_id ,
            COUNT(DISTINCT dar.recipient_id)    AS alerted_unique_users_on_content ,
            COUNT(da.id)                        AS alerts_total_on_content
        FROM data_alerts da
            INNER JOIN views v
                ON da.view_id = v.id
            LEFT JOIN data_alerts_recipients dar
                ON da.id = dar.data_alert_id
            
        GROUP BY
            v.owner_id
        ) as alerts_on_content
            ON u.id = alerts_on_content.alerts_on_content_owner_id

    -- subscriptions created
    LEFT JOIN
        (
        SELECT
            s.creator_id                        AS subscriptions_creator_id ,
            COUNT(s.id)                         AS subscriptions_created
        FROM subscriptions s
        GROUP BY
            s.creator_id
        ) as subscriptions_created
            ON u.id = subscriptions_created.subscriptions_creator_id

    -- subscriptions subscribed to
    LEFT JOIN
        (
        SELECT
            s.user_id                           AS subscriptions_subscriber_id ,
            COUNT(s.id)                         AS subscriptions_subscribed_to
        FROM subscriptions s
        GROUP BY
            s.user_id
        ) as subscriptions_subscribed_to
            ON u.id = subscriptions_subscribed_to.subscriptions_subscriber_id

    -- refreshes on content they own
    LEFT JOIN
        (
        SELECT
            content.owner_id                    AS scheduled_extracts_on_content_owner_id ,
            COUNT(t.id)                         AS scheduled_extracts_count_on_content
        FROM tasks t
            INNER JOIN 
                (
                SELECT
                    w.id            AS obj_id ,
                    'Workbook'      AS obj_type ,
                    w.owner_id
                FROM workbooks w
                UNION
                SELECT
                    d.id            AS obj_id ,
                    'Datasource'    AS obj_type ,
                    d.owner_id
                FROM datasources d
                WHERE d.connectable = true  -- only published data sources can have extracts refreshed. embedded data sources in workbooks are scheduled as workbook
                ) AS content
                    ON t.obj_id = content.obj_id
                        AND t.obj_type = content.obj_type
        WHERE t.type IN ('RefreshExtractTask', 'IncrementExtractTask')
        GROUP BY
            content.owner_id
        ) as scheduled_extracts_on_content
            ON u.id = scheduled_extracts_on_content.scheduled_extracts_on_content_owner_id

            -- subscriptions on content they own
        LEFT JOIN
            (
            SELECT
                            COALESCE (
                                    s_v.owner_id ,
                                    sv_w.owner_id ,
                                    s_w.owner_id
                                    )                        AS subscriptions_on_content_owner_id ,
                            COUNT(s.id)                      AS subscriptions_total_on_content ,
                            COUNT(DISTINCT s.user_id)        AS subscriptions_unique_subscribers_on_content
            FROM _subscriptions s
                LEFT JOIN tasks t
                    ON  s.id = t.obj_id
                        AND t.type = 'SingleSubscriptionTask'
                LEFT JOIN views s_v
                    ON s.view_url = REPLACE(s_v.repository_url, 'sheets/','')
                LEFT JOIN workbooks sv_w
                    ON s_v.workbook_id = sv_w.id
                LEFT JOIN workbooks s_w
                    ON s.workbook_url = s_w.repository_url
                    WHERE COALESCE(s_v.id, s_w.id, sv_w.id, s.customized_view_id) IS NOT NULL
                    GROUP BY
                            COALESCE (
                                    s_v.owner_id ,
                                    sv_w.owner_id ,
                                    s_w.owner_id
                                    )
            ) AS subscriptions_on_content
                            ON u.id = subscriptions_on_content.subscriptions_on_content_owner_id