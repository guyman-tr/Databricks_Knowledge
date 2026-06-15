USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.KYS_TablesWithSmallCompressedRowGroups(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



WITH 
    cte_All_RowGroups AS (
        SELECT  `Schema_Name`, 
                `Table_Name`,
                Distribution_type,
                COUNT(*) AS rg_compressed_count_total
            FROM `dbo`.`v_CCI_MetaData`
            WHERE rg_state = 3
            GROUP BY `Schema_Name`, `Table_Name`, Distribution_type ),

    cte_Compressed_RowGroups AS (
        SELECT  `Schema_Name`, 
                `Table_Name`,
                rg_trim_reason      as trim_reason,
                rg_trim_reason_desc as trim_reason_desc,
                COUNT(*)            as trim_reason_rg_count
            FROM `dbo`.`v_CCI_MetaData`
            WHERE rg_state = 3
            GROUP BY `Schema_Name`, `Table_Name`, rg_trim_reason, rg_trim_reason_desc )

SELECT  
        current_timestamp() as `Collection_Date`,
        current_database(),
        a.*,
        c.trim_reason,
        c.trim_reason_desc,
        c.trim_reason_rg_count
    FROM cte_All_RowGroups a
        LEFT OUTER JOIN cte_Compressed_RowGroups c
            ON  a.`Schema_Name` = c.`Schema_Name`
            AND a.`Table_Name`  = c.`Table_Name`
    ORDER BY a.`Schema_Name`, a.`Table_Name`, c.trim_reason


;

END;
