# BI_DB_dbo.BI_DB_US_Popular_Investor — Column Lineage

## Writer SP
`BI_DB_dbo.SP_US_Popular_Investor` — TRUNCATE+INSERT (no @Date parameter — uses yesterday internally)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | RealCID, UserName, HasAvatar, CountryID=219, IsValidCustomer, IsDepositor |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | FirstPosOpenDate, VL3Date (qualification gates) |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | BI_DB_dbo | Active flag — must be active ALL 35 of last 35 days |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Position open/close counts (ActionTypeID IN 1,2,3,4,5,6,28) |
| DWH_dbo.V_Liabilities | DWH_dbo | StandardDeviation (risk score), Liabilities + ActualNWA (equity) |
| BI_DB_dbo.BI_DB_First5Actions | BI_DB_dbo | FirstActionDate (for DaysOfTrading calculation) |
| BI_DB_dbo.BI_DB_CopyDailyData | BI_DB_dbo | CopyAUM, NumOfCopiers |
| External_etoro_Customer_BlockedCustomerOperations | External | Copy block status (OperationTypeID=2) |
| External_UserApiDB_dbo_Publications | External | AboutMe text length |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough |
| DaysOfTrading | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | DATEDIFF(DAY, FirstActionDate, GETDATE()) |
| Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | Liabilities + ActualNWA (must be >= 100) |
| PositionsOpenedClosedLast30Days | DWH_dbo.Fact_CustomerAction | PositionID | COUNT where ActionTypeID IN (1,2,3,4,5,6,28), last 30 days |
| MaxRiskScorePast2Months | DWH_dbo.V_Liabilities | StandardDeviation | MAX of SD-to-score mapping (1-10 scale) over 2 months |
| Is_Copy_Blocked | External_etoro_Customer_BlockedCustomerOperations | OperationTypeID | 1 if OperationTypeID=2 exists, else 0 |
| UpdateDate | (computed) | — | GETDATE() |
| HasAvatar | DWH_dbo.Dim_Customer | HasAvatar | ISNULL conversion |
| CopyAUM | BI_DB_dbo.BI_DB_CopyDailyData | CopyAUM | ISNULL to 0 |
| NumOfCopiers | BI_DB_dbo.BI_DB_CopyDailyData | NumOfCopiers | ISNULL to 0 |
| Number_of_characters_AboutMe | External_UserApiDB_dbo_Publications | AboutMe | LEN(AboutMe) |
| AllowDisplayFullName | — | — | Not populated by SP (always NULL) |

**PHASE 10B CHECKPOINT: PASS**
