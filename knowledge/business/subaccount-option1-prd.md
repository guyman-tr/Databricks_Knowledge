# Sub-Account Option 1 — "Another GCID + CID" — Blast Radius PRD

**Scope of this document:** the static blast-radius footprint of Option 1 (mint a new GCID and CID per sub-account) inside the Synapse SQL pool `sql_dp_prod_we`, plus a phased rollout that makes the change safely deployable.

**Source of truth:**
- Snapshot of OpsDB Service Broker scheduling: [`_objectsstatus_snapshot.csv`](./_objectsstatus_snapshot.csv) — 936 distinct procedures, Synapse-only schemas (BI_DB / DWH / Dealing / eMoney / EXW / DE / general / dbo). Bronze/Silver/Gold data-lake paths excluded per scope clarification.
- Static scanner: [`_build_option1_blast_radius.py`](./_build_option1_blast_radius.py)
- Touchpoint catalogue: [`subaccount-option1-touchpoints.csv`](./subaccount-option1-touchpoints.csv) — 1,174 touched objects out of 4,019 SQL files scanned.

---

## TL;DR

1. **The whole problem reduces to one column choice:** does sub-account `CID_sub` have its own `Dim_Customer` row with a NEW flag `IsBotAccount = 1`, OR does it share its parent's `RealCID`? Pick the wrong design and 200+ SPs become tickets.
2. **151 stored objects** in the Synapse pool MUST be inspected and modified. They share one signature: `IsValidCustomer = 1` (or equivalent) AND a user-count signal (`FTD`, `Registration`, `Funded`, `COUNT(DISTINCT CID)`, or `GROUP BY CID` aimed at user metrics). 28 of these are scheduled at priority 20 (daily), 96 at priority 0 (called transitively), 2 at priority 99 (FinanceReportSPS).
3. **6 priority-99 finance SPs** already `GROUP BY CID` **without** a validity filter (`SP_CB_Gap_Categorization`, `SP_Client_Balance_New`, `SP_CycleGap`, `SP_Daily_CB_Gaps_All`, `SP_Finance_Non_US_Settlement_Report`, `SP_Outliers_New`). They are arguably brittle today; Option 1 turns latent into actual.
4. **8 priority-99 finance SPs** read `Dim_Customer` for enrichment and need only the schema migration — no logic change. They are recompile-and-deploy targets.
5. **Recommended rollout: 6 phases over ~10 weeks** with a hard gate at Phase 2 (Tier A user-count fix) before any sub-account is provisioned in production. A single column rename (`IsValidCustomer` semantics) is the cheapest mitigation, but not the safest. The PRD recommends the additive-flag path (§ Decision 1).

---

## 1. The fundamental risk

Option 1 mints a synthetic real customer per sub-account: new `GCID_sub`, new `CID_sub`, full row in `UserApiDB.Customer.Customers` and downstream in `Dim_Customer`. Every existing `JOIN`, every `WHERE CID = X`, every aggregation key continues to work mechanically. **That is the danger** — the joins do not break, but the semantics silently shift.

| Metric class      | Today                                  | After Option 1 (no fix)                                      | After fix |
|-------------------|----------------------------------------|--------------------------------------------------------------|-----------|
| User counts (FTDs, Registrations, Funded, KYC pop., AML pop.) | counts real customers | inflates by ~Nx (N = avg sub-accounts per customer) | filtered |
| Money flow (revenue, MIMO, AUM, P&L, balances, fees, NOP)     | aggregates real money | still correct — money does flow through CID_sub      | unchanged |
| Reconciliation (CycleGap, CB_Gaps, NWA, Crypto_RECON)         | reconciles real CIDs  | reconciles all CIDs incl. sub-accounts — semantically OK if money flows are summed; brittle if it filters on validity | needs explicit decision |

The fix is to make user-count consumers exclude `IsBotAccount = 1` rows while leaving money-flow consumers untouched. The blast radius is the size of the "user-count consumer" set.

---

## 2. The IsBotAccount design — three choices, one recommendation

### Decision 1 (RECOMMENDED): additive flag + redefined validity column

- Add `IsBotAccount BIT NOT NULL DEFAULT 0` on `Dim_Customer` and on the upstream `External_*Customer*Customers` source.
- **Redefine `IsValidCustomer = 1`** to mean "valid AND `IsBotAccount = 0`". The column name keeps backward compatibility for the ~150 user-count SPs that already filter on it.
- Add a NEW column `IsValidCustomer_IncludingSubAccounts BIT` that is `1` for all rows that currently satisfy the legacy definition. Money-flow SPs migrate to this column on a per-SP basis as needed.

