-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_otd_daterange
-- Captured: 2026-05-18T08:10:30Z
-- ==========================================================================

WITH PREP AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY a.DateID) AS RowNum
    FROM (
        SELECT
            bddfmap.DateID,
            bddfmap.RealCID,
            COUNT(bddfmap.RealCID) AS CountDeposits
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction bddfmap
        WHERE (bddfmap.ActionTypeID = 7 OR (bddfmap.ActionTypeID = 44 AND bddfmap.IsFTD = 1))
            AND bddfmap.FundingTypeID <> 33
        GROUP BY bddfmap.DateID, bddfmap.RealCID

        UNION ALL

        SELECT
            mfts.TxStatusModificationDateID AS DateID,
            mfts.CID AS RealCID,
            COUNT(mfts.CID) AS CountDeposits
        FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
        WHERE mfts.TxStatusID = 2
            AND mfts.TxTypeID IN (7, 14)
        GROUP BY mfts.TxStatusModificationDateID, mfts.CID
    ) a
),
FilteredRealCID AS (
    SELECT DISTINCT RealCID
    FROM PREP
    WHERE RowNum = 1 AND CountDeposits > 1
),
RankedDeposits AS (
    SELECT
        RealCID,
        DateID,
        CountDeposits,
        ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID) AS RowNum,
        COUNT(*) OVER (PARTITION BY RealCID) AS TotalRows
    FROM PREP
    WHERE RealCID NOT IN (SELECT RealCID FROM FilteredRealCID)
),
DATERANGE AS (
    SELECT
        RealCID,
        MIN(DateID) AS FromDateID,
        CASE
            WHEN MIN(TotalRows) = 1 THEN CAST(DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd') AS INT)
            WHEN MIN(CountDeposits) > 1 THEN MIN(DateID)
            ELSE COALESCE(MIN(CASE WHEN RowNum = 2 THEN DateID END), MIN(DateID))
        END AS ToDateID
    FROM RankedDeposits
    GROUP BY RealCID
)
SELECT * FROM DATERANGE
