# Column Lineage — BI_DB_dbo.BI_DB_ClubChangeLogProduct

**Generated**: 2026-04-21 | **Writer SP**: SP_ClubChangeLogProduct | **Batch**: 18

## Source Chain

```
etoro.Customer.CustomerStatic (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export)
  v
DWH_dbo.Fact_SnapshotCustomer (RealCID, PlayerLevelID, IsValidCustomer, DateRangeID)
  +-- DWH_dbo.Dim_Range (DateRangeID → FromDateID/ToDateID)
  +-- DWH_dbo.Dim_PlayerLevel (PlayerLevelID → Name, Sort)
  |-- SP_ClubChangeLogProduct (@Date, append-only)
  v
BI_DB_dbo.BI_DB_ClubChangeLogProduct
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Customer.CustomerStatic | CID | Rename: Fact_SnapshotCustomer.RealCID → CID. Passthrough. | Tier 1 |
| 2 | Date | ETL | @Date parameter | SET to SP @Date parameter (run date). | Tier 2 |
| 3 | OldTier | BI_DB_ClubChangeLogProduct (self) | CurrentTier | Most-recent prior row per CID (ROW_NUMBER OVER PARTITION BY CID ORDER BY Date DESC). NULL for FirstClub events. | Tier 2 |
| 4 | OldClub | BI_DB_ClubChangeLogProduct (self) | CurrentClub | Most-recent prior row per CID. NULL for FirstClub events. | Tier 2 |
| 5 | OldSort | BI_DB_ClubChangeLogProduct (self) | CurrentSort | Most-recent prior row per CID. NULL for FirstClub events. | Tier 2 |
| 6 | CurrentTier | Fact_SnapshotCustomer | PlayerLevelID | Passthrough from today's snapshot row for this CID. FK to Dim_PlayerLevel. | Tier 2 |
| 7 | CurrentClub | Dim_PlayerLevel | Name | Resolved at ETL time: JOIN Dim_PlayerLevel ON PlayerLevelID → Name. Denormalized into row. | Tier 2 |
| 8 | CurrentSort | Dim_PlayerLevel | Sort | Resolved at ETL time: JOIN Dim_PlayerLevel ON PlayerLevelID → Sort. Denormalized into row. | Tier 2 |
| 9 | PLChangeType | ETL | CASE logic | CASE: CurrentSort < OldSort → 'Downgrade'; else → 'Upgrade'; no prior row → 'FirstClub'. Legacy SP wrote 'First Club' (space). | Tier 2 |
| 10 | UpdateDate | ETL | SYSUTCDATETIME() | Set at INSERT time and at IsFTC UPDATE time. | Tier 2 |
| 11 | IsFTC | ETL | Window function | COUNT(CID) OVER (PARTITION BY CID ORDER BY Date) = 1 AND CurrentTier > 1 → 1; else 0. Updated post-insert. | Tier 2 |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
