# Column Lineage: BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|---------------|
| BI_DB_dbo.External_etoro_Billing_Deposit | BI_DB_dbo | Deposit transactions (approved, last 31 days + all-time) | fbd.CID = c.CID, PaymentStatusID=2 |
| BI_DB_dbo.External_etoro_Billing_Funding_Datafactory | BI_DB_dbo | Funding type filter for 24hr rapid deposits | Fund.FundingID = fbd.FundingID |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Compensation transactions (ActionTypeID=36, CompensationReasonID=7, Amount<0) | fca.RealCID = d.CID |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer validity filter (IsValidCustomer=1) | dc.RealCID = d.CID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name resolution | dps.PlayerStatusID = dc.PlayerStatusID |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | Status reason name resolution | dpsr.PlayerStatusReasonID = dc.PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | Status sub-reason name resolution | dpssr.PlayerStatusSubReasonID = dc.PlayerStatusSubReasonID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| RealCID | BI_DB_dbo.External_etoro_Billing_Deposit | CID | Passthrough (renamed from d.CID) |
| CompensationAmount | DWH_dbo.Fact_CustomerAction | Amount | ETL-computed: -SUM(Amount) WHERE ActionTypeID=36 AND CompensationReasonID=7 AND Amount<0, HAVING COUNT>3 AND SUM<-2000 |
| #ofDeposits | BI_DB_dbo.External_etoro_Billing_Deposit | DepositID | ETL-computed: COUNT(DepositID) WHERE PaymentStatusID=2 |
| DepositAmount$ | BI_DB_dbo.External_etoro_Billing_Deposit | Amount, ExchangeRate | ETL-computed: SUM(Amount * ExchangeRate) WHERE PaymentStatusID=2 |
| Compensation$/Deposits$ | Multiple | CompensationAmount, DepositAmount$ | ETL-computed: CompensationAmount / DepositAmount$ |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Dim-lookup passthrough via Dim_Customer.PlayerStatusID |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Dim-lookup passthrough via Dim_Customer.PlayerStatusReasonID |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Dim-lookup passthrough via Dim_Customer.PlayerStatusSubReasonID |
| LastDepositDate | BI_DB_dbo.External_etoro_Billing_Deposit | ModificationDate | ETL-computed: MAX(ModificationDate) WHERE PaymentStatusID=2 |
| #OfDeposits24hrs | BI_DB_dbo.External_etoro_Billing_Deposit | DepositID | ETL-computed: COUNT(DepositID) last 24hrs, specific FundingTypeIDs (29,32,35,15,11), HAVING >3 |
| DepositAmount$24hrs | BI_DB_dbo.External_etoro_Billing_Deposit | Amount, ExchangeRate | ETL-computed: SUM(Amount * ExchangeRate) last 24hrs, specific FundingTypeIDs |
| UpdateDate | — | — | ETL-computed: GETDATE() |
