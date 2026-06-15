# Synapse SP_DDR_Fact_Fact_MIMO_AllPlatforms: recovery UPDATE bypasses REMOVE_BAD_FTDS

**Date:** 2026-05-31
**Status:** Bug confirmed in Synapse prod. DBX is clean.
**Affected dates:** 20260522, 20260523, 20260525 (REQ-24699 bad-FTD cohort)
**Symptom:** After the 2026-05-31 ~10:23 UTC patch of `Function_MIMO_First_Deposit_All_Platforms` and rerun of `SP_DDR_Fact_Fact_MIMO_AllPlatforms` for 20260522, Synapse `BI_DB_DDR_Fact_MIMO_AllPlatforms` for `DateID = 20260522` still shows `IsGlobalFTD = 18,209` (~17,236 of which are the `$1` synthetic cohort).

---

## 1. Smoking-gun side-by-side (after both systems were rerun today)

Same date, same source rows, only the platform-level filter logic differs:

| Date | Platform | Bucket | Rows | Synapse pftd | Synapse gftd | DBX pftd | DBX gftd |
|---|---|---|---:|---:|---:|---:|---:|
| 5/22 | TP | =$1 | 17,243 | **17,236** | **17,236** | 17,236 | **5** |
| 5/22 | TP | other | 35,635 | 657 | 657 | 657 | 657 |
| 5/22 | eMoney | =$1 | 15 | 0 | 0 | 0 | 0 |
| 5/22 | eMoney | other | 39,110 | 305 | 305 | 305 | 305 |
| 5/22 | Options | other | 112 | 1 | 1 | 1 | 1 |
| 5/22 | MoneyFarm | other | 10 | 10 | 10 | 10 | 10 |
| 5/23 | TP | =$1 | 470 | 470 | 470 | 470 | 1 |
| 5/25 | TP | =$1 | 17 | 10 | 10 | 10 | 0 |

DBX and Synapse agree on every other bucket. The single delta is the `$1` TP cohort on the bad-cohort dates, and **only on `IsGlobalFTD`**. `IsPlatformFTD` is identical on both sides (both sourced from raw platform IsFTD which neither system filters).

`Function_MIMO_First_Deposit_All_Platforms(0)` returns the correct filtered set:

| Date | TVF rows | TVF $1 rows | DimCust raw $1 | REMOVE_BAD_FTDS excludes |
|---|---:|---:|---:|---:|
| 5/22 | 1,008 | 35 | 17,236 | 17,201 |
| 5/25 | 942 | 0 | (small) | all |

So the TVF is doing its job. The contamination happens **after** the TVF is consulted.

---

## 2. Why DBX is clean

`main.de_output.sp_ddr_fact_mimo_allplatforms` body (production, queried from `system.information_schema.routines`):

```sql
BEGIN
  DECLARE v_dateID INT;
  ...
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  WHERE DateID = v_dateID;

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms (...)
  SELECT ...
  FROM main.etoro_kpi_prep.v_mimo_allplatforms
  WHERE DateID = v_dateID;
END
```

That's it. One DELETE, one INSERT. **No recovery UPDATE block.** All FTD-flag logic lives in the view.

The view sets `IsGlobalFTD` via a single LEFT JOIN to `v_mimo_first_deposit_all_platforms` (the DBX equivalent of the Synapse TVF):

```sql
LEFT JOIN global_ftds gf
  ON m.MIMOAction   = 'Deposit'
  AND m.RealCID      = gf.RealCID
  AND m.IsPlatformFTD = 1
  AND m.FTDPlatformID = gf.FTDPlatformID
```

`v_mimo_first_deposit_all_platforms` includes the `remove_bad_ftds` CTE with the new REQ-24699 dates (20260522/23/25). Bad-cohort RealCIDs are filtered out at the view level, so they never match in the JOIN, so `IsGlobalFTD = 0` for them in the fact table. No downstream "recovery" step puts them back.

---

## 3. Why Synapse falls into the trap

`SP_DDR_Fact_Fact_MIMO_AllPlatforms` does the right thing on the main load:

1. `#globalFTDs` is built from `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)` — **filtered**
2. `#final` LEFT JOINs `#globalMIMO` to `#globalFTDs` — produces `IsGlobalFTD = 1` only for legit (~1,008) FTDs
3. DELETE+INSERT to `BI_DB_DDR_Fact_MIMO_AllPlatforms` for `@dateID` — at this point Synapse and DBX would agree

…but then it runs **two "FTD recovery" UPDATEs** at the bottom of the SP that source directly from `Dim_Customer` with no `REMOVE_BAD_FTDS` filter:

```sql
-- TP recovery (the one that re-introduces the 5/22 cohort)
UPDATE  t1
SET   t1.IsPlatformFTD = 1,  IsGlobalFTD = 1
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms t1
INNER JOIN (
    SELECT RealCID, dc.FTDTransactionID
    FROM DWH_dbo.Dim_Customer dc          --  ← bypasses TVF
    WHERE dc.FTDPlatformID = 1
) t3
    ON cast(t1.TransactionID AS VARCHAR(100)) = t3.FTDTransactionID
WHERE (t1.IsPlatformFTD = 0 OR t1.IsGlobalFTD = 0)
    AND t1.MIMOPlatform = 'TradingPlatform'
    AND t1.MIMOAction   = 'Deposit'
    AND t1.DateID       >= 20250901;       --  ← no upper bound: touches ALL dates
```

