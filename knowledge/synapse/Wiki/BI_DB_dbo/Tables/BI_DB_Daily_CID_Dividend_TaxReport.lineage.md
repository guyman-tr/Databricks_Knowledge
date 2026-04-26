# BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport — Column Lineage

## Writer SP

`BI_DB_dbo.SP_Daily_CID_Dividend_TaxReport` (Priority 0, Daily, SB_Daily)

## Source Objects

| Source Object | Role |
|--------------|------|
| BI_DB_dbo.BI_DB_DailyDividendsByPosition | Position-level dividend data (DateID=@DateID) |
| DWH_dbo.Dim_Instrument | Instrument details (InstrumentDisplayName, ISINCode) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | BI_DB_DailyDividendsByPosition | RealCID | Passthrough (GROUP BY) |
| DividendID | BI_DB_DailyDividendsByPosition | DividendID | Passthrough (GROUP BY) |
| PaymentDate | BI_DB_DailyDividendsByPosition | Date | Passthrough (GROUP BY) |
| Regulation | BI_DB_DailyDividendsByPosition | Regulation | Passthrough (GROUP BY) |
| PositionID | BI_DB_DailyDividendsByPosition | PositionID | Passthrough (GROUP BY) |
| PositionType | BI_DB_DailyDividendsByPosition | PositionType | Passthrough (GROUP BY) |
| IsSettled | BI_DB_DailyDividendsByPosition | IsSettled | Passthrough (GROUP BY) |
| InstrumentID | BI_DB_DailyDividendsByPosition | InstrumentID | Passthrough (GROUP BY) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough via InstrumentID JOIN |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough via InstrumentID JOIN |
| TaxCode | BI_DB_DailyDividendsByPosition | TaxCode | Passthrough (GROUP BY) |
| BuyTax | BI_DB_DailyDividendsByPosition | BuyTax | Passthrough (GROUP BY) |
| TotalDividendPaid | BI_DB_DailyDividendsByPosition | Amount | SUM(Amount) — aggregated dividend payment |
| IsValidCustomer | BI_DB_DailyDividendsByPosition | IsValidCustomer | Passthrough (GROUP BY) |
| UpdateDate | — | — | ETL metadata: GETDATE() |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.
