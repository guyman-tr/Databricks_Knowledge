# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary source — daily open position P&L snapshot (filtered to stocks/ETFs, settled, CySEC) |
| Dim_Instrument | DWH_dbo | JOIN filter — InstrumentTypeID IN (5,6) for stocks/ETFs |
| Fact_SnapshotCustomer | DWH_dbo | JOIN — IsCreditReportValidCB, IsValidCustomer for CySEC customers |
| Dim_Range | DWH_dbo | JOIN — DateRangeID resolution for Fact_SnapshotCustomer point-in-time lookup |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | — | — | Hardcoded to 999999999 (anonymized) |
| PositionID_Hashed | BI_DB_PositionPnL | PositionID | SHA1 hash: CONVERT(NVARCHAR(40), HASHBYTES('SHA1', CONVERT(NVARCHAR(MAX), PositionID)), 2) |
| InstrumentID | BI_DB_PositionPnL | InstrumentID | Passthrough |
| MirrorID | BI_DB_PositionPnL | MirrorID | Passthrough |
| Commission | BI_DB_PositionPnL | Commission | Passthrough |
| InitForexRate | BI_DB_PositionPnL | InitForexRate | Passthrough |
| SpreadedPipBid | BI_DB_PositionPnL | SpreadedPipBid | Passthrough |
| SpreadedPipAsk | BI_DB_PositionPnL | SpreadedPipAsk | Passthrough |
| PositionPnL | BI_DB_PositionPnL | PositionPnL | Passthrough |
| Price | BI_DB_PositionPnL | Price | Passthrough |
| HedgeServerID | BI_DB_PositionPnL | HedgeServerID | Passthrough |
| Amount | BI_DB_PositionPnL | Amount | Passthrough |
| AmountInUnitsDecimal | BI_DB_PositionPnL | AmountInUnitsDecimal | Passthrough |
| LimitRate | BI_DB_PositionPnL | LimitRate | Passthrough |
| StopRate | BI_DB_PositionPnL | StopRate | Passthrough |
| IsBuy | BI_DB_PositionPnL | IsBuy | Passthrough |
| Occurred | BI_DB_PositionPnL | Occurred | Passthrough |
| Date | BI_DB_PositionPnL | Date | Passthrough |
| DateID | BI_DB_PositionPnL | DateID | Passthrough |
| UpdateDate | BI_DB_PositionPnL | UpdateDate | Passthrough |
| IsSettled | BI_DB_PositionPnL | IsSettled | Passthrough (always 1 due to filter) |
| NOP | BI_DB_PositionPnL | NOP | Passthrough |
| DailyPnL | BI_DB_PositionPnL | DailyPnL | Passthrough |
| Leverage | BI_DB_PositionPnL | Leverage | Passthrough |
| RateBid | BI_DB_PositionPnL | RateBid | Passthrough |
| RateAsk | BI_DB_PositionPnL | RateAsk | Passthrough |
| USD_CR | BI_DB_PositionPnL | USD_CR | Passthrough |
| SettlementTypeID | BI_DB_PositionPnL | SettlementTypeID | Passthrough |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough via JOIN on RealCID = CID, RegulationID = 2 |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough via JOIN on RealCID = CID, RegulationID = 2 |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (20M+ open positions per day)
  |-- Filter: InstrumentTypeID IN (5,6) AND IsSettled = 1
  |-- JOIN DWH_dbo.Dim_Instrument ON InstrumentID
  v
#pos (stocks/ETFs only, settled)
  |-- JOIN DWH_dbo.Fact_SnapshotCustomer (via Dim_Range, RegulationID = 2 = CySEC)
  v
#posFCA (CySEC stock/ETF positions with credit/validity flags)
  |-- TRUNCATE + INSERT, CID → 999999999, PositionID → SHA1
  v
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody (20.5M rows, single day)
  |-- Generic Pipeline (Append, delta, daily)
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody
```
