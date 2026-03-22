---
object: Dealing_Monitoring_ADV_MoreThanPercent
lineage_type: DWH Multi-source Aggregation (companion to Dealing_Monitoring_ADV)
production_source: DWH_dbo.Dim_Position + DWH_dbo.Dim_Customer + Dealing_Monitoring_ADV (inline)
---

# Dealing_Monitoring_ADV_MoreThanPercent — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Position (InstrumentTypeID IN 5,6, IsValidCustomer=1, OpenDateID=@DateID)
  │ → Per-CID volume per instrument for the day
  │
DWH_dbo.Dim_Customer
  │ → IsPI flag (GuruStatusID ≥ 2)
  │
Dealing_Monitoring_ADV (or inline CTE)
  │ → Per-instrument ADV for the same date
  │
  ▼
Filter: (CID volume / ADV) > threshold %
  │
  ▼
Dealing_Monitoring_ADV_MoreThanPercent
(written by SP_Monitoring_ADV — same SP call as Dealing_Monitoring_ADV)
```

## Refresh Schedule
Daily — SP_Monitoring_ADV, OpsDB Priority 0, ProcessType 1 (SQL). Active.
Written in the same SP execution as `Dealing_Monitoring_ADV`.
