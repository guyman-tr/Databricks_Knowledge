---
object: Dealing_ClientDataTop50
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Position (top-50 by volume per instrument per week)
---

# Dealing_ClientDataTop50 — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position (InstrumentTypeID IN 4,2,1, IsValidCustomer=1, last 7 days)
                │
                ├── GROUP BY InstrumentID, CID
                │   SUM(Volume) → WeeklyVolume / 5 → AvgDailyVolume
                │   MAX(DailyVolume) → MaxCustomer
                │
                ├── percentageOfAvgDailyVolume = CID_Vol / Instrument_TotalVol
                │
                └── ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY AvgDailyVolume DESC) = rn
                    WHERE rn <= 50
                │
                ▼
        Dealing_ClientDataTop50 (Date, InstrumentID, CID, rn, AvgDailyVolume, ...)
```

## Refresh Schedule
Weekly Saturday — SP_W_Sat_WeeklyClientData, OpsDB Priority 0, ProcessType 1 (SQL)
