# `sp_ddr_customer_daily_status` alignment — DBX ↔ Synapse

**Date:** 2026-06-01
**Status:** proposal — awaiting approval
**Prod deployment model:** thin wrapper job (UC edits persist; no inline notebook recreation)
**Companion:** [`sp_alignment_investigation.md`](./sp_alignment_investigation.md) §4

---

## 1. Diff summary

Pulled both bodies (Synapse: 98KB / DBX: ~19KB). Read-side structure is broadly aligned — population assembly, FSC join, TVF-equivalent reads, segment partition, MIMO daily flags, login flags, FTD pivot. Differences fall into 4 buckets.

| # | Synapse pattern | DBX status | Severity | Action |
|---|---|---|---:|---|
| 1 | `#mimo_coerced` eMoney leg — date-coerce eMoney FTD rows where `TxStatusModificationDate ≠ Dim_Customer.FirstDepositDate AND FirstDepositDate >= '2025-09-01'`. Coerced row is aligned to DimCustomer's canonical date. | ❌ Missing | 🟡 Material — small | Port |
| 2 | `#mimo_coerced` TP leg — same shape for TP, gated by `Dim_Customer.FTDRecoveryDate IS NOT NULL`. | ❌ Missing | 🟡 Material — small | Port |
| 3 | `#mimo_coerced_withdraw` — withdraws for coerced CIDs (preserves cashout/redeem flags on the canonical day). | ❌ Missing | 🟡 Minor — depends on #1/#2 | Port (with #1/#2) |
| 4 | `Function_Population_Active_Traders` includes Options trading detection (via `Function_Revenue_OptionsPlatform`). | 🟡 DBX `_tmp_ddr_at` only checks `Fact_CustomerAction.ActionTypeID IN (1,39,15,17)` — no Options trade detection. | 🟡 Material for Options-only traders | Port |
| 5 | Final SELECT `WHERE RN = 1` dedup (band-aid for "dual processing of withdraw" prod bug). | ❌ Missing | 🟢 Edge case | Port (defensive) |
| 6 | Cosmetic: Synapse calls dedicated TVFs (Funded / FirstTimeFunded / FirstTradingAction). DBX inlines via `v_population_*` views. | ✅ Equivalent | 🟢 None | Skip |
| 7 | Cosmetic: DBX SP references `v_mimo_options_platform`. Both `v_mimo_options_platform` and `v_mimo_optionsplatform` exist with identical row counts. | 🟢 Cosmetic alias | 🟢 None | Pick canonical, drop the other later |

---

## 2. Impact measurement on live data (2026-06-01)

### Coercion population (gaps 1/2):

| Bucket | Distinct CIDs |
|---|---:|
| eMoney coercion candidates total (Sep 2025 → now) | 279 |
| eMoney coercion candidates with `FirstDepositDate = 2026-05-22` | **0** |
| TP coercion candidates total (Sep 2025 → now) | 7 |
| TP coercion candidates with `FirstDepositDate = 2026-05-22` | **0** |

May 2026 daily breakdown of eMoney coercion (DimCustomer date):

| dim_date | coerced_cids |
|---|---:|
| 2026-05-28 | 2 |
| 2026-05-27 | 6 |
| 2026-05-21 | 1 |
| 2026-05-19 | 2 |
| 2026-05-16 | 1 |
| 2026-05-13 | 1 |
| 2026-05-12 | 3 |
| 2026-05-07 | 1 |
| 2026-05-06 | 1 |
| 2026-05-02 | 1 |
| 2026-05-01 | 1 |

**Read:** small but non-zero — 1-6 CIDs/day get their canonical FTD day shifted. Downstream consumers that filter `IBANFirstDeposited = 1 AND DateID = X` (Marketing Cloud cohort exports, Tableau retention dashboards) will misalign by 1 day for these CIDs without coercion. Synapse parity requires the port.

### Active Traders Options gap (gap 4):

Synapse pulls Options trades from `Function_Revenue_OptionsPlatform`. DBX `_tmp_ddr_at` doesn't include that source. Customers who only trade Options on a given day would be classified `BalanceOnlyAccount` or `Portfolio_Only` in DBX instead of `ActiveTraded`.

(Magnitude: Options trading is small but growing. Patch is one CTE addition.)

---

## 3. Proposed aligned body

See [`sp_ddr_customer_daily_status.aligned.sql`](./sp_ddr_customer_daily_status.aligned.sql).

### Structural changes from current DBX:

