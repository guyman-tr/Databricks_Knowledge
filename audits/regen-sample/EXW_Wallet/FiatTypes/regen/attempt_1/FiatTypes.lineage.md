# EXW_Wallet.FiatTypes — Lineage

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.FiatTypes | Production Table | Wallet | WalletDB | Direct copy via Generic Pipeline (Override) |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.FiatTypes | Id | Passthrough | Tier 3 |
| 2 | FiatId | WalletDB.Wallet.FiatTypes | FiatId | Passthrough | Tier 3 |
| 3 | FiatName | WalletDB.Wallet.FiatTypes | FiatName | Passthrough | Tier 3 |
| 4 | IsActive | WalletDB.Wallet.FiatTypes | IsActive | Passthrough | Tier 3 |
| 5 | AvatarUrl | WalletDB.Wallet.FiatTypes | AvatarUrl | Passthrough | Tier 3 |
| 6 | Precision | WalletDB.Wallet.FiatTypes | Precision | Passthrough | Tier 3 |
| 7 | InstrumentId | WalletDB.Wallet.FiatTypes | InstrumentId | Passthrough | Tier 3 |
| 8 | NumericCode | WalletDB.Wallet.FiatTypes | NumericCode | Passthrough | Tier 3 |
| 9 | etr_y | Generic Pipeline | — | ETL partition year (not populated) | Tier 2 |
| 10 | etr_ym | Generic Pipeline | — | ETL partition year-month (not populated) | Tier 2 |
| 11 | etr_ymd | Generic Pipeline | — | ETL partition year-month-day (not populated) | Tier 2 |
| 12 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load time | Tier 2 |
