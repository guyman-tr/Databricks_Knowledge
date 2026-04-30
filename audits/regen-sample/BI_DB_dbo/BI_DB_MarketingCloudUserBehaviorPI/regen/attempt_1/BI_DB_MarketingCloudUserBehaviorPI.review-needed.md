# Review Needed: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

## 1. Data Staleness

- **Current data range**: DateID 20240502--20240531 (May 2024). The SP may not be actively running. Confirm with the data engineering team whether `SP_MarketingCloudUserBehavior` is still scheduled and the Salesforce Marketing Cloud SFTP export is still in use.

## 2. TotalAmountInvest Source Discrepancy

- In the PI section, `TotalAmountInvest` is sourced from `Dim_Mirror.RealizedEquity` (not `SUM(Dim_Position.Amount)` as in the Instrument sibling table). The SP code assigns `dm.RealizedEquity` as `TotalAmountInvest` in the `#dp_AmountInvestPI` temp table. Confirm this is intentional and not a bug -- the column name `TotalAmountInvest` is misleading if it actually represents realized equity.

## 3. LastOpen Semantic

- `LastOpen` is derived from `MAX(Dim_Mirror.OpenDateID)`, meaning it reflects the most recent mirror (copy-trade relationship) opened, NOT the most recent position opened. The Instrument sibling derives `LastOpen` from `MAX(Dim_Position.OpenDateID)`. This semantic difference should be documented for consumers.

## 4. Unresolved Upstream

- `DWH_pagetracking.Fact_UserPageViews` has no wiki documentation. CID and CIDViewed columns are attributed based on SP code inspection. If a wiki is created for Fact_UserPageViews, update Tier 1 sources for CID, CIDViewed, and DateID.

## 5. OpenActiveInstruments Naming

- The column is named `OpenActiveInstruments` but in the PI context it counts open copy-trade positions (via Dim_Mirror), not distinct instruments. The name is inherited from the Instrument sibling table's schema but has a different semantic meaning here. Consider whether this causes confusion for Marketing Cloud consumers.
