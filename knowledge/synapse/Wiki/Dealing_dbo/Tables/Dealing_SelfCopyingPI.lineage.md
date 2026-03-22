---
object: Dealing_SelfCopyingPI
lineage_type: DWH Detection → Alert Table (DECOMMISSIONED)
production_source: DWH_dbo.Dim_Mirror (PI copy relationships + IP matching)
---

# Dealing_SelfCopyingPI — Lineage Map

## Status: DECOMMISSIONED
SP: `HOLD_20240416_SP_SelfCopyingPI.sql` — placed on HOLD April 2024.
Last data: 2023-09-03.

## Historical Data Flow

```
DWH_dbo.Dim_Mirror (active copy relationships)
  │ → CopyerIP, ParentCID, CopyerAUM, TotalCopyAum
  │ → Filter: CopyerIP matches ParentCID's known IP
  │
  ▼
Dealing_SelfCopyingPI (ParentCID, CopyerIP, PercentageOfAUM, ...)
```

## Refresh Schedule
Was Daily — decommissioned April 2024.
