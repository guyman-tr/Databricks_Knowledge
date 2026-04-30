# Lineage: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType

## Source Objects

| Source Object | Schema | Role | Wiki |
|--------------|--------|------|------|
| DWH_dbo.Dim_Position | DWH_dbo | Trading volume and value per CID (opens + closes within quarter) | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Population gate (RegulationID=9, IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3) and investor type flags | [Fact_SnapshotCustomer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md) |
| DWH_dbo.Dim_Country | DWH_dbo | EU flag and CountryID for investor type classification | [Dim_Country.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md) |
| DWH_dbo.Dim_Range | DWH_dbo | DateRangeID expansion for snapshot date filtering | [Dim_Range.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md) |
| DWH_dbo.Dim_Regulation | DWH_dbo | RegulationID=9 filter (FSA Seychelles) | [Dim_Regulation.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md) |
| BI_DB_dbo.SP_Q_AML_FSA_Report | BI_DB_dbo | Writer SP — quarterly DELETE+INSERT | SP code in SSDT |

## Column Lineage

| Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|--------------|-----------------|-----------------|-----------|------|
| Investor_Type | DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.Dim_Country | CountryID, EU | CASE: CountryID=181→'Seychelles', CountryID=219→'US', EU=1→'EU', else→'Other' | Tier 2 |
| EndDateID | SP_Q_AML_FSA_Report | @EndDateID parameter | Quarter-end date as YYYYMMDD int, computed from @Date input | Tier 2 |
| TradingVolume | DWH_dbo.Dim_Position | InitialUnits, AmountInUnitsDecimal | SUM(OpenUnits + CloseUnits) per investor segment. OpenUnits = InitialUnits for opens within quarter (excl. partial-close children). CloseUnits = AmountInUnitsDecimal for closes within quarter. | Tier 2 |
| TradingValueUSD | DWH_dbo.Dim_Position | InitialUnits, InitForexRate, InitConversionRate, AmountInUnitsDecimal, EndForexRate, EndForex_USDConversionRate | SUM(OpenValueUSD + CloseValueUSD) per investor segment. OpenValueUSD = InitialUnits * InitForexRate * InitConversionRate. CloseValueUSD = AmountInUnitsDecimal * EndForexRate * EndForex_USDConversionRate. | Tier 2 |
| UpdateDate | SP_Q_AML_FSA_Report | — | GETDATE() at SP execution time | Tier 2 |
