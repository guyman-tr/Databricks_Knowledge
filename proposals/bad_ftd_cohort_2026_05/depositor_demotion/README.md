# Bad $1 FTD cohort — depositor flag demotion

> **NOTE — canonical one-shots have moved to `../one_shots/`.**
> The numbered files in this folder were the drafting/dev-testing workspace.
> Production-ready scripts (Synapse + Databricks) and the orchestration README
> now live at `../one_shots/`. This folder retains the `_*.py` runners, the
> initial obsolete drafts (`04_*`, `05_*` SP-patch files now folded into the
> canonical SP sources), and dev-pool audit history.

**Status:** scripts drafted and dev-tested. Production run pending PR #3875 merge.

## Why this folder exists (beyond REQ-25250)

The REQ-25250 MIMO patch fixes the bug that lets the bad $1 FTD cohort show up
with `IsPlatformFTD=1` / `IsGlobalFTD=1` in `BI_DB_DDR_Fact_MIMO_AllPlatforms`
on the FTD date itself. That handles the *first-deposit-event* metrics
(`GlobalFirstDeposited`, `TPFirstDeposited`, `*_FirstDeposited_ThisYear`,
etc.) on **all dates after REQ-25250 merges + Synapse rerun runs**.

But there is a **second, independent bug** that REQ-25250 does NOT fix:

| Column | Source | Filtered by REMOVE_BAD_FTDS? |
|---|---|---|
| `IsDepositor` | `V_Fact_SnapshotCustomer.IsDepositor` ← `Dim_Customer.FirstDepositDate IS NOT NULL` | **No** |
| `IsDepositorGlobal` | `IsDepositor OR Options_FTD_DateID IS NOT NULL OR MoneyFarm_FTD_DateID IS NOT NULL` | **No** (inherits the unfiltered `IsDepositor`) |
| `Global_FTD_DateID` / `TP_FTD_DateID` / `*_FTDA` | `Function_MIMO_First_Deposit_All_Platforms` TVF | Partial — TVF still returns bad cohort rows for Aug 2025 (verified) |

