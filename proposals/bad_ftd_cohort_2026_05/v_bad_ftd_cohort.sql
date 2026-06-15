-- =====================================================================
-- v_bad_ftd_cohort
-- ---------------------------------------------------------------------
-- Single source of truth for the "bad $1 FTD cohort" predicate.
--
-- WHAT IT RETURNS
--   RealCIDs of customers who SHOULD currently be excluded from FTD
--   recognition (across all platforms, all DateIDs, both IsPlatformFTD
--   and IsGlobalFTD).
--
-- WHO ENDS UP IN HERE
--   A customer is bad-cohort if ALL three hold:
--     1. Their Dim_Customer.FirstDepositDate is one of the known
--        synthetic-cohort dates (currently 6 dates — see cohort_dates).
--     2. Their Dim_Customer.FirstDepositAmount = 1.
--     3. They have ONLY ONE Deposit row in the upstream deposit feeds
--        (Fact_CustomerAction TP/IBAN + eMoney_Fact_Transaction_Status).
--
-- THE UN-BLACKLIST MECHANISM (CRITICAL)
--   Condition (3) is the un-blacklist. The MOMENT a $1-cohort customer
--   makes a legitimate second deposit (any amount, any platform), the
--   COUNT > 1 predicate flips them out of multi_deposit_cids, which
--   removes them from this view's output, which means downstream:
--     - v_mimo_first_deposit_all_platforms returns them
--     - v_mimo_allplatforms's IsPlatformFTD/IsGlobalFTD flags turn ON
--       for their original $1 FTD row
--   So a customer who $1-FTD'd on 5/22 and then $200-deposited on 6/15
--   becomes a legitimate FTDer with FTD date 5/22 and FTD amount $1.
--   This is intentional and matches the Synapse intent: "we recognize
--   $1 users who go on to put in a true FTD".
--
--   To audit who's been un-blacklisted, use v_bad_ftd_cohort_unblacklisted
--   (the inverse view in the same file).
--
-- WHY UPSTREAM SOURCES (NOT THE MIMO FACT)
--   Earlier draft used `BI_DB_DDR_Fact_MIMO_AllPlatforms` for the
--   un-blacklist count. That created a self-reference: when
--   sp_ddr_fact_mimo_allplatforms does its DELETE WHERE DateID = X
--   between phases, the fact temporarily loses rows. The cohort view
--   re-evaluates and customers whose only "2nd deposit" was on date X
--   re-blacklist; the subsequent INSERT then writes their X row with
--   IsPlatformFTD/IsGlobalFTD = 0. The post-run audit looks correct
--   (rows are back) but the written values are wrong.
--   Fix: count deposits from upstream source-of-truth tables that the
--   SP does not touch (Fact_CustomerAction + eMoney_Fact_Transaction_Status).
--   Same semantic, stable against in-SP DELETEs.
--
-- WHY NOT EXISTS (NOT NOT IN)
--   `NOT IN (subquery)` returns NULL if the subquery contains ANY NULL,
--   which silently nullifies the whole predicate (returns 0 rows).
--   `NOT EXISTS` correctly handles NULLs (and is faster on Spark).
--   We also filter `RealCID IS NOT NULL` in upstream_deposits as
--   belt-and-suspenders.
--
-- ADDING A NEW BAD-COHORT DATE
--   Add to the cohort_dates VALUES list and redeploy. The new RealCIDs
--   automatically flow through to all downstream views and SPs. Don't
--   change any other view.
-- =====================================================================
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_bad_ftd_cohort AS
WITH cohort_dates AS (
  SELECT TO_DATE(d, 'yyyyMMdd') AS d
  FROM VALUES
    ('20250818'),  -- original Aug 2025 cohort (~13K, REQ-original)
    ('20250819'),
    ('20250820'),
    ('20260522'),  -- REQ-24699 May 2026 cohort (~17.7K)
    ('20260523'),
    ('20260525')
  AS t(d)
),
upstream_deposits AS (
  -- Source-of-truth deposit feeds. Stable against any downstream
  -- materialization. Same predicates used by v_mimo_tradingplatform
  -- (TP) and v_mimo_first_deposit_all_platforms.new_iban (eMoney).
  SELECT fca.RealCID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  WHERE fca.ActionTypeID IN (7, 44)         -- 7 = TP deposit, 44 = IBAN
    AND fca.RealCID IS NOT NULL
  UNION ALL
  SELECT mfts.CID AS RealCID
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
  WHERE mfts.MoneyMoveDirection = 'MoneyIn'
    AND mfts.TxStatusID = 2                 -- successful
    AND mfts.TxTypeID IN (7, 14)            -- 7 = IBAN deposit, 14 = C2F
    AND mfts.CID IS NOT NULL
),
multi_deposit_cids AS (
  -- Customers with more than one deposit across TP + eMoney.
  -- These are the legit later-FTDers — they get un-blacklisted.
  SELECT RealCID
  FROM upstream_deposits
  GROUP BY RealCID
  HAVING COUNT(*) > 1
)
SELECT dc.RealCID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
WHERE CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND dc.FirstDepositAmount = 1
  AND NOT EXISTS (
    SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID
  );

