# Column Lineage: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires

## Source Objects
| Source | Type | Relationship |
|--------|------|-------------|
| DWH_dbo.Fact_BillingDeposit | Table | Primary source (deposit transactions) |
| DWH_dbo.Dim_FundingType | Table | FundingTypeName lookup |
| DWH_dbo.Dim_Customer | Table | Customer validation (IsValidCustomer, PlayerLevelID, CountryID) |
| DWH_dbo.Dim_Country | Table | Region lookup via customer CountryID |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |

## Column Lineage
| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | DepositID | Fact_BillingDeposit | DepositID | Passthrough (bigint in target vs int in source) |
| 2 | CID | Fact_BillingDeposit | CID | Passthrough |
| 3 | FundingID | Fact_BillingDeposit | FundingID | Passthrough (bigint in target vs int in source) |
| 4 | CurrencyID | Fact_BillingDeposit | CurrencyID | Passthrough |
| 5 | PaymentStatusID | Fact_BillingDeposit | PaymentStatusID | Passthrough (always 2 due to filter) |
| 6 | Amount | Fact_BillingDeposit | Amount, ExchangeRate | Computed: bd.Amount * bd.ExchangeRate (converted to USD equivalent) |
| 7 | PaymentDate | Fact_BillingDeposit | PaymentDate | Passthrough |
| 8 | ValueDate | Fact_BillingDeposit | ProcessorValueDate, PaymentDate | CASE: IF FundingTypeID=2 (Wire) THEN ProcessorValueDate ELSE PaymentDate |
| 9 | ModificationDate | Fact_BillingDeposit | ModificationDate | Passthrough |
| 10 | Approved | Fact_BillingDeposit | Approved | Passthrough |
| 11 | DepotID | Fact_BillingDeposit | DepotID | Passthrough |
| 12 | FundingTypeID | Fact_BillingDeposit | FundingTypeID | Passthrough |
| 13 | FundingTypeName | Dim_FundingType | Name | Lookup via FundingTypeID |
| 14 | Region | Dim_Country | Region | Lookup via Dim_Customer.CountryID -> Dim_Country.CountryID |
| 15 | Regulation | Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID -> Dim_Regulation.ID |
| 16 | HandlingDays | Fact_BillingDeposit | ValueDate, ModificationDate | ETL-computed: working days from ValueDate to ModificationDate (weekday-adjusted, min 0) |
| 17 | FromStartToFinish | Fact_BillingDeposit | PaymentDate, ModificationDate | ETL-computed: working days from PaymentDate to ModificationDate (weekday-adjusted, min 0) |
| 18 | UpdateDate | — | — | ETL-computed: GETDATE() at SP execution |
| 19 | ModificationDateID | — | — | Not populated (NULL in all rows) — column exists in DDL but excluded from INSERT statement |
