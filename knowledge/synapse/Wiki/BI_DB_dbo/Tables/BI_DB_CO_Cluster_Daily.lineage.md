# BI_DB_dbo.BI_DB_CO_Cluster_Daily — Lineage

## ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=8 cashouts — scope: GCIDs with CO on @Date, all historical COs)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer, PlayerLevelID, GCID → RealCID)
  + DWH_dbo.Dim_Range (date range filter: @DateID BETWEEN FromDateID AND ToDateID)
  + DWH_dbo.Dim_Customer (FirstDepositDate for Seniority_in_Days, IsDepositor filter)
  + DWH_dbo.V_Liabilities (RealizedEquity at last CO date: DateID = Last_Transaction_ID)
  -> SP_BI_DB_CO_Cluster_Daily (no @date parameter — self-determines from MAX(Report_Date))
     [WHILE loop from MAX(Report_Date)+1 to GETDATE()-1]
     [DELETE WHERE Report_Date_ID = @DateID + INSERT per date]
  -> BI_DB_dbo.BI_DB_CO_Cluster_Daily
```

**Orchestration**: OpsDB ProcessName=SB_Daily, Priority=0, Frequency=Daily.
**Table start**: 2024-01-01 (hardcoded fallback if table is empty: `ISNULL(MAX(Report_Date), '2024-01-01')`).

## Source → Target Column Mapping

| Target Column | Source Object | Source Column / Expression | Tier |
|--------------|---------------|----------------------------|------|
| Report_Date | Computed | @Date (current loop date) | T2 |
| Report_Date_ID | Computed | @DateID = CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) | T2 |
| CID | DWH_dbo.Fact_CustomerAction | RealCID (of cashout customers who cashed out on @Date) | T2 |
| CO_Cluster | Computed | CASE WHEN rules based on RealizedEquity, Cashouts, Seniority_in_Days, Prev_CO_Date gap | T2 |
| CO_First_Transaction | DWH_dbo.Fact_CustomerAction | MIN(Occurred AS DATE) WHERE ActionTypeID=8 (first-ever CO) | T2 |
| CO_Last_Transaction | DWH_dbo.Fact_CustomerAction | MAX(Occurred AS DATE) WHERE ActionTypeID=8 (most recent CO, = @Date for daily row) | T2 |
| Prev_CO_Date | DWH_dbo.Fact_CustomerAction | MAX(Occurred) WHERE rn=2 in ROW_NUMBER OVER CID ORDER BY Occurred DESC — second-most-recent CO | T2 |
| Seniority_in_Days | Computed | DATEDIFF(DAY, Dim_Customer.FirstDepositDate, Last_CO_Transaction) | T2 |
| RealizedEquity_CO | DWH_dbo.V_Liabilities | RealizedEquity WHERE DateID = Last_Transaction_ID (equity at last CO); CASE WHEN < 0 THEN 0 | T2 |
| ACC_CO_AmountUSD | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8 (accumulated total cashout amount ever) | T2 |
| ACC_Cashouts | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=8 (total cashout transaction count ever) | T2 |
| Current_Day_CO_Amount | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8 AND Occurred=@Date (today's CO amount) | T2 |
| UpdateDate | Computed | GETDATE() | T2 |

## Cluster Classification Rules

| Cluster | Condition | Priority |
|---------|-----------|----------|
| Null_Equity | RealizedEquity IS NULL | 1 (highest) |
| Churn_CO | RealizedEquity < 10 | 2 |
| OTC | CO_First = CO_Last AND RealizedEquity >= 10 | 3 (one cashout ever) |
| Regular_CO | Equity >= 10 AND ((ACC_Cashouts >= 5 AND gap from Prev_CO to Last_CO <= 360 days) OR (Seniority <= 360 days AND ACC_Cashouts >= 3)) | 4 |
| Occasional_CO | Equity >= 10 AND ((ACC_Cashouts >= 5 AND gap > 360 days) OR (Seniority > 360 days AND cashouts 2-4) OR (Seniority <= 360 days AND cashouts = 2)) | 5 |
| Uncategorized | None of above | 6 (fallback) |

## Population Note

Only customers who made a cashout (ActionTypeID=8, not a redeem, not an airdrop) on @Date appear in the daily output. Customers without a cashout that day have no row for that Report_Date.
