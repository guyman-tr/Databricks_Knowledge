/*===========================================================================
  05_dbx_sp_patch_daily_status.sql

  Purpose : Patch snippet to add to Databricks
            main.de_output.sp_ddr_customer_daily_status so every nightly run
            automatically zeros IsDepositor / IsDepositorGlobal / FTD anchor
            columns for the bad $1 FTD cohort RealCIDs.

  Why     : Same bug pattern as the Synapse SP - bs.IsDepositor comes from
            snapshotcustomer (which inherits Dim_Customer.FirstDepositDate
            IS NOT NULL) without any cohort filter, so the bad cohort gets
            IsDepositor=1, IsDepositorGlobal=1 every night.

  Pattern : Final UPDATE block run after the main INSERT INTO target table,
            scoped to the SP's p_date_id parameter. Reuses the deployed
            main.etoro_kpi_prep.v_bad_ftd_cohort view.

  How to apply :
    1. Edit the SP DDL in
       proposals/bad_ftd_cohort_2026_05/sp_ddr_customer_daily_status.aligned.sql
       (or wherever the canonical source lives in repo).
    2. Insert the block below immediately before the DROP TABLE statements
       (which clean up _tmp_ddr_* temp tables at end of BEGIN/END).
    3. Redeploy via CI/CD (CREATE OR REPLACE PROCEDURE).

  Self-contained : Uses main.etoro_kpi_prep.v_bad_ftd_cohort which is already
                   deployed and tested.
===========================================================================*/

----------------------------------------------------------------------------
-- BEGIN PATCH BLOCK
-- Insert at the end of the SP body, BEFORE the cleanup DROP TABLE statements.
-- Specifically, after:
--   INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
--   SELECT * EXCEPT (rn) FROM ( ... ) WHERE rn = 1;
-- and before:
--   DROP TABLE IF EXISTS main.de_output._tmp_ddr_pop;
--   ...
----------------------------------------------------------------------------

-- REQ-xxxxx : demote bad $1 FTD cohort
-- These RealCIDs made real $1 deposits so snapshotcustomer.IsDepositor = true,
-- but business semantics say they are not depositors. Zero all depositor
-- and FTD anchor fields on today's row.
UPDATE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
SET
    IsDepositor              = 0,
    IsDepositorGlobal        = 0,

    TP_FTD_DateID            = NULL,
    TP_FTD_Date              = NULL,
    TP_FTDA                  = CAST(0 AS DECIMAL(16,6)),
    TP_External_FTDA         = CAST(0 AS DECIMAL(16,6)),

    IBAN_FTD_DateID          = NULL,
    IBAN_FTD_Date            = NULL,
    IBAN_FTDA                = CAST(0 AS DECIMAL(16,6)),

    Options_FTD_DateID       = NULL,
    Options_FTD_Date         = NULL,
    Options_FTDA             = CAST(0 AS DECIMAL(19,4)),

    MoneyFarm_FTD_DateID     = NULL,
    MoneyFarm_FTD_Date       = NULL,
    MoneyFarm_FTDA           = CAST(0 AS DECIMAL(19,4)),

    Global_FTD_DateID        = 30000101,
    Global_FTD_Date          = NULL,
    Global_FTDA              = CAST(0 AS DECIMAL(16,6)),

    GlobalFirstDeposited     = 0,
    TPFirstDeposited         = 0,
    IBANFirstDeposited       = 0,
    OptionsFirstDeposited    = 0,
    MoneyFarmFirstDeposited  = 0,
    TPExternalFirstDeposited = 0,

    LoggedInTPDepositor      = 0,
    LoggedInIBANDepositor    = 0,
    LoggedInGlobalDepositor  = 0,

    UpdateDate               = CURRENT_TIMESTAMP()
WHERE DateID = p_date_id
  AND RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

----------------------------------------------------------------------------
-- END PATCH BLOCK
----------------------------------------------------------------------------

/*===========================================================================
  Change-history comment to add at top of SP body:

  -- yyyy-mm-dd | REQ-xxxxx | Guy Mansharov
  --   Final demotion UPDATE for bad $1 FTD cohort (Aug 2025 + May 2026):
  --   IsDepositor, IsDepositorGlobal, all FTD anchor columns and
  --   FirstDeposited flags forced to 0 / NULL for cohort RealCIDs on the
  --   current p_date_id. Complements REQ-25250 (MIMO demotion) which fixes
  --   the upstream MIMO IsPlatformFTD/IsGlobalFTD leak.
===========================================================================*/
