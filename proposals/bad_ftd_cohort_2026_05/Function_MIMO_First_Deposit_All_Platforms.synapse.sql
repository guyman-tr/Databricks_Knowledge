/*
================================================================================
  PR: Extend REMOVE_BAD_FTDS to cover 2026-05-22, 23, 25 ($1 FTD synthetic cohort)
  Function: BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms
  Author:   Guy M
  Date:     2026-05-27

  Why:
    Companion change to Function_Population_First_Time_Funded - same six dates
    in the REMOVE_BAD_FTDS CTE keep MIMO outputs consistent with FTF.

    Cohort signature on the new dates:
      * 2026-05-22  -> 17,236 rows ($1.0000, FTDPlatformID=1, sequential
                       FTDTransactionID starting 76251759 at 05:33:05 UTC)
      * 2026-05-23  ->    470 rows
      * 2026-05-25  ->     10 rows

  Apply method:
    ALTER FUNCTION - full body re-create. Replace from "CREATE FUNCTION..."
    through the trailing parenthesis.
================================================================================
*/

ALTER FUNCTION [BI_DB_dbo].[Function_MIMO_First_Deposit_All_Platforms] (@OnlyValidCustomers [BIT])
RETURNS TABLE
AS RETURN (
/********************************************************************************************
    Author:      Guy Manova
    Date:        2024-09-25
    Description: single entry point:
        - For FTDs before 2025-09-01 = OLD logic (IBAN/TP union)
        - For FTDs on/after 2025-09-01 = NEW logic (Dim_Customer-driven)

    **************************
    ** Change History
    **************************
    Date            Author      Description
    2025-06-14      Guy M       added Trade From IBAN (44) & C2F edge case
    2025-09-13      Guy M       replaced old logic with Dim Customer (kept platform naming)
    2025-09-13      Guy M       added c2USD support
    2025-09-14      Guy M       combined old+new into one function with date routing
    2025-10-06      Guy M       added emoney fiat transactions "Created" to the order by
    2025-10-06      Guy M       options will show up as well with full integration of global ftd
    2025-10-26      Guy M       explicit try casts in the join to force ignoring of strings from options platform FTDTransactionID
    2025-11-23      Guy M       added the removal of "bad ftds" - the 13K wrongly identified, without hurting those that did legitimately make FTD later.
    2026-05-27      Guy M       extended REMOVE_BAD_FTDS to cover 2026-05-22, 2026-05-23, 2026-05-25 ($1 FTD synthetic cohort, ~17.7K rows, sequential FTDTransactionIDs on TP).
------------------------------------*/

/* -------------------------
   OLD LOGIC (valid for FTDs < 2025-09-01)
   ------------------------- */
WITH OLD_IBAN AS (
    SELECT
        a.RealCID,
        a.TransactionID AS DepositID,
        a.TxStatusModificationTime AS FirstDepositDate,
        a.USDAmountApprox        AS FirstDepositAmount,
        'eMoney'                 AS FTDPlatform,
        3                        AS FTDPlatformID,
        a.IsCryptoToFiat,
        a.IsIBANTrade,
        a.IsIBANQuickTransfer
    FROM (
        SELECT
            mfts.CID AS RealCID,
            mfts.TxStatusModificationTime,
            mfts.USDAmountApprox,
            mfts.TransactionID,
            ROW_NUMBER() OVER (PARTITION BY mfts.CID ORDER BY mfts.TxStatusModificationTime) AS RN,
            CASE WHEN mfts.TxTypeID = 14 THEN 1 ELSE 0 END AS IsCryptoToFiat,
            NULL AS IsIBANTrade,
            NULL AS IsIBANQuickTransfer
        FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
        WHERE mfts.MoneyMoveDirection = 'MoneyIn'
          AND mfts.TxStatusID = 2
          AND mfts.TxTypeID IN (7, 14)
    ) a
    WHERE a.RN = 1
),
OLD_TP AS (
    SELECT
        fca.RealCID,
        fca.DepositID,
        fca.Occurred       AS FirstDepositDate,
        fca.Amount         AS FirstDepositAmount,
        'TradingPlatform'  AS FTDPlatform,
        1                  AS FTDPlatformID,
        NULL               AS IsCryptoToFiat,
        CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END AS IsIBANTrade,
        CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE (fca.ActionTypeID = 7  AND fca.IsFTD = 1)
       OR (fca.ActionTypeID = 44 AND fca.IsFTD = 1)
),
OLD_COMBINED AS (
    SELECT * FROM OLD_IBAN
    UNION ALL
    SELECT * FROM OLD_TP
),
OLD_ORDERED AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY FirstDepositDate) AS RN
    FROM OLD_COMBINED
),
OLD_BASE AS (
    SELECT
        RealCID,
        DepositID,
        FirstDepositDate,
        FirstDepositAmount,
        FTDPlatform,
        FTDPlatformID,
        IsCryptoToFiat,
        IsIBANTrade,
        IsIBANQuickTransfer,
        CAST(0 AS BIT) AS IsC2USD
    FROM OLD_ORDERED
    WHERE RN = 1
      AND FirstDepositDate < DATEFROMPARTS(2025, 9, 1)
),

