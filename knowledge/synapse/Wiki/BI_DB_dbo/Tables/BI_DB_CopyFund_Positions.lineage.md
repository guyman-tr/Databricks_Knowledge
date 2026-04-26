# BI_DB_dbo.BI_DB_CopyFund_Positions — Column Lineage

Generated: 2026-04-23 | Schema: BI_DB_dbo | Object: BI_DB_CopyFund_Positions

## ETL Chain

```
DWH_dbo.Dim_Position (copy-trade positions opened/closed on @date, MirrorID > 0)
  |-- SP_CopyFund_Positions (Guy Manova, 2025-03-07) ---|
  |   + DWH_dbo.Dim_Mirror (MirrorTypeID=4 Fund mirrors only)
  |     → Pre-join eliminates runtime join cost from Positions → MirrorIDs
  v
BI_DB_dbo.BI_DB_CopyFund_Positions (DELETE+INSERT per @date, append-mode, HASH(PositionID))
  |-- CLUSTERED COLUMNSTORE INDEX (analytical workload optimized) ---|
  |-- Post-load dedupe: detects and resolves duplicate PositionIDs ---|
  |-- Not in Generic Pipeline (no UC target) ---|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough | Tier 1 |
| CID | DWH_dbo.Dim_Position | CID | Passthrough (copier's customer ID) | Tier 1 |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough | Tier 1 |
| OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Passthrough | Tier 1 |
| CloseDateID | DWH_dbo.Dim_Position | CloseDateID | Passthrough; dedupe keeps MAX(CloseDateID) | Tier 1 |
| ParentCID | DWH_dbo.Dim_Mirror | ParentCID | Passthrough (Fund PI's customer ID) | Tier 1 |
| ParentUserName | DWH_dbo.Dim_Mirror | ParentUserName | Passthrough (Fund PI's username) | Tier 1 |
| MirrorTypeID | DWH_dbo.Dim_Mirror | MirrorTypeID | Passthrough; always 4 (Fund) due to WHERE MirrorTypeID=4 filter | Tier 1 |
| UpdateDate | ETL metadata | (none) | GETDATE(); dedupe keeps MAX(UpdateDate) | Propagation |
| IsPartialCloseChild | DWH_dbo.Dim_Position | IsPartialCloseChild | Passthrough | Tier 1 |

## Source Objects

- `DWH_dbo.Dim_Position` — primary position data (PositionID, CID, MirrorID, OpenDateID, CloseDateID, IsPartialCloseChild)
- `DWH_dbo.Dim_Mirror` — mirror metadata (ParentCID, ParentUserName, MirrorTypeID); filtered WHERE MirrorTypeID=4

## UC External Lineage

UC Target: _Not_Migrated — not in Generic Pipeline mapping
