---
object: Dealing_NOP_Report
lineage_type: Multi-LP External Aggregation
production_source: LP-specific staging/external tables (GS, IB, JP, Vision, SAXO, BNY Mellon, Marex, IronBeam, FXCM, UBS)
---

# Dealing_NOP_Report — Lineage Map

## Data Flow

```
GS staging/API
IB staging/API
JP staging/API
Vision staging/API
SAXO staging/API
BNY Mellon staging/API
Marex staging/API
IronBeam staging/API
FXCM staging/API
UBS staging/API
  │ → Per-LP NOP, margin, open premium, unrealised P&L
  │ → (exact source tables per LP not fully traced — SP is ~21K tokens)
  │
DWH_dbo.Dim_Instrument
  │ → InstrumentName, AssetClass
  │
Date logic:
  - Saturday: SP does not run
  - Sunday: @Date = last Friday
  - Friday: NextDate = next Monday
  │
  ▼
Dealing_NOP_Report
```

## Refresh Schedule
Daily (weekdays) — SP_NOP_Report, OpsDB Priority 0, ProcessType 3 (SQL&TIME). Active.
Does NOT run on Saturday. Sunday execution writes with last-Friday date.
