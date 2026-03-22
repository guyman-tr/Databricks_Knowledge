# BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Summary

| Metric | Value |
|---|---|
| Total Columns | 174 |
| Tier 1 (upstream wiki) | 7 |
| Tier 2 (SP code) | 167 |
| Tier 3 (live data) | 0 |
| Tier 4 (inferred) | 0 |
| Tier 5 (domain expert) | 0 |
| Columns needing review | 0 Tier 4 |

## Review Status

174 documented columns. 7 are Tier 1 — inherited from upstream DWH_dbo Dimension wikis where the `Name` column is documented as Tier 1 from production `Dictionary.*` tables. 167 are Tier 2 — derived from direct analysis of `SP_Client_Balance_New` (9,574 lines). Two columns (`DepositConversionFee`, `WithdrawConversionFee`) are documented as always NULL (placeholder columns).

### Tier 1 Columns (7)

| Column | Source Dim | Origin |
|---|---|---|
| Regulation | Dim_Regulation.Name | Dictionary.Regulation |
| AccountType | Dim_AccountType.Name | Dictionary.AccountType |
| Label | Dim_Label.Name | Dictionary.Label |
| Country | Dim_Country.Name | Dictionary.Country |
| MifidCategory | Dim_MifidCategorization.Name | Dictionary.MifidCategorization |
| Club | Dim_PlayerLevel.Name | Dictionary.PlayerLevel |
| PlayerStatus | Dim_PlayerStatus.Name | Dictionary.PlayerStatus |

### Tier 1 Gap Analysis — Why Not More?

This is a **BI reporting layer table** that aggregates and denormalizes from DWH sources. Most columns fall into three categories:

1. **Financial metrics** (Deposits, Cashouts, Compensation, etc.) — computed by `SUM(Amount) WHERE ActionTypeID=N AND ...` from `Fact_CustomerAction`. These are ETL-computed (Tier 2) by definition.
2. **Snapshot values** (realizedEquity, TotalRealStocks, etc.) — passthrough from `Fact_SnapshotEquity` and `V_Liabilities`. The upstream fact wikis classify these as Tier 2 (ETL-computed by their own SPs), so tier transitivity keeps them at Tier 2.
3. **Dimension lookups** (Regulation, Country, Club, etc.) — join-enriched from Dim_* tables. Only the `Name` columns trace back to production `Dictionary.*` tables (Tier 1). Other dim attributes (Region, IsCreditReportValidCB) are Tier 2 in the upstream wiki.

**No additional Tier 1 columns are available** without first upgrading upstream DWH_dbo fact/view wikis (which would require tracing their columns back to production sources via DB_Schema wikis).

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All 174 columns have been verified through SP code analysis or upstream wiki inheritance.

## Columns Needing Clarification

1. **Balance Cycle Completeness**: The cycle equation in Section 2.2 may not account for all flow columns added since the original equation was written (TradingFees, TicketFee, TicketFeeByPercent, InternalTransferDeposits, InternalTransferWithdraws, CashoutRollback, ReverseDeposit, SDRT, CompensationCryptoTransferOut, C2P). Are these included in the cycle gap calculation in SP_Daily_CB_Gaps_All, or are they treated as immaterial?

2. **DepositConversionFee / WithdrawConversionFee**: These columns are always NULL. Are they planned for implementation, or should they be removed from the DDL?

3. **C2P (Cash-to-Portfolio)**: This is the newest column (Nov 2025). Is the description "crypto positions opened from IBAN (eMoney)" accurate, or does it have a broader meaning?

4. **CompensationsApexUSStocks exclusions**: Reason 91 is excluded because it "overlaps with crypto staking." Is this still the current business rule, or has the Apex integration changed?

5. **TanganyStatus values**: The specific values for TanganyStatus are not documented in the SP. What are the possible values and their meanings?

## Structural Questions

1. **V_Liabilities wiki**: The upstream wiki for V_Liabilities has lineage only (body is thin). Columns sourced from V_Liabilities (OpeningBalance, ClosingBalance, NOP, AvailableCash, etc.) remain Tier 2 because V_Liabilities itself has no rich column descriptions to inherit. If V_Liabilities wiki is enriched in the future, a rerun would upgrade these columns.

2. **Fact_CustomerAction wiki**: The upstream wiki for Fact_CustomerAction is documented, but the filter logic (ActionTypeID + CompensationReasonID combinations) is specific to SP_Client_Balance_New. These columns are correctly Tier 2 because the aggregation formulas are ETL-computed.

## Tier 5 Re-Review Needed

> Tier 5 (domain expert) overrides whose underlying Tier 1–3 source has materially changed
> since the correction was made. The Tier 5 is still applied, but a domain expert should
> confirm it remains valid given the new upstream definition.

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|

---
*Generated: 2026-03-20 (rerun)*
