---
object: Dealing_Boundary_Cost_H_Indices
schema: Dealing_dbo
lineage_type: decommissioned-historical
generated: 2026-03-21
---

# Lineage — Dealing_Boundary_Cost_H_Indices

## Pipeline Status

**DECOMMISSIONED** — No active writer SP. Last data 2023-03-15. SP_Boundary_Cost (the active SP) does not reference this table.

## ETL Chain

```
[Unknown historical writer SP — indices-filtered variant]
    → Dealing_Boundary_Cost_H_Indices  (FROZEN Mar 2023)
```

The active `Dealing_Boundary_Cost` table is written by `SP_Boundary_Cost`. This `_H_Indices` variant appears to be a historical predecessor or filtered snapshot that was maintained separately.

## Production Source

Not in Generic Pipeline mapping. Internal DWH analytical table — sources are price feeds, position data, and NOP calculation from internal systems.

## Column Lineage

| DWH Column | Source (inferred) | Transform |
|------------|------------------|-----------|
| Date, DateID | Date parameter | passthrough |
| InstrumentID, InstrumentName, InstrumentType | DWH_dbo.Dim_Instrument | passthrough |
| LastBid, LastAsk, Mid | Price feed | passthrough / computed |
| NOP | Position data | (UnitsBuy - UnitsSell) × price |
| WAVG_BuyPrice, WAVG_SellPrice | Position data | weighted average |
| IsSettled | Business logic | ETL-computed (boundary crossing flag) |
| UpdateDate | ETL | GETDATE() |
