# BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Writer SP** | BI_DB_dbo.SP_Money_In_New_Management_Dashboard |
| **Load Pattern** | Daily DELETE+INSERT by DepositID+CID, plus DELETE older than 7 months |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **UC Target** | _Not_Migrated |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|--------------|-----------|------|
| 1 | DepositID | DWH_dbo.Fact_BillingDeposit | DepositID | Direct | T2 |
| 2 | AmountUSD | DWH_dbo.Fact_BillingDeposit | AmountUSD | Direct | T2 |
| 3 | Country | DWH_dbo.Dim_Country | Name | Via Fact_SnapshotCustomer.CountryID | T2 |
| 4 | Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Via Fact_SnapshotCustomer.CountryID | T2 |
| 5 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Country.RegulationID | T2 |
| 6 | CID | DWH_dbo.Fact_BillingDeposit | CID | Direct | T2 |
| 7 | PaymentDate | DWH_dbo.Fact_BillingDeposit | PaymentDate | Direct | T2 |
| 8 | DepositDate | DWH_dbo.Fact_BillingDeposit | PaymentDate | CAST(PaymentDate AS Date) | T2 |
| 9 | ModificationDate | DWH_dbo.Fact_BillingDeposit | ModificationDate | Direct | T2 |
| 10 | PaymentStatusID | DWH_dbo.Fact_BillingDeposit | PaymentStatusID | Direct | T2 |
| 11 | IsFTD | DWH_dbo.Fact_BillingDeposit | IsFTD | Direct (1=first-time deposit) | T2 |
| 12 | DepositStatus | DWH_dbo.Fact_BillingDeposit | PaymentStatusID + FundingTypeID | CASE: 2→Approved, (1,5,11,12)→Exclude, 6+FT(35,37)→Exclude, 13+FT(1,34,11,28)→Exclude, else Declined | T2 |
| 13 | DepositMethod | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID | T2 |
| 14 | PaymentStatus | DWH_dbo.Dim_PaymentStatus | Name | Via PaymentStatusID | T2 |
| 15 | DepositFundingType | DWH_dbo.Fact_BillingDeposit | FundingTypeID | CASE: 2→Manual, 0→Error, else Automatic | T2 |
| 16 | FirstAttempt_Ind | Computed | — | 1 if this deposit is the customer's first-ever deposit attempt (MIN PaymentDate in last 2 days), 0 otherwise | T2 |
| 17 | FA_Approve_Rate | Computed | — | 1 if first attempt AND first approval within 24 hours, 0 otherwise | T2 |
| 18 | UpdateDate | ETL | GETDATE() | Set on INSERT | T5 |
| 19 | ProcessorValueDate | DWH_dbo.Fact_BillingDeposit | ProcessorValueDate | Direct | T2 |
| 20 | Currency | DWH_dbo.Dim_Currency | Abbreviation | Via CurrencyID | T2 |
| 21 | CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Direct | T2 |
| 22 | Club | DWH_dbo.Dim_PlayerLevel | Name | Via Fact_SnapshotCustomer.PlayerLevelID | T2 |
| 23 | DepositDateID | DWH_dbo.Fact_BillingDeposit | PaymentDate | CAST(CONVERT(VARCHAR(8), CAST(PaymentDate AS Date), 112) AS INT) | T2 |
| 24 | ModificationDateID | DWH_dbo.Fact_BillingDeposit | ModificationDate | CAST(CONVERT(VARCHAR(8), ModificationDate, 112) AS INT) | T2 |
| 25 | ConversionFeeRevenue | DWH_dbo.Fact_BillingDeposit | BaseExchangeRate, ExchangeRate, Amount | (BaseExchangeRate - ExchangeRate) * Amount | T2 |
| 26 | eMoneyEligible | Computed | Multiple | 1 if: >14 days since first deposit, IsDepositor=1, VerificationLevelID=3, PlayerStatusID NOT IN (2,4,14,15), country in eMoney_Dim_Country_Rollout with rollout date <= PaymentDate | T2 |
| 27 | DepositProvider | DWH_dbo.Dim_BillingDepot | Name | Via DepotID | T2 |
