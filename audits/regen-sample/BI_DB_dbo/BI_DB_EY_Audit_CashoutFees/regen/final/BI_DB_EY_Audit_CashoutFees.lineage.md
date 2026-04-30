# Lineage: BI_DB_dbo.BI_DB_EY_Audit_CashoutFees

## Source Objects

| Source Object | Type | Schema | Role | Wiki Path |
|--------------|------|--------|------|-----------|
| DWH_dbo.Fact_CustomerAction | Table | DWH_dbo | Primary fact — cashout action rows (ActionTypeID=30) | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md |
| DWH_dbo.Fact_SnapshotCustomer | Table | DWH_dbo | Customer state snapshot — provides regulation, country, club, account type, guru status | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md |
| DWH_dbo.Dim_PlayerLevel | Table | DWH_dbo | Dim lookup — Club (tier name) | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerLevel.md |
| DWH_dbo.Dim_Regulation | Table | DWH_dbo | Dim lookup — Regulation name | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md |
| DWH_dbo.Dim_AccountType | Table | DWH_dbo | Dim lookup — AccountType name | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_AccountType.md |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Dim lookup — Country name | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| DWH_dbo.Dim_GuruStatus | Table | DWH_dbo | Dim lookup — PopularInvestors (GuruStatusName) | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_GuruStatus.md |
| DWH_dbo.Dim_Range | Table | DWH_dbo | Date range bridge — resolves Fact_SnapshotCustomer.DateRangeID to active date range | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| DateID | SP_EY_Audit_CashoutFees | @sdateID parameter | CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT) — date parameter converted to YYYYMMDD int | Tier 2 |
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough | Tier 1 |
| WithdrawID | DWH_dbo.Fact_CustomerAction | WithdrawID | Passthrough | Tier 1 |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | Passthrough | Tier 1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID = Dim_Regulation.DWHRegulationID | Tier 1 |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID = Dim_PlayerLevel.PlayerLevelID | Tier 1 |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID = Dim_Country.CountryID | Tier 1 |
| AccountType | DWH_dbo.Dim_AccountType | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.AccountTypeID = Dim_AccountType.AccountTypeID | Tier 1 |
| PopularInvestors | DWH_dbo.Dim_GuruStatus | GuruStatusName | Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID = Dim_GuruStatus.GuruStatusID | Tier 1 |
| Category | SP_EY_Audit_CashoutFees | (literal) | Hardcoded 'CashOut' literal | Tier 2 |
| Commission | DWH_dbo.Fact_CustomerAction | Commission | -1 * SUM(ca.Commission) — negated and aggregated per WithdrawID | Tier 2 |
| UpdateDate | SP_EY_Audit_CashoutFees | GETDATE() | ETL timestamp, no input column | Tier 2 |
