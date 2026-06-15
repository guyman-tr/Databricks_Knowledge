# DDR SP alignment: DBX ↔ Synapse — lineage investigation + proposed fixes

**Date:** 2026-06-01
**Trigger:** Bad-$1-FTD cohort surfaced a structural drift: DBX `sp_ddr_*` were written as thin "select-from-view" wrappers; several Synapse SPs contain hardened recovery passes that the views can't express. Need to port those passes into the DBX SPs.

**Scope:** every DDR-family SP under `BI_DB_dbo` in Synapse and its DBX counterpart under `main.de_output`. Per-SP gap analysis + proposed aligned bodies. Primary deliverable is the rewritten `sp_ddr_fact_mimo_allplatforms`. Secondary findings flagged for follow-up.

---

## 1. Lineage map (one row per Synapse SP)

| # | Synapse SP (BI_DB_dbo) | Bytes | DBX counterpart (main.*) | Bytes | Gap level |
|---|---|---:|---|---:|---|
| 1 | `SP_DDR_Fact_AUM` | 26,930 | `de_output.sp_ddr_fact_aum` (slim) + `etoro_kpi_prep.tvf_ddr_fact_aum` | 1,123 + 7,796 | ✅ Aligned (TVF has the two-arm filter) |
| 2 | `SP_DDR_Fact_PnL` | 4,686 | `de_output.sp_ddr_fact_pnl` (slim) + `etoro_kpi_prep.tvf_pnl_single_day` | 1,604 + 6,310 | ✅ Aligned |
| 3 | `SP_DDR_Fact_Trading_Volumes_And_Amounts` | 9,272 | `de_output.sp_ddr_fact_trading_volumes_and_amounts` | 3,081 | 🟡 By-design drift (uses w_metrics, ignores Synapse TVF source). Also missing the `BI_DB_VolumeQA` dump — minor. |
| 4 | `SP_DDR_Fact_Revenue_Generating_Actions` | 88,744 | `de_output.sp_ddr_fact_revenue_generating_actions` + `v_ddr_revenues` family | 3,113 + ~15 views | ✅ Aligned (Options PFOF 90d rolling + Staking guards already in place from prior work) |
| 5 | `SP_DDR_Fact_Fact_MIMO_AllPlatforms` | 24,356 | `de_output.sp_ddr_fact_mimo_allplatforms` + `v_mimo_allplatforms` | **1,411** + ~3,500 | 🔴 **Primary issue.** Missing both FTD-recovery `UPDATE`s. Cohort-contamination via Synapse, FTD undercount via DBX. |
| 6 | `SP_DDR_Customer_Daily_Status` | 98,448 | `de_output.sp_ddr_customer_daily_status` | 19,330 | 🟡 Smaller drift. Reads filtered TVF; gets FTD list right post-cohort. But it doesn't replicate Synapse's "back-data dim_customer recovery" path that mirrors the MIMO recovery (similar logic, lower magnitude impact). |
| 7 | `SP_DDR_Customer_Periodic_Status` | 61,836 | `de_output.ddr_tvf_customer_periodic_status` (TVF) — **table targeted for deprecation** | 19,678 | ✅ **Resolved.** Per user direction: the DBX TVF is performant enough to negate the need for materializing. Table `gold_..._bi_db_ddr_customer_periodic_status` becomes a deprecation target (audit consumers first). No SP wrapper. |
| 8 | `SP_DDR_Fact_Non_Revenue_Generating_Actions` | 16,562 | **none** | — | 🔴 No DBX equivalent. Synapse populates `BI_DB_DDR_Fact_Non_Revenue_Generating_Actions` (bonuses, comps, copy actions, login events, post/comment/like, P&L adjustments). DBX has the *table* (sync target) but no SP producing it natively. |
| 9 | `SP_DDR_Aggregated` | 270,206 | none | — | 🟡 Aggregation-only over already-loaded facts. Out of scope here. |
| 10 | `SP_DDR_Auxiliary_Metrics` | 39,402 | none | — | 🟡 Same as above. |
| 11 | `SP_DDR_Aggregated_Auxiliary_Metrics` | 88,452 | none | — | 🟡 Same as above. |
| 12 | `SP_DDR` (orchestrator) | 154,192 | none | — | 🟡 Orchestrator. DBX is using a Lakeflow Job equivalent. |
| 13 | `SP_DDR_Process_Monitor` | 10,346 | none | — | 🟡 Monitoring. Out of scope. |
| 14 | `SP_CIDFirstDates` | 124,712 | none (table is passive sync from Synapse: `bi_db.gold_..._bi_db_cidfirstdates_masked`) | — | 🟡 Cumulative single-shot. Currently consumed as passive sync. |
| 15 | `SP_MarketingCloudDaily` | 169,516 | none | — | 🟡 Marketing Cloud export. Passive sync. |
| 16 | `SP_RevenueForum` | 44,878 | none | — | 🟡 Revenue Forum. Passive sync. |
| 17 | `SP_DDR_Fact_MIMO_Trading_Platform` | 15,126 | `etoro_kpi_prep.v_mimo_tradingplatform` (view) | ~2K | ✅ View consumes raw Fact_CustomerAction + Fact_BillingDeposit. IsPlatformFTD logic matches Synapse pattern. |
| 18 | `SP_DDR_Fact_MIMO_eMoney_Platform` | 16,328 | `etoro_kpi_prep.v_mimo_emoneyplatform` (view) | similar | ✅ Same. |
| 19 | `SP_DDR_Fact_MIMO_Options_Platform` | 3,240 | `etoro_kpi_prep.v_mimo_optionsplatform` (view) | similar | ✅ Same. |

