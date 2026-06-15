SELECT
    COUNT(DISTINCT da.id)       AS "alert_count" ,
    COUNT(dar.id)               AS "alert_recipient_count" ,
    da.view_id                  AS "item_id" ,
    'View'                      AS "item_type"
FROM data_alerts AS da
    INNER JOIN data_alerts_recipients AS dar
        ON da.id = dar.data_alert_id
GROUP BY da.view_id

UNION

SELECT
    COUNT(DISTINCT da.id)       AS "alert_count" ,
    COUNT(dar.id)               AS "alert_recipient_count" ,
    da.workbook_id              AS "item_id" ,
    'Workbook'                  AS "item_type"
FROM data_alerts AS da
    INNER JOIN data_alerts_recipients AS dar
        ON da.id = dar.data_alert_id
GROUP BY da.workbook_id