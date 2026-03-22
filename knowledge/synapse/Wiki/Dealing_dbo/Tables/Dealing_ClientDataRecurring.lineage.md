---
object: Dealing_ClientDataRecurring
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Position (current week + 4-week lookback windows)
---

# Dealing_ClientDataRecurring — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position (InstrumentTypeID IN 4,2,1, IsValidCustomer=1)
                │
                ├── Current week CIDs per instrument
                ├── Week-1 CIDs per instrument (LastSunday to @Date)
                ├── Week-2 CIDs per instrument (14-21 days ago)
                └── Week-4 CIDs per instrument (28-35 days ago)
                │
                ▼
     INTERSECT per instrument → recurring fractions
                │
                ▼
     Dealing_ClientDataRecurring (InstrumentID, PercentageOfReturn,
                                  percentageOf2week, percentageOf4week, Date)
```

## Refresh Schedule
Weekly Saturday — SP_W_Sat_WeeklyClientData, OpsDB Priority 0, ProcessType 1 (SQL)