Legend:
- ✅ Aligned (zero or cosmetic drift)
- 🟡 Drift exists but lower priority / by design / out of scope
- 🔴 Material gap — recovery/correctness impact

---

## 2. Why the "select-from-view" pattern broke

The DBX SPs in `de_output` were written as essentially:

```sql
DELETE FROM <fact> WHERE DateID = v_dateID;
INSERT INTO <fact> SELECT ... FROM <view> WHERE DateID = v_dateID;
```

That's perfect when **all of the SP's logic is row-by-row and stateless** (PnL, Trading Volumes, AUM via the TVF). It breaks when the Synapse SP has **secondary passes that depend on already-materialized data**:

| Synapse pass | Why a view can't replicate it |
|---|---|
| TP FTD recovery `UPDATE` (in MIMO SP) | Needs to scan the *already-loaded* MIMO fact table looking for `IsGlobalFTD = 0` rows whose `TransactionID` matches a `Dim_Customer.FTDTransactionID` populated *after* the row was originally inserted. A view re-evaluates from source — by then the source still doesn't have the FTD flag. |
| eMoney FTD recovery `UPDATE` (in MIMO SP) | Same shape: late-arriving DimCustomer → join → flip flags. |
| Full Options/MoneyFarm refresh (no date filter) | Daily Options/MoneyFarm data is "best effort", so Synapse does `DELETE WHERE MIMOPlatform = 'Options'` (all dates) followed by full INSERT. View-based per-date approach drops late-corrected rows. |
| Daily_Status post-process recovery | Same FTD late-arrival problem, this time fixing `IsDepositorGlobal` / `FirstTimeFunded` / `Options_FTD_DateID` after the row exists. |
| Non_Revenue_Generating_Actions temp pivoting | Builds in #fcaBizPrep then aggregates — would need either a CTE chain or a materialized intermediate. Doable via view but expensive. |

The recovery passes were "written in blood" — patches added over months as Dim_Customer's FTDPlatformID population proved unreliable on the date the deposit actually happened.

---

## 3. PRIMARY: refactored `v_mimo_allplatforms` + thin `sp_ddr_fact_mimo_allplatforms`

### 3.1 Design decision: logic lives in the view

Per user direction: since `v_mimo_allplatforms` exists and the SP is meant to be a thin `SELECT → table`, all semantic logic lives in the view. The SP is a pure materializer.

**Structurally different from Synapse, semantically equivalent.** Synapse runs a wide-scope recovery `UPDATE` over the materialized fact table. DBX puts the same logic in the view so every per-date materialization re-evaluates from current `Dim_Customer`. Back-dating becomes: rerun the SP for affected dates (loop workflow already in use).

