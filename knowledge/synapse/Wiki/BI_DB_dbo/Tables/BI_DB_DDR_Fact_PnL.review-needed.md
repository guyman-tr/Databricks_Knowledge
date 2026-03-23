# Review Sidecar: BI_DB_dbo.BI_DB_DDR_Fact_PnL

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Writer SP | Verified | `SP_DDR_Fact_PnL` — DELETE/INSERT by `DateID`, aggregates from `Function_PnL_Single_Day` + `Dim_Instrument` |
| Grain / GROUP BY | Verified | Matches SP `GROUP BY` list and measure expressions |
| Tier 2 column semantics | Verified | All 15 columns traced to `SP_DDR_Fact_PnL` (measures and dimensions as coded) |
| Upstream TVF | Verified | `Function_PnL_Single_Day` reads `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`, `BI_DB_CopyFund_Positions`, `Function_Instrument_Snapshot_Enriched` for `IsSQF` |
| Consumers | Verified via repo grep | `BI_DB_V_DDR_PnL` (direct); `BI_DB_V_DDR_Daily_Panel`; `Function_DDR_Aggregation_*` via view |
| Confluence / Jira | Not searched this pass | Section 8 in main wiki left placeholder — run Phase 10 scan if links required |

## Unverified Items

| Topic | Notes |
|-------|-------|
| `InstrumentTypeID` business labels | IDs are correct from `Dim_Instrument`; human-readable names need dim lookup or glossary |
| `IsSettled` business definition | Passed through from TVF / position data — confirm product meaning in `Dim_Position` / policy docs |
| DDR orchestration schedule | Which parent job calls `SP_DDR_Fact_PnL` — confirm via OpsDB or orchestration wiki |
| Lake / merge note | SP header mentions null handling for merge keys (2025-12-07) — validate for UC export if applicable |

## Quality Notes

- No live Synapse sampling in this pass — distributions described from DDL only.
- Total PnL for reporting is commonly `UnrealizedPnLChange + NetProfit` per `BI_DB_V_DDR_PnL`; analysts should not sum measures across duplicate grain misunderstandings.