**Pros:** smallest immediate touch list — Tier A SPs continue to work without code change once the column semantics shift. Money-flow SPs that should include sub-accounts get migrated incrementally.

**Cons:** column-semantics change is a foot-gun. Anyone with a downstream model or BI extract that filters on `IsValidCustomer = 1` and ALSO needs sub-account inclusion will break silently. Mitigation: announce in advance and pair with column comments + Genie/wiki updates.

### Decision 2: additive flag + manual filter everywhere

- Add `IsBotAccount` exactly as in Decision 1 but DO NOT change `IsValidCustomer` semantics.
- Every Tier A SP gets a manual `AND IsBotAccount = 0` clause appended to its existing `IsValidCustomer = 1` filter.

**Pros:** explicit, auditable, no surprises.

**Cons:** every Tier A SP becomes a code change ticket. ~151 SPs. Even a 30-minute change × 151 SPs ≈ 75 dev-hours, plus testing. Realistic estimate: 6–8 weeks of one engineer.

### Decision 3: parameter-based gating (use existing pattern)

- The codebase already has the precedent: `Function_DDR_Aggregation_Yesterday`, `Function_MIMO_First_Deposit_All_Platforms`, `Function_Trading_Volume`, `Function_Population_*` all expose `@OnlyValidCustomers BIT` parameters that gate `IsValidCustomer = 1`.
- Extend the same pattern: add `@IncludeSubAccounts BIT` to functions and the SPs that call them.

**Pros:** uses an established codebase pattern, lets each consumer make an explicit choice.

**Cons:** only useful for the function-based subset (~30 functions); ad-hoc SPs still need direct edits. Best used as a complement to Decision 1, not a replacement.

**Recommendation:** Decision 1 + Decision 3 hybrid. Decision 1 covers ad-hoc SPs at zero touch cost. Decision 3 covers the structured Function_* layer cleanly. Decision 2 is the fallback if column-semantics change is rejected.

---

## 3. Summary tables

### 3.1 Touchpoints by tier × priority

Source: `subaccount-option1-summary.json`.

| Priority | Tier A (MUST FIX) | Tier B (REVIEW) | Tier C (RESIDUAL) | Service Broker process |
|---------:|------------------:|----------------:|------------------:|------------------------|
|       99 |                 2 |              19 |                 0 | FinanceReportSPS       |
|       98 |                 0 |               0 |                 0 | FinanceReportSPS       |
|       90 |                 1 |               5 |                 0 | SB_Daily               |
|       85 |                 0 |               0 |                 0 | SB_Daily               |
|       80 |                 0 |               0 |                 0 | SB_Daily               |
|       70 |                 0 |               2 |                 0 | SB_Daily               |
|       60 |                 0 |              28 |                 1 | SB_Daily               |
|       21 |                 2 |               5 |                 0 | SB_Daily               |
|       20 |                28 |              63 |                 2 | SB_Daily               |
|       15 |                 0 |               1 |                 1 | SB_Daily               |
|       10 |                 0 |              13 |                 0 | SB_Daily               |
|        1 |                 0 |               1 |                 0 | COPY DATA              |
|        0 |                96 |             205 |                 4 | SB_Daily (fan-out)     |
| unscheduled (views, functions, legacy SPs not in ObjectsStatus) | 22 | 669 | 4 | n/a |
| **Total** |          **151** |        **1,011** |             **12** |                        |

> "Unscheduled" = files in the Synapse repo with no row in `OpsDB.dbo.ObjectsStatus`. Includes views, functions (priority is implicit via the SPs that call them), and legacy/quarantined SPs.

### 3.2 Tier B sub-buckets (priority-99 sample)

The 19 Tier B priority-99 finance reports split into three orthogonal sub-buckets:

| Sub-bucket                                                            |  Count | What it means                                                                                                 |
|-----------------------------------------------------------------------|-------:|---------------------------------------------------------------------------------------------------------------|
| `validity-filter only` (likely money-flow)                            |     5  | Filters on `IsValidCustomer`/`IsCreditReportValidCB` but no user-count signal. Confirm sub-accounts are included. |
| `user-count without validity filter` (likely already buggy)            |     6  | `GROUP BY CID` with no validity filter. Already brittle today; Option 1 amplifies the bug.                    |
| `Dim_Customer enrichment only` (schema-add consumer)                   |     8  | Reads `Dim_Customer` columns for enrichment. Needs the new column to exist; no logic change.                  |

