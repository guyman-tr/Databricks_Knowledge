# Lineage: EXW_Wallet.RequestStatuses

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|--------------|-------------|--------------|--------|
| 1 | WalletDB.Wallet.RequestStatuses | Production Table | Direct copy (Generic Pipeline, Append) | Wallet |
| 2 | CopyFromLake.WalletDB_Dictionary_RequestStatuses | Dictionary (Synapse) | Lookup for RequestStatusId → Name | CopyFromLake |
| 3 | EXW_Wallet.Requests | Sibling staging table | Joined via RequestId in consuming SPs | EXW_Wallet |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | Id | WalletDB.Wallet.RequestStatuses | Id | Passthrough | Tier 3 |
| 2 | RequestId | WalletDB.Wallet.RequestStatuses | RequestId | Passthrough | Tier 3 |
| 3 | RequestStatusId | WalletDB.Wallet.RequestStatuses | RequestStatusId | Passthrough (FK to WalletDB.Dictionary.RequestStatuses) | Tier 3 |
| 4 | Timestamp | WalletDB.Wallet.RequestStatuses | Timestamp | Passthrough | Tier 3 |
| 5 | DetailsJson | WalletDB.Wallet.RequestStatuses | DetailsJson | Passthrough | Tier 3 |
| 6 | etr_y | Generic Pipeline | — | ETL-generated year partition column | Tier 2 |
| 7 | etr_ym | Generic Pipeline | — | ETL-generated year-month partition column | Tier 2 |
| 8 | etr_ymd | Generic Pipeline | — | ETL-generated year-month-day partition column | Tier 2 |
| 9 | SynapseUpdateDate | Generic Pipeline | — | Synapse ingestion timestamp | Tier 2 |
| 10 | partition_date | Generic Pipeline | — | Date-based partition derived from source event date | Tier 2 |

## Consuming Objects

| # | Consumer | Type | Usage |
|---|----------|------|-------|
| 1 | EXW_dbo.SP_EXW_C2F_E2E | Stored Procedure | Joins to Requests and Dictionary to determine latest request status for C2F and C2P end-to-end tracking |
| 2 | EXW_dbo.SP_EXW_FactRedeemTransactions | Stored Procedure | Joins to Requests to determine redemption request status (Done/Error/Pending) |
