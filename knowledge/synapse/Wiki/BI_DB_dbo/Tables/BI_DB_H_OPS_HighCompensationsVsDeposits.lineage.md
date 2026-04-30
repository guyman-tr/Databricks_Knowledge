# Lineage: BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits

## Source Objects

| Source Object | Schema | Type | Relationship | Wiki |
|--------------|--------|------|-------------|------|
| SP_H_OPS_HighCompensationsVsDeposits | BI_DB_dbo | Stored Procedure | Writer SP (TRUNCATE+INSERT) | — |
| External_etoro_Billing_Deposit | BI_DB_dbo | External Table | Deposit transactions (approved, last 31 days) | — |
| External_etoro_Billing_Funding_Datafactory | BI_DB_dbo | External Table | Funding type filter for 24hr deposit detection | — |
| External_etoro_history_credit_Pavlina | BI_DB_dbo | External Table | Compensation credit history (created by SP_Create_External_etoro_history_credit) | — |
| Dim_Customer | DWH_dbo | Table | Customer attributes + IsValidCustomer filter | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| Dim_PlayerStatus | DWH_dbo | Table | Player status name lookup via Dim_Customer.PlayerStatusID | [Dim_PlayerStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md) |
| Dim_PlayerStatusReasons | DWH_dbo | Table | Player status reason name lookup via Dim_Customer.PlayerStatusReasonID | [Dim_PlayerStatusReasons.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatusReasons.md) |
| Dim_PlayerStatusSubReasons | DWH_dbo | Table | Player status sub-reason name lookup via Dim_Customer.PlayerStatusSubReasonID | [Dim_PlayerStatusSubReasons.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatusSubReasons.md) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|--------------|-----------|------|
| RealCID | External_etoro_Billing_Deposit | CID | Rename CID → RealCID; filtered to approved depositors in last 31 days | Tier 1 |
| CompensationAmount | External_etoro_history_credit_Pavlina | Payment | SUM(Payment) where CreditTypeID=6 AND CompensationReasonID=7 AND Payment<0, HAVING COUNT>3 AND SUM<-2000; negated to positive | Tier 2 |
| #ofDeposits | External_etoro_Billing_Deposit | DepositID | COUNT(DepositID) for approved deposits, grouped by CID, HAVING SUM(Amount*ExchangeRate)>0 | Tier 2 |
| DepositAmount$ | External_etoro_Billing_Deposit | Amount, ExchangeRate | SUM(Amount * ExchangeRate) for approved deposits | Tier 2 |
| Compensation$/Deposits$ | External_etoro_history_credit_Pavlina / External_etoro_Billing_Deposit | CompensationAmount, DepositAmount$ | -CompensationAmount / DepositAmount$ (ratio) | Tier 2 |
| PlayerStatus | Dim_PlayerStatus | Name | Passthrough via Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name | Tier 1 |
| PlayerStatusReason | Dim_PlayerStatusReasons | Name | Passthrough via Dim_Customer.PlayerStatusReasonID → Dim_PlayerStatusReasons.Name | Tier 1 |
| PlayerStatusSubReason | Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Passthrough via Dim_Customer.PlayerStatusSubReasonID → Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName; renamed to PlayerStatusSubReason | Tier 1 |
| LastDepositDate | External_etoro_Billing_Deposit | ModificationDate | MAX(ModificationDate) for approved deposits per CID | Tier 2 |
| #OfDeposits24hrs | External_etoro_Billing_Deposit | DepositID | COUNT(DepositID) for approved deposits in last 24hrs via ACH/PWMB/Trustly/Sofort/Giropay funding types; ISNULL to 0 | Tier 2 |
| UpdateDate | — | — | GETDATE() — ETL execution timestamp | Tier 2 |
| DepositAmount$24hrs | External_etoro_Billing_Deposit | Amount, ExchangeRate | SUM(Amount * ExchangeRate) for approved deposits in last 24hrs via ACH/PWMB/Trustly/Sofort/Giropay; ISNULL to 0 | Tier 2 |