Since `Dim_Customer.FirstDepositDate` is the source of truth (these users
*did* deposit $1 — it's a data FTD, just not a business FTD), the user has
explicitly stated **we cannot touch `Dim_Customer`**. The fix must live in
the analytical layer.

## Quantified impact (Synapse prod, snapshot 2026-05-31)

| Cohort | RealCIDs | `IsDepositor=1` in daily_status | `IsDepositorGlobal=1` |
|---|---:|---:|---:|
| Aug 2025 (8/18, 8/19, 8/20) | 13,302 | 13,302 | 13,302 |
| May 2026 (5/22, 5/23, 5/25) | 17,678 | 17,678 | 17,678 |
| **Total** | **30,980** | **30,980** | **30,980** |

Every downstream KPI that counts *current* depositors (not new FTDs) is
inflated by ~31K customers, going back to at least 2025-12-01 (Aug cohort)
and 2026-05-22 (May cohort).

## "Will the recent PRs take care of going forward?" — short answer: partially

| Bug | Fixed going forward by | Status |
|---|---|---|
| #1: MIMO `IsPlatformFTD` / `IsGlobalFTD` leak on FTD date | REQ-25250 (Synapse SP demotion UPDATE) | PR #3875 open, awaiting merge |
| #1: Synapse downstream `daily_status.*FirstDeposited` + `periodic_status.*_FirstDeposited_ThisX` | Rerun via `synapse_rerun.sql` after REQ-25250 merges | Pending merge |
| #1: DBX downstream (`gold_…ddr_customer_daily_status`) | Reads from Synapse bronze MIMO → auto-corrects after Synapse rerun | Free with above |
| #2: `IsDepositor` / `IsDepositorGlobal` in `customer_daily_status` | **NOT fixed by any open PR** — both SPs blindly copy `snapshotcustomer.IsDepositor` | Needs new SP patches (drafted in `04_*` / `05_*`) |
| #2: TVF FTD anchors (`TP_FTD_DateID`, `Global_FTD_DateID`, etc.) | **NOT fully fixed** — current `Function_MIMO_First_Deposit_All_Platforms` still returns bad cohort rows in prod | Possibly also needs TVF patch |

## File inventory

| # | File | System | Type | What it does |
|---|---|---|---|---|
| 01 | `01_synapse_demote_daily_status.sql` | Synapse | one-shot UPDATE | Zero `IsDepositor`, `IsDepositorGlobal`, and all FTD anchor columns for all 30,980 bad cohort rows in `BI_DB_DDR_Customer_Daily_Status` (all DateIDs >= each cohort's FTD date) |
| 02 | `02_synapse_demote_mimo_aug2025.sql` | Synapse | one-shot UPDATE | Zero `IsPlatformFTD` for Aug 2025 leaked rows in `BI_DB_DDR_Fact_MIMO_AllPlatforms` (May 2026 will be handled by REQ-25250 rerun, not this script) |
| 03 | `03_dbx_demote_daily_status.sql` | Databricks UC | one-shot UPDATE | Same as 01, for `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` |
| 04 | `04_synapse_sp_patch_daily_status.sql` | Synapse | SP patch | Adds a final demotion UPDATE block to `SP_DDR_Customer_Daily_Status` so future runs filter Bug #2 automatically |
| 05 | `05_dbx_sp_patch_daily_status.sql` | Databricks UC | SP patch | Same as 04, for `main.de_output.sp_ddr_customer_daily_status` |

Scripts 01-03 are **idempotent**: re-running them will set already-zeroed
columns to zero again, no data lost.

Scripts 04-05 are **going-forward**: without them, every nightly run of the
SP will re-introduce `IsDepositor=1` for the bad cohort, undoing 01/03 on
the current `etr_ymd` only (historical rows stay clean).

## Tables NOT in scope

- `BI_DB_DDR_Customer_Periodic_Status` — does not have an `IsDepositor`
  column; its `*_FirstDeposited_ThisX` flags read from the TVF, which means
  Aug 2025 is already clean and May 2026 will auto-fix once REQ-25250 merges
  and `synapse_rerun.sql` runs. **No one-shot needed.**
- `BI_DB_DDR_Fact_PnL`, `BI_DB_DDR_Fact_AUM`, `BI_DB_DDR_Fact_Trading_Volumes_And_Amounts`,
  `BI_DB_DDR_Fact_Revenue_Generating_Actions` — none have a depositor or FTD
  flag of their own. **No one-shot needed.**
- `Dim_Customer` — explicitly out of scope per user direction (these are
  real $1 deposits, semantically not business FTDs).
- `Fact_SnapshotCustomer` — derived from `Dim_Customer`, same reason.

## Recommended execution order (when ready)

1. Merge REQ-25250 (PR #3875).
2. Deploy SP patches 04 + 05 to bidev / dev compute and smoke-test.
3. Run one-shot demotion scripts 01, 02, 03 in dev → audit row counts.
4. Run `synapse_rerun.sql` for affected DateIDs (REQ-25250 effect).
5. Promote SP patches 04 + 05 to prod via CI/CD.
6. Run one-shot demotion scripts 01, 02, 03 in prod.
7. Spot-check `SELECT SUM(IsDepositor) FROM customer_daily_status cs JOIN bad_cohort` → should be 0.

## Cohort definition (used in all scripts)

Same logic as `main.etoro_kpi_prep.v_bad_ftd_cohort` (DBX) and the
`REMOVE_BAD_FTDS` CTE in `Function_MIMO_First_Deposit_All_Platforms`
(Synapse):

```
FirstDepositDate IN (2025-08-18, 2025-08-19, 2025-08-20,
                     2026-05-22, 2026-05-23, 2026-05-25)
AND FirstDepositAmount = 1
AND RealCID has at most ONE upstream deposit ever (ActionTypeID IN (7,44) on TP,
                                                   TxTypeID IN (7,14) MoneyIn on eMoney)
```

The second condition excludes "un-blacklisted" users — those who came back
later and made a legitimate FTD. They should remain depositors.
