# BI_DB_dbo.BI_DB_STP_Redeems — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| External_etoro_Billing_Redeem | BI_DB_dbo | Primary — redeem requests (RedeemID, CID, AmountOnRequest, LastModificationDate, Units) |
| Dim_RedeemStatus | DWH_dbo | Lookup — RedeemStatusID → DisplayName |
| External_etoro_BackOffice_RedeemApproval | BI_DB_dbo | Join — approval records per UserGroupID (OPS, Risk, Trading, AML, Admin) |
| External_etoro_Billing_vWithdrawToFunding | BI_DB_dbo | Join — execution approval: ManagerID=0 AND CashoutStatusID=3 → Auto |
| Dim_Manager | DWH_dbo | Lookup — ManagerID → FirstName + LastName |
| Dim_Customer | DWH_dbo | Lookup — CID → PlayerLevelID, RegulationID |
| Dim_PlayerLevel | DWH_dbo | Lookup — PlayerLevelID → Name |
| Dim_Regulation | DWH_dbo | Lookup — ID → Name |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RedeemID | External_etoro_Billing_Redeem | RedeemID | Passthrough |
| CID | External_etoro_Billing_Redeem | CID | Passthrough |
| AmountOnRequest | External_etoro_Billing_Redeem | AmountOnRequest | Passthrough |
| LastModificationDate | External_etoro_Billing_Redeem | LastModificationDate | Passthrough |
| RedeemStatus | DWH_dbo.Dim_RedeemStatus | DisplayName | Dim-lookup via RedeemStatusID |
| OPSApproved | External_etoro_BackOffice_RedeemApproval | UserGroupID, Approved | MAX(CASE WHEN UserGroupID=2 AND Approved=1 AND Comment NOT IN ('Auto Approval')) |
| RiskApproved | External_etoro_BackOffice_RedeemApproval | UserGroupID, Approved | MAX(CASE WHEN UserGroupID=3 AND Approved=1 ...) |
| TradingApproved | External_etoro_BackOffice_RedeemApproval | UserGroupID, Approved | MAX(CASE WHEN UserGroupID=6 AND Approved=1 ...) |
| AMLApproved | External_etoro_BackOffice_RedeemApproval | UserGroupID, Approved | MAX(CASE WHEN UserGroupID=36 AND Approved=1 ...) |
| AmdinistratorsApproved | External_etoro_BackOffice_RedeemApproval | UserGroupID, Approved | MAX(CASE WHEN UserGroupID=1 AND Approved=1 ...) |
| Approval | External_etoro_BackOffice_RedeemApproval | Comment | CASE: 'Auto Approval' or 'Cleared - Auto Approval' → comment text, else 'Manually Approved' |
| ExecutionApproval | External_etoro_Billing_vWithdrawToFunding | ManagerID, CashoutStatusID | CASE: ManagerID=0 AND CashoutStatusID=3 → 'Auto', else 'Manual' |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup via Dim_Customer.PlayerLevelID |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via Dim_Customer.RegulationID |
| Units | External_etoro_Billing_Redeem | Units | Passthrough (coin units for crypto redeems) |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation via RedeemApproval.ManagerID |

## ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_Redeem (RedeemStatusID=8 = TransactionDone)
  + DWH_dbo.Dim_RedeemStatus (DisplayName)
  + BI_DB_dbo.External_etoro_BackOffice_RedeemApproval (approval flags per UserGroup)
  + BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding (execution approval)
  + DWH_dbo.Dim_Manager (approver name)
  |-- #DATA: per redeem with approval flags ---|
  |-- #MANUALAPPROVAL: redeems with manual approval ---|
  + DWH_dbo.Dim_Customer (PlayerLevelID, RegulationID)
  + DWH_dbo.Dim_PlayerLevel (Name)
  + DWH_dbo.Dim_Regulation (Name)
  |-- #FINAL: enriched with PlayerLevel, Regulation, consolidated Approval ---|
  |  DELETE by LastModificationDate range + INSERT
  v
BI_DB_dbo.BI_DB_STP_Redeems (335K rows, 2023-08-28 to present)
```
