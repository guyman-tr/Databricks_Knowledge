# Review Notes — BI_DB_dbo.BI_DB_ClubChangeLogProduct

**Batch**: 18 | **Generated**: 2026-04-21 | **Reviewer**: TBD

## Tier 4 Items (Low Confidence — Needs Human Review)

None. All columns are either Tier 1 (CID verbatim from upstream) or Tier 2 (SP code confirmed).

## Data Quality Issues Flagged

1. **PLChangeType dual naming** — The column contains both `'FirstClub'` (14.9M rows, current SP) and `'First Club'` (31.5M rows, legacy SP) for the same event type. The SP naming changed at some point (unknown date — no SP header comment). Consumers filtering `PLChangeType = 'FirstClub'` silently miss 31.5M historical events. **Review action**: Consider a one-time UPDATE to standardize to 'FirstClub', or document the dual-form as a permanent gotcha in all downstream consumers.

2. **CID column nullable** — DDL has CID as int NULL despite being the primary customer identifier. Can CID ever be NULL in practice? Query confirmed no NULLs in sample but not validated at full scale.

## Open Questions

1. **Who executes SP_ClubChangeLogProduct?** — OpsDB confirms P20/SB_Daily but no explicit dependency on BI_DB_CID_DailyPanel_FullData in OpsDB (even though the panel reads from this table). Is the execution order guaranteed by the SB process queue?

2. **IsFTC logic nuance** — IsFTC=1 fires for the FIRST time a customer ever reaches Tier > 1. But if a customer was Bronze, promoted to Silver, then downgraded back to Bronze, then promoted again to Silver — does the second Silver promotion get IsFTC=1? The COUNT OVER PARTITION BY CID ORDER BY Date = 1 checks if it's the first row with CurrentTier > 1 by cumulative count. A second promotion would have COUNT=2 → IsFTC=0. Confirm with business owner whether this is the intended behavior.

3. **Author Tom Boksenbojm / Eden Winkler** — SP created 2023-03-28 with IsFTC added same day. The 'First Club' legacy rows (31.5M) predate the SP creation — where did those rows come from? Was this table migrated or backfilled from a prior system?

## Cross-Object Consistency

- CID description matches Customer.CustomerStatic upstream wiki verbatim ✓
- CurrentClub/CurrentSort/CurrentTier values match Dim_PlayerLevel wiki Tier Hierarchy (2.1) ✓