### 3.2 Three-phase shape (no MERGE, no in-SP recovery)

1. **Phase 1 — daily incremental for TP + eMoney** — `DELETE WHERE DateID = v_dateID AND MIMOPlatform IN ('TradingPlatform','eMoney')` + `INSERT FROM v_mimo_allplatforms ...`.
2. **Phase 2 — Options full refresh** — `DELETE WHERE MIMOPlatform = 'Options'` + full reload. Matches Synapse parity (best-effort daily wipe).
3. **Phase 3 — MoneyFarm full refresh** — same. MoneyFarm has no native daily MIMO feed.

Body in [`sp_ddr_fact_mimo_allplatforms.aligned.sql`](./sp_ddr_fact_mimo_allplatforms.aligned.sql).

### 3.3 View files

- [`v_bad_ftd_cohort.sql`](./v_bad_ftd_cohort.sql) — predicate view; un-blacklist mechanism (`HAVING COUNT > 1`) documented prominently. Includes audit companion `v_bad_ftd_cohort_unblacklisted`.
- [`v_mimo_first_deposit_all_platforms.refactored.sql`](./v_mimo_first_deposit_all_platforms.refactored.sql) — same logic, now sources `v_bad_ftd_cohort` (single source of truth for cohort dates).
- [`v_mimo_allplatforms.aligned.sql`](./v_mimo_allplatforms.aligned.sql) — encapsulates: per-platform UNION, bad-cohort filter applied to `IsPlatformFTD`, filtered global FTD JOIN for `IsGlobalFTD`, IsCryptoToFiat synthesis.

### 3.4 Key design decisions

1. **`v_bad_ftd_cohort` is the single source of truth.** Cohort dates live in ONE `VALUES` list. Both `v_mimo_first_deposit_all_platforms` AND `v_mimo_allplatforms` consume it. New cohort dates → edit one view → flows everywhere. Eliminates the exact drift that broke Synapse (cohort dates added to TVF, forgotten in recovery UPDATE).
2. **Un-blacklist mechanism is inside `v_bad_ftd_cohort` (via `HAVING COUNT > 1`).** A $1-cohort customer who later makes a legit 2nd deposit drops out of the cohort view automatically, then naturally becomes a legitimate FTDer in the TVF and in `v_mimo_allplatforms`. No separate maintenance, no recovery pass.
3. **`v_mimo_allplatforms` applies the bad-cohort filter to `IsPlatformFTD` too (NEW vs current prod view).** Current production view passes `IsFTD` from per-platform views through unmodified — including bad cohort. After this refactor, both flags co-move with cohort status. Synapse intends the same (its recovery UPDATE sets both).
4. **No `MERGE`, no recovery `UPDATE` in the SP.** All recovery semantics live in the view via re-evaluation against current source state. To pick up late-arriving DimCustomer updates for historical dates, rerun the SP per date.
5. **Idempotent.** Running for the same date twice → same output. Running for any date refreshes Options + MoneyFarm globally plus that date's TP/eMoney slice.

### 3.5 Validated output for 2026-05-22 (2026-06-01 test run)

| Platform | Action | Synapse pftd/gftd | DBX pre-run pftd/gftd | DBX post-run pftd/gftd |
|---|---|---:|---:|---:|
| TP | Deposit | **17,893 / 17,893** | 17,893 / 662 | **692 / 692** ✓ |
| TP | Withdraw | 0 / 0 | 0 / 0 | 0 / 0 |
| eMoney | Deposit | 305 / 305 | 305 / 305 | 305 / 305 |
| eMoney | Withdraw | 0 / 0 | 0 / 0 | 0 / 0 |
| Options | Deposit | 1 / 1 | 1 / 1 | 1 / 1 |
| Options | Withdraw | 0 / 0 | 0 / 0 | 0 / 0 |
| MoneyFarm | Deposit | 10 / 10 | 10 / 10 | 10 / 10 |

**Result:** DBX post-run shows TP Deposit at **692/692** — bad cohort excluded from BOTH flags, both flags co-move, un-blacklisted 35 picked up. Synapse remains at 17,893/17,893 (buggy recovery UPDATE counts the bad cohort). Row counts and `sum_usd` match across all platforms; the only divergence is the FTD flag count on TP Deposit (DBX more correct).

