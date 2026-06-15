/*
================================================================================
  Synapse DDR rerun after $1 FTD synthetic cohort exclusion
  Author:   Guy M
  Date:     2026-05-28

  Why:
    Function_MIMO_First_Deposit_All_Platforms and Function_Population_First_Time_Funded
    were patched to extend REMOVE_BAD_FTDS with the 2026-05-22 .. 23, 25 cohort
    (~17.7K rows, $1, sequential FTDTransactionIDs on FTDPlatformID=1).
    Every DDR proc that consults those two TVFs - or reads from a fact table
    populated by them - now needs a rerun for the affected window.

  Affected window:
    First bad date  = 2026-05-22 (the new cohort)
    Last full run   = 2026-05-27 (latest DateID in the DDR fact tables today)
    -> rerun for DateID 20260522, 20260523, 20260524, 20260525, 20260526, 20260527

    Note: 2026-05-24 had no bad-FTD rows in Dim_Customer but the daily SPs
    consult the TVFs on every run, so re-run all six dates contiguously to
    keep Customer_Periodic_Status' weekly/monthly aggregates consistent.

    The 2025-08-18..20 cohort is NOT in scope here - it was already excluded
    by REMOVE_BAD_FTDS in the 2025-11-23 deploy and back-data was fixed then.

  Dependency tiers (DO NOT REORDER):

    Tier 1 - Direct consumers of patched TVFs (idempotent per-date inserts,
             each SP DELETE-WHERE-DateID then INSERT):
      * SP_DDR_Customer_Daily_Status        - reads Function_Population_First_Time_Funded
      * SP_DDR_Fact_Fact_MIMO_AllPlatforms  - reads Function_MIMO_First_Deposit_All_Platforms
      * SP_DDR                              - reads Function_Population_First_Time_Funded
      * SP_MarketingCloudDaily              - reads Function_Population_First_Time_Funded

    Tier 2 - Consumers of Tier 1 output tables (must run AFTER all Tier 1
             dates complete - SP_DDR_Customer_Periodic_Status aggregates
             week/month/quarter/year from BI_DB_DDR_Customer_Daily_Status):
      * SP_DDR_Customer_Periodic_Status     - reads BI_DB_DDR_Customer_Daily_Status
      * SP_RevenueForum                     - reads BI_DB_DDR_Fact_MIMO_AllPlatforms

    Tier 3 - Cumulative single-shot (run once at end with latest DateID):
      * SP_CIDFirstDates                    - "first dates per CID" sweep

  Run-time expectation:
    Each SP takes ~1-5 minutes per call on prod. Total ~45-90 minutes if
    run serially. SP_DDR is the heaviest.

  Recovery / verification:
    After all reruns, compare:
      SELECT DateID, SUM(Deposited) AS Deposited, SUM(FirstDepositors) AS FTDs
      FROM BI_DB_dbo.BI_DB_DDR_Daily_Aggregated
      WHERE DateID BETWEEN 20260522 AND 20260527
      GROUP BY DateID ORDER BY DateID;
    Expected: 2026-05-22 FTDs should drop by ~17,236; 05-23 by ~470; 05-25 by ~10.
================================================================================
*/

-----------------------------------------------------------
-- TIER 1: per-date, direct consumers of patched TVFs
-----------------------------------------------------------

-- Customer Daily Status (writes BI_DB_DDR_Customer_Daily_Status)
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-22';
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-23';
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-24';
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-25';
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-26';
EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '2026-05-27';

-- MIMO All-Platforms fact (writes BI_DB_DDR_Fact_MIMO_AllPlatforms)
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-22';
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-23';
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-24';
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-25';
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-26';
EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '2026-05-27';

-- DDR daily-aggregated + CID-level (writes BI_DB_DDR_Daily_Aggregated + BI_DB_DDR_CID_Level)
EXEC BI_DB_dbo.SP_DDR '2026-05-22';
EXEC BI_DB_dbo.SP_DDR '2026-05-23';
EXEC BI_DB_dbo.SP_DDR '2026-05-24';
EXEC BI_DB_dbo.SP_DDR '2026-05-25';
EXEC BI_DB_dbo.SP_DDR '2026-05-26';
EXEC BI_DB_dbo.SP_DDR '2026-05-27';

-- Marketing Cloud daily extract (FTF-driven)
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-22';
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-23';
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-24';
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-25';
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-26';
EXEC BI_DB_dbo.SP_MarketingCloudDaily '2026-05-27';


-----------------------------------------------------------
-- TIER 2: depend on Tier 1 output (run AFTER all Tier 1)
-----------------------------------------------------------

-- Customer Periodic Status - reads BI_DB_DDR_Customer_Daily_Status,
-- aggregates week / month / quarter / year. Cumulative across the window:
-- the weekly/monthly aggregates for 05-27 sum up the (now-corrected) dailies
-- for 05-22..27, so we must rerun every date in the window in order.
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-22';
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-23';
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-24';
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-25';
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-26';
EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status '2026-05-27';

-- Revenue Forum - reads BI_DB_DDR_Fact_MIMO_AllPlatforms
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-22';
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-23';
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-24';
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-25';
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-26';
EXEC BI_DB_dbo.SP_RevenueForum '2026-05-27';


-----------------------------------------------------------
-- TIER 3: cumulative single-shot at latest date
-----------------------------------------------------------

-- CID First Dates - single-shot "first ever X" per CID across MIMO + daily-status.
-- Param is DATETIME. One run at the most recent populated date is sufficient.
EXEC BI_DB_dbo.SP_CIDFirstDates '2026-05-27';


-----------------------------------------------------------
-- POST-RUN SANITY CHECK
-----------------------------------------------------------
/*
SELECT
    DateID,
    SUM(Deposited)        AS Deposited,
    SUM(FirstDepositors)  AS FTDs,
    SUM(FirstDepositAmounts) AS FTD_USD
FROM BI_DB_dbo.BI_DB_DDR_Daily_Aggregated
WHERE DateID BETWEEN 20260522 AND 20260527
GROUP BY DateID
ORDER BY DateID;

-- Expected drops from the bad-cohort exclusion:
--   20260522: FTDs -17,236 ; FTD_USD -$17,236
--   20260523: FTDs -470    ; FTD_USD -$470
--   20260525: FTDs -10     ; FTD_USD -$10
*/
