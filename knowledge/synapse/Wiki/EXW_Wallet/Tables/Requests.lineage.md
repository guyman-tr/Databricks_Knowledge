# Lineage: EXW_Wallet.Requests

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Schema | Notes |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.Requests | Production Table | Direct mirror | WalletDB | Wallet | Raw source via Generic Pipeline (Append, daily) |
| 2 | WalletDB.Dictionary.RequestTypes | Dictionary | Lookup (RequestTypeId) | WalletDB | Dictionary | 10 request type values |
| 3 | EXW_Wallet.RequestStatuses | Sibling Table | JOIN (Id → RequestId) | Synapse | EXW_Wallet | Request status history |
| 4 | EXW_Wallet.CryptoTypes | Sibling Table | Lookup (CryptoId) | Synapse | EXW_Wallet | Cryptocurrency dictionary |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.Requests | Id | Passthrough | Tier 3 |
| 2 | CorrelationId | WalletDB.Wallet.Requests | CorrelationId | Passthrough | Tier 3 |
| 3 | Gcid | WalletDB.Wallet.Requests | Gcid | Passthrough | Tier 3 |
| 4 | CryptoId | WalletDB.Wallet.Requests | CryptoId | Passthrough | Tier 3 |
| 5 | RequestTypeId | WalletDB.Wallet.Requests | RequestTypeId | Passthrough | Tier 3 |
| 6 | Timestamp | WalletDB.Wallet.Requests | Timestamp | Passthrough | Tier 3 |
| 7 | DetailsJson | WalletDB.Wallet.Requests | DetailsJson | Passthrough | Tier 3 |
| 8 | DeviceId | WalletDB.Wallet.Requests | DeviceId | Passthrough | Tier 3 |
| 9 | etr_y | — | — | ETL partition column (unused) | Tier 3 |
| 10 | etr_ym | — | — | ETL partition column (unused) | Tier 3 |
| 11 | etr_ymd | — | — | ETL partition column (unused) | Tier 3 |
| 12 | SynapseUpdateDate | — | — | Synapse load timestamp | Tier 3 |
| 13 | partition_date | WalletDB.Wallet.Requests | Timestamp | Derived (CAST to DATE) | Tier 3 |
