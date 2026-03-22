---
object: Dealing_Best_Execution_Compensation_CBH_HOLD
schema: Dealing_dbo
lineage_type: decommissioned
generated: 2026-03-21
---

# Lineage — Dealing_Best_Execution_Compensation_CBH_HOLD

## Pipeline Status

**DECOMMISSIONED** — No active writer SP. Last data 2023-05-16.

## ETL Chain

```
[Unknown writer SP — not in current SSDT repo]
    → Dealing_Best_Execution_Compensation_CBH_HOLD  (FROZEN May 2023)
```

Likely derived from slippage position data enriched with LP rate data for the CBH routing context. The compensation calculation pattern (`Compensation = MIN(SlippageInDollar, Compensation_Limit)` where `OverThreshold=1`) is inferred from column structure.

## Production Source

Not mapped in Generic Pipeline. Sources were LP execution records + production position data.

## Notes

- No writer SP found in SSDT Dealing_dbo stored procedures
- Structurally identical to `Dealing_Best_Execution_Compensation_HBC_HOLD` (different LP routing)
- Active counterpart `Dealing_Best_Execution_Compensation_CBH` (Batch 5) was also decommissioned Jan 2025
