# BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns -- all 8 elements are Tier 2 or Tier 3.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| EV | The EV formula floors at zero per position (`CASE WHEN RC + PFE - Collateral < 0 THEN 0`). Confirm this is the correct IFR/SA-CCR interpretation -- some implementations floor at the netting-set level, not per position. |
| Own_Funds_Requirement | The formula uses `a = 1.2` (alpha factor). CRR Article 274 specifies alpha = 1.4 for SA-CCR. The 1.2 value may be IFR-specific or firm-negotiated. Confirm the regulatory basis for alpha = 1.2. |
| Collateral_Value_after_adjustments | For CySEC/FCA/BVI, collateral = InvestedAmount * (1 - CurrencyMismatch), but for ASIC/GAML/Sey/FSRA/MAS, collateral = RC * (1 - CurrencyMismatch). This asymmetry seems intentional (invested amount vs mark-to-market) but should be confirmed with the finance team. |
| RC | CMV for ASIC/GAML/Sey/FSRA/MAS uses AdjustedPnLForRegulations (PnL + FullCommission - Commission) while EU/UK/BVI uses raw PositionPnL. Confirm this commission adjustment is a regulatory requirement for those jurisdictions. |
| ReportD | eToro Trading CIDs (5969875, 5969870, 5969868) are hardcoded. These should be validated periodically -- are there additional eToro Trading accounts? |

## Structural Questions

- The SP description placeholder says "Bla" and the date says "yyyy-mmy-dd" -- this is a legacy SP with minimal header documentation.
- The SP has extensive commented-out debugging code and alternative approaches. The active logic has been validated against the INSERT statement but commented code may contain historical business context.
- The `#collect` temp table WHERE clause has complex OR logic combining IsSettled=0 with IsFuture=1 and InstrumentTypeID=10 with IsSettled=1. The precedence of AND/OR may produce unexpected results -- the lack of parentheses around the IsFuture block is suspicious.
- Stock Margin (SettlementTypeID=5) was added October 2025 but is tracked via a flag column (`StockMargin`) that flows through all temp tables. Confirm stock margin positions are treated identically to CFD for KTCD purposes.
- The SP has no explicit error handling (no TRY/CATCH). A failure mid-execution could leave the table in a DELETE-without-INSERT state.
- CVA was changed from 1 to 1.5 for RegulationID NOT IN (4,10,9,11,13) in July 2025. The code comment says "change to 1.5 in aus/gaml/sey" but the logic actually applies 1.5 to regulations IN (4,10,9,11,13). Verify the intent matches implementation.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