### 3.6 Two bugs caught during the test run (and fixed)

#### 3.6.1 Self-reference bug in `v_bad_ftd_cohort`

**Symptom:** After first SP run, TP Deposit landed at 662/662 instead of expected 692/692. 30 un-blacklisted customers lost their FTD flag.

**Root cause:** The original `v_bad_ftd_cohort` counted multi-deposit customers from `BI_DB_DDR_Fact_MIMO_AllPlatforms` itself. When the SP did `DELETE WHERE DateID = 20260522` between phases, the fact lost rows. The cohort view re-evaluated and customers whose only 2nd deposit was on 5/22 re-blacklisted; the subsequent INSERT then wrote their 5/22 row with both flags = 0. The post-run audit looked correct (rows were back in the fact) but the WRITTEN values reflected mid-transaction state.

**Fix:** Change `v_bad_ftd_cohort` to count deposits from upstream source-of-truth tables (`Fact_CustomerAction` for TP/IBAN + `eMoney_Fact_Transaction_Status` for eMoney) instead of from the MIMO fact. Same semantic, stable against in-SP DELETEs.

#### 3.6.2 `NOT IN` NULL bug

**Symptom:** After fix 3.6.1, `v_bad_ftd_cohort` returned 0 rows. Cohort filter disabled. TP Deposit landed at 17,893/17,893 (same as Synapse buggy state).

**Root cause:** `upstream_deposits` contained 2 NULL RealCIDs (from `Fact_CustomerAction` rows with NULL RealCID). They grouped into `multi_deposit_cids` (count = 2 > 1). Then `dc.RealCID NOT IN (SELECT RealCID FROM multi_deposit_cids)` returned NULL for every row due to SQL three-valued logic with NULLs.

**Fix:** Switch `NOT IN` → `NOT EXISTS` (correctly handles NULLs) AND filter `RealCID IS NOT NULL` in `upstream_deposits` as belt-and-suspenders.

Both fixes encoded in the deployed view; comments in [`v_bad_ftd_cohort.sql`](./v_bad_ftd_cohort.sql) document them prominently.

---

## 4. NEXT 1-BY-1 ITEM: `sp_ddr_customer_daily_status`

**Status:** small impact, dealing with it next. The user has explicitly flagged this as the next item after MIMO.

DBX body (`de_output.sp_ddr_customer_daily_status`, 19KB) is structurally aligned with Synapse on the read side — builds populationTP/IBAN/Options/MoneyFarm tables, joins to snapshotcustomer / population_funded / etc., reads MIMO fact for daily flags. We patched it during today's work for `IsDepositor` BOOLEAN handling, `IsDepositorGlobal` calculation, and pointed the MIMO read at `bi_db.gold_..._mimo_allplatforms` instead of the stale `de_output.de_output_ddr_fact_mimo_allplatforms`.

What it's still missing vs Synapse (to be diffed properly in the next pass):

| Synapse feature | DBX status | Impact |
|---|---|---|
| Late-FTD recovery on `OptionsFirstDeposited` (`CASE WHEN Options_FTD_DateID = p_date_id THEN 1 ELSE mi.OptionsFirstDeposited END`) | ✅ Present (last verified body) | None |
| Same for `MoneyFarmFirstDeposited` | ✅ Present | None |
| Same for `DepositedOptions` | ✅ Present | None |
| `FirstTimeFunded` derived from `v_population_first_time_funded` | ✅ Present | None |
| Re-evaluate `IsDepositorGlobal` against `Dim_Customer.IsDepositor` post-row-build | 🟡 Done at compute-time via the new IsDepositorGlobal expression (covers the gap) | None |
| Deduplication at the end ("dual processing of withdraw" bug fix) | ❓ Need to diff full SP body | Minor — may produce duplicate rows in edge cases |
| Notebook job inlines `CREATE OR REPLACE PROCEDURE` — direct UC edits get overwritten | 🔴 Confirmed today | Operational: any SP fix needs to land in the notebook, not just UC |

**Action plan for the next 1-by-1 pass:**
1. Pull the full DBX SP body + the full Synapse SP body (98KB).
2. Diff section by section.
3. Identify the notebook that re-creates the SP in prod and patch it in lockstep with the UC SP.
4. Rerun the affected May window once MIMO is refactored & deployed.

