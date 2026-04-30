# Review Needed: BI_DB_dbo.BI_DB_PositionPnL_SWITCH

## Infrastructure Table Classification

- **Question**: Should this table be included in the documentation backlog at all? It is a transient partition-switching shadow table that is always empty after ETL completes. It has no independent consumers, no UC target, and no analytical value.
- **Recommendation**: Consider adding to the blacklist (`_blacklist.json`) as an infrastructure/ETL artifact alongside `BI_DB_PositionPnL_SWITCH_SINGLE`.

## Tier Coverage

- **0 Tier 1 columns**: Expected — this table has no independent production source. All 39 columns are schema-cloned from `BI_DB_PositionPnL`.
- **39 Tier 2 columns**: Descriptions inherited from the `BI_DB_PositionPnL` upstream wiki. Source attribution is `(Tier 2 — BI_DB_PositionPnL)` since the schema relationship is a dynamic DDL clone, not a traditional ETL passthrough.

## Open Items

1. **Schema drift risk**: If `BI_DB_PositionPnL` gains or loses columns, this SSDT DDL may fall out of sync. In practice, `SP_PositionPnL` recreates the table dynamically from `SELECT TOP 0 *`, so the SSDT DDL is only used for the initial deployment. Verify whether the SSDT DDL is actively maintained or just a deployment artifact.

2. **Companion table**: `BI_DB_PositionPnL_SWITCH_SINGLE` serves a similar infrastructure role (staging for new partition data). It should receive the same documentation treatment.
