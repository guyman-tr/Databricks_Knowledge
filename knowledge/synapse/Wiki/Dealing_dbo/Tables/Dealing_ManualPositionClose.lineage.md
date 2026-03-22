---
object: Dealing_ManualPositionClose
lineage_type: Operational Log → DWH
production_source: Dealing_staging.External_DB_Logs_History_ManualPositionClose_Crisis
---

# Dealing_ManualPositionClose — Lineage Map

## Data Flow

```
Dealing_staging.External_DB_Logs_History_ManualPositionClose_Crisis
  (PositionID, OperationID, InsertDate ∈ [DateMinus1, Date))
                │
                JOIN Dealing_staging.External_DB_Logs_History_ManualOperationPositionClose_Crisis
                  ON OperationID → OperationDescription, UserName
                │
                ▼
              #ManualClosePositions (PositionID, OperationDescription, UserName)
                │
                ├── JOIN DWH_dbo.Dim_Position (PositionID match) → #Positions
                │     (InstrumentID, AmountInUnitsDecimal, EndForexRate, Conversion, US_Client, CloseOccurred)
                │
                └── JOIN DWH_dbo.Dim_Position (TreeID = PositionID, MirrorID > 0) → #TreeUnits
                      (NumberOfChildPositions, NumberOfChildCIDs, TotalChildUnits)
                │
                ▼
              #Final → Dealing_ManualPositionClose
```

## Production Source
Staging tables mirror `DB_Logs_History` tables from the production trading platform (crisis/admin interface).

## Refresh Schedule
Daily — SP_ManualPositionClose, OpsDB Priority 0, ProcessType 1 (SQL)
