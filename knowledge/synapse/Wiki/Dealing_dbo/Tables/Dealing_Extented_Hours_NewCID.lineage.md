---
object: Dealing_dbo.Dealing_Extented_Hours_NewCID
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_Extented_Hours_NewCID

## ETL Chain

```
DWH_dbo.Dim_Position
  Filter: Exchange = 'Extended Hours Trading'
  Filter: CID NOT EXISTS in any prior Dim_Position with Exchange = 'Extended Hours Trading'
  Join: DWH_dbo.Dim_Customer (CountryID, Country_Name)
  Join: DWH_dbo.Dim_Instrument (Name, Symbol)
  → SP_Extented_Hours_NewCID (@Date)
    GROUP BY Date × CountryID × InstrumentID × MirrorID
    COUNT(DISTINCT CID) as New_CIDs
    → Dealing_dbo.Dealing_Extented_Hours_NewCID
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | SP parameter @Date |
| New_CIDs | COUNT(DISTINCT CID) filtered by first-time extended hours |
| UpdateDate | GETDATE() at SP execution time |
| CountryID | DWH_dbo.Dim_Customer via Dim_Position |
| Country_Name | DWH_dbo.Dim_Customer via Dim_Position |
| InstrumentID | DWH_dbo.Dim_Position |
| Name | DWH_dbo.Dim_Instrument |
| Symbol | DWH_dbo.Dim_Instrument |
| MirrorID | DWH_dbo.Dim_Position |

## Refresh

- **OpsDB tracked**: ✅ Yes — Priority 0, SB_Daily
- **Pipeline status**: ⚠️ ~7 months stale — last run 2025-08-29
