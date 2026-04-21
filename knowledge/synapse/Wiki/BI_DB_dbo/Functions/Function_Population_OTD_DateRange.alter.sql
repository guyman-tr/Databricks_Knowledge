-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_OTD_DateRange
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_population_otd_daterange
-- Col comments: 2 added, 1 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_otd_daterange (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  FromDateID COMMENT 'MIN(DateID) over RankedDeposits (per-customer deposit timeline after filters). Source: Fact_CustomerAction.DateID, eMoney_Fact_Transaction_Status.TxStatusModificationDateID. (T2 — Function_Population_OTD_DateRange)',
  ToDateID COMMENT 'CASE WHEN MIN(TotalRows)=1 THEN CAST(FORMAT(CAST(GETDATE() AS DATE), ''yyyyMMdd'') AS INT) WHEN MIN(CountDeposits)>1 THEN MIN(DateID) ELSE COALESCE(MIN(CASE WHEN RowNum=2 THEN DateID END), MIN(DateID)) END — encodes single-depositor-open-ended vs multi-on-first-day vs second-deposit end. Source: Fact_CustomerAction, eMoney_Fact_Transaction_Status. (T2 — Function_Population_OTD_DateRange)'
)
COMMENT 'BI_DB_dbo.Function_Population_OTD_DateRange > Builds, per customer, the date range where “one-time depositor” (OTD) status applies. Deposit events (TP): Fact_CustomerAction grouped by DateID, RealCID WHERE ActionTypeID = 7 OR (ActionTypeID = 44 AND IsFTD = 1) AND FundingTypeID <> 33. Deposit events (eMoney): eMoney_Fact_Transaction_Status WHERE TxStatusID = 2 (settled) AND TxTypeID IN (7, 14), grouped by TxStatusModificationDateID, CID. Unioned daily counts are ranked by DateID; customers whose first row already has CountDeposits > 1 are excluded. ToDateID logic: if only one deposit day ever → today’s DateID; if first day had multiple deposits in branch → MIN(DateID); else second deposit DateID or fallback MIN(DateID).'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Population_OTD_DateRange > Builds, per customer, the date range where “one-time depositor” (OTD) status applies. Deposit events (TP): Fact_CustomerAction grouped by DateID, RealCID WHERE ActionTypeID = 7 OR (ActionTypeID = 44 AND IsFTD = 1) AND FundingTypeID <> 33. Deposit events (eMoney): eMoney_Fact_Transaction_Status WHERE TxStatusID = 2 (settled) AND TxTypeID IN (7, 14), grouped by TxStatusModificationDateID, CID. Unioned daily counts are ranked by DateID; customers whose first row already has CountDeposits > 1 are excluded. ToDateID logic: if only one deposit day ever → today’s DateID; if first day had multiple deposits in branch → MIN(DateID); else second deposit DateID or fallback MIN(DateID).')
WITH SCHEMA COMPENSATION
AS WITH PREP AS (
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

;
