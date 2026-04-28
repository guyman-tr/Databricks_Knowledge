# DWH_dbo.Fact_Deposit_Fees — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---------------|-------------|--------------|----------|
| 1 | `BackOffice.BillingDepositsPCIVersion` | Production Table | Primary source (via Generic Pipeline → Data Lake → staging) | SP_Fact_Deposit_Fees_DL_To_Synapse SELECT FROM DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion |
| 2 | `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion` | Synapse Staging Table | Direct source for SP INSERT | SP_Fact_Deposit_Fees_DL_To_Synapse |
| 3 | `DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse` | Stored Procedure | Writer SP | SSDT repo |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | BackOffice.BillingDepositsPCIVersion | CID | Passthrough via staging | Tier 3 |
| 2 | DepositStatus | BackOffice.BillingDepositsPCIVersion | DepositStatus | Passthrough via staging | Tier 3 |
| 3 | Threedsresponse | BackOffice.BillingDepositsPCIVersion | Threedsresponse | Passthrough via staging | Tier 3 |
| 4 | DepositRiskStatus | BackOffice.BillingDepositsPCIVersion | DepositRiskStatus | Passthrough via staging | Tier 3 |
| 5 | DepositAmount | BackOffice.BillingDepositsPCIVersion | DepositAmount | Passthrough via staging | Tier 3 |
| 6 | Currency | BackOffice.BillingDepositsPCIVersion | Currency | Passthrough via staging | Tier 3 |
| 7 | StatusModificationTime | BackOffice.BillingDepositsPCIVersion | StatusModificationTime | Passthrough via staging | Tier 3 |
| 8 | ModificationDateID | BackOffice.BillingDepositsPCIVersion | StatusModificationTime | ETL-computed: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))` | Tier 2 |
| 9 | DepositTime | BackOffice.BillingDepositsPCIVersion | DepositTime | Passthrough via staging | Tier 3 |
| 10 | FirstApprovedTime | BackOffice.BillingDepositsPCIVersion | FirstApprovedTime | Passthrough via staging | Tier 3 |
| 11 | DepositValueDate | BackOffice.BillingDepositsPCIVersion | DepositValueDate | Passthrough via staging | Tier 3 |
| 12 | DepositCollarAmount | BackOffice.BillingDepositsPCIVersion | DepositCollarAmount | Passthrough via staging | Tier 3 |
| 13 | FundingMethod | BackOffice.BillingDepositsPCIVersion | FundingMethod | Passthrough via staging | Tier 3 |
| 14 | Depot | BackOffice.BillingDepositsPCIVersion | Depot | Passthrough via staging | Tier 3 |
| 15 | OldPaymentID | BackOffice.BillingDepositsPCIVersion | OldPaymentID | Passthrough via staging | Tier 3 |
| 16 | DepositID | BackOffice.BillingDepositsPCIVersion | DepositID | Passthrough via staging | Tier 3 |
| 17 | TransactionID_Internal | BackOffice.BillingDepositsPCIVersion | TransactionID_Internal | Passthrough via staging | Tier 3 |
| 18 | CountryByRegIP | BackOffice.BillingDepositsPCIVersion | CountryByRegIP | Passthrough via staging | Tier 3 |
| 19 | Riskstatus | BackOffice.BillingDepositsPCIVersion | Riskstatus | Passthrough via staging | Tier 3 |
| 20 | FTD | BackOffice.BillingDepositsPCIVersion | FTD | Passthrough via staging | Tier 3 |
| 21 | BaseExchangeRate | BackOffice.BillingDepositsPCIVersion | BaseExchangeRate | Passthrough via staging | Tier 3 |
| 22 | ExchangeRate | BackOffice.BillingDepositsPCIVersion | ExchangeRate | Passthrough via staging | Tier 3 |
| 23 | FeeinPIPs | BackOffice.BillingDepositsPCIVersion | FeeinPIPs | Passthrough via staging | Tier 3 |
| 24 | PIPsinUSD | BackOffice.BillingDepositsPCIVersion | PIPsinUSD | Passthrough via staging | Tier 3 |
| 25 | CustomerStatus | BackOffice.BillingDepositsPCIVersion | CustomerStatus | Passthrough via staging | Tier 3 |
| 26 | Brand | BackOffice.BillingDepositsPCIVersion | Brand | Passthrough via staging | Tier 3 |
| 27 | CardCategory | BackOffice.BillingDepositsPCIVersion | CardCategory | Passthrough via staging | Tier 3 |
| 28 | PaymentDetails | BackOffice.BillingDepositsPCIVersion | PaymentDetails | Passthrough via staging | Tier 3 |
| 29 | FundingID | BackOffice.BillingDepositsPCIVersion | FundingID | Passthrough via staging | Tier 3 |
| 30 | ResponseCode | BackOffice.BillingDepositsPCIVersion | ResponseCode | Passthrough via staging | Tier 3 |
| 31 | TransactionResponse | BackOffice.BillingDepositsPCIVersion | TransactionResponse | Passthrough via staging | Tier 3 |
| 32 | CustomerLevel | BackOffice.BillingDepositsPCIVersion | CustomerLevel | Passthrough via staging | Tier 3 |
| 33 | AccountManager | BackOffice.BillingDepositsPCIVersion | AccountManager | Passthrough via staging | Tier 3 |
| 34 | TotalRollbackDollarAmount | BackOffice.BillingDepositsPCIVersion | TotalRollbackDollarAmount | Passthrough via staging | Tier 3 |
| 35 | TotalRollbackAmount | BackOffice.BillingDepositsPCIVersion | TotalRollbackAmount | Passthrough via staging | Tier 3 |
| 36 | RollbackReason | BackOffice.BillingDepositsPCIVersion | RollbackReason | Passthrough via staging | Tier 3 |
| 37 | UserName | BackOffice.BillingDepositsPCIVersion | UserName | Passthrough via staging | Tier 3 |
| 38 | AffiliateID | BackOffice.BillingDepositsPCIVersion | AffiliateID | Passthrough via staging | Tier 3 |
| 39 | ExternalTransactionID | BackOffice.BillingDepositsPCIVersion | ExternalTransactionID | Passthrough via staging | Tier 3 |
| 40 | Funnel | BackOffice.BillingDepositsPCIVersion | Funnel | Passthrough via staging | Tier 3 |
| 41 | Regulation | BackOffice.BillingDepositsPCIVersion | Regulation | Passthrough via staging | Tier 3 |
| 42 | WhiteLabel | BackOffice.BillingDepositsPCIVersion | WhiteLabel | Passthrough via staging | Tier 3 |
| 43 | DepositType | BackOffice.BillingDepositsPCIVersion | DepositType | Passthrough via staging | Tier 3 |
| 44 | Threedsparameters | BackOffice.BillingDepositsPCIVersion | Threedsparameters | Passthrough via staging | Tier 3 |
| 45 | MIDName | BackOffice.BillingDepositsPCIVersion | MIDName | Passthrough via staging | Tier 3 |
| 46 | MID | BackOffice.BillingDepositsPCIVersion | MID | Passthrough via staging | Tier 3 |
| 47 | UpdateDate | — | — | ETL-computed: `GETDATE()` at insert time | Tier 2 |
