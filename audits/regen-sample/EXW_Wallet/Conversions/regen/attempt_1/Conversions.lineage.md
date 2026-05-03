# EXW_Wallet.Conversions — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Database |
|---|---|---|---|---|
| 1 | WalletDB.Wallet.Conversions | Production Table | Direct Bronze load via Generic Pipeline | WalletDB |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.Conversions | Id | Passthrough | Tier 3 |
| 2 | FromWalletId | WalletDB.Wallet.Conversions | FromWalletId | Passthrough | Tier 3 |
| 3 | ToWalletId | WalletDB.Wallet.Conversions | ToWalletId | Passthrough | Tier 3 |
| 4 | ConversionTypeId | WalletDB.Wallet.Conversions | ConversionTypeId | Passthrough | Tier 3 |
| 5 | FromAmount | WalletDB.Wallet.Conversions | FromAmount | Passthrough | Tier 3 |
| 6 | ToAmount | WalletDB.Wallet.Conversions | ToAmount | Passthrough | Tier 3 |
| 7 | CorrelationId | WalletDB.Wallet.Conversions | CorrelationId | Passthrough | Tier 3 |
| 8 | Occurred | WalletDB.Wallet.Conversions | Occurred | Passthrough | Tier 3 |
| 9 | FromCryptoId | WalletDB.Wallet.Conversions | FromCryptoId | Passthrough | Tier 3 |
| 10 | ToCryptoId | WalletDB.Wallet.Conversions | ToCryptoId | Passthrough | Tier 3 |
| 11 | etr_y | Generic Pipeline | Occurred | ETL-derived partition year from Occurred | Tier 3 |
| 12 | etr_ym | Generic Pipeline | Occurred | ETL-derived partition year-month from Occurred | Tier 3 |
| 13 | etr_ymd | Generic Pipeline | Occurred | ETL-derived partition year-month-day from Occurred | Tier 3 |
