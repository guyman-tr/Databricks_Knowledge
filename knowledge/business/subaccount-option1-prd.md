# Sub-Account Option 1 — "Another GCID + CID" — Blast Radius PRD

**Scope of this document:** the static blast-radius footprint of Option 1 (mint a new GCID and CID per sub-account) inside the Synapse SQL pool `sql_dp_prod_we`, plus a phased rollout that makes the change safely deployable.

**Source of truth:**
- Snapshot of OpsDB Service Broker scheduling: [`_objectsstatus_snapshot.csv`](./_objectsstatus_snapshot.csv) — 936 distinct procedures, Synapse-only schemas (BI_DB / DWH / Dealing / eMoney / EXW / DE / general / dbo). Bronze/Silver/Gold data-lake paths excluded per scope clarification.
- Static scanner: [`_build_option1_archetypes.py`](./_build_option1_archetypes.py)
- **Per-SP triage CSV:** [`subaccount-option1-triage.csv`](./subaccount-option1-triage.csv) — 1,459 SQL files (SPs / Functions / Views) classified into one of 6 archetypes (A–F) plus X for "no destination INSERT detected". One row per object with: archetype, confidence, destination tables, parsed customer-key / money / count / dim / txn-grain / population-flag column lists, validity-gate evidence with line+snippet, GROUP-BY-on-customer-key evidence, recommended action, key insight.
- **Quantitative summary:** [`subaccount-option1-archetype-summary.json`](./subaccount-option1-archetype-summary.json) — counts by archetype, archetype × priority, recommended action; high-priority example SPs per archetype.
- **Archetype reference (engineer-facing):** [`subaccount-option1-archetypes.md`](./subaccount-option1-archetypes.md) — decision tree, definitions, sampled SP worked-examples, treatment recipes per archetype.

---

## TL;DR

1. **The problem reduces to one new helper table.** Build `general.Dim_MasterGCID(CID, GCID, master_CID, master_GCID, is_synthetic, sub_account_kind)` mapping every CID — real or synthetic — to the human "master" customer it belongs to. Every Option 1 fix is one of three operations on this table: `JOIN` it, swap a `GROUP BY` key, or filter `is_synthetic`.

2. **Every active Synapse SP falls into one of six archetypes** depending on the destination grain of its `INSERT INTO <real-table>` statement. The archetype determines the synthetic-user treatment:

   | # | Archetype | Treatment | Count | Priority-99 hits |
   |---|-----------|-----------|------:|-----------------:|
   | A | Customer-keyed snapshot (CID + flag/date cols) | filter synthetics OR enrich dest with `master_CID` | 189 | 1 |
   | B | Per-customer money aggregate (CID + money + GROUP BY CID) | swap `GROUP BY CID` → `GROUP BY master_CID` | 114 | 6 |
   | **C** | **Dim-grain rollup with `IsValidCustomer` validity gate** (NO CID in dest) — **REGULATOR-RISK** | **per-SP policy decision: do synthetics count as "valid"?** | **96** | **4** |
   | D | Money-flow at transaction grain (CID + PositionID/TransactionID) | enrich dest table with `master_CID` column | 81 | 5 |
   | E | Population headcount (NewUsers / NewWallets cols) | swap `COUNT(DISTINCT CID/GCID)` → `COUNT(DISTINCT master_GCID)` | 13 | 0 |
   | F | Non-customer dim grain, no validity gate | policy decision (usually no-op) | 155 | 2 |
   | X | No INSERT destination detected (views, functions, dispatchers, dynamic SQL) | manual review | 811 | 3 |

3. **Archetype C is the regulator-facing hot zone.** 96 SPs have NO customer key in their destination but their *source* filters `IsValidCustomer = 1` before aggregating. Whether a synthetic counts as "valid" silently determines whether their commission / volume / NWA gets reported to the regulator. **9 of these are priority ≥ 90 finance-package SPs** including KPMG IFR Capital-Adequacy submission and the four DDR aggregators. The non-mechanical labor lives entirely here.

4. **Archetypes A, B, D, E are mechanical.** Once `Dim_MasterGCID` exists, the fix for these 397 SPs is a templatable code edit — usually a `JOIN Dim_MasterGCID` plus one keyword swap. The CI gate is "every fixed SP produces identical output on baseline data (no synthetics) before deploy".

5. **Archetype F is mostly no-op.** 155 SPs aggregate at instrument / LP / HedgeServer / currency grain with no customer-level filter. Synthetics' positions naturally pass-through these (positions live once in `tradonomi`). Only 9 priority ≥ 21 F-SPs need explicit policy review.

