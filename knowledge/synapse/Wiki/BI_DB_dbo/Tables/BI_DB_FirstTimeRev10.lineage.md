# BI_DB_dbo.BI_DB_FirstTimeRev10 — Column Lineage

**Generated**: 2026-04-23 | **Pipeline**: SP_FirstTimeRev10 (Daily, SB_Daily — SP code not accessible)

## ETL Chain

```
DWH_dbo / Trade.PositionTbl (closed positions with commission data)
  |-- SP_FirstTimeRev10 (Daily, SB_Daily — logic not accessible) ---|
  v
BI_DB_dbo.BI_DB_FirstTimeRev10 (2.9M rows, first-time ≥$10 commission event per CID)
  |-- (downstream consumers include SP_Marketing_Cube → BI_DB_MarketingMonthlyRawData — inferred)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | Closed position event | date of position close | Calendar date of the first ≥$10 commission event | Tier 2 — data evidence |
| 2 | Timestamp | Closed position event | exact close timestamp | Exact datetime of position close/commission generation | Tier 2 — data evidence |
| 3 | CID | Trade source (position owner) | CID | Customer ID — one row per CID (deduplicated to first occurrence) | Tier 1 — Customer.CustomerStatic |
| 4 | PositionID | Trade.PositionTbl | PositionID | The specific position that first crossed the $10 commission threshold | Tier 2 — data evidence + naming |
| 5 | AggregatedCommission | Trade.PositionTbl | commission/spread | Commission/revenue from that position; observed min=$10.01, max=$17,264.93 | Tier 2 — data evidence |
| 6 | DateID | ETL | date of event | YYYYMMDD integer date key (e.g., 20260412) | Tier 2 — data evidence (value=20260412 for Date=2026-04-12) |
| 7 | UpdateDate | ETL pipeline | — | ETL write timestamp (next-day morning; 2026-04-13 for Date=2026-04-12) | Propagation |

## Notes

- **One row per CID**: total_rows = distinct_cids (2,899,549) — confirmed first-time milestone fact.
- **$10 threshold**: Minimum observed AggregatedCommission = $10.01, confirming the "Rev10" ($10 revenue) threshold.
- **SP code unavailable**: `SP_FirstTimeRev10` exists in BI_DB_dbo (OpsDB: Priority 0, Daily, SB_Daily) but sys.sql_modules shows empty definition and no SSDT file exists. Logic inferred from data evidence and sibling table comparison.
- **Sibling tables**: `BI_DB_FirstTimeRev5` ($5 threshold, min=$5.01) and `BI_DB_FirstTimeRev30` ($30 threshold, min=$30.00) follow identical structure.
- **UpdateDate pattern**: All rows for a given Date have the same UpdateDate (next-day 05:03:58 AM) — batch ETL run.