---

## 5. RESOLVED: `sp_ddr_customer_periodic_status` — eliminate the table

**Decision (user):** the DBX TVF `de_output.ddr_tvf_customer_periodic_status` is performant enough to negate the need for materializing. The table `bi_db.gold_..._bi_db_ddr_customer_periodic_status` is targeted for deprecation.

**No SP wrapper to build.** Instead:

1. Audit consumers of the materialized table (Tableau, downstream notebooks, Marketing Cloud feeds, Synapse-side joins, etc.). Capture the list.
2. Point each consumer at the TVF.
3. Once all consumers are migrated, drop the table (and the Synapse-side Lakeflow sync that populates it, if applicable).

**Open question:** is anything currently writing the DBX table? Need a quick check on the Delta history of `gold_..._bi_db_ddr_customer_periodic_status` to confirm (Synapse sync vs no writes vs something else). That tells us whether the migration is "switch consumers" or "switch consumers + retire sync job".

---

## 6. NEW WORK: `sp_ddr_fact_non_revenue_generating_actions`

The Synapse SP (16KB) produces a granular daily fact of non-revenue customer actions: compensation pivots (RAF, PI w/wo cashout, affiliate w/wo cashout, C2P), stoploss edits, investment amounts opened/closed, login (with depositor flag), registration, copy actions (add/remove/new/stop), social actions (post/comment/like), P&L adjustments, bonuses.

DBX has the *table* (`gold_..._bi_db_ddr_fact_non_revenue_generating_actions` presumably exists for sync), but no native producer.

Priority: medium. Build a `v_ddr_non_revenue_actions` view + thin SP wrapper modeled on the Revenue SP pattern. Defer to a separate proposal/PR — it's an additive new SP, not a fix to an existing one. Document the gap, schedule the work.

---

## 7. Phase plan

### Drafted (uncommitted, ready for review)
- ✅ This investigation doc
- ✅ `v_bad_ftd_cohort.sql` — predicate view + audit companion `v_bad_ftd_cohort_unblacklisted`
- ✅ `v_mimo_first_deposit_all_platforms.refactored.sql` — same logic, consumes `v_bad_ftd_cohort`
- ✅ `v_mimo_allplatforms.aligned.sql` — encapsulates all MIMO logic (recovery via view re-evaluation, bad-cohort filter on both flags)
- ✅ `sp_ddr_fact_mimo_allplatforms.aligned.sql` — thin 3-phase materializer

### Deploy day 1 (MIMO — after review)
1. Deploy `v_bad_ftd_cohort` (+ audit companion).
2. Deploy refactored `v_mimo_first_deposit_all_platforms`. Verify same rows returned for 5/22.
3. Deploy refactored `v_mimo_allplatforms`. Verify standalone view returns expected counts for 5/22 (TP IsPlatformFTD ~ 35, TP IsGlobalFTD ~ 35).
4. Deploy refactored `sp_ddr_fact_mimo_allplatforms`.
5. Rerun SP for `20260522`, `20260523`, `20260525`. Verify the cohort dates land cleanly.
6. Rerun SP for the May 9–20 dates loops covered yesterday — same view re-evaluates from current source.

### Deploy day 2 (Daily Status — next 1-by-1 item)
7. Pull full Synapse `SP_DDR_Customer_Daily_Status` body, diff against DBX `sp_ddr_customer_daily_status` line-by-line.
8. Identify and patch the production notebook that re-creates the SP inline (so UC fixes survive job runs).
9. Rerun `sp_ddr_customer_daily_status` for May 9 onward — consumes the now-correct MIMO fact.
10. DBX↔Synapse parity verification for the full May window on `IsDepositor`, `IsDepositorGlobal`, the FirstDeposit flags.

### Deploy day 3 (Periodic Status — table deprecation)
11. Inventory consumers of `bi_db.gold_..._bi_db_ddr_customer_periodic_status` (Tableau, notebooks, Marketing Cloud, Synapse-side joins).
12. Migrate consumers to the TVF (`main.de_output.ddr_tvf_customer_periodic_status`).
13. Once cutover, drop the table and (if applicable) retire the Synapse sync job.

