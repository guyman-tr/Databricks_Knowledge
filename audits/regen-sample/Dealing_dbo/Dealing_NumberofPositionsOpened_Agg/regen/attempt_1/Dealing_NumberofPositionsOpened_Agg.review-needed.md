# Review Needed: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

## 1. Data Start Date Discrepancy

The table contains data from 2022-01-01, while the parent table `Dealing_DealingDashboard_Clients` has data from July 2020. This suggests the aggregation INSERT was added to SP_DealingDashboard_Clients in early 2022. The SP change history does not document when this INSERT block was introduced (the earliest noted change is the Oct 2021 creation by Jenia Simonovitch). Confirm whether historical backfill to 2020 is needed or if 2022 is the intended start.

## 2. No Known Downstream Consumers

No views, SPs, or other objects in the SSDT repo reference this table (beyond the writer SP). Confirm whether this table has external consumers (dashboards, reports, API exports) or if it is redundant given that the same data can be derived from `Dealing_DealingDashboard_Clients` with a GROUP BY.

## 3. Zero-Value Rows on Weekends

Weekend dates (e.g., DateID=20260426, a Saturday) contain rows with `NumberOfPositionsOpened=0` for all instrument types. Confirm whether these zero-value rows are intentional for time-series continuity or if they should be filtered out.

## 4. Tier Summary

All 6 columns are Tier 2 (ETL-computed or passthrough from ETL-computed upstream). No Tier 1 is expected because this table is fully derived within the DWH — it has no direct production source. No Tier 4 columns exist.

---

*Generated: 2026-04-30*
