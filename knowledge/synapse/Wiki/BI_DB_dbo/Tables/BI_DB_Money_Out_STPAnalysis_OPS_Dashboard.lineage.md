# BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard — Column Lineage

## Writer SP

`BI_DB_dbo.SP_H_Money_Out_STPAnalysis_OPS_Dashboard` (@Date DATE)

## Load Pattern

DELETE+INSERT (daily window replace on ModificationDate between @PrevDate and @CurDate) + 7-month rolling purge.

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | BI_DB_dbo.External_etoro_Billing_Withdraw | BW | Primary — withdrawal requests (CashoutStatusID=3 = Processed) |
| 2 | BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding | wtf | Payment leg — amount, modification date, cashout mode, execution method, funding |
| 3 | DWH_dbo.Dim_CashoutMode | CM | Lookup — CashoutModeName for Preparation |
| 4 | BI_DB_dbo.External_etoro_Dictionary_ExecuteEntryMethod | e | Lookup — DisplayName for ExecutionApproval |
| 5 | BI_DB_dbo.External_etoro_Billing_Funding_Datafactory | bf | Bridge — FundingID to FundingTypeID |
| 6 | DWH_dbo.Dim_FundingType | ft | Lookup — Name for FundingType_Sent |
| 7 | BI_DB_dbo.External_etoro_BackOffice_WithdrawApproval | R | Approval flags — per-group manual approval detection |
| 8 | DWH_dbo.Dim_Customer | dc | Dead code — used in #FINAL but INSERT reads from #billing |
| 9 | DWH_dbo.Dim_PlayerLevel | dpl | Dead code — same |
| 10 | DWH_dbo.Dim_Regulation | dr | Dead code — same |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | WithdrawID | Billing.Withdraw | WithdrawID | Passthrough (via External_etoro_Billing_Withdraw) |
| 2 | CID | Billing.Withdraw | CID | Passthrough (via External_etoro_Billing_Withdraw) |
| 3 | RequestDate | Billing.Withdraw | RequestDate | Passthrough (via External_etoro_Billing_Withdraw) |
| 4 | Amount$Withdraw | Billing.WithdrawToFunding | Amount | Rename: Amount → Amount$Withdraw. Passthrough value. |
| 5 | ModificationDate | Billing.WithdrawToFunding | ModificationDate | Passthrough (via External_etoro_Billing_vWithdrawToFunding) |
| 6 | ExecutionApproval | Dictionary.ExecuteEntryMethod | DisplayName | JOIN on wtf.RequestExecuteEntryMethodId = e.ExecuteEntryMethodID |
| 7 | AutoApproval | BackOffice.WithdrawApproval | Comment | CASE: if Comment IN ('Auto Approval','Cleared - Auto Approval') then Comment ELSE 'Manual'. Re-derived in #FINAL as CASE on #MANUALAPPROVAL presence. |
| 8 | Preparation | Dim_CashoutMode | CashoutModeName | JOIN on wtf.CashoutModeID = CM.CashoutModeID |
| 9 | UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
| 10 | WithdrawPaymentID | Billing.WithdrawToFunding | ID | Rename: ID → WithdrawPaymentID. Passthrough. |
| 11 | FundingType_Sent | Dim_FundingType | Name | JOIN chain: wtf → bf (FundingID) → Dim_FundingType (FundingTypeID) → Name |
| 12 | OPSApproved | BackOffice.WithdrawApproval | UserGroupID, Approved, Comment | MAX(CASE WHEN UserGroupID=2 AND Approved=1 AND Comment NOT IN auto → 1 ELSE 0) |
| 13 | RiskApproved | BackOffice.WithdrawApproval | UserGroupID, Approved, Comment | MAX(CASE WHEN UserGroupID=3 AND Approved=1 AND Comment NOT IN auto → 1 ELSE 0) |
| 14 | TradingApproved | BackOffice.WithdrawApproval | UserGroupID, Approved, Comment | MAX(CASE WHEN UserGroupID=6 AND Approved=1 AND Comment NOT IN auto → 1 ELSE 0) |
| 15 | AMLApproved | BackOffice.WithdrawApproval | UserGroupID, Approved, Comment | MAX(CASE WHEN UserGroupID=36 AND Approved=1 AND Comment NOT IN auto → 1 ELSE 0) |
| 16 | AmdinistratorsApproved | BackOffice.WithdrawApproval | UserGroupID, Approved, Comment | MAX(CASE WHEN UserGroupID=1 AND Approved=1 AND Comment NOT IN auto → 1 ELSE 0) |

## Production Source Chain

```
etoro.Billing.Withdraw (CashoutStatusID=3, production)
etoro.Billing.vWithdrawToFunding (view over Billing.WithdrawToFunding, production)
etoro.BackOffice.WithdrawApproval (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
BI_DB_dbo.External_etoro_Billing_Withdraw (External table)
BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding (External table)
BI_DB_dbo.External_etoro_BackOffice_WithdrawApproval (External table)
  + DWH_dbo.Dim_CashoutMode, Dim_FundingType (Synapse dims)
  |-- SP_H_Money_Out_STPAnalysis_OPS_Dashboard @Date ---|
  v
BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard (4.17M rows)
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard
```
