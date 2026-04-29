# DWH_dbo.Fact_CurrencyPriceWithSplit - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All 14 columns are Tier 2 (derived from SP code analysis).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ProviderID | What are the 3 distinct ProviderID values and what data provider does each represent? |
| isvalid | Is isvalid=0 always safe to exclude? Are there cases where isvalid=0 rows carry meaningful price data not captured by isvalid=1 rows? |
| ConvertRateIsBuy_1/0 | The ~1.3M NULL ConvertRate rows - are these expected for certain instrument types (e.g., crypto pairs with no USD cross-rate)? Is ISNULL(..., 1.0) the correct fallback or should they be excluded? |

## Structural Questions

| Question |
|----------|
| What downstream fact tables or SPs consume Fact_CurrencyPriceWithSplit for P&L conversion? SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse is suspected - confirm. |
| The SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse has an OLD_VER variant in the repo. Is the current SP fully replacing it or are both run in some scenarios? |
| The Generic Pipeline mapping shows copy_strategy=Merge with frequency_minutes=1440 (daily). Is the Databricks UC table fully in sync with Synapse daily, or is there a lag? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