/* -------------------------
   NEW LOGIC (valid for FTDs >= 2025-09-01)
   ------------------------- */
NEW_IBAN AS (
    SELECT
        a.RealCID,
        a.TransactionID AS DepositID,
        a.IsCryptoToFiat,
        a.IsIBANTrade,
        a.IsIBANQuickTransfer,
        a.SourceCugTransactionID
    FROM (
        SELECT
            mfts.CID AS RealCID,
            mfts.TxStatusModificationTime,
            mfts.USDAmountApprox,
            mfts.TransactionID,
            ROW_NUMBER() OVER (PARTITION BY mfts.CID ORDER BY mfts.TxStatusModificationTime, eft.Created) AS RN,
            CASE WHEN mfts.TxTypeID = 14 THEN 1 ELSE 0 END AS IsCryptoToFiat,
            NULL AS IsIBANTrade,
            NULL AS IsIBANQuickTransfer,
            mfts.SourceCugTransactionID
        FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
        LEFT JOIN eMoney_dbo.FiatTransactions eft
            ON mfts.SourceCugTransactionID = eft.SourceCugTransactionId
        WHERE mfts.MoneyMoveDirection = 'MoneyIn'
          AND mfts.TxStatusID = 2
          AND mfts.TxTypeID IN (7, 14)
    ) a
    WHERE a.RN = 1
),
NEW_TP AS (
    SELECT
        fca.RealCID,
        fca.DepositID,
        NULL AS IsCryptoToFiat,
        CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END AS IsIBANTrade,
        CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE (fca.ActionTypeID = 7  AND fca.IsFTD = 1)
       OR (fca.ActionTypeID = 44 AND fca.IsFTD = 1)
),
C2USD AS (
    SELECT CID, fbd.DepositID
    FROM DWH_dbo.Fact_BillingDeposit fbd
    WHERE fbd.IsFTD = 1
      AND fbd.FundingTypeID = 27
),
DIMCUST AS (
    SELECT
        dc.RealCID,
        CASE
            WHEN dc.FTDPlatformID = 3 THEN ib.DepositID
            WHEN dc.FTDPlatformID = 1 THEN dc.FTDTransactionID
            ELSE NULL
        END AS DepositID,
        CASE
            WHEN dc.FTDPlatformID = 2 THEN NULL
            ELSE dc.FTDTransactionID
        END AS FTDTransactionID,
        dc.FirstDepositDate,
        dc.FirstDepositAmount,
        df.FTDPlatformName AS FTDPlatform,
        dc.FTDPlatformID,
        COALESCE(ib.IsCryptoToFiat, tp.IsCryptoToFiat)            AS IsCryptoToFiat,
        COALESCE(tp.IsIBANTrade,    ib.IsIBANTrade)               AS IsIBANTrade,
        COALESCE(ib.IsIBANQuickTransfer, tp.IsIBANQuickTransfer)  AS IsIBANQuickTransfer,
        CASE WHEN cus.DepositID IS NOT NULL THEN 1 ELSE 0 END     AS IsC2USD
    FROM DWH_dbo.Dim_Customer dc
    LEFT JOIN NEW_IBAN ib
        ON dc.RealCID = ib.RealCID
       AND TRY_CONVERT(BIGINT, dc.FTDTransactionID) = TRY_CONVERT(BIGINT, ib.SourceCugTransactionID)
       AND dc.FTDPlatformID = 3
    LEFT JOIN NEW_TP tp
        ON dc.RealCID = tp.RealCID
       AND TRY_CONVERT(BIGINT, ib.DepositID) = TRY_CONVERT(BIGINT, tp.DepositID)
    LEFT JOIN C2USD cus
        ON dc.RealCID = cus.CID
       AND TRY_CONVERT(BIGINT, tp.DepositID) = TRY_CONVERT(BIGINT, dc.FTDTransactionID)
       AND dc.FTDPlatformID = 1
    LEFT JOIN DWH_dbo.Dim_FTDPlatform df
        ON dc.FTDPlatformID = df.FTDPlatformID
),

