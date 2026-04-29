# Lineage — BI_DB_dbo.BI_DB_Deposit_checking_temp_table

## Source Objects

| Source Object | Schema | Type | Role |
|---|---|---|---|
| `SP_Client_Balance_Check_Opening_Balance` | BI_DB_dbo | Stored Procedure | Writer — DELETE + INSERT pattern, runs from SP_Client_Balance_New |
| `BI_DB_Client_Balance_Aggregate_Level_New` | BI_DB_dbo | Table | Source of `Deposits` and `InternalTransferDeposits` columns used to compute `Deposits_CB` |
| `Fact_CustomerAction` | DWH_dbo | Table | Source of `Amount` (ActionTypeID=7) used to compute `Deposits_FCA` |

## Column Lineage

| # | Column | Tier | Source Object | Source Column / Transform | Notes |
|---|---|---|---|---|---|
| 1 | Deposits_FCA | Tier 2 | DWH_dbo.Fact_CustomerAction | `SUM(ISNULL(Amount, 0)) WHERE ActionTypeID = 7 AND DateID = @dateID` | Total deposit amount for the check date from the fact table |
| 2 | Deposits_CB | Tier 2 | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | `SUM(ISNULL(Deposits, 0)) - SUM(ISNULL(InternalTransferDeposits, 0)) WHERE DateID = @dateID` | Net deposits per Client Balance aggregate, excluding internal transfers |
| 3 | Balance_diff_deposit | Tier 2 | Computed | `@v_Deposits_FCA - @v_Deposits_CB` | Difference between FCA deposits and CB deposits; 0 = no discrepancy |
| 4 | Error_Message | Tier 2 | SP_Client_Balance_Check_Opening_Balance | Constructed string if `Balance_diff_deposit <> 0`, else NULL/empty | ETL-generated diagnostic message; empty string when check passes |
| 5 | UpdateDate | Tier 2 | SP_Client_Balance_Check_Opening_Balance | `GETDATE()` at INSERT time | Timestamp of last SP execution |
