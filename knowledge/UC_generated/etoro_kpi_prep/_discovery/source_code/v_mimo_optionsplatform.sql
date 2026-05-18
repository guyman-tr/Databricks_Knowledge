-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_mimo_optionsplatform
-- Captured: 2026-05-18T08:06:36Z
-- ==========================================================================

WITH MIMORecords AS (
    SELECT DISTINCT
        ca.OfficeCode,
        ca.AccountNumber,
        ca.RegisteredRepCode,
        CAST(DATE_FORMAT(ca.ProcessDate, 'yyyyMMdd') AS INT) AS DateID,
        ca.ProcessDate AS Date,
        dc.RealCID,
        ca.PayTypeCode,
        ca.ACATSControlNumber AS TransactionID,
        ABS(CAST(ca.Amount AS DECIMAL(19,4))) AS AmountUSD,
        CASE 
            WHEN ca.TerminalID = 'OMJNL' THEN 42 
            WHEN ca.EnteredBy = 'ACH' THEN 29 
            WHEN ca.EnteredBy = 'WRD' THEN 2 
        END AS FundingTypeID,
        CASE 
            WHEN ca.TerminalID = 'OMJNL' THEN 1 
            ELSE 0 
        END AS IsInternalTransfer
    FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca 
    JOIN main.general.bronze_usabroker_apex_options op 
        ON ca.AccountNumber = op.OptionsApexID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
        ON op.GCID = dc.GCID
    WHERE 
        ca.OfficeCode IN ('4GS', '5GU')  
        AND ca.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
        AND (ca.EnteredBy IN ('ACH','WRD') OR ca.TerminalID = 'OMJNL')
),

-- Step 2: Deduplicate deposits for FTD join
DEPOSIT_UNIQUE_FOR_FTDJOIN AS (
    SELECT DateID, FTDDate, RealCID, FTDAmount
    FROM (
        SELECT 
            DateID,
            Date AS FTDDate,
            RealCID,
            AmountUSD AS FTDAmount,
            ROW_NUMBER() OVER (PARTITION BY RealCID, DateID, AmountUSD ORDER BY DateID) AS RN
        FROM MIMORecords
        WHERE PayTypeCode = 'C' AND IsInternalTransfer = 0
    ) a
    WHERE RN = 1
),

-- Step 3: Global FTD detection via Dim_Customer
GLOBAL_FTD AS (
    SELECT gd.*,
        CASE WHEN dc_ftd.RealCID IS NOT NULL THEN 1 ELSE 0 END AS IsGlobalFTD
    FROM DEPOSIT_UNIQUE_FOR_FTDJOIN gd
    LEFT JOIN (
        SELECT 
            RealCID,
            CAST(FirstDepositDate AS DATE) AS DCFTDDate,
            FirstDepositAmount AS DCFTDAmount 
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
        WHERE FirstDepositDate >= '2025-09-01'
          AND FTDPlatformID = '2'
    ) dc_ftd
      ON gd.RealCID = dc_ftd.RealCID
     AND gd.FTDAmount = dc_ftd.DCFTDAmount
     AND gd.FTDDate = dc_ftd.DCFTDDate
),

-- Step 4: FINRA-only first deposit date per account
FINRAONLY_ftd_date AS (
    SELECT AccountNumber, MIN(Date) AS FTDDate
    FROM MIMORecords
    WHERE PayTypeCode = 'C' 
        AND IsInternalTransfer = 0
        AND RegisteredRepCode = 'FO1'
    GROUP BY AccountNumber
),

-- Step 5: FINRA-only FTD records
FINRAONLY_FTD_records AS (
    SELECT DISTINCT
        mr.AccountNumber, 
        mr.Date, 
        mr.TransactionID,
        mr.RealCID
    FROM MIMORecords mr
    JOIN FINRAONLY_ftd_date fd 
        ON mr.AccountNumber = fd.AccountNumber 
       AND mr.Date = fd.FTDDate
    WHERE 
        mr.PayTypeCode = 'C'
        AND mr.IsInternalTransfer = 0
),

-- Step 6: Single-transaction FTDs
FTDSingle AS (
    SELECT f.*
    FROM FINRAONLY_FTD_records f
    JOIN (
        SELECT AccountNumber, RealCID
        FROM FINRAONLY_FTD_records
        GROUP BY AccountNumber, RealCID
        HAVING COUNT(*) = 1
    ) s 
    ON f.AccountNumber = s.AccountNumber
),

-- Step 7: Multi-transaction FTDs (pick first by TransactionID)
FTDMultiple AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f.AccountNumber ORDER BY f.TransactionID) AS rn
    FROM FINRAONLY_FTD_records f
    WHERE f.AccountNumber IN (
        SELECT AccountNumber
        FROM FINRAONLY_FTD_records
        GROUP BY AccountNumber
        HAVING COUNT(*) > 1
    )
),

-- Step 8: Combined FTD with global flag
FinalFTD AS (
    SELECT rns.*, COALESCE(gftd.IsGlobalFTD, 0) AS IsGlobalFTD
    FROM (
        SELECT AccountNumber, Date, TransactionID, RealCID
        FROM FTDSingle
        UNION ALL
        SELECT AccountNumber, Date, TransactionID, RealCID
        FROM FTDMultiple
        WHERE rn = 1
    ) rns
    LEFT JOIN GLOBAL_FTD gftd
        ON rns.RealCID = gftd.RealCID AND gftd.IsGlobalFTD = 1
)

-- Step 9: Final output
SELECT DISTINCT
    mr.OfficeCode,
    mr.RegisteredRepCode,
    mr.AccountNumber,
    mr.DateID,
    mr.Date,
    dc.RealCID,
    CASE 
        WHEN mr.PayTypeCode = 'C' THEN 'Deposit' 
        WHEN mr.PayTypeCode = 'D' THEN 'Withdraw'
    END AS MIMOAction,
    mr.AmountUSD,
    mr.FundingTypeID,
    CASE 
        WHEN f.TransactionID IS NOT NULL THEN 1
        ELSE 0
    END AS IsFTD,
    mr.IsInternalTransfer,
    mr.TransactionID,
    COALESCE(f.IsGlobalFTD, 0) AS IsGlobalFTD,
    dc.IsValidCustomer,
    dc.IsCreditReportValidCB
FROM MIMORecords mr
JOIN main.general.bronze_usabroker_apex_options op 
    ON mr.AccountNumber = op.OptionsApexID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    ON op.GCID = dc.GCID
LEFT JOIN FinalFTD f 
    ON f.AccountNumber = mr.AccountNumber
   AND f.Date = mr.Date
   AND f.TransactionID = mr.TransactionID
