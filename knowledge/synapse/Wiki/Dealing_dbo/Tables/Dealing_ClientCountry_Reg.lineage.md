---
object: Dealing_ClientCountry_Reg
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Customer + Dim_Regulation + Dim_Country
---

# Dealing_ClientCountry_Reg — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Regulation ──► #Regulation_Countries (RegulationID, Region)
                                      │
DWH_dbo.Dim_Country ──► #Regions (CountryID, Country, Region)
                                      │
DWH_dbo.Dim_Customer ──────────────────┤
                                      ▼
                              #Final2 (RealCID, Country, RegulationID, Regulation,
                                        Customer_Region, Regulation_Region, IsSameRegion)
                                      │
                              GROUP BY RegulationID, Regulation
                              SUM(IsSameRegion=1) → Count_SameRegion
                              SUM(IsSameRegion=0) → Count_DiffRegion
                                      │
                                      ▼
                    Dealing_ClientCountry_Reg (Date, RegulationID, Regulation,
                                              Count_SameRegion, Count_DiffRegion)
```

## Source Tables

| Source | Schema | Used For |
|--------|--------|---------|
| `Dim_Customer` | DWH_dbo | All customers with RegulationID + CountryID |
| `Dim_Regulation` | DWH_dbo | Regulation name and geographic region |
| `Dim_Country` | DWH_dbo | Country region classification |

## Refresh Schedule
Daily — SP_ClientCountry (same call as Dealing_ClientCountry), OpsDB Priority 0
