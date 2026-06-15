-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_First_Time_Funded
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_population_first_time_funded
-- Col comments: 18 added, 0 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_first_time_funded (
  RealCID COMMENT 'Direct (via DWH_FTD). Source: Dim_Customer.RealCID. (T1 - Function_Population_First_Time_Funded)',
  FTDPlatformID COMMENT 'Direct pass-through from Dim_Customer.FTDPlatformID. (T1 - Function_Population_First_Time_Funded)',
  FTDPlatform COMMENT 'COALESCE(FTDPlatformName, ''TP''). Source: Dim_FTDPlatform.FTDPlatformName. (T2 - Function_Population_First_Time_Funded)',
  FTDDateID COMMENT 'CAST(CONVERT(VARCHAR(8), FirstDepositDate, 112) AS INT). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FTDDate COMMENT 'CAST(FirstDepositDate AS DATE). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FTDTime COMMENT 'Same timestamp as FTD column (first deposit). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeDateID COMMENT 'MIN(OpenDateID) WHERE ISNULL(IsAirDrop,0) = 0, grouped by CID AS RealCID. Source: Dim_Position.OpenDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), MIN(OpenDateID)), 112) under same non-airdrop position filter as row 7. Source: Dim_Position.OpenDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeTime COMMENT 'MIN(OpenOccurred) under same non-airdrop position filter as row 7. Source: Dim_Position.OpenOccurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBDateID COMMENT 'MIN(CAST(FORMAT(CAST(Occurred AS DATE), ''yyyyMMdd'') AS INT)) where ActionTypeID = 36 and CompensationReasonID = 57. Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBDate COMMENT 'CAST(MIN(Occurred) AS DATE). Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBTime COMMENT 'MIN(Occurred). Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstOptionsTradeDateID COMMENT 'MIN(FirstTradeDateID) by RealCID. Source: Function_Revenue_OptionsPlatform.FirstTradeDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstOptionsTradeDate COMMENT 'MIN(FirstTradeDate). Source: Function_Revenue_OptionsPlatform.FirstTradeDate. (T2 - Function_Population_First_Time_Funded)',
  FirstVerifiedDateID COMMENT 'MIN(FromDateID) where VerificationLevelID = 3 on snapshot. Source: Dim_Range.FromDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstVerifiedDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), MIN(FromDateID)), 112). Source: Dim_Range.FromDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstFundedDateID COMMENT 'GREATEST(FTDDateID, FirstVerifiedDateID, COALESCE(LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID), COALESCE(...))). Source: Dim_Customer, Dim_Range, Dim_Position, Fact_CustomerAction, Function_Revenue_OptionsPlatform. (T2 - Function_Population_First_Time_Funded)',
  FirstFundedDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), FirstFundedDateID), 112). Source: (same as row 17). (T2 - Function_Population_First_Time_Funded)'
)
COMMENT 'BI_DB_dbo.Function_Population_First_Time_Funded > For depositors with a warehouse FTD (excluding a curated “bad FTD” set), joins first verified snapshot range and left-joins first trade, first IOB (interest-on-balance), and first options trade. Computes a single FirstFundedDateID/Date as the latest of FTD, verification, and the earliest qualifying trading/options/IOB activity.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Population_First_Time_Funded > For depositors with a warehouse FTD (excluding a curated “bad FTD” set), joins first verified snapshot range and left-joins first trade, first IOB (interest-on-balance), and first options trade. Computes a single FirstFundedDateID/Date as the latest of FTD, verification, and the earliest qualifying trading/options/IOB activity.')
WITH SCHEMA COMPENSATION
AS WITH First_IOB AS (
    SELECT
        RealCID,
        MIN(Occurred) AS FirstIOBTime,
        CAST(MIN(Occurred) AS DATE) AS FirstIOBDate,
        MIN(CAST(DATE_FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT)) AS FirstIOBDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    WHERE ActionTypeID = 36
      AND CompensationReasonID = 57
    GROUP BY RealCID
),
REMOVE_BAD_FTDS AS (
    -- Wrongly tagged $1 FTDs to exclude from all FTF/MIMO outputs.
    -- 2025-08-18..20: original Nir S exclusion (~13K synthetic FTDs).
    -- 2026-05-22..23, 2026-05-25: rapid-fire sequential FTDTransactionID cohort on FTDPlatformID=1
    --   (17,236 + 470 + 10 rows, all $1.0000, no follow-up deposits). Same script signature
    --   as Aug 2025 incident. Added 2026-05-27 by Guy M.
    SELECT
        dc.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
        TO_DATE('20250818', 'yyyyMMdd'),
        TO_DATE('20250819', 'yyyyMMdd'),
        TO_DATE('20250820', 'yyyyMMdd'),
        TO_DATE('20260522', 'yyyyMMdd'),
        TO_DATE('20260523', 'yyyyMMdd'),
        TO_DATE('20260525', 'yyyyMMdd')
    )
    AND dc.FirstDepositAmount = 1
    AND dc.RealCID NOT IN (
        SELECT map.RealCID
        FROM main.etoro_kpi_prep.v_mimo_allplatforms map
        WHERE map.MIMOAction = 'Deposit'
        GROUP BY map.RealCID
        HAVING COUNT(map.RealCID) > 1
    )
),
DWH_FTD AS (
    SELECT
        ftd.FTDPlatformID,
        ftd.Name as FTDPlatform,
        dc.RealCID,
        dc.FirstDepositDate AS FTDTime,
        CAST(dc.FirstDepositDate AS DATE) AS FTDDate,
        CAST(DATE_FORMAT(dc.FirstDepositDate, 'yyyyMMdd') AS INT) AS FTDDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN main.etoro_kpi_prep.v_globalftdplatform ftd
        ON ftd.FTDPlatformID = dc.FTDPlatformID
    WHERE dc.IsDepositor = 1
      AND dc.RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)
),
Verification AS (
    SELECT
        fsc.RealCID,
        TO_DATE(CAST(MIN(fsc.FromDateID) AS STRING), 'yyyyMMdd') AS FirstVerifiedDate,
        MIN(fsc.FromDateID) AS FirstVerifiedDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    WHERE fsc.VerificationLevelID = 3
    GROUP BY fsc.RealCID
),
Trade AS (
    SELECT
        CID AS RealCID,
        MIN(OpenOccurred) AS FirstTradeTime,
        TO_DATE(CAST(MIN(OpenDateID) AS STRING), 'yyyyMMdd') AS FirstTradeDate,
        MIN(OpenDateID) AS FirstTradeDateID
    FROM main.dwh.dim_position
    WHERE IFNULL(IsAirDrop, 0) = 0
    GROUP BY CID
),
OptionsTrade AS (
    SELECT
        op.RealCID,
        MIN(op.FirstTradeDate) AS FirstOptionsTradeDate,
        MIN(op.FirstTradeDateID) AS FirstOptionsTradeDateID
    FROM main.etoro_kpi_prep.v_revenue_optionsplatform op
    GROUP BY op.RealCID
)
SELECT
    f.RealCID,

    -- FTD
    f.FTDPlatformID,
    f.FTDPlatform,
    f.FTDDateID,
    f.FTDDate,
    f.FTDTime,

    -- Trades & Activities
    t.FirstTradeDateID,
    t.FirstTradeDate,
    t.FirstTradeTime,
    iob.FirstIOBDateID,
    iob.FirstIOBDate,
    iob.FirstIOBTime,
    ot.FirstOptionsTradeDateID,
    ot.FirstOptionsTradeDate,

    -- Verification
    v.FirstVerifiedDateID,
    v.FirstVerifiedDate,

    -- First Funded (Latest of FTD, Activity, Verification)
    GREATEST(
        f.FTDDateID,
        v.FirstVerifiedDateID,
        COALESCE(
            LEAST(
                t.FirstTradeDateID,
                iob.FirstIOBDateID,
                ot.FirstOptionsTradeDateID
            ),
            COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
        )
    ) AS FirstFundedDateID,

    TO_DATE(
        CAST(
            GREATEST(
                f.FTDDateID,
                v.FirstVerifiedDateID,
                COALESCE(
                    LEAST(
                        t.FirstTradeDateID,
                        iob.FirstIOBDateID,
                        ot.FirstOptionsTradeDateID
                    ),
                    COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
                )
            ) AS STRING
        ),
        'yyyyMMdd'
    ) AS FirstFundedDate

FROM DWH_FTD f
INNER JOIN Verification v
    ON f.RealCID = v.RealCID
LEFT JOIN Trade t
    ON f.RealCID = t.RealCID
LEFT JOIN First_IOB iob
    ON f.RealCID = iob.RealCID
LEFT JOIN OptionsTrade ot
    ON f.RealCID = ot.RealCID

WHERE 
    (t.FirstTradeDateID IS NOT NULL
     OR iob.FirstIOBDateID IS NOT NULL
     OR ot.FirstOptionsTradeDateID IS NOT NULL)

;