REMOVE_BAD_FTDS AS (
    -- Wrongly tagged $1 FTDs to exclude. Nir S requested removal from DDR customer tables; added here for consistency.
    -- 2025-08-18..20: original ~13K cohort.
    -- 2026-05-22..23, 2026-05-25: ~17.7K rapid-fire sequential FTDTransactionID cohort on FTDPlatformID=1, all $1.0000, no follow-up deposits.
    SELECT
        dc.RealCID
    FROM DWH_dbo.Dim_Customer dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
            CONVERT(DATE, '20250818', 112),
            CONVERT(DATE, '20250819', 112),
            CONVERT(DATE, '20250820', 112),
            CONVERT(DATE, '20260522', 112),
            CONVERT(DATE, '20260523', 112),
            CONVERT(DATE, '20260525', 112)
        )
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID NOT IN (
            SELECT map.RealCID
            FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
            WHERE map.MIMOAction = 'Deposit'
            GROUP BY map.RealCID
            HAVING COUNT(map.RealCID) > 1
      )
),

NEW_BASE AS (
    SELECT
        RealCID,
        DepositID,
        FirstDepositDate,
        FirstDepositAmount,
        FTDPlatform,
        FTDPlatformID,
        IsCryptoToFiat,
        IsIBANTrade,
        IsIBANQuickTransfer,
        IsC2USD
    FROM DIMCUST
    WHERE FirstDepositDate >= DATEFROMPARTS(2025, 9, 1)
),

/* -------------------------
   UNION the routed bases, then common joins
   ------------------------- */
BASE AS (
    SELECT * FROM OLD_BASE
    UNION ALL
    SELECT * FROM NEW_BASE
),
FINAL AS (
    SELECT
         b.RealCID
       , b.DepositID
       , b.FirstDepositDate
       , b.FirstDepositAmount
       , b.FTDPlatform
       , b.FTDPlatformID
       , b.IsCryptoToFiat
       , b.IsIBANTrade
       , b.IsIBANQuickTransfer
       , b.IsC2USD
       , fsc.GCID
       , fsc.DemoCID
       , fsc.CustomerChangeTypeID
       , fsc.CurentValue
       , fsc.PreviousValue
       , fsc.CountryID
       , fsc.LabelID
       , fsc.LanguageID
       , fsc.VerificationLevelID
       , fsc.DocsOK
       , fsc.PlayerStatusID
       , fsc.Bankruptcy
       , fsc.RiskStatusID
       , fsc.RiskClassificationID
       , fsc.CommunicationLanguageID
       , fsc.PremiumAccount
       , fsc.Evangelist
       , fsc.GuruStatusID
       , fsc.UpdateDate
       , fsc.RegulationID
       , fsc.AccountStatusID
       , fsc.AccountManagerID
       , fsc.PlayerLevelID
       , fsc.AccountTypeID
       , fsc.DateRangeID
       , fsc.IsDepositor
       , fsc.PendingClosureStatusID
       , fsc.DocumentStatusID
       , fsc.SuitabilityTestStatusID
       , fsc.MifidCategorizationID
       , fsc.IsEmailVerified
       , fsc.IsValidCustomer
       , fsc.DesignatedRegulationID
       , fsc.EvMatchStatus
       , fsc.RegionID
       , fsc.PlayerStatusReasonID
       , fsc.IsCreditReportValidCB
       , fsc.AffiliateID
       , fsc.Email
       , fsc.City
       , fsc.Address
       , fsc.Zip
       , fsc.PhoneNumber
       , fsc.IsPhoneVerified
       , fsc.PhoneVerificationDateID
       , fsc.PlayerStatusSubReasonID
    FROM BASE b
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc
      ON b.RealCID = fsc.RealCID
    JOIN DWH_dbo.Dim_Range dr
      ON fsc.DateRangeID = dr.DateRangeID
     AND CAST(FORMAT(CAST(b.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT)
         BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE (@OnlyValidCustomers = 0 OR fsc.IsValidCustomer = @OnlyValidCustomers)
      AND b.RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)
)
SELECT * FROM FINAL
WHERE (@OnlyValidCustomers = 0)
   OR (@OnlyValidCustomers = 1 AND IsValidCustomer = 1)
   OR (@OnlyValidCustomers = 1 AND IsValidCustomer = 0)  -- (kept to mirror original)
);
GO
