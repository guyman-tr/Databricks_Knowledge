# Lineage: EXW_Wallet.CryptoTypes

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Documentation |
|---|--------------|-------------|--------|----------|-------------|---------------|
| 1 | WalletDB.Wallet.CryptoTypes | Production Table | Wallet | WalletDB | Generic Pipeline (Override, daily) | No upstream wiki located |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | CryptoID | WalletDB.Wallet.CryptoTypes | CryptoID | Passthrough | Tier 3 |
| 2 | Name | WalletDB.Wallet.CryptoTypes | Name | Passthrough | Tier 3 |
| 3 | MinReqAccounts | WalletDB.Wallet.CryptoTypes | MinReqAccounts | Passthrough | Tier 3 |
| 4 | MinUnit | WalletDB.Wallet.CryptoTypes | MinUnit | Passthrough | Tier 3 |
| 5 | Status | WalletDB.Wallet.CryptoTypes | Status | Passthrough | Tier 3 |
| 6 | MinReqVerifications | WalletDB.Wallet.CryptoTypes | MinReqVerifications | Passthrough | Tier 3 |
| 7 | MaxVerificationTimeMinutes | WalletDB.Wallet.CryptoTypes | MaxVerificationTimeMinutes | Passthrough | Tier 3 |
| 8 | Occurred | WalletDB.Wallet.CryptoTypes | Occurred | Passthrough | Tier 3 |
| 9 | IsActive | WalletDB.Wallet.CryptoTypes | IsActive | Passthrough | Tier 3 |
| 10 | CryptoActivityStatus | WalletDB.Wallet.CryptoTypes | CryptoActivityStatus | Passthrough | Tier 3 |
| 11 | BalanceAssetName | WalletDB.Wallet.CryptoTypes | BalanceAssetName | Passthrough | Tier 3 |
| 12 | WebHookVerifications | WalletDB.Wallet.CryptoTypes | WebHookVerifications | Passthrough | Tier 3 |
| 13 | StartMonitoringDelaySeconds | WalletDB.Wallet.CryptoTypes | StartMonitoringDelaySeconds | Passthrough | Tier 3 |
| 14 | BalanceThreshold | WalletDB.Wallet.CryptoTypes | BalanceThreshold | Passthrough | Tier 3 |
| 15 | InitialFeeUnits | WalletDB.Wallet.CryptoTypes | InitialFeeUnits | Passthrough | Tier 3 |
| 16 | BlockchainExplorerFormat | WalletDB.Wallet.CryptoTypes | BlockchainExplorerFormat | Passthrough | Tier 3 |
| 17 | IsEtoroHandlingFee | WalletDB.Wallet.CryptoTypes | IsEtoroHandlingFee | Passthrough | Tier 3 |
| 18 | BlockchainCryptoId | WalletDB.Wallet.CryptoTypes | BlockchainCryptoId | Passthrough | Tier 3 |
| 19 | AssetTypeId | WalletDB.Wallet.CryptoTypes | AssetTypeId | Passthrough | Tier 3 |
| 20 | SymbolFull | WalletDB.Wallet.CryptoTypes | SymbolFull | Passthrough | Tier 3 |
| 21 | DisplayName | WalletDB.Wallet.CryptoTypes | DisplayName | Passthrough | Tier 3 |
| 22 | AvatarUrl | WalletDB.Wallet.CryptoTypes | AvatarUrl | Passthrough | Tier 3 |
| 23 | Precision | WalletDB.Wallet.CryptoTypes | Precision | Passthrough | Tier 3 |
| 24 | TagName | WalletDB.Wallet.CryptoTypes | TagName | Passthrough | Tier 3 |
| 25 | InstrumentId | WalletDB.Wallet.CryptoTypes | InstrumentId | Passthrough | Tier 3 |
| 26 | AssetBlockchainAddress | WalletDB.Wallet.CryptoTypes | AssetBlockchainAddress | Passthrough | Tier 3 |
| 27 | OrderIndex | WalletDB.Wallet.CryptoTypes | OrderIndex | Passthrough | Tier 3 |
| 28 | CryptoCategoryName | WalletDB.Wallet.CryptoTypes | CryptoCategoryName | Passthrough | Tier 3 |
| 29 | StakingDisplayName | WalletDB.Wallet.CryptoTypes | StakingDisplayName | Passthrough | Tier 3 |
| 30 | StakingAvatarUrl | WalletDB.Wallet.CryptoTypes | StakingAvatarUrl | Passthrough | Tier 3 |
| 31 | StakingSymbolFull | WalletDB.Wallet.CryptoTypes | StakingSymbolFull | Passthrough | Tier 3 |
| 32 | etr_y | Generic Pipeline | — | ETL partition column (year) | Tier 2 |
| 33 | etr_ym | Generic Pipeline | — | ETL partition column (year-month) | Tier 2 |
| 34 | etr_ymd | Generic Pipeline | — | ETL partition column (year-month-day) | Tier 2 |
| 35 | SynapseUpdateDate | Generic Pipeline | — | ETL load timestamp | Tier 2 |
