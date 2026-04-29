# BI_DB_dbo.BI_DB_RiskPayPalDepositors — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | DWH_dbo.Fact_BillingDeposit | DWH_dbo | Primary — PayPal deposit events (FundingTypeID=3) | Population driver; CID, ModificationDateID |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes | fbd.CID = dc.RealCID |
| 3 | DWH_dbo.Dim_Country | DWH_dbo | Country/region lookup | dc.CountryID = dc1.CountryID |
| 4 | DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name | cc.PlayerStatusID = ps.PlayerStatusID |
| 5 | BI_DB_dbo.External_etoro_BackOffice_CustomerRisk | External | Risk status source | bcr.GCID = cc.GCID |
| 6 | DWH_dbo.Dim_RiskStatus | DWH_dbo | Risk status name | rs.RiskStatusID = bcr.RiskStatusID |
| 7 | DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name | dr.ID = cc.DesignatedRegulationID |
| 8 | DWH_dbo.Dim_ScreeningStatus | DWH_dbo | PEP screening status | ps1.ScreeningStatusID = cc.ScreeningStatusID |
| 9 | DWH_dbo.Dim_DocumentStatus | DWH_dbo | Document review status | ds.DocumentStatusID = cc.DocumentStatusID |
| 10 | DWH_dbo.Dim_PhoneVerified | DWH_dbo | Phone verification state | dp.PhoneVerifiedID = cc.PhoneVerifiedID |
| 11 | DWH_dbo.V_Liabilities | DWH_dbo | TotalEquity computation | vl.CID = p.CID AND vl.DateID = @StartDateID |
| 12 | BI_DB_dbo.External_etoro_Billing_Withdraw | External | Open cashout detection | pop.CID = bw.CID |
| 13 | DWH_dbo.Dim_CashoutStatus | DWH_dbo | Cashout status filter | cs.CashoutStatusID = bw.CashoutStatusID |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | CID | Fact_BillingDeposit | CID | DISTINCT — population of PayPal depositors |
| 2 | Country | Dim_Country | Name | Passthrough via Dim_Customer.CountryID JOIN |
| 3 | City | Dim_Customer | City | Passthrough — Unicode city name |
| 4 | Region | Dim_Country | MarketingRegionManualName | Rename — aliased AS Region |
| 5 | DesignatedRegulation | Dim_Regulation | Name | Passthrough via Dim_Customer.DesignatedRegulationID JOIN |
| 6 | DateOfRegistration | Dim_Customer | RegisteredReal | Passthrough — renamed |
| 7 | VerificationLevelID | Dim_Customer | VerificationLevelID | Passthrough |
| 8 | PlayerStatus | Dim_PlayerStatus | Name | Passthrough via Dim_Customer.PlayerStatusID JOIN |
| 9 | RiskStatus | Dim_RiskStatus | Name | Passthrough via External_etoro_BackOffice_CustomerRisk.RiskStatusID JOIN |
| 10 | DocumentStatus | Dim_DocumentStatus | DocumentStatusName | Passthrough via Dim_Customer.DocumentStatusID JOIN |
| 11 | PhoneVerifiedName | Dim_PhoneVerified | PhoneVerifiedName | Passthrough via Dim_Customer.PhoneVerifiedID JOIN |
| 12 | PEPStatus | Dim_ScreeningStatus | Name | Passthrough via Dim_Customer.ScreeningStatusID JOIN |
| 13 | TotalEquity | V_Liabilities | Liabilities + ActualNWA | Computed — sum of liabilities and actual net worth |
| 14 | TotalDeposits | Fact_BillingDeposit | AmountUSD | Aggregated — SUM WHERE PaymentStatusID=2 |
| 15 | NumberOfPPfundingIDs | Fact_BillingDeposit | FundingID | Aggregated — COUNT(DISTINCT) WHERE FundingTypeID=3 |
| 16 | OpenCashout | External_etoro_Billing_Withdraw | CashoutStatusID | Computed — CASE: 'Yes' if open cashout exists (status 1,2,5,14,15), else 'No' |
| 17 | ModificationDateID | Fact_BillingDeposit | ModificationDateID | Passthrough — partition/incremental key |
| 18 | UpdateDate | ETL | GETDATE() | ETL metadata — row insert timestamp |
