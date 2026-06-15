/*
================================================================================
  PR: Extend REMOVE_BAD_FTDS to cover 2026-05-22, 23, 25 ($1 FTD synthetic cohort)
  Function: BI_DB_dbo.Function_Population_First_Time_Funded
  Author:   Guy M
  Date:     2026-05-27

  Why:
    A new synthetic-FTD cohort appeared in Dim_Customer matching the same
    signature as the 2025-08-18..20 incident already excluded by Nir S:
      * 2026-05-22  -> 17,236 rows ($1.0000, FTDPlatformID=1)
      * 2026-05-23  ->    470 rows
      * 2026-05-25  ->     10 rows
    All on TradingPlatform with sequential FTDTransactionIDs starting
    76251759 at 2026-05-22 05:33:05 UTC, no follow-up deposits in MIMO.
    Verified via the same "NOT IN repeat-depositors" guard as the original:
    99.8%+ have no second deposit.

  Companion change:
    BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms also has its
    REMOVE_BAD_FTDS CTE extended with the same date list.

  Apply method:
    ALTER FUNCTION (Synapse TVF is INLINE - drop & recreate or ALTER).
    Below is the full body re-create. Replace from "CREATE FUNCTION..." through
    the trailing parenthesis.
================================================================================
*/

ALTER FUNCTION [BI_DB_dbo].[Function_Population_First_Time_Funded] ()
RETURNS TABLE
AS RETURN (
/**************************************
Start Main Comment History
******************************************************
Author:      Guy Manova
Date:        2025-08-20
Description: Function to determine the FTF (First-Time-Funded) date of each user.

**************************
** Change History
**************************
Date            Author      Description
2025-08-20      Guy M       Added IOB (interest on balance) as an alternative to first trade as the determining factor to being funded.
2025-08-20      Guy M       Removed the 13K false FTDs on 2025-08-19.
2025-09-30      Guy M       Improved the logic of the IOB - fixed cases when trade opens AFTER IOB.
2025-10-16      Guy M       Added OptionsTrade as an additional qualifying activity. Cleaned null handling and removed placeholder values.
2025-11-23      Guy M       Added the removal of "bad ftds" - the 13K wrongly identified, without hurting those that did legitimately make FTD later.
2026-05-27      Guy M       Extended REMOVE_BAD_FTDS to cover 2026-05-22, 2026-05-23, 2026-05-25 ($1 FTD synthetic cohort, ~17.7K rows, sequential FTDTransactionIDs on TP).
**************************************** End Main Comment History ****************************************/

    WITH First_IOB AS (
        SELECT
            RealCID,
            MIN(Occurred) AS FirstIOBTime,
            CAST(MIN(Occurred) AS DATE) AS FirstIOBDate,
            MIN(CAST(FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT)) AS FirstIOBDateID
        FROM DWH_dbo.Fact_CustomerAction
        WHERE ActionTypeID = 36
          AND CompensationReasonID = 57
        GROUP BY RealCID
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

    DWH_FTD AS (
        SELECT
            COALESCE(df.FTDPlatformName, 'TP') AS FTDPlatform,
            dc.RealCID,
            dc.FirstDepositDate AS FTDTime,
            CAST(dc.FirstDepositDate AS DATE) AS FTDDate,
            CAST(CONVERT(VARCHAR(8), dc.FirstDepositDate, 112) AS INT) AS FTDDateID,
            dc.FTDPlatformID
        FROM DWH_dbo.Dim_Customer dc
        LEFT JOIN DWH_dbo.Dim_FTDPlatform df
            ON df.FTDPlatformID = dc.FTDPlatformID
        WHERE dc.IsDepositor = 1
          AND dc.RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)
    ),

    Verification AS (
        SELECT
            fsc.RealCID,
            CONVERT(DATE, CONVERT(VARCHAR(8), MIN(dr.FromDateID)), 112) AS FirstVerifiedDate,
            MIN(dr.FromDateID) AS FirstVerifiedDateID
        FROM DWH_dbo.Fact_SnapshotCustomer fsc
        JOIN DWH_dbo.Dim_Range dr
            ON fsc.DateRangeID = dr.DateRangeID
        WHERE fsc.VerificationLevelID = 3
        GROUP BY fsc.RealCID
    ),

    Trade AS (
        SELECT
            CID AS RealCID,
            MIN(OpenOccurred) AS FirstTradeTime,
            CONVERT(DATE, CONVERT(VARCHAR(8), MIN(OpenDateID)), 112) AS FirstTradeDate,
            MIN(OpenDateID) AS FirstTradeDateID
        FROM DWH_dbo.Dim_Position
        WHERE ISNULL(IsAirDrop, 0) = 0
        GROUP BY CID
    ),

    OptionsTrade AS (
        SELECT
            op.RealCID,
            MIN(op.FirstTradeDate)   AS FirstOptionsTradeDate,
            MIN(op.FirstTradeDateID) AS FirstOptionsTradeDateID
        FROM [BI_DB_dbo].[Function_Revenue_OptionsPlatform](20000101, CAST(FORMAT(GETDATE(), 'yyyyMMdd') AS INT), 0) AS op
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

        CONVERT(
            DATE,
            CONVERT(
                VARCHAR(8),
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
                ),
                112
            )
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
        -- must have at least one activity (trade, IOB, or options)
        (t.FirstTradeDateID IS NOT NULL
         OR iob.FirstIOBDateID IS NOT NULL
         OR ot.FirstOptionsTradeDateID IS NOT NULL)
);
GO
