# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Q_AML_FSA_Report` — quarterly TRUNCATE+INSERT (FSA Seychelles, RegulationID=9)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Position | DWH_dbo | Primary — position open/close data (InitialUnits, AmountInUnitsDecimal, forex rates) |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata — InstrumentTypeID, IsSettled for Instrument_Type classification |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer demographics — Country via CountryID |
| DWH_dbo.Dim_Country | DWH_dbo | Dim-lookup — Country name |
| DWH_dbo.Dim_AccountType | DWH_dbo | Dim-lookup — AccountTypeGroupID for Account_Type_Group classification |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Deposit/cashout activity for Is_Active flag |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | rename (RealCID → CID) |
| Instrument_Type | DWH_dbo.Dim_Instrument | InstrumentTypeID, IsSettled | CASE: IT=5→'Stocks', IT=6→'ETFs', IT=10+settled→'Real_Crypto', IT=10+!settled→'CFD_Crypto', !settled+!crypto→'Other_CFDs', ELSE 'Other' |
| TradingVolume | DWH_dbo.Dim_Position | InitialUnits (opens), AmountInUnitsDecimal (closes) | SUM(InitialUnits for opens + AmountInUnitsDecimal for closes) during quarter |
| TradingValue | DWH_dbo.Dim_Position | InitialUnits, InitForexRate, InitConversionRate (opens); AmountInUnitsDecimal, EndForexRate, EndForex_USDConversionRate (closes) | SUM(InitialUnits*InitForexRate*InitConversionRate opens + AmountInUnitsDecimal*EndForexRate*EndForex_USDConversionRate closes) |
| Report_End_Date | (computed) | — | Quarter-end date as integer YYYYMMDD |
| UpdateDate | (computed) | — | GETDATE() — ETL execution timestamp |
| Is_Active | (computed) | — | 1 if customer had position or deposit/cashout activity during the quarter, else 0 |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup passthrough (JOIN on CountryID) |
| Account_Type_Group | DWH_dbo.Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', ELSE 'Other' |

**PHASE 10B CHECKPOINT: PASS**