The bad-cohort customers have:
- `Dim_Customer.FTDPlatformID = 1`
- `Dim_Customer.FTDTransactionID = TransactionID` of their $1 TP deposit
- `BI_DB_DDR_Fact_MIMO_AllPlatforms.IsGlobalFTD = 0` (from the clean main load)

⇒ the predicate `(IsPlatformFTD = 0 OR IsGlobalFTD = 0)` fires, the JOIN matches, and 17,236 rows on 5/22 get flipped back to `IsGlobalFTD = 1`. This is exactly the gap we measured.

A sibling UPDATE just above it does the same for eMoney recovery — same blind spot. It hasn't fired this time because the 5/22 cohort is TP-only.

The `DateID >= 20250901` (open upper bound) is also why the SP rewrote rows for *every* date back to Sep 2025 when we ran it for 5/22, and why it took ~4 min instead of seconds.

---

## 4. Secondary observation (NOT the main bug)

On 5/22 DBX shows only `5` $1-TP `IsGlobalFTD=1` rows. The TVF actually returns `35` $1-TP customers for 5/22 (the "kept" subset that has `COUNT(MIMO_Deposit) > 1`). So DBX is missing 30 of the legit recovered $1 FTDs.

Why: the DBX JOIN in `v_mimo_allplatforms` requires the row's MIMO `DateID` to equal a corresponding source MIMO row on that date with `IsFTD = 1` and matching `FTDPlatformID`. If a customer's `Dim_Customer.FTDPlatformID` differs from where their 5/22 deposit landed (e.g., DimCustomer says they're an eMoney/MoneyFarm FTD now, but their 5/22 row is a TP deposit), the JOIN fails.

Synapse compensates for this via the same recovery UPDATE — it doesn't care about platform-of-source, it just matches `t1.TransactionID = dc.FTDTransactionID` from DimCustomer.

So Synapse has a feature ("recover late-arriving DimCustomer-driven FTDs") that DBX does not. The bad-cohort bug is the cost of that feature being unfiltered. We can either:

- A. Keep DBX as-is (lose 30 of ~1,000 legit FTDs per day to cross-platform DimCustomer drift, gain protection from cohort contamination), or
- B. Add an equivalent recovery step to DBX with the proper `REMOVE_BAD_FTDS` predicate baked in from day one.

Worth a discussion but not urgent.

---

## 5. Recommended fix for Synapse

Add the `REMOVE_BAD_FTDS` filter to both recovery UPDATEs in `SP_DDR_Fact_Fact_MIMO_AllPlatforms`. Cleanest is to inline the same predicate used in the TVF:

```sql
-- snippet to add to the WHERE of EACH of the two UPDATE statements
AND t3.RealCID NOT IN (
    SELECT dc.RealCID
    FROM DWH_dbo.Dim_Customer dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
              CONVERT(DATE,'20250818',112),
              CONVERT(DATE,'20250819',112),
              CONVERT(DATE,'20250820',112),
              CONVERT(DATE,'20260522',112),
              CONVERT(DATE,'20260523',112),
              CONVERT(DATE,'20260525',112))
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID NOT IN (
          SELECT map.RealCID
          FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
          WHERE map.MIMOAction = 'Deposit'
          GROUP BY map.RealCID
          HAVING COUNT(map.RealCID) > 1
      )
)
```

Apply identically to BOTH the TP recovery UPDATE (`WHERE t1.MIMOPlatform = 'TradingPlatform'`) and the eMoney recovery UPDATE (`WHERE t1.MIMOPlatform = 'eMoney'`).

Better long-term refactor (out of scope for this hotfix): replace both recovery UPDATEs with a single `UPDATE ... FROM ... INNER JOIN Function_MIMO_First_Deposit_All_Platforms(0)` so the filter cannot drift again. Same predicate, single source of truth.

---

## 6. Cleanup after the SP patch

Once the SP is patched in dev/bidev/prod, rerun for `2026-05-22, 2026-05-23, 2026-05-25` (and any downstream that consumed the polluted MIMO between today's earlier rerun and the SP patch landing):

- `SP_DDR_Fact_Fact_MIMO_AllPlatforms` (TP recovery UPDATE has open-ended `DateID >= 20250901`, but re-running per-date is fine because the inner JOIN scopes the work)
- `SP_DDR_Customer_Daily_Status` for 20260522–25
- `SP_DDR_Customer_Periodic_Status` for the cumulative window from 20260522 onward
- `SP_DDR`, `SP_MarketingCloudDaily` for the same dates (Tier-1 consumers per `synapse_rerun.sql`)
- `SP_DDR_Customer_Periodic_Status`, `SP_RevenueForum` (Tier-2)
- `SP_CIDFirstDates` (Tier-3 cumulative, one shot)

---

## 7. Tomorrow's action list

1. Open Synapse PR with the two recovery-UPDATE patches against the same branch as the TVF fix (or a follow-up PR — recommend follow-up so it's reviewable on its own).
2. Deploy to bidev → verify `BI_DB_DDR_Fact_MIMO_AllPlatforms` for 20260522 shows IsGlobalFTD ≈ 1,008 (not 18,209) post-rerun.
3. Promote to prod, rerun the tiered SP list from §6.
4. Re-verify DBX/Synapse parity for 20260522/23/25 — should now agree at ~1,008 / ~605 / small on `IsGlobalFTD`.
5. (Optional) decide on §4 above — whether to port the recovery UPDATE pattern to DBX or accept the small ongoing drift.

