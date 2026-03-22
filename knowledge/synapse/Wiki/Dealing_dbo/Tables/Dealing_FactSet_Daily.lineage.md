# Lineage: Dealing_dbo.Dealing_FactSet_Daily

## Source Tables
| Source | Role |
|--------|------|
| Dealing_dbo.Dealing_FactSet_Management | Active PI/CP list (IsActive=1 AND DailyLastSentDate<@Date) |
| DWH_dbo.Fact_SnapshotCustomer | CID customer snapshot (GuruStatusID, equity, CID status) |
| DWH_dbo.Dim_GuruStatus | CopyType derivation |
| DWH_dbo.V_Liabilities | CashBalance |
| BI_DB_dbo.BI_DB_CopyDailyData | AUM per PI/CP |
| BI_DB_dbo.BI_DB_PositionPnL | Open position portfolio (InstrumentID, Units, Price, Direction, Leverage, ISIN) |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Price per instrument/date |
| DWH_dbo.Dim_Instrument | InstrumentName, InstrumentType, ISIN, Currency |
| BI_DB_dbo.DWH_GainDaily | RETURN_D (daily return percentage) |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Generated | @Date parameter |
| CopyType | Dim_GuruStatus | 'PI' or 'CP' based on GuruStatusID |
| Username | Fact_SnapshotCustomer | Customer username |
| Tier | Fact_SnapshotCustomer | Customer tier/level |
| LastNightRiskScore | Fact_SnapshotCustomer | Most recent risk score |
| AUM | BI_DB_CopyDailyData | Assets under management |
| CashBalance | V_Liabilities | Cash balance in portfolio |
| InstrumentID | BI_DB_PositionPnL.InstrumentID | Open position instrument |
| InstrumentName | Dim_Instrument.InstrumentName | Instrument display name |
| InstrumentType | Dim_Instrument.InstrumentType | Asset class |
| ISIN | Dim_Instrument.ISIN | International securities identifier |
| Units | BI_DB_PositionPnL.Units | Position units held |
| Price | Fact_CurrencyPriceWithSplit | EOD instrument price |
| Direction | Derived | 'Buy' or 'Sell' from IsBuy flag |
| Leverage | BI_DB_PositionPnL.Leverage | Position leverage |
| UpdateDate | Generated | `GETDATE()` |
| CID | Fact_SnapshotCustomer.CID | Customer identifier |
| Currency | Dim_Instrument.Currency | Instrument currency |
| RETURN_D | DWH_GainDaily.Gain_d | Daily portfolio return percentage |

## Special Rows
- "Not a PI anymore" rows inserted for PIs whose GuruStatusID dropped to <2 on @Date−1 (deregistration notification)

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_FactSet_Daily/ |
| Notes | STALE — last data 2024-06-04. SP uses TRUNCATE instead of DELETE-INSERT. |