6. **Archetype X is the manual-review backlog.** 811 files have no detectable INSERT destination — overwhelmingly views, functions, dispatcher SPs, and unscheduled legacy code. Of these, only ~17 are scheduled at priority ≥ 60 (most are dispatchers that auto-resolve once their callees are fixed; `SP_PositionPnL` is the one priority-99 outlier that uses dynamic SQL and needs eyes-on).

7. **The schema-migration write path is tiny.** Three places need to populate `Dim_MasterGCID`: the SP that builds `Dim_Customer`, the upstream `External_*Customer*` source for the `is_synthetic` flag, and a one-time backfill script. `RealCID` semantics are NOT touched.

8. **Recommended rollout: 6 phases over ~10 weeks**, with Phase 2 split into 2a (mechanical A/B/D/E fix — scriptable) and 2b (per-SP C policy review — needs Finance + Compliance sign-off). 2a can run in parallel with 2b; 2b is the critical path.

---

## 1. The fundamental risk

Option 1 mints a synthetic real customer per sub-account: new `GCID_sub`, new `CID_sub`, full row in `UserApiDB.Customer.Customers` and downstream in `Dim_Customer`. Every existing `JOIN ON CID = CID`, every `WHERE CID = X`, every aggregation key continues to work mechanically. **That is the danger** — the joins do not break, but the semantics silently shift. There is no error message; there is just a different number on a regulator-facing report.

The risk is shaped by the destination grain of each SP, not by which patterns it uses internally. Three failure modes, mapped to archetypes:

| Failure mode | Archetypes affected | Fix shape |
|--------------|---------------------|-----------|
| **User-count inflation.** Each synthetic is counted as a new active / funded / registered customer. FTD numbers, KYC populations, AML pop counts inflate by Nx. | A (189), E (13) | Filter at population definition: `WHERE m.is_synthetic = 0` (Archetype A) or `COUNT(DISTINCT master_GCID)` (Archetype E). |
| **Money-flow split across master + synthetic.** Each synthetic generates its own row of money sums; the regulator sees "customer X has $100" + "customer X-sub-1 has $50" instead of "customer X has $150". | B (114), D (81) | Aggregate to master via `JOIN Dim_MasterGCID m` + `GROUP BY m.master_CID`. For transaction-grain (D), enrich the destination with a `master_CID` column so downstream B-SPs don't each have to redo the join. |
| **Validity-gate ambiguity.** Source filters `IsValidCustomer = 1` *before* aggregating to a non-customer dim grain. Whether a synthetic gets `IsValidCustomer = 1` (inheriting from master) or `0` (excluded) silently changes the dim aggregate without any flag in the output. | **C (96)** | **Per-SP policy decision** — does the regulator's view want the synthetic's flow rolled to master, excluded entirely, or kept as a separate row? Cannot be defaulted; must be reviewed with Finance + Compliance. |

The first two failure modes (A/E and B/D) are **mechanical** — once the
design is signed off, the fix is a templatable code edit. The third one (C)
is **non-mechanical** — it's a per-SP decision touching 96 SPs of which 9
are priority ≥ 90.

> **What this PRD explicitly does NOT touch:** `RealCID` semantics. The
> previous regex-based scanner flagged 7,820 `RealCID` references as
> in-scope; ~all of them were noise. `RealCID` is legacy mirror-account
> scaffolding from the copy-trading domain. The new identity column is
> `master_CID` on the new `Dim_MasterGCID` table — **not** a redefinition
> of `RealCID`. See § 4.1 for the half-page on why.

---

## 2. The `Dim_MasterGCID` design — one table, three operations

```sql
CREATE TABLE general.Dim_MasterGCID (
    CID                 BIGINT       NOT NULL,    -- every CID in the system, real or synthetic
    GCID                BIGINT       NOT NULL,    -- the GCID this CID belongs to
    master_CID          BIGINT       NOT NULL,    -- the "real customer" CID for this group
    master_GCID         BIGINT       NOT NULL,    -- the "real customer" GCID (= GCID for non-synthetic rows)
    is_synthetic        BIT          NOT NULL,    -- 1 = sub-account / bot-trader / etc, 0 = real customer
    sub_account_kind    VARCHAR(40)  NULL,        -- 'real' | 'sub_currency' | 'sub_strategy' | 'bot_trader'
    valid_from          DATE         NOT NULL,    -- as-of date when this mapping became active
    valid_to            DATE         NULL         -- NULL = current
);
CREATE STATISTICS Stat_Dim_MasterGCID_CID         ON general.Dim_MasterGCID(CID);
CREATE STATISTICS Stat_Dim_MasterGCID_master_GCID ON general.Dim_MasterGCID(master_GCID);
```