Same three sub-buckets exist at every priority tier (proportions vary).

### 3.3 The 21 priority-99 finance SPs by name

| Tier | SP                                              | Bucket                    |
|------|-------------------------------------------------|---------------------------|
|  A   | `SP_Crypto_NOP`                                 | validity-filter + user-count |
|  A   | `SP_M_Crypto_RECON`                             | validity-filter + user-count |
|  B   | `SP_ASIC_ClientBalanceFinance`                  | validity-filter only      |
|  B   | `SP_DailyZero_TreeSize_NEW`                     | validity-filter only      |
|  B   | `SP_RealCrypto_Lev2`                            | validity-filter only      |
|  B   | `SP_RollOverFee_Dividends`                      | validity-filter only      |
|  B   | `SP_VarCommission`                              | validity-filter only      |
|  B   | `SP_CB_Gap_Categorization`                      | user-count, NO validity   |
|  B   | `SP_Client_Balance_New`                         | user-count, NO validity   |
|  B   | `SP_CycleGap`                                   | user-count, NO validity   |
|  B   | `SP_Daily_CB_Gaps_All`                          | user-count, NO validity   |
|  B   | `SP_Finance_Non_US_Settlement_Report`           | user-count, NO validity   |
|  B   | `SP_Outliers_New`                               | user-count, NO validity   |
|  B   | `SP_CID_Daily_NWA`                              | Dim_Customer enrichment   |
|  B   | `SP_DailyDividendsByPosition`                   | Dim_Customer enrichment   |
|  B   | `SP_Daily_CreditLine`                           | Dim_Customer enrichment   |
|  B   | `SP_Daily_Dividends`                            | Dim_Customer enrichment   |
|  B   | `SP_DepositWithdrawFee`                         | Dim_Customer enrichment   |
|  B   | `SP_Finance_Panel_Reports`                      | Dim_Customer enrichment   |
|  B   | `SP_PositionPnL`                                | Dim_Customer enrichment   |
|  B   | `SP_Real_Crypto_Loans`                          | Dim_Customer enrichment   |

### 3.4 The Tier A high-priority anchor list

Top-priority Tier A SPs that need explicit MUST-FIX treatment in Phase 2:

| Priority | Object                                                                  |
|---------:|-------------------------------------------------------------------------|
|   99     | `BI_DB_dbo.SP_Crypto_NOP`                                               |
|   99     | `BI_DB_dbo.SP_M_Crypto_RECON`                                           |
|   90     | `BI_DB_dbo.SP_CIDFirstDates` (the FTD/Funded master dates SP)           |
|   21     | `BI_DB_dbo.SP_PositionPnL_Agg_daily_Staking`                            |
|   21     | `BI_DB_dbo.SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export` (UK regulator) |
|   21     | `BI_DB_dbo.SP_W_Tue_Reg_UK_Compliance_Professional_OptUp` (UK regulator) |
|   20     | 28 SPs (see CSV — includes `SP_AML_SAR_Report`, `SP_AML_SubEntity_Categorization`, `SP_CIDFunnelFlow`, `SP_CryptoDashboard`, `SP_Daily_TradeData`, `SP_DepositUsersFirstTouchPoints`, `SP_IFRS_15_Balance`, `SP_Inactivity_Fees`, …) |

Functions of equal weight (unscheduled, but called by the above):

- `BI_DB_dbo.Function_DDR_Aggregation_*` (8 functions — already use `@OnlyValidCustomers`)
- `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms`
- `BI_DB_dbo.Function_Population_Active_Traders`
- `BI_DB_dbo.Function_Population_Funded`
- `BI_DB_dbo.Function_Population_First_Trading_Action`
- `BI_DB_dbo.Function_Trading_Volume`

These functions are the natural injection points for `@IncludeSubAccounts` (Decision 3).

---

## 4. The RealCID design landmine

`Dim_Customer` has a column `RealCID` whose meaning today is "the master CID for a customer when there are mirror/sub-accounts under the same GCID". Many priority-90/99/20 SPs use `RealCID` as the user-identity rollup key:

