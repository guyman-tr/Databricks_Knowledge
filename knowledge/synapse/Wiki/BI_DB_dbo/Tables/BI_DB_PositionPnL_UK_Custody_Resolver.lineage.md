# BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary source (via #posFCA) — CID, PositionID, InstrumentID, Occurred, Date, DateID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | BI_DB_PositionPnL (via #posFCA) | CID | Passthrough (real CID, NOT anonymized) |
| PositionID | BI_DB_PositionPnL (via #posFCA) | PositionID | Passthrough (real PositionID) |
| PositionID_HashedEU | BI_DB_PositionPnL | PositionID | SHA1 hash (matches EU_Custody.PositionID_Hashed) |
| PositionID_HashedUK | BI_DB_PositionPnL | PositionID | MD5 hash (matches UK_Custody.PositionID_Hashed) |
| InstrumentID | BI_DB_PositionPnL (via #posFCA) | InstrumentID | Passthrough |
| Occurred | BI_DB_PositionPnL (via #posFCA) | Occurred | Passthrough |
| Date | BI_DB_PositionPnL (via #posFCA) | Date | Passthrough |
| DateID | BI_DB_PositionPnL (via #posFCA) | DateID | Passthrough |
| UpdateDate | — | — | GETDATE() at insert time |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL → filter stocks/ETFs + settled + CySEC → #posFCA
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- TRUNCATE + INSERT
  |-- Real CID + PositionID preserved
  |-- Both SHA1 and MD5 hashes generated
  v
BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver (20.5M rows, single day)
  |-- Generic Pipeline (Append, parquet)
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver
```
