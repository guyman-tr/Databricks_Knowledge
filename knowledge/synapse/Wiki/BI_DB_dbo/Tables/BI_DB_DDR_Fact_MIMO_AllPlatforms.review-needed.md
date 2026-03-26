# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 21 columns are Tier 2 with verified SP code provenance.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| TransactionID | DDL defines as `int` but SP casts to `VARCHAR(50)` — confirm whether Synapse implicitly truncates or if this is a latent data truncation risk |
| AmountOrigCurrency | Negative values observed for TP withdrawals — confirm sign convention across platforms (eMoney appears signed differently) |
| IsTradeFromIBAN | Column renamed from IsIBANTrade — confirm whether "Trade from IBAN" means deposit FROM eMoney TO trading platform, or eMoney-originated trade |

## Structural Questions

| Topic | Question |
|-------|----------|
| Options reliability | SP comment says Options data "not reliably ready daily" — quantify the lag or failure rate |
| MoneyFarm scope | Only FTDs appear — confirm whether general MIMO for MoneyFarm will be added in future or is intentionally excluded |
| FTD recovery cutoff | Recovery UPDATEs only apply for DateID >= 20250901 — confirm whether historical data pre-Sept 2025 has known FTD gaps |
| C2USD UPDATE scope | UPDATE for FundingTypeID=27 only applies to DateID >= 20250701 — confirm whether earlier C2USD deposits are intentionally untagged |