```sql
JOIN [DWH_dbo].[Dim_Customer] b ON a.CID = b.RealCID            -- SP_CIDFirstDates L1211
GROUP BY pp.CID,dft.Name                                          -- SP_AML_SAR_Report L84
GROUP BY ffca.RealCID                                             -- SP_ClusteringDailyPrepData L43
GROUP BY a.RealCID                                                -- SP_Outliers_New L101
GROUP BY cc.RealCID                                               -- SP_ChargebackReport L72
```

**The landmine:** for an Option 1 sub-account, what is `RealCID`?

| Choice                                                                | Implication                                                                                          |
|-----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| **A. `RealCID = CID_sub`** (sub-account is its own master)            | Money/PnL aggregates correctly stay at the sub-account level. User counts that GROUP BY RealCID inflate by Nx — exactly the bug we're trying to avoid. Many AML/Compliance SPs use RealCID. |
| **B. `RealCID = CID_parent`** (sub-account rolls up to parent)         | User counts via `GROUP BY RealCID` collapse correctly. Money/PnL via `GROUP BY RealCID` re-aggregates parent + all sub-accounts together — masking the per-sub-account view that's the whole point of the feature. |

Neither is universally correct. The PRD recommends:

- **Set `RealCID = CID_sub`** (Choice A) — preserves per-sub-account money flows.
- **Pair with `IsBotAccount`** so user-count consumers explicitly exclude sub-accounts.
- **Add a new column `ParentCustomerCID`** on `Dim_Customer` for sub-accounts. Set to the parent customer's CID. Lets SPs that NEED the rollup view (Compliance/AML "people behind accounts" reporting) opt in explicitly.

This is the single biggest design question Option 1 raises. **Without this resolution, the rollout cannot proceed past Phase 1.**

---

## 5. Phased rollout

Each phase is gated by the prior phase's deploy + 7-day stability window. Total: ~10 weeks one engineer + 2 weeks regulator-facing review for Phase 6.

| Phase | Goal                                                                                  | Touchpoints                                       | Duration |
|-------|---------------------------------------------------------------------------------------|---------------------------------------------------|----------|
| 0     | Decisions 1–3 sign-off. RealCID semantics decision. Schema migration plan reviewed.    | docs only                                         | 1 week   |
| 1     | Schema add: `IsBotAccount`, `ParentCustomerCID`, `IsValidCustomer_IncludingSubAccounts` columns on `Dim_Customer` and the External_*Customer*Customers source. Default 0 / NULL everywhere. Backfill: trivially 0 for all existing rows. | 8 priority-99 SPs (Tier B "Dim_Customer enrichment") will recompile and pass. | 1 week   |
| 2     | **HARD GATE**: Tier A user-count fix. Apply Decision 1 (redefine `IsValidCustomer = 1` semantics) OR Decision 2 (add `AND IsBotAccount = 0` to 151 SPs). Add `@IncludeSubAccounts` parameter to the 14 functions that already use `@OnlyValidCustomers`. | 151 Tier A SPs, 14 functions                      | 4 weeks  |
| 3     | Tier B "user-count without validity filter" cleanup. Decide for each whether the missing filter is a pre-existing bug (fix it) or intentional (annotate). | 6 priority-99 SPs + ~30 lower-priority SPs        | 2 weeks  |
| 4     | Tier B "validity-filter only (money-flow)" review. For each SP, decide whether sub-account CIDs should be included in the metric. If yes, leave alone (Decision 1 already handled it). If no, add explicit `IncludeSubAccounts=0`. | 5 priority-99 SPs + ~50 lower-priority SPs        | 1 week   |
| 5     | Genie/Wiki/Glossary updates. Update column descriptions for `IsValidCustomer`, `RealCID`, `IsBotAccount`. Re-run Wiki batch jobs.                                  | docs only                                         | 1 week   |
| 6     | UAT + first sub-account provisioned in production behind a feature flag, monitored for 7 days. Regulator notification (UK FCA: SP_W_Tue_Reg_UK_Compliance_*).      | end-to-end                                        | 2 weeks  |

**Phase 2 cannot be skipped.** If Decision 1 is taken, Phase 2 collapses to "redefine the column comment, run a query that asserts every Tier A SP still references `IsValidCustomer = 1`". If Decision 2 is taken, Phase 2 is the actual 151-SP edit campaign.

---

## 6. Risk register

