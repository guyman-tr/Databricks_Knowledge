# BI_DB_dbo.BI_DB_LimitedAccountsWithReasonsNEW — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough | Tier 2 |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | JOIN on DesignatedRegulationID | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationID | Tier 2 |
| PlayerStatusBlockedTime | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | MAX change date via LAG() window on PlayerStatusID | Tier 2 |
| PlayerStatusReasonBlockedTime | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | MAX change date via LAG() on PlayerStatusReasonID | Tier 2 |
| PlayerStatusSubReasonBlockedTime | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | MAX change date via LAG() on PlayerStatusSubReasonID | Tier 2 |
| PendingClosureTime | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | MAX change date via LAG() on PendingClosureStatusID | Tier 2 |
| DaysFromBlock | SP computed | PlayerStatusBlockedTime | DATEDIFF(DAY, PlayerStatusBlockedTime, GETDATE()) | Tier 2 |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on DWHPlayerStatusID | Tier 2 |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | JOIN on PlayerStatusReasonID | Tier 2 |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | JOIN on PlayerStatusSubReasonID | Tier 2 |
| PendingClosureStatus | DWH_dbo.Dim_PendingClosureStatus | PendingClosureStatusName | JOIN on PendingClosureStatusID | Tier 2 |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 2 |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities + ActualNWA, 0) | Tier 2 |
| IsHighRiskCountry | DWH_dbo.Dim_Country | IsHighRiskCountry | Passthrough | Tier 2 |
| PlayerStatusGrouping | SP computed | Multiple | Complex CASE: 'IN' if within SLA for block type, 'OUT' otherwise | Tier 2 |
| PendingClosureStatusGrouping | SP computed | Multiple | Complex CASE: 'IN' if pending closure eligible, 'OUT' otherwise | Tier 2 |
| Equity_Level | SP computed | Equity | CASE: A:0-5, B:5-50, C:50-500, D:500+ | Tier 2 |
| Region | DWH_dbo.Dim_Country | Region | JOIN via Dim_Customer.CountryID | Tier 2 |
| Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID | Tier 2 |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID | Tier 2 |
| UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn filter (12 months) | BI_DB_dbo |
| DWH_dbo.Dim_Customer | Customer profile, status IDs, demographics | DWH_dbo |
| DWH_dbo.Fact_SnapshotCustomer | Historical status changes via LAG() window | DWH_dbo |
| DWH_dbo.Dim_Range | Date range SCD for snapshot records | DWH_dbo |
| DWH_dbo.Dim_PlayerStatus | Player status name lookup | DWH_dbo |
| DWH_dbo.Dim_PlayerStatusReasons | Player status reason name lookup | DWH_dbo |
| DWH_dbo.Dim_PlayerStatusSubReasons | Player status sub-reason name lookup | DWH_dbo |
| DWH_dbo.Dim_PendingClosureStatus | Pending closure status name lookup | DWH_dbo |
| DWH_dbo.Dim_Country | Country name, region, high-risk flag | DWH_dbo |
| DWH_dbo.Dim_Regulation | Regulation name (designated + current) | DWH_dbo |
| DWH_dbo.Dim_PlayerLevel | Player level name | DWH_dbo |
| DWH_dbo.V_Liabilities | Customer equity (Liabilities + ActualNWA) | DWH_dbo |
