# Sub-Account Architecture: Effort & Risk

**Audience:** CTO  
**Date:** 2026-04-23  
**Source:** `SubAccount alternatives.pdf`  
**Companion:** `canvases/subaccount-effort-risk.canvas.tsx`  
**Deep dive — Option 1:** [`subaccount-option1-prd.md`](./subaccount-option1-prd.md) + [`subaccount-option1-archetypes.md`](./subaccount-option1-archetypes.md) (full blast radius PRD: **1,459 SQL files classified into 6 archetypes** by destination INSERT grain · **96 regulator-risk Archetype-C SPs** are the non-mechanical core — 9 of them priority ≥ 90 including KPMG IFR + the four `SP_DDR*` aggregators · 397 mechanical Archetype A/B/D/E fixes via a new `general.Dim_MasterGCID(CID, master_CID, master_GCID, is_synthetic)` table · 6-phase rollout with parallel 2a-mechanical / 2b-policy split · per-SP triage in `subaccount-option1-triage.csv`)

For each option: the specific risk it creates, and the specific labor that risk forces.

---

## The two failure modes that drive every option

1. **Fake-user contamination** (Options 1 + 4). Sub-account looks like a real customer; needs to be excluded from population/FTD/registration KPIs but counted in revenue/MIMO/AUM. Concrete labor surface: **~140 SPs in the analytics layer** filter today on `IsValidCustomer` or `IsCreditReportValid`. Each is a place that must be re-decided.

2. **Join fanout** (Options 2 + 5). A previously 1:1 join becomes 1:N.
   - Option 2 breaks every `GCID = GCID` join — identity-layer change, atomic, ~100+ SPs touch this pattern, hits all 13 Priority 99 finance reports.
   - Option 5 only breaks consumers that join on CID **without subsequent aggregation**. Aggregating consumers (SUM + GROUP BY CID downstream) absorb it cleanly. Per-table, gradual, audit-gated.

---

## Bottom line

| # | Option | Effort | Risk | What the labor actually is |
|---|---|---|---|---|
| 3 | Mirror No-Copy | LOW | LOW | 1 dictionary row + 1 API scope change |
| 4 | Mirror + Copy (bot CID) | MEDIUM | MEDIUM | Validity-filter audit (~140 SPs) |
| 1 | New GCID + CID | HIGH | MED-HIGH | Per-KPI bifurcation (~140 SPs) |
| 5 | SubPortfolio table (gradual) | MED-HIGH | MEDIUM | Per-table consumer audit, 1 table at a time |
| 2 | New CID → Same GCID | CRITICAL | CRITICAL | Schema migration of identity layer |

---

## Per option

### Option 3 — Mirror No-Copy

- **Risk:** None of consequence. Same row stays in every consumer.
- **Labor:** Add 1 row to `Dictionary.MirrorType`. Plumb `mirrorID` into the trading API JWT scope. Decide private-instrument visibility for the sub-account.
- **Hard ceiling:** No copy support inside the sub-account.

### Option 4 — Mirror + Copy (bot CID)

- **Risk:** Bot CID looks like a real customer everywhere. Pollutes user counts, FTD, registrations, AML alerts, KYC pipeline. Compliance pattern flag: a customer with zero organic activity that only ever copies one CID is exactly what AML alerts trigger on.
- **Labor:** Add `IsBotAccount` (or extend `IsInternal`) at the OLTP customer record. Then add it to the WHERE clause of every analytics SP currently filtering by `IsValidCustomer` and `IsCreditReportValid` — ~140 SPs. AML/KYC pipelines need explicit review (they may want to keep watching bot CIDs even when other reports exclude them).

### Option 1 — New GCID + CID

- **Risk:** Same fake-user contamination as Option 4, **plus** acquisition KPIs (FTD, Registrations, valid-customer counts) inflate per sub-account. Tax filings (1099, W8Ben) emit per GCID, so a sub-GCID = duplicate IRS filing risk if not excluded.
- **Labor:** Same `IsBotAccount`-style plumbing as Option 4, but you also decide PER-METRIC whether the sub-GCID is counted (revenue/MIMO/AUM = yes; FTD/Registration/valid-customer = no). Two deploys, not one. Same ~140 SP review surface, with bigger semantic decisions per SP.

### Option 5 — SubPortfolio table (gradual)

- **Risk:** Per broken table, any consumer that joins on CID without subsequent aggregation gets row fanout. Aggregating consumers (SUM + GROUP BY CID downstream) absorb it cleanly. Probably not huge but **not currently quantified**.
- **Labor:** Per table you choose to break: classify every direct consumer as (a) aggregator → safe, (b) pass-through-by-CID → must be updated. One table at a time, audit-gated. Save Priority 99 finance SPs for last.
- **Action item before committing:** run a one-shot static scan per candidate producer. List direct consumers, classify each as (a) has SUM + GROUP BY CID downstream → safe, (b) selects CID columns into output without aggregation → unsafe. Half-day Python over the SQL repo. Turns Option 5 risk from "probably manageable" into "I have the list".

### Option 2 — New CID → Same GCID

