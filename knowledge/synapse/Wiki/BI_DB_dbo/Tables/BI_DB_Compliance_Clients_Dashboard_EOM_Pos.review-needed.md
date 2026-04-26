# Review Needed — BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos

Generated: 2026-04-23 | Batch 71

## Tier 4 Items (Unverified)

None — all columns resolved to Tier 1, Tier 2, or Propagation.

## Questions for Reviewer

1. **RealCID column naming**: The `RealCID` column contains `COUNT(RealCID)` — a customer count, not a customer ID. Was this intentional in the original design, or a historical naming error? This is a significant usability risk for downstream consumers.
2. **"Opened_EOD" only**: PositionType is hardcoded 'Opened_EOD' for all rows. Does another SP populate 'Closed_EOD' or 'Open_EOM' rows into this same table? If so, identify the SP and confirm the table name is accurate.
3. **Positions opened ON EOM date only**: The SP filters `OpenDateID = @DateID` — only positions opened exactly on the last day of the month. Is this intentional for compliance reporting, or should it capture all positions open AS OF month-end?
4. **New customer definition (60-day threshold)**: FirstDepositDate ≤ 60 days before EOM is used as the "new customer" threshold. Confirm this 60-day window is a stable business rule, not a temporary configuration.
5. **Author unknown**: SP has no author attribution beyond a MAS addition by Oskar Harhalakis (2025-12-03). Confirm original author.
6. **Downstream consumers**: No SSDT downstream references found. Confirm which compliance dashboard consumes this table.

## Known Limitations

- **Aggregate only** — no individual customer rows; `RealCID` is a count not an ID.
- **EOM-only granularity** — intra-month position data not available here; use Dim_Position directly.
- **Opens on EOM date only** — this is NOT an "all open positions as of EOM" table; it specifically captures new openings on the last day.
- **N/A in IsSettledTypeDetailed** — 108 rows (0.1%) with 'N/A' represent edge-case instrument combinations not covered by the 5-way CASE logic.
- ROUND_ROBIN / CLUSTERED INDEX (DateID) — range scans by date are efficient; cross-regulation joins with HASH tables will broadcast this table.
