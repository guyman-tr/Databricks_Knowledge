# Review Needed: BI_DB_dbo.BI_DB_PI_Positions

## Items for Human Review

### 1. Data Freshness
- **Last UpdateDate**: 2024-04-15 06:47:28. The SP `SP_PI_Dashboard_COPYDATA_RuningSideBySide` appears to have stopped running. Confirm whether this is intentional (product deprecated) or an operational issue.

### 2. IsSettled Column — Tier 5 Expert Review
- `IsSettled` is carried through as Tier 5 (Expert Review) from the Dim_Position wiki, which itself marks this column with low upstream confidence. The upstream production source and exact derivation logic for IsSettled are not fully documented. Live data shows two values: 0 (CFD, 14.8M rows) and 1 (real asset, 9.3M rows). Consider verifying with the trading team whether IsSettled = 1 always means "real asset" vs CFD.

### 3. Population Drift
- Demoted PIs (GuruStatusID changed to < 2 or 7/8) retain their historical position rows but receive no new data. Confirm whether this is acceptable for historical analysis or whether a purge mechanism exists.

### 4. FullCommissionOnCloseOrig Source
- The Dim_Position wiki documents this column as `Tier 2 — SP_Dim_Position_DL_To_Synapse` with the formula: `CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0`. This is a passthrough from Dim_Position into BI_DB_PI_Positions. Promoted to Tier 1 (passthrough with upstream wiki) but the ultimate production source beyond SP_Dim_Position is not fully documented upstream.

### 5. Unresolved Upstream
- `BI_DB_dbo.BI_DB_PI_WeeklyTrades` (also managed by this SP) has no wiki. It consumes `BI_DB_CID_WeeklyPanel_FullData` and is a sibling shadow cache.

---

*Generated: 2026-04-29 | Reviewer: [pending]*
