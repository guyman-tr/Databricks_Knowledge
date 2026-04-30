# Review Needed: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

## Tier 3 Items (source identified, no upstream wiki)

| Column | Current Tier | Issue | Suggested Action |
|--------|-------------|-------|------------------|
| CIDViewed | Tier 3 | Source is Fact_UserPageViews.CIDViewed but Fact_UserPageViews has no wiki in the bundle or repo. Cannot inherit Tier 1 description. | Confirm if Fact_UserPageViews wiki exists elsewhere or accept Tier 3. |

## Data Staleness

- **Current data range**: DateID 20240502--20240531 (May 2024).
- **Last UpdateDate**: 2024-06-02.
- The SP may not be running in the current schedule. Verify with the ETL team whether SP_MarketingCloudUserBehavior is still active.

## Column Name Gotchas

- **LastMonthAmountInvest / LastMonthOpenPositionsInvest**: Despite the "LastMonth" prefix, these columns actually reflect the current calendar month at SP runtime, not the previous month. Consider whether the column names should be updated for clarity.
- **OpenActiveInstruments**: Despite the name suggesting instruments, this column counts open copy-trade positions, not distinct instruments.
- **TotalAmountInvest**: In this PI table, this column uses Dim_Mirror.RealizedEquity (not Dim_Position.Amount as in the Instrument companion table). The same column name with different semantics across sibling tables may confuse analysts.

## Unresolved Upstream Sources

| Source | Status |
|--------|--------|
| DWH_pagetracking.Fact_UserPageViews | No wiki found -- page-view tracking table, no documentation available in bundle |
| DWH_pagetracking.Fact_MarketPageViews | Referenced by companion table only, not directly by PI section |