### Follow-up (lower priority, separate proposals)
14. `sp_ddr_fact_non_revenue_generating_actions` — schedule new SP build (no DBX producer today).
15. `sp_ddr_fact_trading_volumes_and_amounts` `BI_DB_VolumeQA` parity — port the QA dump or document the omission.

### Open question (in parallel — Synapse side)
16. Patch Synapse `SP_DDR_Fact_Fact_MIMO_AllPlatforms` recovery UPDATEs to apply `REMOVE_BAD_FTDS` (per [`synapse_sp_recovery_update_bug.md`](./synapse_sp_recovery_update_bug.md)). DBX will be more correct than Synapse until this lands.

---

## 8. Risks & mitigations

| Risk | Mitigation |
|---|---|
| `v_mimo_allplatforms` evaluates `Dim_Customer` + 4 per-platform views — could be slow at scale | Per-date filter pushes down through `v_mimo_tradingplatform`/`v_mimo_emoneyplatform`. Options/MoneyFarm full-refresh phases are bounded by their own platform sizes (small). Benchmark on bidev. |
| Bad-cohort filter on `IsPlatformFTD` is a SEMANTIC CHANGE from current prod (drops the cohort's pftd from 17,236 → ~35) | Documented in §3.5. Synapse intends the same. Sync downstream consumers before deploy if they read `IsPlatformFTD` cumulatively. |
| `v_bad_ftd_cohort` reads `BI_DB_DDR_Fact_MIMO_AllPlatforms` to apply the un-blacklist predicate — self-referential | Same as Synapse: works because the predicate evaluates against the *current* state of MIMO fact. View runs after MIMO is loaded for the current cycle; un-blacklist becomes visible on the next rerun. |
| New cohort dates require a view edit | Yes, single point — edit `cohort_dates` VALUES list in `v_bad_ftd_cohort` and redeploy. All downstream views automatically pick it up. |
| Late-arriving DimCustomer updates flip flags for dates already exported to downstream consumers (Marketing Cloud) | Out of scope here — same problem exists in Synapse and is accepted. Mitigated by rerunning SP for affected dates and re-exporting. |
| Loop reruns for wide windows are slower than Synapse's single wide-scope UPDATE | Acceptable per user direction — the per-date model is the cost of "all logic in the view". Photon makes per-date materialization fast (~seconds per date). |

---

## 9. Open questions for you

1. **Bad-cohort filter on `IsPlatformFTD`:** confirm you're OK with this dropping from 17,236 → ~35 for the cohort dates. Synapse intends the same; this is the "blood-written" semantic that Synapse drifted away from. Until Synapse is patched (§7 item 16), DBX will be MORE correct than Synapse on `IsPlatformFTD` for cohort dates.
2. **Options/MoneyFarm full refresh:** confirm we're keeping the wipe-and-reload model (vs migrating to per-date with a separate backfill SP). I'd vote keep — Synapse parity, simpler.
3. **`sp_ddr_fact_non_revenue_generating_actions`:** anyone consuming the DBX table downstream? If only Synapse-sync feeds existing dashboards, we can defer indefinitely.
4. **Audit-companion view `v_bad_ftd_cohort_unblacklisted`:** keep as a public companion view, or pull it into a private/internal-only namespace? It's useful for spot-checking but not for production consumption.

---

Sibling files in this folder:
- [`v_bad_ftd_cohort.sql`](./v_bad_ftd_cohort.sql) — reusable predicate view + audit companion
- [`v_mimo_first_deposit_all_platforms.refactored.sql`](./v_mimo_first_deposit_all_platforms.refactored.sql) — same logic, sources `v_bad_ftd_cohort`
- [`v_mimo_allplatforms.aligned.sql`](./v_mimo_allplatforms.aligned.sql) — proposed view DDL with all MIMO logic
- [`sp_ddr_fact_mimo_allplatforms.aligned.sql`](./sp_ddr_fact_mimo_allplatforms.aligned.sql) — proposed thin SP DDL
- [`synapse_sp_recovery_update_bug.md`](./synapse_sp_recovery_update_bug.md) — companion Synapse fix
