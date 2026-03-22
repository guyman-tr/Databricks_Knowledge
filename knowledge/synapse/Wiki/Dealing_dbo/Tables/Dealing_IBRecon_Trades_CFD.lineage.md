# Column Lineage — Dealing_dbo.Dealing_IBRecon_Trades_CFD

**Writer**: `Dealing_dbo.SP_IB_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — IB CFD trades vs eToro trade activity
**Status**: ⚠️ Effectively abandoned — 1 row, last data 2025-03-28

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_ActivityRecon | Production (Tier 1) | eToro trades side (HS 300) |
| Dealing_staging.LP_IB_I1893329_Daily_Trades | LP Feed (Tier 2) | IB CFD trade confirmations (not delivering data) |

## Column → Source Mapping

Identical structure to `Dealing_IBRecon_Trades`. All columns map the same way but scoped to CFD accounts (HS 300).

| Column | Source | Notes |
|---|---|---|
| IB_Units | LP_IB_I1893329_Daily_Trades | CFD trade quantity |
| HedgeServerID | SP logic | 300 |
| All others | Same as Dealing_IBRecon_Trades | Same SP branch |