For every existing real customer, `is_synthetic = 0` and `master_CID = CID`, `master_GCID = GCID` (self-reference). For every synthetic CID minted by Option 1, `is_synthetic = 1` and `master_CID` / `master_GCID` point at the human user behind the sub-account.

**Three operations cover every archetype's fix:**

| Op | Where to use | SQL pattern |
|----|--------------|-------------|
| `JOIN Dim_MasterGCID` + filter `is_synthetic = 0` | Archetype A (filter at population) | `LEFT JOIN general.Dim_MasterGCID m ON m.CID = src.CID WHERE m.is_synthetic = 0` |
| `JOIN Dim_MasterGCID` + replace `GROUP BY` key | Archetype B | `JOIN general.Dim_MasterGCID m ON m.CID = src.CID ... GROUP BY m.master_CID` |
| `JOIN Dim_MasterGCID` + enrich destination | Archetype D, optionally A | add `master_CID BIGINT` to dest, populate from join |

**Population:**

- **At customer-creation time (OLTP).** When `UserApiDB.Customer.Customers` mints a new row, an OLTP trigger or service writes the corresponding `Dim_MasterGCID` row. Simplest: a single OLTP service owns the table.
- **At `Dim_Customer`-build time (DWH).** The SP that builds `DWH_dbo.Dim_Customer` joins `Dim_MasterGCID` and re-asserts the mapping. Acts as the consistency check.
- **One-time backfill.** All existing CIDs get `master_CID = CID`, `is_synthetic = 0`. ~50M rows. Single-pass CTAS, completes in minutes on Synapse.

### 2.1 Why `Dim_MasterGCID` and not `Dim_Customer.master_CID`?

Putting the mapping on `Dim_Customer` would seem cheaper (no new table). It's not, for three reasons:

- **`Dim_Customer` recompiles cascade.** Every SP that reads `Dim_Customer` schemas-recompiles when the table changes. Adding a column triggers recompilation of ~390 SPs. A separate table doesn't.
- **The mapping is small and dense.** 50M rows × 5 cols × HASH(CID) distribution → fits in a single distribution unit. `Dim_Customer` is wider and serves a different purpose (customer attributes, KYC, risk).
- **Independent ownership.** The mapping has its own SLA (must be populated for every active CID before downstream SPs run) and its own backfill semantics. Cleaner to govern as a standalone table.

---

## 3. The 6 archetypes — distribution by service-broker priority

Source: [`subaccount-option1-archetype-summary.json`](./subaccount-option1-archetype-summary.json). Severity ordering for picking the dominant archetype when an SP has multiple INSERT destinations: **C > A > B > D > E > F > X**.

### 3.1 Archetype × priority matrix

| Priority | A | B | **C** | D | E | F | X | Total |
|---------:|--:|--:|------:|--:|--:|--:|--:|------:|
| 99 (FinanceReportSPS) | 1 | 6 | **4** | 5 | 0 | 2 | 3 | 21 |
| 98 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 1 |
| 90 | 2 | 0 | **4** | 1 | 0 | 0 | 1 | 8 |
| 80 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| 70 | 0 | 1 | 0 | 0 | 0 | 0 | 2 | 3 |
| 60 | 7 | 11 | 0 | 6 | 1 | 3 | 8 | 36 |
| 21 | 1 | 1 | **1** | 0 | 0 | 3 | 1 | 7 |
| 20 | 29 | 17 | **20** | 6 | 2 | 15 | 65 | 154 |
| 15 | 0 | 1 | 1 | 0 | 0 | 2 | 3 | 7 |
| 10 | 2 | 6 | 0 | 6 | 0 | 2 | 2 | 18 |
| 1 | 0 | 0 | 1 | 0 | 0 | 0 | 3 | 4 |
| 0 | 112 | 52 | **50** | 36 | 4 | 67 | 126 | 447 |
| unscheduled | 35 | 18 | 15 | 21 | 6 | 60 | 597 | 752 |
| **Total** | **189** | **114** | **96** | **81** | **13** | **155** | **811** | **1,459** |

### 3.2 The C-archetype priority ≥ 90 hot list (regulator-facing)

These 9 SPs concentrate the entire non-mechanical labor of the project. Mistakes here go straight to a regulator filing.

