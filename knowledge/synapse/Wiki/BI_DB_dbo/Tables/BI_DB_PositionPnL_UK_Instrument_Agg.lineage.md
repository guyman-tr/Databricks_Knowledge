# BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| #posFCA (temp table from SP) | BI_DB_dbo | Primary source — CySEC stock/ETF positions aggregated by instrument (same source as EU_Custody, NOT from UK_Custody table) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Entity | — | — | Hardcoded 'UK' |
| InstrumentID | #posFCA (BI_DB_PositionPnL) | InstrumentID | GROUP BY key |
| PositionPnL | #posFCA (BI_DB_PositionPnL) | PositionPnL | SUM() |
| Amount | #posFCA (BI_DB_PositionPnL) | Amount | SUM() |
| AmountInUnitsDecimal | #posFCA (BI_DB_PositionPnL) | AmountInUnitsDecimal | SUM() |
| Date | #posFCA (BI_DB_PositionPnL) | Date | GROUP BY key |
| DateID | #posFCA (BI_DB_PositionPnL) | DateID | GROUP BY key (= @dateID) |
| NOP | #posFCA (BI_DB_PositionPnL) | NOP | SUM() |
| IsBuy | #posFCA (BI_DB_PositionPnL) | IsBuy | GROUP BY key |
| UpdateDate | — | — | GETDATE() at insert time |
| IsCreditReportValidCB | #posFCA (Fact_SnapshotCustomer) | IsCreditReportValidCB | GROUP BY key |
| IsValidCustomer | #posFCA (Fact_SnapshotCustomer) | IsValidCustomer | GROUP BY key |
| HedgeServerID | #posFCA (BI_DB_PositionPnL) | HedgeServerID | GROUP BY key |

## ETL Pipeline

```
#posFCA (CySEC stock/ETF positions, same source as EU_Custody)
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- DELETE WHERE DateID = @dateID, then INSERT
  |-- GROUP BY InstrumentID, Date, DateID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID
  |-- SUM(PositionPnL, Amount, AmountInUnitsDecimal, NOP), Entity='UK', UpdateDate=GETDATE()
  v
BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg (8.66M rows, accumulating)
  |-- No UC mapping found
```
