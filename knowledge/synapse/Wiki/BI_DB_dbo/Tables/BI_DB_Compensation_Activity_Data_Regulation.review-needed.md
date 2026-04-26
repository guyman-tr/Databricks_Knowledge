# Review Needed — BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation

Generated: 2026-04-23 | Batch 71

## Tier 4 Items (Unverified)

None — all columns resolved to Tier 2 (SP-derived) or Propagation.

## Questions for Reviewer

1. **ActionType CategoryID IN (17,18)**: The SP uses `Dim_ActionType.CategoryID IN (17,18)` — confirmed as PositionClose (17) and PositionOpen (18) from the Dim_ActionType wiki. The RealStocksETFTransactions and CFDTransactions counts therefore include BOTH opens and closes. Is this the intended metric (total position events) or should this be opens-only?
2. **FSRA absent**: FSRA (RegulationID=11) is present in the SP CASE logic but has no row in March 2026 data. Confirm this is expected (no active FSRA traders in the period) vs. a data quality issue.
3. **Downstream consumers**: No downstream SP/view references found in SSDT. Is this table consumed by an external compliance dashboard?
4. **ASIC merge**: ASIC (RegulationID=4) and ASIC&GAML (RegulationID=10) are merged into one label. Is this intentional for compliance reporting, or should they be split for finer granularity?

## Known Limitations

- **Aggregate only** — no per-customer detail; use Fact_CustomerAction for individual-level analysis.
- **Previous month scope** — historical trend requires external tooling (this table is overwritten each run).
- **ASIC merged** — RegulationID=4 (ASIC) and RegulationID=10 (ASIC&GAML) are not separable from this table.
- **NULL = no activity** — NULL in CFDTransactions (US) or RealCryptoPositionCount (MAS) indicates no events of that type, not a data quality gap.
- ROUND_ROBIN / HEAP — trivially sized (7 rows); no performance concerns.
