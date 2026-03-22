---
object: Dealing_ClientsDataChange_6Months
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Position (current week metrics for 6-month trend comparison)
---

# Dealing_ClientsDataChange_6Months — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position ──► Current-week metrics per instrument
DWH_dbo.Dim_Position ──► @SixMonthsAgo-week metrics per instrument
                              │
                              ▼
                    JOIN on InstrumentID (current vs. 6-month-prior)
                              │
                              ▼
                 Dealing_ClientsDataChange_6Months
                 (instrument-level current-week values for 6-month comparison)
```

## Refresh Schedule
Weekly Saturday — SP_W_Sat_WeeklyClientData, OpsDB Priority 0, ProcessType 1 (SQL)
