# BI_DB_dbo.BI_DB_YearlyGain — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| BI_DB_dbo.BI_DB_MonthlyGain | BI_DB_dbo | Monthly gain percentages per customer (compounded into yearly) | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| RealCID | BI_DB_MonthlyGain | RealCID | passthrough |
| StartDate | — | DATEADD(DAY,1,DATEADD(YEAR,-1,@date)) | computed — first day of the 12-month window |
| EndDate | — | @date | SP input parameter |
| Gain | BI_DB_MonthlyGain | Gain | computed — geometric compound: 100*(EXP(SUM(LOG(1+Gain/100)))-1) over 12 months |
| UpdateDate | — | — | GETDATE() |

## Lineage Notes

- Yearly gain is calculated by geometrically compounding all monthly gains in the 12-month window.
- Formula handles negative months: uses LOG(1+Gain/100) only when (1+Gain/100) > 0, else -1 as fallback.
- One row per CID per EndDate (takes the latest StartPeriod row via ROW_NUMBER DESC).
- UC Target: _Not_Migrated.
