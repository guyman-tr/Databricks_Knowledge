/*
================================================================================
  Databricks UC REQ-25250 backfill -- 2026-05-22 .. 2026-06-06
  Date drafted: 2026-06-08
  Connection : Databricks SQL warehouse (Unity Catalog, main.de_output.*)

  Context:
    REQ-25250 deployed the bad-$1-FTD-cohort demotion logic into the DBX SPs:
      * main.de_output.sp_ddr_fact_mimo_allplatforms
          (recovery filter + final IsPlatformFTD/IsGlobalFTD demotion via
           main.etoro_kpi_prep.v_bad_ftd_cohort)
      * main.de_output.sp_ddr_customer_daily_status
          (final IsDepositor / IsDepositorGlobal / IsFunded / FirstTimeFunded /
           FirstFundedDateID / FTD-anchor / *FirstDeposited demotion)

    These patches demote only on the CURRENT call's date -- they do NOT
    retro-touch historical rows. Verified on the 2026-06-07 run; the
    periodic-status TVF for 06-07 matched Synapse on every short-window metric
    (Week / Month) and the only gap was GlobalFirstDeposited_ThisYear
    (DBX -17,440 vs Synapse), entirely explained by the missing pre-fix
    days 2026-05-22 .. 2026-06-06 in UC.

    Backfill window: 16 dates  ->  32 SP executions (MIMO + Daily_Status).

  Dependency order (DO NOT REORDER between tiers):

    Tier 1a -> sp_ddr_fact_mimo_allplatforms      (writes ddr_fact_mimo_allplatforms)
    Tier 1b -> sp_ddr_customer_daily_status       (reads MIMO output)

    Tier 2  -> NOT NEEDED IN DBX.
               ddr_tvf_customer_periodic_status is a TVF, recomputed on demand
               from Customer_Daily_Status. Once Tier 1b is backfilled, every
               periodic-status query will see correct windows automatically.

    Within a tier, dates may run in any order (each SP starts with
    DELETE FROM ... WHERE etr_ymd = p_etr_ymd, so re-running a date is safe).
    The loops below run chronologically for predictability and log readability.

  Recovery:
    Every SP is idempotent on its own date. If a tier fails halfway, just
    re-run the same tier -- already-processed dates will be DELETE+INSERTed
    again with no duplication.

  Run options:
    [A] Paste the two BEGIN .. END blocks below into a Databricks SQL editor
        (warehouse must have spark.sql.scripting.enabled=true; the DDR
        warehouse already does -- verified in DESCRIBE PROCEDURE output).
        Each block is one scripting batch and will print a status row per date.

    [B] If your warehouse doesn't support multi-statement scripting, scroll
        down to "PLAN B -- flat per-day CALL list" and run those instead
        (16 + 16 = 32 statements; copy-paste in chunks).

  Expected runtime:
    Tier 1a MIMO       : ~1-3 min/date  ->  20-50 min total
    Tier 1b Daily      : ~3-7 min/date  ->  60-110 min total
    --------------------------------------------------------
    Total                                  ~80-160 min
================================================================================
*/


-- ============================================================================
-- TIER 1a : sp_ddr_fact_mimo_allplatforms
--   Param: STRING 'YYYYMMDD'
--   16 calls, ~1-3 min each
-- ============================================================================
BEGIN
  DECLARE d DATE DEFAULT DATE '2026-05-22';
  WHILE d <= DATE '2026-06-06' DO
    SELECT CONCAT('MIMO_AllPlatforms : ', DATE_FORMAT(d, 'yyyy-MM-dd')) AS status;
    CALL main.de_output.sp_ddr_fact_mimo_allplatforms(DATE_FORMAT(d, 'yyyyMMdd'));
    SET d = DATE_ADD(d, 1);
  END WHILE;
END;


-- ============================================================================
-- TIER 1b : sp_ddr_customer_daily_status
--   Param: DATE 'YYYY-MM-DD'
--   16 calls, ~3-7 min each
--   MUST run after Tier 1a completes (reads ddr_fact_mimo_allplatforms).
-- ============================================================================
BEGIN
  DECLARE d DATE DEFAULT DATE '2026-05-22';
  WHILE d <= DATE '2026-06-06' DO
    SELECT CONCAT('Customer_Daily_Status : ', DATE_FORMAT(d, 'yyyy-MM-dd')) AS status;
    CALL main.de_output.sp_ddr_customer_daily_status(d);
    SET d = DATE_ADD(d, 1);
  END WHILE;
END;


-- ============================================================================
-- NO TIER 2 IN DBX -- periodic_status is a TVF, computed on demand.
-- After Tier 1b finishes, this query returns the fresh, demoted window:
--
--   SELECT * FROM main.de_output.ddr_tvf_customer_periodic_status(DATE '2026-06-07');
--
-- (and any other date you care to inspect)
-- ============================================================================


-- ============================================================================
-- POST-BACKFILL SANITY CHECK  (optional, run after both tiers finish)
--   Re-runs the same year-to-date metric that was off by 17,440 on 06-07.
--   After backfill it should match Synapse:
--     Synapse: 217,803
-- ============================================================================
/*
SELECT
    COUNT(*)                                    AS row_cnt,
    SUM(IsFunded_ThisWeek)                      AS is_funded_w,
    SUM(FirstTimeFunded_ThisWeek)               AS ftf_w,
    SUM(GlobalFirstDeposited_ThisWeek)          AS gfd_w,
    SUM(GlobalFirstDeposited_ThisMonth)         AS gfd_m,
    SUM(GlobalFirstDeposited_ThisYear)          AS gfd_y       -- target: 217,803
FROM main.de_output.ddr_tvf_customer_periodic_status(DATE '2026-06-07');
*/


-- ============================================================================
-- POST-BACKFILL BAD-COHORT DEMOTION CHECK  (optional)
--   All *_should_be_0 must be 0 across every date in the window.
-- ============================================================================
/*
SELECT cs.DateID,
       COUNT(*)                            AS bad_cohort_rows,
       SUM(cs.IsDepositor)                 AS dep_should_be_0,
       SUM(cs.IsDepositorGlobal)           AS dep_global_should_be_0,
       SUM(cs.IsFunded)                    AS funded_should_be_0,
       SUM(cs.FirstTimeFunded)             AS first_funded_should_be_0,
       MAX(cs.UpdateDate)                  AS last_update
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
INNER JOIN main.etoro_kpi_prep.v_bad_ftd_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.DateID BETWEEN 20260522 AND 20260607
GROUP BY cs.DateID
ORDER BY cs.DateID;
*/


-- ============================================================================
-- PLAN B -- flat per-day CALL list (use if scripting BEGIN/END is unavailable)
-- ============================================================================
/*
-- Tier 1a: MIMO
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260522');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260523');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260524');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260525');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260526');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260527');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260528');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260529');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260530');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260531');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260601');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260602');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260603');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260604');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260605');
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260606');

-- Tier 1b: Daily Status (DATE param, run AFTER Tier 1a completes)
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-22');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-23');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-24');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-25');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-26');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-27');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-28');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-29');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-30');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-05-31');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-01');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-02');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-03');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-04');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-05');
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-06');
*/
