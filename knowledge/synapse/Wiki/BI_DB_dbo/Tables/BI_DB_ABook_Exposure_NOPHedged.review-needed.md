# Review Needed: BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged

**Generated**: 2026-04-23
**Quality Score**: 7.5/10
**Status**: Needs domain expert review

## Open Questions

1. **Why is the data stale?** — Generic Pipeline #471 is configured for hourly Override refreshes, but all 15,178 rows are from 2024-02-15 00:08:38. Did the pipeline stop, was it suspended, or did the source system change? Is this table currently being used for anything?

2. **InstrumentIDToHedge NULL semantics** — 85% of rows (12,978) have NULL InstrumentIDToHedge. This has been interpreted as "hedge with same instrument (InstrumentID)." Is this correct, or does NULL mean something else (e.g., no hedge placed)?

3. **InstrumentID_Final derivation** — Documented as COALESCE(InstrumentIDToHedge, InstrumentID). Please confirm this is the correct interpretation. From live data, when InstrumentIDToHedge IS NULL, InstrumentID_Final = InstrumentID. When InstrumentIDToHedge is set, InstrumentID_Final = InstrumentIDToHedge (even when they equal InstrumentID). Is this a system-level resolution of the actual hedge instrument?

4. **NULL LiquidityAccountID rows** — 3,735 rows (25%) have no liquidity account. Are these BBook positions, or positions pending LP assignment, or a different type of unhedged exposure?

5. **Writer SP** — No writer SP was found in SSDT BI_DB_dbo. How does data get into this table? Is it populated via a direct SQL insert from an on-prem system, or via a staging schema SP?

6. **Relationship to BI_DB_ABook_Exposure** — The sibling table has the same core columns but adds 5 unhedged columns (NOP_unhedged, Nop_Units_unhedged, OpenPositions_unhedged, Short_unhedged, Long_unhedged). This table is net-only. Are they populated by the same source at different stages, or by completely different sources?

## Columns Requiring Confirmation

| Column | Concern |
|--------|---------|
| InstrumentIDToHedge | Tier 3 — 85% NULL. Interpretation: proxy hedge instrument. Confirm NULL = same instrument. |
| InstrumentID_Final | Tier 3 — described as COALESCE(InstrumentIDToHedge, InstrumentID). Confirm semantics. |
| LiquidityAccountID | Tier 3 — described as LP account FK. Confirm NULL semantics (BBook vs unassigned). |
| LiquidityAccountName | Tier 3 — de-normalized LP name. Confirm source (joins to which reference table?). |
| OpenPositions | Tier 3 — from live data: OpenPositions = Long when Short=0 (net position only?). Confirm if this is |Long|+|Short| or just NOP. |

## Lineage Gaps

- Source system that feeds this table before Generic Pipeline #471 picks it up is unknown
- Generic Pipeline reads Synapse data, but what puts data INTO Synapse is undocumented
- `BI_DB_Migration.BI_DB_ABook_Exposure_NOPHedged` migration table exists — UpdateDate is varchar(50) there vs datetime here, suggesting a type conversion during migration

## Live Data Observations

- All rows date to 2024-02-15 (stale — pipeline appears suspended)
- NOPHedged can exceed NOP (observed: KRNY/USD NOPHedged=45.15, NOP=43.47 — 1.038x over-hedged)
- When HedgeServerID=2: LiquidityAccountID=NULL, NOPHedged=0 — this server appears to be the BBook server
- LiquidityAccount 272 "APEX Traffix Account Real 3EU05025 Real" = most common (3,032 rows, 20% of table)
