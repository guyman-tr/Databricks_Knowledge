# BI_DB_dbo.BI_DB_FSRA_Weekly_Report — Column Lineage

## Writer SP
`BI_DB_dbo.SP_W_Wed_BI_DB_FSRA_Weekly_Report`

## Source Tables
| Source Table | Schema | Join/Usage |
|---|---|---|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Population base — FSRA valid customers |
| DWH_dbo.Dim_Range | DWH_dbo | SCD date range resolution |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name (RegulationID=11 → FSRA) |
| DWH_dbo.Dim_Country | DWH_dbo | Country name from CountryID |
| DWH_dbo.Dim_AccountType | DWH_dbo | Account type filter |
| DWH_dbo.Dim_MifidCategorization | DWH_dbo | Client classification (Retail/Retail Pending/Pending) |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | VerificationLevel2Date for IsNewV2Customer flag |
| DWH_dbo.Dim_Position | DWH_dbo | Closed and opened positions during period |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument type, name, display name |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Current open positions (Amount + PositionPnL) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| StartDate | — | — | ETL-computed: DATEADD(DAY, -6, @Date) — start of 7-day reporting window |
| StartDateID | — | — | ETL-computed: YYYYMMDD int of StartDate |
| EndDate | — | — | ETL-computed: @Date parameter value |
| EndDateID | — | — | ETL-computed: YYYYMMDD int of EndDate |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough — FSRA valid customers only |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough (always 'FSRA' per RegulationID=11 filter) |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via Fact_SnapshotCustomer.CountryID |
| Client_Classification | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via Fact_SnapshotCustomer.MifidCategorizationID |
| VerificationLevelID | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | Passthrough |
| VerificationLevel2Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | ISNULL(..., '1900-01-01') — sentinel for never-verified |
| IsNewV2Customer | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | ETL-computed: CASE WHEN VL2Date BETWEEN StartDate AND EndDate THEN 1 ELSE 0 |
| PositionID | DWH_dbo.Dim_Position / BI_DB_PositionPnL | PositionID | Passthrough from UNION of closed/opened/current-open positions; NULL for customers with no positions |
| WasClosedDuringPeriod | DWH_dbo.Dim_Position | CloseDateID | ETL-computed: 1 if position closed during StartDateID–EndDateID, else 0; NULL for no-position rows |
| WasOpenedDuringPeriod | DWH_dbo.Dim_Position | OpenDateID | ETL-computed: 1 if position opened during StartDateID–EndDateID (excludes partial close children), else 0; NULL for no-position rows |
| IsCurrentOpen | BI_DB_dbo.BI_DB_PositionPnL | DateID | ETL-computed: 1 if position is in PositionPnL on EndDateID (currently open), else 0; NULL for no-position rows |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough — text label (Stocks, Crypto Currencies, ETF, etc.) |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough — internal instrument name |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough — user-facing display name |
| Amount | DWH_dbo.Dim_Position / BI_DB_PositionPnL | Amount, NetProfit, InitialAmountCents, PositionPnL | Source-dependent: closed=Amount+NetProfit, opened=InitialAmountCents/100, current-open=Amount+PositionPnL |
| UpdateDate | — | — | ETL metadata: GETDATE() |