COMMENT ON VIEW main.etoro_kpi_prep.v_bad_ftd_cohort IS
'Predicate view: RealCIDs of the $1 synthetic-FTD cohort that should NOT currently count as FTDs. Un-blacklist mechanism: HAVING COUNT > 1 against upstream source feeds (NOT the MIMO fact — that would create a self-reference inside sp_ddr_fact_mimo_allplatforms). NOT EXISTS, not NOT IN, to survive NULL CIDs. Mirrors REMOVE_BAD_FTDS CTE from Synapse BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms (REQ-24699). Single source of truth: add new cohort dates HERE, never inline elsewhere.';


-- =====================================================================
-- v_bad_ftd_cohort_unblacklisted  (audit companion)
-- ---------------------------------------------------------------------
-- Inverse / debug view: full bad-cohort population with their current
-- upstream deposit count and blacklist status. Same upstream sources as
-- v_bad_ftd_cohort. Use to verify the un-blacklist mechanism is firing
-- as customers make 2nd deposits over time.
-- =====================================================================
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_bad_ftd_cohort_unblacklisted AS
WITH cohort_dates AS (
  SELECT TO_DATE(d, 'yyyyMMdd') AS d
  FROM VALUES
    ('20250818'), ('20250819'), ('20250820'),
    ('20260522'), ('20260523'), ('20260525')
  AS t(d)
),
upstream_deposits AS (
  SELECT fca.RealCID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  WHERE fca.ActionTypeID IN (7, 44)
    AND fca.RealCID IS NOT NULL
  UNION ALL
  SELECT mfts.CID AS RealCID
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
  WHERE mfts.MoneyMoveDirection = 'MoneyIn'
    AND mfts.TxStatusID = 2
    AND mfts.TxTypeID IN (7, 14)
    AND mfts.CID IS NOT NULL
),
deposit_counts AS (
  SELECT RealCID, COUNT(*) AS deposit_count
  FROM upstream_deposits
  GROUP BY RealCID
)
SELECT
  dc.RealCID,
  CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate,
  dc.FirstDepositAmount,
  dc.FTDPlatformID,
  COALESCE(dcnt.deposit_count, 0) AS DepositCount_Upstream,
  CASE WHEN COALESCE(dcnt.deposit_count, 0) > 1 THEN 'unblacklisted' ELSE 'still_blacklisted' END AS Status
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
LEFT JOIN deposit_counts dcnt ON dc.RealCID = dcnt.RealCID
WHERE CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND dc.FirstDepositAmount = 1;

COMMENT ON VIEW main.etoro_kpi_prep.v_bad_ftd_cohort_unblacklisted IS
'Audit view: full bad-cohort population with current upstream deposit count and blacklist status. Mirrors v_bad_ftd_cohort logic, exposes the count for debugging. Sources: Fact_CustomerAction (TP/IBAN) + eMoney_Fact_Transaction_Status.';