| ID  | Risk                                                                                              | Likelihood | Impact | Mitigation                                                                                     |
|-----|---------------------------------------------------------------------------------------------------|-----------:|-------:|------------------------------------------------------------------------------------------------|
| R1  | A user-count SP slips through Phase 2, FTD/Reg/Funded counts inflate post-Phase 6.                |    Medium  |  High  | Scanner re-run as a CI gate before Phase 6 launches. Diff Tier A list pre/post-fix.            |
| R2  | A money-flow SP gets caught by the redefined `IsValidCustomer` and starts excluding sub-accounts. |    Medium  |  High  | Decision 1's `IsValidCustomer_IncludingSubAccounts` column gives an opt-back-in path. Phase 4 audit. |
| R3  | `RealCID` semantics ambiguity. AML/Compliance "people behind accounts" reports break.             |    Medium  |  High  | Phase 0 decision + `ParentCustomerCID` column. AML team review of SP_AML_SAR_Report, SP_AML_SubEntity_Categorization, SP_AML_PI_Abuse, SP_BI_AMLPeriodicReview before Phase 2 deploy. |
| R4  | The 6 priority-99 "user-count without validity filter" SPs have been quietly wrong for years; fixing them changes regulator-facing numbers. |    High    | Medium | Phase 3 dedicated review with Finance. Run side-by-side comparison for 30 days before cutover.|
| R5  | An External_* table upstream of `Dim_Customer` doesn't propagate the new flag.                    |       Low  |  High  | Phase 1 includes upstream SP_CopyLakeToSynapse adjustments. CTAS dependency chain regenerated. |
| R6  | Regulator-facing reports (`SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export`, `SP_W_Tue_Reg_UK_Compliance_Professional_OptUp`) submit a different number to the FCA the day after deploy. |    Medium  |  High  | Phase 6 includes 2-week regulator-aware window with both old and new figures parallel-run.    |
| R7  | `Function_DDR_Aggregation_*` are called by Power BI / external Genie consumers; signature change of adding a parameter breaks them. |    High    | Medium | Add new param with `DEFAULT 0`. Deprecate old call signature gradually.                       |
| R8  | A 3rd-party tool (Tableau extract, Genie, Salesforce sync) caches the legacy `IsValidCustomer` semantics. |    Medium  | Medium | Phase 5 communication + cache-invalidation plan.                                              |

---

## 7. Test plan

### 7.1 Pre-deploy unit-equivalent tests

For each Tier A SP, run:

```sql
-- before-after equivalence on baseline data (no sub-accounts yet)
EXEC <SP> @AsOf = '2026-04-25';
-- Expect: row counts, sums, distinct CID counts unchanged ±0 on a day with no Option 1 sub-accounts active.
```

Automated as part of Phase 2 CI. Fails the deploy if any SP changes its output on baseline data.

### 7.2 Synthetic sub-account injection tests

Before Phase 6, inject 100 fake sub-accounts into a stg branch of `Dim_Customer` with `IsBotAccount = 1`. Run all priority-99 + priority-90 + priority-20 Tier A SPs and verify:

- User-count outputs unchanged (FTD, Registration, Funded, KYC pop counts).
- Money-flow outputs increase by exactly the sum of money flowing through those 100 sub-accounts.

### 7.3 Regulator-facing diff

For 14 days post-Phase 6 launch, run both legacy and new versions of:

- `SP_ASIC_ClientBalanceFinance`
- `SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export`
- `SP_W_Tue_Reg_UK_Compliance_Professional_OptUp`
- `SP_AML_SAR_Report`

Compare row counts and key aggregates. Investigate any divergence > 0.1%.

### 7.4 RealCID regression test

Build a query that for every priority ≥ 20 SP, counts:

- `COUNT(*) WHERE GROUP BY RealCID is used`
- `COUNT(*) WHERE GROUP BY CID is used`
- ratio change pre/post sub-account injection.

If RealCID-based aggregates change unexpectedly, Phase 0 RealCID decision was wrong — abort and revisit.

---

## 8. Open questions

