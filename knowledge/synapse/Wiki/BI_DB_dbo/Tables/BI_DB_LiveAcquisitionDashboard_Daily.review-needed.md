# Review Needed: BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily

Generated: 2026-04-22 | Reviewer: Marketing / Acquisition / Data Platform

## Tier 4 / Unverified Items

None — all 17 columns have confirmed sources via SP code analysis.

## Questions for Business Reviewer

1. **Rolling 90-day window intent**: The table name includes "Daily" but the load pattern is DELETE+full-reload of 90 days. Is this table the *current* view used in live dashboards, or is it a feed for `BI_DB_LiveAcquisitionDashboard` (the parent/historical table)? Understanding the relationship between the two helps analysts know which to query for real-time vs. historical analysis.

2. **CID column as bigint**: The DDL declares `CID` as `bigint`, but `Dim_Customer.RealCID` is `int`. Is this an intentional upcast for future CID growth, or should it match the source type? Queries that JOIN on CID to Dim_Customer may have implicit type conversion overhead.

3. **Region (MarketingRegionManualName)**: The Region values (UK, Spain, French, Italian, CEE) appear to be Marketing-curated. Who maintains this mapping in Dim_Country? Is there a canonical list of valid region values, or do new regions appear spontaneously as Dim_Country is updated?

4. **`@Days` declared but unused**: The SP declares `@Days = DATEADD(DAY,-1,@date)` but uses `< @date` in both WHERE clauses (not `<= @Days`). This means data up to @date-1 is included (since `Date < @date`). Was this intentional after the "11.05.21 Change Parameter" update, or is @Days a stale variable that should be removed?

5. **CLUSTERED INDEX on CID**: For a date-based dashboard, the clustered index on CID (not Date) means date-range queries do full scans. Was this a deliberate choice (assuming most queries look up by customer) or an oversight? Should a CCI or Date-indexed clustered index be considered?

6. **FTDs vs Registrations KPI in same row format**: With ~91.6% Registrations and ~8.4% FTDs in the table, analysts using `SUM(FTDA)` without filtering KPI='FTDs' will silently get the right answer (since FTDA is NULL for Registrations) but `COUNT(*)` will be inflated 10x. Should the table have a constraint or documentation to enforce KPI filtering in queries?

7. **Downstream relationship to BI_DB_LiveAcquisitionDashboard**: Is `SP_H_LiveAcquisitionDashboard` or `SP_H_LiveAcquisitionDashboard_New` the historical companion to this table? Does the Daily table feed the historical table, or are they independent?

## Known Data Quality Issues

- **CID type mismatch**: DDL uses bigint but source is int — implicit conversion on JOIN
- **@Days unused variable**: Stale SP variable from prior logic change — no functional impact but confusing
- **FunnelFromName is NULL for many rows**: LEFT JOIN on FunnelFromID — customers without a source funnel attribution have NULL
- **State is NULL for non-IP-matched customers**: Dim_State_and_Province LEFT JOIN — not all customers have a mapped region
- **No historical data**: Rolling 90-day window means events older than 90 days are permanently lost from this table

## Lineage Confidence

| Column Group | Confidence | Source |
|-------------|------------|--------|
| Country | HIGH (Tier 1) | Dim_Country.Name → Dictionary.Country confirmed |
| CID, Date, FTDA, SerialID, SubSerialID, DownloadID | HIGH (Tier 2) | Dim_Customer column analysis; source columns confirmed in SP |
| Channel, SubChannel | HIGH (Tier 2) | Dim_Channel wiki confirms AffWizz source |
| AffiliatesGroupsName, Contact | HIGH (Tier 2) | Dim_Affiliate wiki confirms AffWizz source |
| Region | MEDIUM (Tier 2) | MarketingRegionManualName is manually curated — may drift |
| FunnelName, FunnelFromName | HIGH (Tier 2) | SP code confirms Dim_Funnel LEFT JOIN on FunnelID / FunnelFromID |
| State | HIGH (Tier 2) | SP code confirms Dim_State_and_Province JOIN on RegionID |
| KPI | HIGH (Tier 2) | Hardcoded literals in SP UNION ALL branches |