- **Risk:** Every `JOIN ON x.GCID = y.GCID` returns N rows where 1 was expected. Hundreds of SPs do this. Identity-layer change, atomic, unrecoverable. Direct hit to all 13 Priority 99 finance reports.
- **Labor:** Migrate `Customer.CustomerIdentification` PK. Update every GCID-keyed JOIN in BI_DB / DWH / Dealing / eMoney / EXW + 5,000+ ComplianceDB objects + every OLTP source DB in lockstep. No partial deploy.

---

## Where the labor lands — Validity-filter hot spots (Options 1 + 4)

`IsValidCustomer` / `IsCreditReportValid` filter occurrences per analytics SP.

| SP | Occurrences | Domain |
|---|---:|---|
| `BI_DB_dbo.SP_Client_Balance_New` | 474 | Priority 99 |
| `BI_DB_dbo.SP_CMR_Automation_Tangany_Volume` | 189 | Crypto compliance |
| `BI_DB_dbo.SP_CMR_Automation_Crypto_To_Position` | 189 | Crypto compliance |
| `BI_DB_dbo.SP_IFRS_15_Balance` | 74 | IFRS reporting |
| `BI_DB_dbo.SP_CMR_Automation_EU_ClientBalanceAllCrossTab` | 69 | EU CMR |
| `BI_DB_dbo.SP_M_Finance_Audit_Auxillary_Datapoints` | 64 | Finance audit |
| `BI_DB_dbo.SP_Finance_Non_US_Settlement_2025` | 44 | Priority 99 |
| `BI_DB_dbo.SP_DailyCommisionReport` | 33 | Daily revenue |
| `BI_DB_dbo.SP_Q_QSR_New` | 27 | Quarterly stat return |
| `BI_DB_dbo.SP_RBSF` | 13 | Regulatory |
| `DWH_dbo.SP_Dim_Customer` | 9 | Customer dim |

Total scope: **~140 SPs** with at least one validity filter, including all 13 Priority 99 finance SPs. Plus OLTP equivalents (`PaymentsDBs.GCID_DefaultAccount`, `IsFirstTimeDepositByGCID`, etc.).

---

## Where the labor lands — GCID-join fanout hot spots (Option 2)

Each line is a 1:1 join that becomes 1:N if a single GCID can have multiple CIDs.

| SP | GCID=GCID join lines |
|---|---:|
| `EXW_dbo.SP_EXW_CompensationClosingCountries` | 24 |
| `BI_DB_dbo.SP_BI_DB_Scored_Appropriateness_Negative_Market` | 18 |
| `BI_DB_dbo.SP_BI_DB_Suitability_KYC` | 17 |
| `EXW_dbo.SP_EXW_UserSettingsWalletAllowance` | 17 |
| `BI_DB_dbo.SP_KYC_Panel` | 12 |
| `BI_DB_dbo.SP_KYC_Questions_Answers_Row_Data_46` | 11 |
| `EXW_dbo.SP_EXW_DimUser_Enriched` | 9 |
| `EXW_dbo.SP_EXW_C2F_E2E` | 9 |
| `BI_DB_dbo.SP_QMMF_Report` | 8 |
| `DWH_dbo.SP_Dim_Customer` | 7 |
| `BI_DB_dbo.SP_TIN_Gap` | 7 |

~100+ SPs touch this pattern at least once. On top of changing the PK definition itself, plus 5,000+ ComplianceDB objects (UserApiDB-anchored) that join through GCID.

---

## What we already have in production

- `SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport` — existing master/sub-account alignment monitoring
- `SP_AML_BI_Alerts_New_Master_SubAccount` — existing master/sub-account AML alerting
- `MasterAccountCID` column in `[Customer].[AccountUserInfo]` (UserApiDB), `[BackOffice].[Customer]` (etoro), 49 SQL files

eToro already runs master/sub-account alignment today. The `MasterAccountCID` hierarchical pattern is the working blueprint for Option 5's gradual rollout.

---

## Recommendation

**Phase 1 (now):** Option 3 — Mirror No-Copy. Validates the user-facing concept with zero downstream blast.

**Phase 2 (6-9 months):** Option 4 — Mirror + Copy, only if copy-inside-sub-account is required. Pay the validity-filter audit cost once.

**Phase 3 (12-24 months):** Option 5 — gradual SubPortfolio rollout. Per-table audit-gated. Use the existing master/sub-account precedent as the blueprint.

**Never:** Option 2. Atomic identity-layer migration. Direct hit on every GCID join + every Priority 99 finance report.

---

## Action item before any commitment to Option 5

Run a static SQL scan per candidate producer table:

1. List all direct consumers (anything that `SELECT ... FROM <table>` or joins it).
2. Classify each consumer:
   - Has `SUM(...) ... GROUP BY CID` (or a CID-level CTE that wraps the input) → **safe under sub-portfolio**.
   - Selects CID columns directly into output without aggregation → **unsafe, must be updated before producer is broken**.
3. Output: per-table list of (a) safe consumers, (b) consumers needing rework.

Half-day Python script over the SQL repo. Turns Option 5 from "probably manageable" into a sized backlog.
