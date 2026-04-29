# Column Lineage: BI_DB_dbo.BI_DB_ProfessionalCustomers

## Source Objects

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.External_BI_OUTPUT_Customer_ProfessionalCustomers | External Table | Professional customer application data (GCID, ApplicationDate, SelectedCriteria) from analysis lake |
| DWH_dbo.Dim_Customer | Dimension | GCID-to-RealCID resolution |
| DWH_dbo.Fact_SnapshotCustomer | Fact | MifidCategorizationID tracking for Approved/Cancelled transitions |
| DWH_dbo.Dim_Range | Dimension | DateRangeID decode (FromDateID/ToDateID) |
| DWH_dbo.Dim_Date | Dimension | DateKey-to-FullDate resolution |
| DWH_dbo.Dim_Manager | Dimension | AccountManagerID-to-name resolution (FirstName, LastName) |
| DWH_dbo.Dim_Position | Dimension | Activity check (open positions in last 2 months) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | ETL | @StartOfMonth | Computed: DATEADD(MONTH,DATEDIFF(MONTH,0,@Date),0) |
| DateID | ETL | @StartOfMonthINT | Computed: CAST(CONVERT(CHAR(8),@StartOfMonth,112) AS INT) |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (via #cc temp table from #Approved filter) |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: dm1.FirstName + ' ' + dm1.LastName |
| Desk | _NOT POPULATED_ | — | Column exists in DDL but INSERT is commented out in current SP. Historical data present but stale. |
| ActionType | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | CASE: 'Approved' when MifidCategorizationID enters (2,3); 'Cancelled' when it leaves. Only 'Approved' rows inserted (WHERE filter). |
| IsActive | DWH_dbo.Dim_Position | CID | CASE WHEN ao.[CID] IS NOT NULL THEN 1 ELSE 0 END — checks if customer has open positions in last 2 months |
| FromDate | DWH_dbo.Dim_Date | FullDate | Date when MifidCategorizationID first entered Professional (2/3) state |
| ToDate | DWH_dbo.Fact_SnapshotCustomer | — | LEAD(FullDate) OVER (PARTITION BY RealCID ORDER BY FullDate), default 9999-12-31 |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
