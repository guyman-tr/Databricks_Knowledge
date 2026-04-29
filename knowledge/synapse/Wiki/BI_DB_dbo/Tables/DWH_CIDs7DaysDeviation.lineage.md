# BI_DB_dbo.DWH_CIDs7DaysDeviation — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| DWH_dbo.Fact_CustomerUnrealized_PnL | DWH_dbo | Daily customer PnL standard deviation | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Date | DWH_dbo | Date range calculation for 7-day rolling window | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| FullDate | Dim_Date | FullDate | passthrough — the target date |
| CID | Fact_CustomerUnrealized_PnL | CID | passthrough |
| Deviation | Fact_CustomerUnrealized_PnL | StandardDeviation | computed — AVG(StandardDeviation) over 7-day window (day-6 to day) |
| UpdateDate | — | — | GETDATE() |

## Lineage Notes

- 7-day window uses Dim_Date self-join: b.FullDate BETWEEN DATEADD(day,-6,bb.FullDate) AND bb.FullDate
- This table feeds BI_DB_WeeklyCopyBlock risk score calculation (10-bucket CASE on Deviation thresholds)
- UC Target: _Not_Migrated
