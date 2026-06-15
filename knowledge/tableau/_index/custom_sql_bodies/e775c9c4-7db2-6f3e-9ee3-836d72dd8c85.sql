--summary statistics for collections
SELECT
    al.luid ,
    SUM (
        CASE
            WHEN ali.useable_type = 'Workbook'
                THEN 1
            ELSE 0
        END
    )                   AS "Collection Workbook Count" ,
    SUM (
        CASE
            WHEN ali.useable_type = 'View'
                THEN 1
            ELSE 0
        END
    )                   AS "Collection View Count" ,
    SUM (
        CASE
            WHEN ali.useable_type = 'Datasource'
                THEN 1
            ELSE 0
        END
    )                   AS "Collection Datasource Count" ,
    SUM (
        CASE
            WHEN ali.useable_type = 'Flow'
                THEN 1
            ELSE 0
        END
    )                   AS "Collection Flow Count" ,
    SUM (
        CASE
            WHEN ali.useable_type = 'Metric'
                THEN 1
            ELSE 0
        END
    )                   AS "Collection Metric Count" ,
    SUM(1)              AS "Collection Total Item Count"
FROM asset_lists al
    INNER JOIN asset_list_items ali
        ON al.id = ali.asset_list_id
WHERE al.list_type = 'collection'
GROUP BY
    al.luid