| Pri | Object | What it produces | Note |
|---:|--------|------------------|------|
| 99 | `BI_DB_dbo.SP_VarCommission` | LP variable-commission settlement at Regulation × Instrument grain | Affects LP commission payouts |
| 99 | `BI_DB_dbo.SP_Client_Balance_New` | Daily client-balance reconciliation (hybrid: CID + IsValidCustomer gate) | Highest volume |
| 99 | `BI_DB_dbo.SP_Finance_Non_US_Settlement_Report` | Non-US settlement report | Per-instrument |
| 99 | `BI_DB_dbo.SP_Real_Crypto_Loans` | Crypto loan principal at Regulation grain | New product line |
| 90 | `BI_DB_dbo.SP_DDR` | Daily Detailed Report top-level | Tier-1 finance feed |
| 90 | `BI_DB_dbo.SP_DDR_Aggregated` | DDR rollup | |
| 90 | `BI_DB_dbo.SP_DDR_Aggregated_Auxiliary_Metrics` | DDR aux metrics | |
| 90 | `BI_DB_dbo.SP_DDR_Auxiliary_Metrics` | DDR aux | |
| 21 | `Dealing_dbo.SP_Capital_Adequacy_IFR_KPMG` | KPMG IFR capital-adequacy submission | Direct regulator filing |

Plus `Dealing_dbo.SP_DealingDashboard_Clients` (pri=20, internal but high-visibility).

### 3.3 The A/B/D priority ≥ 90 mechanical-fix anchor list

These 21 SPs are the mechanical-fix campaign for Phase 2a. Each one gets a templatable `Dim_MasterGCID` join + keyword swap.

| Archetype | Pri | Object |
|-----------|----:|--------|
| A | 99 | `BI_DB_dbo.SP_M_Crypto_RECON` |
| A | 90 | `BI_DB_dbo.SP_CIDFirstDates` |
| A | 90 | `BI_DB_dbo.SP_FirstTimeFunded` |
| B | 99 | `BI_DB_dbo.SP_ASIC_ClientBalanceFinance` |
| B | 99 | `BI_DB_dbo.SP_CB_Gap_Categorization` |
| B | 99 | `BI_DB_dbo.SP_CID_Daily_NWA` |
| B | 99 | `BI_DB_dbo.SP_Crypto_NOP` |
| B | 99 | `BI_DB_dbo.SP_Daily_CreditLine` |
| B | 99 | `BI_DB_dbo.SP_Outliers_New` |
| D | 99 | `BI_DB_dbo.SP_CycleGap` |
| D | 99 | `BI_DB_dbo.SP_DailyDividendsByPosition` |
| D | 99 | `BI_DB_dbo.SP_DepositWithdrawFee` |
| D | 99 | `BI_DB_dbo.SP_Finance_Panel_Reports` |
| D | 99 | `BI_DB_dbo.SP_RealCrypto_Lev2` |
| D | 90 | `BI_DB_dbo.SP_Futures_Finance_Prep_Data` |

Functions of equal weight (unscheduled, but called by the above):

- `BI_DB_dbo.Function_DDR_Aggregation_*` (8 functions — already use `@OnlyValidCustomers`)
- `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms`
- `BI_DB_dbo.Function_Population_Active_Traders`
- `BI_DB_dbo.Function_Population_Funded`
- `BI_DB_dbo.Function_Population_First_Trading_Action`
- `BI_DB_dbo.Function_Trading_Volume`

These functions are the natural injection points for an `@IncludeSubAccounts BIT = 0` parameter to make the Dim_MasterGCID gate explicit at the call site.

### 3.4 The X-archetype priority ≥ 60 manual-review queue

These 17 priority ≥ 60 X-rows have no detectable INSERT destination; manual review is needed. Most are dispatchers that auto-resolve once their callees are fixed; the priority-99 outliers are the first concern.

| Priority | Object | Likely shape |
|---------:|--------|--------------|
| 99 | `BI_DB_dbo.SP_DailyZero_TreeSize_NEW` | Dispatcher / dynamic SQL |
| 99 | `BI_DB_dbo.SP_Daily_CB_Gaps_All` | Dispatcher (calls SP_Daily_CB_Gaps_*) |
| 99 | `BI_DB_dbo.SP_PositionPnL` | **Dynamic SQL — eyes-on required** |
| 90 | `general.SP_Run_Tangany_ADF` | ADF trigger wrapper |
| 70 | `BI_DB_dbo.SP_UsageTracking_SF` | Snowflake export |
| 70 | `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` | Dispatcher |
| 60 | (8 SPs) | Mostly EXW / DE extraction wrappers |

---

## 4. Identity-column design

### 4.1 Why `RealCID` is NOT the answer (half-page)

