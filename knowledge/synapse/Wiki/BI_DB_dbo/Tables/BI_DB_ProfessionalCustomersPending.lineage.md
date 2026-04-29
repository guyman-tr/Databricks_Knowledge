# Column Lineage: BI_DB_dbo.BI_DB_ProfessionalCustomersPending

## Source Objects

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.External_BI_OUTPUT_Customer_ProfessionalCustomers | External Table | Professional customer applications (GCID, ApplicationDate, SelectedCriteria) from analysis lake |
| DWH_dbo.Dim_Customer | Dimension | GCID-to-RealCID resolution for application CIDs |
| DWH_dbo.Fact_SnapshotCustomer | Fact | Current customer state: MifidCategorizationID IN (4,5) = pending professional |
| DWH_dbo.Dim_Range | Dimension | DateRangeID decode for current-state filtering |
| DWH_dbo.Dim_Country | Dimension | CountryID-to-Name resolution |
| DWH_dbo.Dim_PlayerLevel | Dimension | PlayerLevelID-to-Name resolution (ClubTier) |
| DWH_dbo.Dim_Manager | Dimension | AccountManagerID-to-name resolution |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | ETL | @StartOfMonth | Computed: DATEADD(MONTH,DATEDIFF(MONTH,0,@Date),0) |
| DateID | ETL | @StartOfMonthINT | Computed: CAST(CONVERT(CHAR(8),@StartOfMonth,112) AS INT) |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (filtered MifidCategorizationID IN (4,5)) |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Name | Dim lookup passthrough |
| Desk | DWH_dbo.Dim_Country | — | NOT POPULATED by current SP (INSERT column commented out). See BI_DB_ProfessionalCustomers for same issue. |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: dm1.FirstName + ' ' + dm1.LastName |
| Country | DWH_dbo.Dim_Country | Name | Dim lookup passthrough via Fact_SnapshotCustomer.CountryID |
| DaysSinceApplication | ETL + External source | ApplicationDate | DATEDIFF(DAY, ApplicationDate, @Date) |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
