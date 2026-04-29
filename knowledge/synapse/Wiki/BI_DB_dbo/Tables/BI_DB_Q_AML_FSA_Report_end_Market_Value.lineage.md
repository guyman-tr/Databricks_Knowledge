# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Q_AML_FSA_Report` — quarterly TRUNCATE+INSERT (FSA Seychelles, RegulationID=9)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Primary — open position values (AmountInUnitsDecimal, RateBid, USD_CR) |
| DWH_dbo.Dim_AccountType | DWH_dbo | Dim-lookup — AccountTypeGroupID for Account_Type_Group classification |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata — InstrumentTypeID, IsSettled for Instrument_Type classification |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Market_Value | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal, RateBid, USD_CR | SUM(AmountInUnitsDecimal * RateBid * USD_CR) for open positions |
| Account_Type_Group | DWH_dbo.Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', ELSE 'Other' |
| End_DateID | (computed) | — | Quarter-end date as integer YYYYMMDD |
| UpdateDate | (computed) | — | GETDATE() — ETL execution timestamp |
| Instrument_Type | DWH_dbo.Dim_Instrument | InstrumentTypeID, IsSettled | CASE: IT=5→'Stocks', IT=6→'ETFs', IT=10+settled→'Real_Crypto', IT=10+!settled→'CFD_Crypto', !settled+!crypto→'Other_CFDs', ELSE 'Other' |

**PHASE 10B CHECKPOINT: PASS**