Earlier drafts of this PRD treated `RealCID` as the master-customer column for sub-accounts. That was wrong. `RealCID` is legacy mirror-account scaffolding from the copy-trading domain:

- When a child account copies a parent in the copy-trading product, the child gets its own `CID` while `RealCID` keeps pointing at the parent.
- `RealCID` is currently used as a rollup key in DDR / AML / Compliance SPs (`GROUP BY RealCID`, `JOIN ON CID = RealCID`).
- Sub-accounts under Option 1 have their OWN `RealCID` (which equals their own `CID` if they're not also a copy-mirror). They do not naturally reuse the legacy column.

Trying to overload `RealCID` to mean both "copy-trading mirror master" and "sub-account master" double-binds the column. Every existing AML / Compliance SP that uses `RealCID` for the copy-trading meaning would silently shift if Option 1 redefined it. **Don't do that.**

The correct shape is two orthogonal mappings:
- `RealCID` (existing) — for the copy-trading domain. **Untouched** by Option 1.
- `Dim_MasterGCID.master_CID` (new) — for sub-accounts under Option 1. Always populated for every CID.

A synthetic sub-account can have both: `RealCID = its own CID` (it isn't a copy-mirror) and `master_CID = the real human's CID` (it's a sub-account). They answer different questions.

### 4.2 The `Dim_MasterGCID` write path

Three places need to populate `Dim_MasterGCID`:

1. **OLTP customer-creation.** When the customer-service mints a new GCID/CID for a sub-account, it writes `Dim_MasterGCID` in the same transaction. The OLTP team owns this path.
2. **DWH dim-build SPs.** `DWH_dbo.SP_Dim_Customer` and the `External_*Customer*Customers` ingestion path read `Dim_MasterGCID` and join it onto the dimension build. Acts as a re-assertion check that the OLTP-side mapping is consistent.
3. **One-time backfill.** All existing CIDs get `master_CID = CID`, `is_synthetic = 0`, `valid_from = '1970-01-01'`. Single-pass CTAS.

Total schema-write footprint: 3 code paths, 1 new table. **No `Dim_Customer` schema change.** No `External_*` schema changes (the synthetic flag derives from the customer-source's `CustomerType` or equivalent; if no such flag exists, OLTP must add one — but that's the OLTP side, not DWH).

---

## 5. Phased rollout

Each phase is gated by the prior phase's deploy + 7-day stability window. Total: ~10 weeks one engineer + 2 weeks regulator-facing review for Phase 6. **Phase 2a (mechanical) and 2b (policy) run in parallel.**

| Phase | Goal | Touchpoints | Duration |
|:--|:--|:--|:--|
| 0 | Sign-off on `Dim_MasterGCID` design + Phase-2b policy framework. AML / Finance / Compliance review of the C-archetype hot list (§ 3.2). | docs only | 1 week |
| 1 | Schema add: create `general.Dim_MasterGCID`. Implement OLTP write path. One-time backfill for all existing CIDs with `is_synthetic = 0`. Rebuild `DWH_dbo.SP_Dim_Customer` to assert the mapping. No consumer-side changes yet. | 1 new table + 3 SPs | 1 week |
| **2a** | **Mechanical fix campaign for archetypes A, B, D, E.** Apply templatable `Dim_MasterGCID` join + keyword swap to the 397 A+B+D+E SPs. Heavily scriptable. CI gate: every fixed SP produces identical output on baseline data (no synthetics) before deploy. Includes adding `@IncludeSubAccounts BIT = 0` to the 14 affected `Function_*` siblings. | 397 SPs (189 A + 114 B + 81 D + 13 E), 14 functions | 4 weeks |
| **2b** | **Policy-driven fix for archetype C.** 96 SPs need explicit per-SP decision: do synthetics' money flows roll into the master at the dim aggregate (`m.master_CID` join), get excluded entirely (`m.is_synthetic = 0`), or stay separate? **Critical path** — Phase 6 is gated by 2b sign-off. | 96 C-archetype SPs (especially the 9 priority ≥ 90 hot list) | 4 weeks (parallel with 2a) |
| 3 | Archetype F sweep. Most are no-op; ~10 priority ≥ 21 F-SPs need explicit policy review (instrument-level dedup question). | 9 F-SPs at priority ≥ 21 + spot checks | 1 week |
| 4 | Archetype X manual review. The 17 priority ≥ 60 X-SPs are walked individually. `SP_PositionPnL` (dynamic SQL) is the one priority-99 X-row that needs real attention. | 17 X-SPs | 1 week |
| 5 | Genie / Wiki / Glossary updates. New column docs for `Dim_MasterGCID.master_CID`, `master_GCID`, `is_synthetic`. Decision matrix for archetype C SPs documented. Re-run Wiki batch jobs. | docs only | 1 week |
| 6 | UAT. First sub-account provisioned in production behind a feature flag, monitored for 7 days. Regulator notification (UK FCA Compliance SPs, KPMG IFR). Parallel-run for 2 weeks. | end-to-end | 2 weeks |

**Phase 2a is templatable.** A single transformation script can rewrite the 397 A+B+D+E SPs. Estimated 30 minutes per SP × 397 SPs ≈ 200 dev-hours / 5 weeks at 1 engineer; with templating, closer to 4 weeks.

**Phase 2b is the actual project.** 96 SPs × ~2-hour-per-SP review with Finance + Compliance ≈ 24 days of meeting-time spread over 4 weeks of calendar.

---

## 6. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|:--|:--|:--:|:--:|:--|
| **R0** | **Archetype C ambiguity. Regulator-facing dim-grain SPs silently corrupt KPMG / ASIC / FCA submissions either by inflation (synthetic flow attributed to master AND included under synthetic's own validity = double count) or invisibility (synthetic flow excluded from gated source AND not reattributed to master).** | **High** | **Critical** | Phase 2b: every C-archetype SP gets an explicit policy decision recorded in the triage CSV. Pre-deploy: 14-day parallel run of legacy vs new `SP_VarCommission`, `SP_Capital_Adequacy_IFR_KPMG`, all 4 `SP_DDR*` SPs. Investigate divergence > 0.1%. |
| R1 | An A or E archetype SP slips through Phase 2a; FTD / Registration / Funded counts inflate post-Phase 6. | Medium | High | Scanner re-run as a CI gate before Phase 6 launches. Diff archetype list pre/post-fix to confirm coverage. |
| R2 | A B or D archetype SP gets the master_CID swap wrong (e.g. forgets to swap `GROUP BY` key after adding the join, producing duplicate rows). | Medium | High | Phase 2a CI gate: assert every B/D SP produces identical output on baseline data. Code review: every PR includes a before/after row-count check. |
| R3 | The OLTP-side `is_synthetic` flag is set incorrectly at customer creation (e.g. defaults to 0 for synthetics). Every fix downstream silently breaks. | Medium | Critical | OLTP team owns Phase 1 acceptance test: insert a fake synthetic, verify `Dim_MasterGCID` reflects `is_synthetic = 1` within 5 minutes of customer creation. End-to-end smoke test as part of Phase 6 UAT. |
| R4 | A priority-99 archetype-X SP (e.g. `SP_PositionPnL` with dynamic SQL) is silently affected. | Medium | High | Phase 4 manual review of the 17 priority ≥ 60 X-SPs. `SP_PositionPnL` gets dedicated investigation. |
| R5 | An External_* upstream of `Dim_Customer` doesn't propagate the `is_synthetic` flag. | Low | High | Phase 1 includes upstream ingestion review. Source-of-truth = OLTP `UserApiDB.Customer.Customers.IsSynthetic` (or equivalent). |
| R6 | Power BI / Tableau / Genie consumers cache the old DDR / NOP semantics. Customer-facing dashboards show stale numbers. | Medium | Medium | Phase 5 communication + cache-invalidation plan. Genie spaces re-published. |
| R7 | The `@IncludeSubAccounts` parameter added to `Function_*` siblings breaks existing callers if they pass positional arguments. | Medium | Medium | Add new param with `DEFAULT 0`. Audit existing callers; all current calls go through named-parameter syntax — safe. |
| R8 | An archetype-F SP that was correctly classified as "no-op" is actually computing per-Wallet metrics that double-count when synthetic wallets exist. | Low | Medium | Phase 3 audit of priority ≥ 21 F-SPs. Spot-check: does removing `m.is_synthetic = 1` rows from input change output? |

---

## 7. Test plan

### 7.1 Pre-deploy unit-equivalent tests (Phase 2a CI gate)

For each archetype A/B/D/E SP, run before the deploy:

```sql
-- before-after equivalence on baseline data (no synthetics yet, so master_CID = CID for everyone)
EXEC <SP> @AsOf = '2026-04-25';
-- Expect: row counts, sums, distinct CID counts unchanged ±0.
```

Automated as part of Phase 2a CI. Fails the deploy if any SP changes its output on baseline data. This catches the 99% of mistakes (forgot to swap GROUP BY, joined the wrong direction, etc.).

### 7.2 Synthetic-injection regression (Phase 6 pre-launch)

Inject 100 fake sub-accounts into a stg branch of `Dim_MasterGCID` with `is_synthetic = 1`. Run all priority ≥ 60 archetype A+B+D+E SPs and verify:

- **A-archetype outputs**: row count of "active customers" / "funded customers" / "FTD users" unchanged (synthetics filtered out).
- **B/D-archetype outputs**: money totals shift to the master CID's row (or the master_CID column is populated correctly), with no double-counting.
- **E-archetype outputs**: `NewUsers`, `NewWallets` counts unchanged.

### 7.3 Archetype C parallel run (Phase 6 mandatory)

For 14 days post-Phase 6 launch, run both legacy and new versions of the 9 priority ≥ 90 C-archetype SPs:

- `SP_VarCommission`
- `SP_Client_Balance_New`
- `SP_Finance_Non_US_Settlement_Report`
- `SP_Real_Crypto_Loans`
- `SP_DDR`, `SP_DDR_Aggregated`, `SP_DDR_Aggregated_Auxiliary_Metrics`, `SP_DDR_Auxiliary_Metrics`
- `SP_Capital_Adequacy_IFR_KPMG`

Compare row counts and key aggregates. Investigate any divergence > 0.1%. **Any archetype-C SP that diverges signals an unresolved policy decision and must be rolled back.**

### 7.4 `Dim_MasterGCID` consistency test (continuous)

Daily check: every `CID` in `Dim_Customer` has exactly one row in `Dim_MasterGCID`. Every `is_synthetic = 1` row in `Dim_MasterGCID` has a `master_CID` that resolves to a real customer (`is_synthetic = 0`) row. Alarm if violated.

---

## 8. Open questions

1. **Where does the `is_synthetic` flag originate?** OLTP customer-creation service must set it explicitly. Out of scope for the DWH PRD; gates Phase 1.
2. **Sub-account count target.** N = 2? N = 5? N = 50? The `Dim_MasterGCID` design works at any N, but at N > 10 the storage and ETL side-effects on transaction-grain tables (`BI_DB_PositionPnL`, `Fact_*`, External CDC streams) become non-trivial. Out of scope here but blocks Phase 6 sign-off.
3. **Does Power BI semantic-model use any of the `IsValidCustomer = 1` filters directly?** The Power BI catalog needs to be scanned in parallel; not in scope of the Synapse repo scanner.
4. **For each priority ≥ 90 C-archetype SP, what is the correct policy?** Pre-Phase-2b sign-off required from Finance + Compliance.
5. **Are there any cross-database SPs (e.g. `Tracking.dbo.SP_*` or `FinanceAPI.dbo.SP_*`) that consume Synapse outputs?** Scope of this PRD is Synapse-only; OLTP-side audit is a parallel workstream.

---

## 9. Appendices

### Appendix A — Archetype detection logic

The scanner [`_build_option1_archetypes.py`](./_build_option1_archetypes.py) classifies each SQL file by destination grain.

#### A.1 INSERT extraction

Regex: `INSERT\s+INTO\s+<table>\s*[(<col_list>)]\s*(SELECT|EXEC|VALUES|WITH)`. Comment-aware (block and line comments stripped before matching). Skips `#temp` tables and table variables. Multi-destination SPs are picked by severity-max (C > A > B > D > E > F > X).

#### A.2 Column classification (precedence ordered)

For each destination column in the parsed col list:

| Bucket | Test | Examples |
|--------|------|----------|
| `customer_keys` | exact lowercase match in `{cid, gcid, realcid, accountid, customerid, walletid, holderid, userid, brokercid, providercid, ...}` | `CID`, `GCID`, `RealCID`, `AccountID`, `WalletID` |
| `pop_flag_cols` | exact lowercase match in `POPULATION_FLAG_NAMES` (~50 names) OR contains a substring in `FIRST_EVENT_SUBSTRINGS` (`1st`, `2nd`, `first`, `last_`, `lastlog`, `fmi_`, `fmo_`, `ftd`, `registration`) | `IsFunded`, `IsValidCustomer`, `1stActionDate`, `FirstFundedDate`, `RegistrationDate`, `FMI_Date` |
| `txn_cols` | substring match in `TXN_GRAIN_SUBSTRINGS` (`transactionid`, `positionid`, `eventid`, `orderid`, `chargeid`, `depositwithdrawid`, `tradeid`, `actionid`, ...) | `PositionID`, `TransactionID`, `DepositID`, `Occurred` |
| `count_cols` | substring match in `COUNT_SUBSTRINGS` (`count_`, `_count`, `newuser`, `newwallet`, `headcount`, `_users`, `_wallets`, `activeuser`) | `NewUsers`, `NewWallets`, `ActiveTraders`, `account_id` |
| `money_cols` | substring match in `MONEY_SUBSTRINGS` (`amount`, `balance`, `commission`, `_fee`, `pnl`, `volume`, `rollover`, `dividend`, `revenue`, `shortfall`, `equity`, `margin`, `loss`, `profit`, ...) | `FullCommission`, `Equity`, `Cashouts`, `Balance`, `BankPayIns` |
| `dim_cols` | substring match in `DIM_SUBSTRINGS` (`region`, `country`, `instrument`, `regulation`, `mifid`, `hedgeserver`, `crypto`, `currency`) | `Regulation`, `InstrumentID`, `HedgeServer`, `CountryID` |
| `other` | none of the above | (residual) |

#### A.3 Source-side signal detection

Run on the comment-stripped SQL of the entire file:

| Signal | Regex / detection | Used for |
|--------|-------------------|----------|
| `has_validity_filter` | `\b(IsValidCustomer|IsCreditReportValid(CB)?)\s*=\s*1` | Promote to Archetype C if no customer key in dest |
| `has_population_filter` | `\b(IsDepositor|IsFunded|IsRegistered|IsActive|IsTestCustomer|IsFTDed|FundedAccount)\s*[=<>!]+\s*[01]` OR `\b(VerificationLevelID|PlayerStatusID)\s*(=|<>|!=|NOT IN|IN)\b` | Same |
| `has_group_by_customer_key` | `GROUP\s+BY` clause containing any token in customer-key set | Distinguish B (per-customer aggregate) from A |
| `touches_fact_snapshot_customer` | `\bFact_SnapshotCustomer\b` | Diagnostic only — strong indicator of validity gate |
| `touches_dim_customer` | `\bDim_Customer\b` | Diagnostic only |

#### A.4 Archetype assignment rules

```python
if not has_customer_key:
    if has_count and not has_money:                  return E (high)
    if has_count and not has_money and n_count >= 2: return E (medium)
    if has_validity_filter or has_population_filter: return C (high)  # REGULATOR-RISK
    return F (high)

# has_customer_key in dest
if has_txn_grain and has_money:                      return D (high)
if n_count > n_money + n_pop_flag and n_count >= 1:  return E (medium)
if n_money >= 3 and n_money > n_pop_flag:            return B (high if has GROUP BY CID, else medium)
if n_pop_flag >= 3 or (n_pop_flag >= 1 and n_money <= 1): return A (high)
if n_money >= 1:                                     return B (medium)  # borderline A/B
return A (medium)                                                       # customer-keyed, grain unclear
```

**Confidence** = `high` if destination grain is unambiguous, `medium` if column-class shape is on the A/B or A/D borderline, `low` only on archetype X.

#### A.5 Recommended-action mapping

| Archetype | Action label |
|-----------|--------------|
| A | `filter-synthetics-from-population OR enrich-dest-with-master_CID` |
| B | `aggregate-to-master via JOIN Dim_MasterGCID + GROUP BY master_CID` |
| C | `decide-IsValidCustomer-policy-for-synthetics (REGULATOR RISK)` |
| D | `enrich-dest-with-master_CID column for downstream rollup` |
| E | `swap COUNT(DISTINCT CID/GCID) -> COUNT(DISTINCT master_GCID)` |
| F | `policy decision — sub-account positions show separately or roll to master` |
| X | `manual review — no INSERT destination detected` |

### Appendix B — Regenerating the artefacts

```powershell
python knowledge\business\_build_objectsstatus_snapshot.py
python knowledge\business\_build_option1_archetypes.py
python knowledge\business\_validate_archetypes.py    # sanity check vs 12 manually-classified SPs
python knowledge\business\_top_archetypes.py         # print top high-priority examples per archetype
```

The scanner reads SQL files from `C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we` and writes:

- `subaccount-option1-triage.csv` — one row per SP/Function/View
- `subaccount-option1-archetype-summary.json` — counts and high-priority examples

Heuristics tunable in the scanner header (column-name lists). Re-run after any heuristic change; the diff in the triage CSV shows what reclassified.

### Appendix C — Cross-references

- Five-option dual assessment: [`subaccount-effort-risk-v2.md`](./subaccount-effort-risk-v2.md)
- Slide deck: [`subaccount-effort-risk-v2.pptx`](./subaccount-effort-risk-v2.pptx)
- Archetype reference (engineer-facing): [`subaccount-option1-archetypes.md`](./subaccount-option1-archetypes.md)
- Source PDF: `SubAccount alternatives.pdf` (CTO inbox, not in repo)
