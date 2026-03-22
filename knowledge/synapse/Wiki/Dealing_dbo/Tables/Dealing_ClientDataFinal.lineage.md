---
object: Dealing_ClientDataFinal
lineage_type: DWH Aggregation
production_source: DWH_dbo.Dim_Position (via Fact_SnapshotCustomer, Dim_Instrument, Dim_Country)
---

# Dealing_ClientDataFinal — Lineage Map

## Data Flow

```
CopyFromLake.etoro_History_PositionChangeLog ──► #PositionChangeLog (SL/TP change counts)
                                                              │
DWH_dbo.Dim_Position ──────────────────────────────────────┐ │
DWH_dbo.Dim_Instrument (InstrumentTypeID IN 4,2,1) ────────┤ │
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1) ─────────┤ │
DWH_dbo.Dim_Country ───────────────────────────────────────┘ │
                    │                                         │
                    ▼                                         │
              #Positions (InstrumentID, Country, Volume,      │
                           CloseReasonID, OpenDate,            │
                           ClosedDuringPeriod, OpenedDuringPeriod)
                    │                                         │
                    ├──► #UniqueCIDS, #AvgDuration, #SLTPReasons, #Leverage ...
                    └─────────────────────────────────────────┘
                                      │
                                      ▼
                         Dealing_ClientDataFinal
                         (instrument × country × Saturday)
```

## Refresh Schedule
Weekly Saturday — SP_W_Sat_WeeklyClientData, OpsDB Priority 0, ProcessType 1 (SQL)
