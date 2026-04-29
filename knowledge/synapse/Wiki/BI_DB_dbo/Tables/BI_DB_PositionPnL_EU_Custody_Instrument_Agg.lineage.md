# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| BI_DB_PositionPnL_EU_Custody | BI_DB_dbo | Primary source — aggregated by instrument from the EU custody snapshot |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Entity | — | — | Hardcoded 'EU' |
| InstrumentID | BI_DB_PositionPnL_EU_Custody | InstrumentID | GROUP BY key |
| PositionPnL | BI_DB_PositionPnL_EU_Custody | PositionPnL | SUM() |
| Amount | BI_DB_PositionPnL_EU_Custody | Amount | SUM() |
| AmountInUnitsDecimal | BI_DB_PositionPnL_EU_Custody | AmountInUnitsDecimal | SUM() |
| Date | BI_DB_PositionPnL_EU_Custody | Date | GROUP BY key |
| DateID | BI_DB_PositionPnL_EU_Custody | DateID | GROUP BY key (= @dateID) |
| NOP | BI_DB_PositionPnL_EU_Custody | NOP | SUM() |
| IsBuy | BI_DB_PositionPnL_EU_Custody | IsBuy | GROUP BY key |
| UpdateDate | — | — | GETDATE() at insert time |
| IsCreditReportValidCB | BI_DB_PositionPnL_EU_Custody | IsCreditReportValidCB | GROUP BY key |
| IsValidCustomer | BI_DB_PositionPnL_EU_Custody | IsValidCustomer | GROUP BY key |
| HedgeServerID | BI_DB_PositionPnL_EU_Custody | HedgeServerID | GROUP BY key |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody (20.5M rows, single day)
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- DELETE WHERE DateID = @dateID, then INSERT
  |-- GROUP BY InstrumentID, Date, DateID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID
  |-- SUM(PositionPnL, Amount, AmountInUnitsDecimal, NOP)
  v
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg (8.66M rows, accumulating)
  |-- No UC mapping found
```
