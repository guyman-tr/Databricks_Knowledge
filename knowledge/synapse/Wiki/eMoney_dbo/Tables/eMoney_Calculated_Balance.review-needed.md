# Review Needed: eMoney_dbo.eMoney_Calculated_Balance

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table

## Status

**FLAGGED**: Table is ~10 months stale (MaxDate=2025-06-09). SP_eMoney_Calculated_Balance has not run since 2025-06-10. Additionally, 3 columns are permanently NULL. Multiple architectural notes require reviewer awareness.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | **Table stale — not loaded since 2025-06-09** | CRITICAL | MaxDate = 2025-06-09. SP_eMoney_Calculated_Balance last ran on 2025-06-10. As of 2026-04-20, this table is ~10 months out of date. eMoneyClientBalance continues to be updated daily (MaxDate=2026-04-12). Determine: (a) Was SP_eMoney_Calculated_Balance deliberately decommissioned in favour of eMoneyClientBalance? (b) Was it removed from the daily orchestration pipeline? (c) Is there a performance issue (full scan of eMoney_Fact_Transaction_Status for cumulative TotalBalance)? Any downstream reports relying on this table have had stale data since June 2025. |
| 2 | **ClosingBalance = TotalBalance (cumulative, not incremental)** | HIGH | The INSERT writes `TotalBalance AS ClosingBalance` (SP line 513). ClosingBalance is the all-time cumulative sum of transactions, NOT an end-of-day incremental balance. This is a semantic trap for analysts expecting a traditional "closing balance." The incremental computed sum (OpeningBalance + daily flows + Correction) is used only for ClosingBalanceUSDApprox. Confirm all downstream consumers understand this distinction. |
| 3 | **CardID and ProviderCardID always NULL** | MEDIUM | Both columns are hardcoded to NULL in the INSERT (SP lines 483-484). The commented-out code shows these were intended for card linkage but were never activated. Consider dropping these columns or implementing the card linkage. They have been NULL since table creation (2022-11-16). |
| 4 | **IsGermanBaFin always NULL** | MEDIUM | The German BaFin indicator block (Step 04) is fully commented out. Column is permanently NULL across all rows. Feature was presumably built for a German regulatory requirement that was later deprioritized. Consider dropping this column. |
| 5 | **Full scan of eMoney_Fact_Transaction_Status on every run** | MEDIUM | `#txprep` loads ALL rows from eMoney_Fact_Transaction_Status with no DateID filter (SP lines 186-198). This enables cumulative TotalBalance computation but makes the SP scan the entire multi-year transaction history on every daily run. As eMoney_Fact_Transaction_Status grows, this becomes increasingly expensive. This may be a contributing factor to SP decommission. |
| 6 | TBD bucket uses TxClientBalanceCategory column | INFO | `TBD = SUM WHERE TxClientBalanceCategory='TBD'` rather than a TxTypeID filter. This means if additional TxTypes are classified as TBD in eMoney_Fact_Transaction_Status, they would automatically roll into the TBD bucket here. Currently includes TxTypeID=14 (CryptoToFiat). Confirm TxClientBalanceCategory classification logic in SP_eMoney_DimFact_Transaction. |
| 7 | CLUSTERED INDEX (not COLUMNSTORE) performance note | INFO | Row-store CLUSTERED INDEX(BalanceDateID) enables efficient daily DELETEs and point-in-time reads but makes range aggregations (cross-date analytical queries) slower than COLUMNSTORE. Consider whether UC migration should use a COLUMNSTORE layout. |
| 8 | Accounts excluded by INNER JOINs to DWH dims | INFO | Accounts without matching Fact_SnapshotCustomer, Dim_Country, Dim_PlayerLevel, or Dim_Regulation records are excluded from the population (INNER JOIN). These would be eToro Money accounts with no DWH customer record. Confirm expected exclusion volume. |

## Tier 4 Items

None — all 48 columns confirmed T2 from SP code analysis.

## Reviewer Confirmation Needed

- [ ] **PRIORITY**: Confirm whether SP_eMoney_Calculated_Balance is intentionally decommissioned or accidentally dropped from orchestration
- [ ] Confirm whether downstream consumers of this table (reports, dashboards) are aware of the June 2025 staleness
- [ ] Confirm whether CardID, ProviderCardID, IsGermanBaFin should be dropped (always NULL)
- [ ] Confirm whether ClosingBalance = TotalBalance (cumulative) design is documented for all consuming teams
- [ ] Assess UC migration scope: migrate historical snapshot as-is, or resume daily loads?

*Sidecar generated: 2026-04-20 | Quality: 9.1/10 | Phases completed: P1, P2, P3, P8, P9, P10B, P11, P16*
