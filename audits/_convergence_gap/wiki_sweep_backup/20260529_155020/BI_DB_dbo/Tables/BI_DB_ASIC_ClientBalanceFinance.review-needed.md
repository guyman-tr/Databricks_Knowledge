# Review Sidecar — BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance
<!-- Refreshed 2026-04-23 batch 61 -->

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 19 columns in DDL, 19 in wiki |
| All columns have tier suffix | ✅ | All 19 descriptions end with (Tier N — source) |
| Writer SP confirmed | ✅ | SP_ASIC_ClientBalanceFinance matches OpsDB (P99 FinanceReportSPS) |
| Sample data reviewed | ✅ | 5 rows sampled, values consistent with column descriptions |
| Distribution query | ✅ | RegulationName: 2 values (ASIC ~98.6M, ASIC & GAML ~446.8M); ~565M total rows |
| T1 sources verified | ✅ | CID, Customer, CurrentLabel, PrevLabel, Country, RegulationName — all T1 |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | `PreviuosDayBalance` | High | Column name has a typo ("Previuos" vs "Previous") baked into DDL and SP. Confirmed production name — do NOT rename. All downstream consumers must use the misspelled column name exactly. |
| 2 | `Deposit` (composite) | Medium | The `Deposit` column includes `ChargebackLoss` and `OtherNegative` adjustments from V_Liabilities, making it NOT a pure gross deposit figure. Verify this is the intended ASIC regulatory definition. |
| 3 | `IsGermanBaFin` (near-obsolete) | Low | Only 1 row with `IsGermanBaFin=1` on 2026-04-12 out of ~230K rows. Source is `BI_DB_IsGermanBafin_Freeze_20230712` — a frozen snapshot from July 2023. Confirm if German BaFin reporting is still active or if this flag is effectively dead. |
| 4 | `Customer` = ExternalID | Medium | Column is named `Customer` but contains `Dim_Customer.ExternalID` — an opaque APEX broker account ID, not a name. Verify downstream consumers understand this is an account identifier, not a customer name string. |
| 5 | `IsCreditReportValidCB = 1` filter | Medium | ASIC clients with failed credit bureau checks are silently excluded. Confirm this population exclusion is correct for ASIC regulatory reporting. |
| 6 | `RegulationID IN (4, 10)` | Medium | Hardcoded ASIC regulation IDs in SP. If a new ASIC sub-regulation ID is added to Dim_Regulation, SP must be updated manually. |
| 7 | Zero-row exclusion | Low | SP HAVING clause excludes rows where all financial amounts are zero. Clients with no trading activity on a day are absent. Confirm if ASIC filings require zero-activity rows. |
| 8 | V_Liabilities — no wiki | Low | Balance/equity columns (PreviuosDayBalance, CurrentDayBalance, Equity, TotalOpenMargin, OpenPosition, RealAssetEquity) are traced to V_Liabilities but no upstream wiki exists for that view. Confidence is T2 (SP-code-derived). |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 6 | CID, Customer, CurrentLabel, PrevLabel, Country, RegulationName |
| Tier 2 | 12 | DateID, Date, PreviuosDayBalance, Deposit, Withdrawal, ClosedPnL, CurrentDayBalance, OpenPosition, Equity, TotalOpenMargin, RealAssetEquity, IsGermanBaFin |
| Propagation | 1 | UpdateDate |
