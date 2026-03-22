---
object: Dealing_ClientsDataChange_3Months
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Position (current week metrics for 3-month trend comparison)
---

# Dealing_ClientsDataChange_3Months — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position ──► Current-week metrics per instrument
DWH_dbo.Dim_Position ──► @ThreeMonthsAgo-week metrics per instrument
                              │
                              ▼
                    JOIN on InstrumentID (current vs. 3-month-prior)
                              │
                              ▼
                 Dealing_ClientsDataChange_3Months
                 (instrument-level current-week values for 3-month comparison)
```

## Refresh Schedule
Weekly Saturday — SP_W_Sat_WeeklyClientData, OpsDB Priority 0, ProcessType 1 (SQL)