1. **Add `_tmp_ddr_mimo_coerced`** — port Synapse's `#mimo_coerced` (UNION ALL of eMoney and TP legs). Sources: `BI_DB_DDR_Fact_MIMO_AllPlatforms` JOIN `Dim_Customer` (and for eMoney, also `eMoney_Fact_Transaction_Status` for the SourceCugTransactionID match).
2. **Add `_tmp_ddr_mimo_coerced_withdraw`** — withdraws for those CIDs (only consulted by the cashout/redeem flags in the coerced aggregation arm).
3. **Bifurcate MIMO aggregation** — split `_tmp_ddr_mimo` into:
   - `_tmp_ddr_mimo_non_coerced` — current path, MIMO rows for `RealCID NOT IN coerced`.
   - `_tmp_ddr_mimo_coerced_agg` — for coerced RealCIDs: uses `_tmp_ddr_mimo_coerced` date (which is DimCustomer canonical) for FirstDeposit flags + `_tmp_ddr_mimo_coerced_withdraw` for cashout/redeem flags.
   - `_tmp_ddr_mimo = UNION ALL` of both.
4. **Extend `_tmp_ddr_at`** — add Options trading detection. Two routes:
   - Quickest: union with `main.etoro_kpi_prep.v_revenue_optionsplatform` (single-day filter), `ActionTypeID = 1`, JOIN to `dim_customer_masked` for RealCID. Matches Synapse's `ActiveOptions` CTE.
5. **Final SELECT** — wrap insert in `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY RealCID) AS rn` filter `rn = 1` (defensive against duplicates from the dual-processing bug Synapse already documents).
6. **Pin canonical Options-MIMO view name** — pick one of `v_mimo_options_platform` / `v_mimo_optionsplatform`. Recommendation: keep `v_mimo_optionsplatform` (matches the rest of the family: `v_mimo_tradingplatform`, `v_mimo_emoneyplatform`, `v_mimo_allplatforms`). Drop `v_mimo_options_platform` in a separate cleanup PR after confirming no consumers.

### Things kept unchanged:

- Population assembly across 5 sources.
- FSC join via `v_fact_snapshotcustomer_fromdateid_masked`.
- TVF replacements: `v_population_funded`, `v_population_first_time_funded`, `v_population_first_trading_action`.
- `_tmp_ddr_po` (portfolio only) — already includes options AUM.
- `_tmp_ddr_bo` (balance only) — already includes tp_equity + iban_equity + options_equity.
- Embedded `OptionsFirstDeposited`/`DepositedOptions`/`MoneyFarmFirstDeposited` recovery via `CASE WHEN ft.X_FTD_DateID = p_date_id THEN 1 ELSE ... END`.
- `IsDepositorGlobal` logic (patched today).
- `IsDepositor = true` boolean handling (patched today).
- All output columns.

---

## 4. Test plan

1. Deploy aligned SP body to UC.
2. Run for `20260522` (today's reference date).
3. Compare DBX `daily_status` to Synapse for 5/22:
   - Row count
   - Sums of: `IsDepositor`, `IsDepositorGlobal`, `IsFunded`, `FirstTimeFunded`, `GlobalDeposited`, `GlobalFirstDeposited`, `TPFirstDeposited`, `IBANFirstDeposited`, `OptionsFirstDeposited`, `MoneyFarmFirstDeposited`, `ActiveTraded`, `BalanceOnlyAccount`, `Portfolio_Only`, `AccountActive`, `AccountInActive`, `LoggedIn`.
4. Expected post-deploy:
   - `TPFirstDeposited` drops from 17,893 → ~692 (DBX MIMO refactor flowing through; DBX MORE correct than Synapse until Synapse MIMO patch).
   - `IBANFirstDeposited`: 0-1 CID difference per day from coercion (we'll match Synapse).
   - `ActiveTraded`: small uplift from Options trading detection.
   - All other metrics: 1:1.
5. Loop rerun for May 9 → today once parity confirmed on 5/22.

---

## 5. Risk assessment

| Risk | Mitigation |
|---|---|
| Coerced aggregation logic introduces bug for non-coerced CIDs | Bifurcation is deterministic: `RealCID IN coerced` ↔ goes to coerced arm; `RealCID NOT IN coerced` ↔ goes to non-coerced arm. UNION ALL. Both arms have identical schema. Validated by row-by-row diff for a spot-check sample. |
| Active Traders Options addition flags too many CIDs (over-count) | Mirror Synapse: `ActionTypeID = 1` only (Options buy), not all Options events. Should produce conservative count matching Synapse `Function_Population_Active_Traders`. |
| `ROW_NUMBER` dedup masks a real bug | It's defensive — same posture as Synapse. The dual-processing bug Synapse documents is upstream in the MIMO feed; this is the last-line defense. |
| Cosmetic view-alias change breaks consumers | Don't drop `v_mimo_options_platform` in this PR. Just stop using it in the SP. Cleanup separately. |

---

## 6. Out of scope (defer)

- Notebook-side wrapper: per user, prod is a thin wrapper that `CALL`s the SP. No inline `CREATE OR REPLACE PROCEDURE` in the notebook to patch.
- Drop `v_mimo_options_platform` — separate cleanup PR after consumer audit.
- `IsDepositor` reconciliation between coerced and non-coerced arms — Synapse doesn't reconcile; we preserve the same behavior.
