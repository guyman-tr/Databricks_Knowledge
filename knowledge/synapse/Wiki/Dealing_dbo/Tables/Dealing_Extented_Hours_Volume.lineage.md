---
object: Dealing_dbo.Dealing_Extented_Hours_Volume
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Extented_Hours_Volume

## ETL Chain

```
DWH_dbo.Dim_Position
  Filter: Exchange = 'Extended Hours Trading'
  Join: DWH_dbo.Dim_Customer (CountryID, Country_Name)
  Join: DWH_dbo.Dim_Instrument (Name, Symbol)
  → SP_Extented_Hours_Volume (@Date)
    Classify into session category by UTC hour:
      Pre_Session (10:30–13:30) / Main_Session (13:30–20:00) /
      Post_Session (>20:00) / OverNight_Session (00:00–10:30, added Mar 2025)
    → Dealing_dbo.Dealing_Extented_Hours_Volume
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | SP parameter @Date |
| PositionID | DWH_dbo.Dim_Position |
| CID | DWH_dbo.Dim_Position |
| InstrumentID | DWH_dbo.Dim_Position |
| Name | DWH_dbo.Dim_Instrument |
| Category | SP logic: time-of-day classification of Occurred timestamp |
| Volume | DWH_dbo.Dim_Position (USD-equivalent trade size) |
| Clicks | DWH_dbo.Dim_Position |
| UpdateDate | GETDATE() at SP execution time |
| Symbol | DWH_dbo.Dim_Instrument |
| CountryID | DWH_dbo.Dim_Customer via Dim_Position |
| Country_Name | DWH_dbo.Dim_Customer via Dim_Position |
| Leverage | DWH_dbo.Dim_Position |
| MirrorID | DWH_dbo.Dim_Position |
| Commission | DWH_dbo.Dim_Position |

## Refresh

- **OpsDB tracked**: ✅ Yes — Priority 0, SB_Daily
- **Pipeline status**: ⚠️ ~7 months stale — last run 2025-08-31