1. **Does Decision 1 (redefining `IsValidCustomer`) get sign-off from Finance, AML, Compliance, RegTech?** If any says no, the project is Decision 2 and 4 weeks turns into 6–8 weeks.
2. **`RealCID = CID_sub` or `RealCID = CID_parent`?** The PRD's recommendation is the former + a new `ParentCustomerCID` column. AML team review required.
3. **What's the upstream source of truth for `IsBotAccount`?** Is the flag set at OLTP customer-creation time, or computed in DWH at Dim_Customer-build time? Affects which team owns the lineage.
4. **Do Genie spaces and Power BI extracts cache `IsValidCustomer` semantics?** Phase 5 effort scales with cache touch points.
5. **Sub-account count target.** N = 2? N = 5? N = 50? The `IsBotAccount`-based filter is correct at any N, but at N > 10 the storage and ETL side-effects on `BI_DB_PositionPnL`, `Fact_*`, and the External_* CDC streams become non-trivial. Out of scope here but blocks Phase 6 sign-off.
6. **Does any Power BI semantic model use `Dim_Customer.IsValidCustomer` directly as a filter?** The Power BI catalog needs to be scanned in parallel; not in scope of the Synapse repo scanner.

---

## 9. Appendices

### A. Scanner pattern catalogue (excerpt)

```python
VALIDITY_PATTERNS = {
  "IsValidCustomer":     r"\bIsValidCustomer\b\s*=\s*1",
  "IsCreditReportValid": r"\bIsCreditReportValid\b\s*=\s*1",
  "IsTestCustomer":      r"\bIsTestCustomer\b\s*=\s*0",
  "IsBotAccount":        r"\bIsBot(?:Account)?\b\s*=\s*0",
  "IsInternal":          r"\bIsInternal\b\s*=\s*0",
  "Customer_Status":     r"\bCustomer_?Status\b\s*=\s*N?'Active'",
}

USER_COUNT_PATTERNS = {
  "COUNT_DISTINCT_CID":  r"\bCOUNT\s*\(\s*DISTINCT\s+(?:[A-Za-z_]+\.)?CID\b\s*\)",
  "COUNT_DISTINCT_GCID": r"\bCOUNT\s*\(\s*DISTINCT\s+(?:[A-Za-z_]+\.)?GCID\b\s*\)",
  "FTD":                 r"\b(?:FTD(?:_?Date)?|FirstTimeDeposit|IsFTDed|First[_ ]?Time[_ ]?Deposit)\b",
  "Registration":        r"\b(?:IsRegistered|Registration_?Date|RegistrationDate)\b",
  "Funded":              r"\b(?:IsFunded|Funded_?Date|FundedAccount|FirstFunded)\b",
  "GROUP_BY_CID":        r"GROUP\s+BY[^;]{0,200}\bCID\b",
  "GROUP_BY_GCID":       r"GROUP\s+BY[^;]{0,200}\bGCID\b",
}

JOIN_FANOUT_PATTERNS = {
  "GCID_eq_GCID":        r"ON\s+\w+\.GCID\s*=\s*\w+\.GCID",
  "CID_eq_CID":          r"ON\s+\w+\.CID\s*=\s*\w+\.CID",
}

CUSTOMER_TOUCH_PATTERNS = {
  "Dim_Customer":             r"\bDim_Customer\b",
  "External_Customer":         r"\bExternal_[A-Za-z0-9_]*Customer[A-Za-z0-9_]*\b",
  "UserApiDB_Customer":        r"\bUserApiDB[\.\s]*Customer\b",
  "Dim_Mirror":                r"\bDim_Mirror\b",
  "MirrorID_or_ParentCID":     r"\b(?:MirrorID|MirrorTypeID|ParentCID|RealCID|MasterAccountCID|SubAccountCID)\b",
}
```

Tier classification:

- **Tier A** = has at least one VALIDITY hit AND at least one USR hit.
- **Tier B** = any of: VALIDITY without USR; USR without VALIDITY; GCID=GCID join; CUST touch.
- **Tier C** = only `JOIN.CID_eq_CID` with no other signals.

### B. Regenerating the artefacts

```bash
python knowledge\business\_build_objectsstatus_snapshot.py
python knowledge\business\_build_option1_blast_radius.py
python knowledge\business\_inspect_touchpoints.py | Out-File touchpoints_review.txt
```

### C. Cross-references

- Five-option dual assessment: [`subaccount-effort-risk-v2.md`](./subaccount-effort-risk-v2.md)
- Slide deck: [`subaccount-effort-risk-v2.pptx`](./subaccount-effort-risk-v2.pptx)
- Source PDF: `SubAccount alternatives.pdf` (CTO inbox, not in repo)
