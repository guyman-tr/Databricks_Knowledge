---
object: Daily_Slippage_Positions_HOLD
schema: Dealing_dbo
lineage_type: decommissioned
generated: 2026-03-21
---

# Lineage — Daily_Slippage_Positions_HOLD

## Pipeline Status

**DECOMMISSIONED** — No active writer SP. Last data: 2023-06-13.

## ETL Chain

```
[Unknown source — no active SP in SSDT repo]
    → Daily_Slippage_Positions_HOLD   (FROZEN Jun 2023)
```

Predecessor pattern: The HOLD suffix indicates this was a snapshot taken before a pipeline restructure. The active pipeline continued in `Dealing_Daily_Slippage_Positions` (itself decommissioned Jan 2025).

## Production Source

| Attribute | Value |
|-----------|-------|
| Generic Pipeline mapping | Not found — DWH-internal table |
| Source system | LP execution systems (inferred from column structure) |
| Upstream wiki | None available |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| PositionID | Trade.PositionTbl (inferred) | PositionID | passthrough |
| CID | Trade.PositionTbl (inferred) | ClientID | passthrough |
| SlippageInPips | Computed | CustomerChosenRate vs ExecutionRate | ETL-computed |
| SlippageInDollar | Computed | SlippageInPips × ConversionRate | ETL-computed |
| OverThreshold | Computed | SlippageInDollar > threshold | ETL-computed |
| ChosenToTrigger | Computed | CustomerChosenRate - TriggerRate | ETL-computed |
| TriggerToReceived | Computed | TriggerRate - ReceivedRate | ETL-computed |
| UpdateDate | ETL | GETDATE() | ETL metadata |

## Notes

- Full column lineage unavailable — writer SP not present in SSDT repo
- Structure is identical to `Dealing_Daily_Slippage_Positions` — likely same writer SP, different time period
