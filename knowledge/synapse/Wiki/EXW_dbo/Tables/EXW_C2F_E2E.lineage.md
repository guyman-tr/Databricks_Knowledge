---
object: EXW_dbo.EXW_C2F_E2E
type: Table
schema: EXW_dbo
uc_target: eToro_DWH.EXW_dbo.EXW_C2F_E2E
writer_sp: EXW_dbo.SP_EXW_C2F_E2E
load_pattern: FULL (DELETE + INSERT on every SP run)
primary_sources:
  - WalletConversionDB.C2F.Conversions
  - WalletConversionDB.C2F.ConversionStatuses
  - WalletConversionDB.C2F.CryptoTransactions
  - WalletConversionDB.C2F.EstimatedFiatTransactions
  - WalletConversionDB.C2F.FiatTransactions
  - WalletDB.Wallet.SentTransactions
  - WalletDB.Wallet.Requests
secondary_sources:
  - WalletDB.Wallet.SentTransactionOutputs
  - WalletDB.Wallet.SentTransactionStatuses
  - WalletDB.Wallet.RequestStatuses
  - WalletDB.Wallet.CustomerWalletsView
  - FiatDwhDB (eMoney transactions via EXW_Wallet)
  - DWH_dbo.Fact_SnapshotCustomer (customer point-in-time snapshot)
  - DWH_dbo.Dim_Range (point-in-time JOIN)
  - DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Manager
  - DWH_dbo.Fact_BillingDeposit (EtoroPosition path only)
  - EXW_dbo.EXW_WalletEntity
  - EXW_dbo.EXW_DimUser
tier1_count: 38
tier2_count: 65
total_columns: 103
---

# Column Lineage — EXW_dbo.EXW_C2F_E2E

## Source Objects

| Source | Database | Repo | Path |
|--------|----------|------|------|
| C2F.Conversions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md |
| C2F.ConversionStatuses | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.ConversionStatuses.md |
| C2F.CryptoTransactions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md |
| C2F.EstimatedFiatTransactions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md |
| C2F.FiatTransactions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.FiatTransactions.md |
| Wallet.SentTransactions | WalletDB | CryptoDBs | WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md |
| Wallet.Requests | WalletDB | CryptoDBs | WalletDB/Wiki/Wallet/Tables/Wallet.Requests.md |

## Column Source Map

| DWH Column | Source Table | Source Column | Rename | Tier | Transformation |
|-----------|-------------|---------------|--------|------|----------------|
| C2FCorrelationID | C2F.Conversions | CorrelationId | YES | 1 | Passthrough |
| TargetPlatformID | C2F.Conversions | TargetPlatformId | YES | 1 | Passthrough |
| TargetPlatform | C2F.Conversions / Dictionary.FiatConversionTargets | TargetPlatformId | YES | 2 | Lookup name via Dictionary join |
| ConversionCycle | SP_EXW_C2F_E2E | — | — | 2 | CASE expression: 10+ reconciliation cycle values based on multi-system state |
| LastModificationDateTime | SP_EXW_C2F_E2E | — | — | 2 | GREATEST(FiatTx.Occurred, ConversionTime, ConversionStatusTime, CryptoTransactionTime) |
| LastModificationDate | SP_EXW_C2F_E2E | — | — | 2 | CAST(LastModificationDateTime AS DATE) |
| LastModificationDateID | SP_EXW_C2F_E2E | — | — | 2 | CAST(FORMAT(LastModificationDate,'yyyyMMdd') AS INT) |
| GCID | C2F.Conversions | Gcid | YES | 1 | Passthrough |
| RealCID | EXW_dbo.EXW_DimUser | RealCID | NO | 2 | Lookup via EXW_DimUser on GCID |
| RequestID | Wallet.Requests | Id | YES | 1 | Passthrough |
| RequestCryptoID | Wallet.Requests | CryptoId | YES | 1 | Passthrough |
| RequestDateTime | Wallet.Requests | Timestamp | YES | 1 | Passthrough |
| RequestLastStatusID | Wallet.RequestStatuses | RequestStatusId | YES | 2 | Last status via ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC) |
| RequestLastStatus | WalletDB.Dictionary.RequestStatuses | Name | YES | 2 | Lookup name for RequestLastStatusID |
| RequestLastStatusDateTime | Wallet.RequestStatuses | Timestamp | YES | 2 | Timestamp of last status row |
| SentTransactionID | Wallet.SentTransactions | Id | YES | 1 | Passthrough |
| SentBlockchainTransactionID | Wallet.SentTransactions | BlockchainTransactionId | YES | 1 | Passthrough |
| SentWalletID | Wallet.SentTransactions | WalletId | YES | 1 | Passthrough |
| SentTransactionDateTime | Wallet.SentTransactions | Occurred | YES | 1 | Passthrough |
| SentBlockchainFee | Wallet.SentTransactions | BlockchainFee | YES | 1 | Passthrough |
| SentCryptoID | Wallet.SentTransactions | CryptoId | YES | 1 | Passthrough |
| SentAmount | Wallet.SentTransactionOutputs | Amount | YES | 2 | From SentTransactionOutputs (no upstream wiki; no direct column in SentTransactions) |
| SentEtoroFees | Wallet.SentTransactionOutputs | EtoroFees | YES | 2 | From SentTransactionOutputs (no upstream wiki) |
| SentLastStatusID | Wallet.SentTransactionStatuses | StatusId | YES | 2 | Last status via ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC) |
| SentLastStatus | WalletDB.Dictionary.TransactionStatus | Name | YES | 2 | Lookup name for SentLastStatusID |
| EstimatedFiatAmount | C2F.EstimatedFiatTransactions | FiatAmount | YES | 1 | Passthrough |
| EstimatedUsdAmount | C2F.EstimatedFiatTransactions | UsdAmount | YES | 1 | Passthrough |
| EstimatedCryptoToUsdRate | C2F.EstimatedFiatTransactions | CryptoToUsdRate | YES | 1 | Passthrough |
| EstimatedFiatToUsdRate | C2F.EstimatedFiatTransactions | FiatToUsdRate | YES | 1 | Passthrough |
| EstimatedCryptoToFiatRate | C2F.EstimatedFiatTransactions | CryptoToFiatRate | YES | 1 | Passthrough |
| EstimatedDateTime | C2F.EstimatedFiatTransactions | Occurred | YES | 1 | Passthrough |
| C2FConversionID | C2F.Conversions | Id | YES | 1 | Passthrough |
| CryptoID | C2F.Conversions | CryptoId | YES | 1 | Passthrough |
| Crypto | Wallet.CryptoTypes | Name | YES | 2 | Lookup name via EXW_Wallet.CryptoTypes on CryptoId |
| FiatCurrencyID | C2F.Conversions | FiatId | YES | 1 | Passthrough |
| FiatCurrency | Wallet.FiatTypes | FiatName | YES | 2 | Lookup name via EXW_Wallet.FiatTypes on FiatId |
| CryptoAmount | C2F.Conversions | CryptoAmount | NO | 1 | Passthrough |
| TotalFeePercentage | C2F.Conversions | ConversionFeePercentage | YES | 1 | Passthrough |
| TotalFeeUSD | SP_EXW_C2F_E2E | — | — | 2 | Computed: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage |
| ConversionDateTime | C2F.Conversions | Occurred | YES | 1 | Passthrough |
| ConversionDateID | SP_EXW_C2F_E2E | — | — | 2 | CAST(FORMAT(ConversionDateTime,'yyyyMMdd') AS INT) |
| ConversionDate | SP_EXW_C2F_E2E | — | — | 2 | CAST(ConversionDateTime AS DATE) |
| ConversionStatusID | C2F.ConversionStatuses | StatusId | YES | 1 | Passthrough (last status row via Rn=1) |
| ConversionStatus | C2F.ConversionStatuses / Dictionary | Name | YES | 2 | Lookup name for ConversionStatusID |
| ConversionStatusDateTime | C2F.ConversionStatuses | Occurred | YES | 2 | Timestamp of last status row; no direct upstream description for this derived column |
| ConversionStatusDateID | SP_EXW_C2F_E2E | — | — | 2 | CAST(FORMAT(ConversionStatusDateTime,'yyyyMMdd') AS INT) |
| ConversionStatusDate | SP_EXW_C2F_E2E | — | — | 2 | CAST(ConversionStatusDateTime AS DATE) |
| BlockchainTransactionID | C2F.CryptoTransactions | BlockchainTransactionId | YES | 1 | Passthrough |
| FromAddress | Wallet.CustomerWalletsView | Address | YES | 2 | Source wallet address of the customer (no upstream wiki for CustomerWalletsView) |
| ToAddress | C2F.CryptoTransactions | ToAddress | NO | 1 | Passthrough |
| BlockchainFee | C2F.CryptoTransactions | BlockchainFee | NO | 1 | Passthrough |
| CryptoTransactionDateTime | C2F.CryptoTransactions | Occurred | YES | 1 | Passthrough |
| CryptoTransactionDateID | SP_EXW_C2F_E2E | — | — | 2 | CAST(FORMAT(CryptoTransactionDateTime,'yyyyMMdd') AS INT) |
| CryptoTransactionDate | SP_EXW_C2F_E2E | — | — | 2 | CAST(CryptoTransactionDateTime AS DATE) |
| CryptoToFiatRate | C2F.FiatTransactions | CryptoToFiatRate | NO | 1 | Passthrough |
| FiatToUsdRate | C2F.FiatTransactions | FiatToUsdRate | NO | 1 | Passthrough |
| CryptoToUsdRate | C2F.FiatTransactions | CryptoToUsdRate | NO | 1 | Passthrough |
| FiatAmount | C2F.FiatTransactions | FiatAmount | NO | 1 | Passthrough |
| UsdAmount | C2F.FiatTransactions | UsdAmount | NO | 1 | Passthrough |
| FiatAccountID | C2F.FiatTransactions | AccountId | YES | 1 | Passthrough |
| FiatDetails | C2F.FiatTransactions | Details | YES | 1 | Passthrough |
| RateTime | C2F.FiatTransactions | RateTimestamp | YES | 1 | Passthrough |
| FiatTxTime | C2F.FiatTransactions | Occurred | YES | 1 | Passthrough |
| eMoneyTransactionID | FiatDwhDB (via EXW_Wallet) | TransactionID | YES | 2 | From eMoney transaction log; no upstream wiki |
| eMoneyTxCreatedDate | FiatDwhDB | Created | YES | 2 | Creation date of the eMoney transaction |
| eMoneyReferenceNumber | FiatDwhDB | ReferenceNumber | YES | 2 | External eMoney reference (same value as FiatDetails for IbanAccount) |
| eMoneyLastTxStatusID | FiatDwhDB | TransactionStatusId | YES | 2 | Last eMoney transaction status ID |
| eMoneyLastTxStatus | FiatDwhDB.Dictionary | Name | YES | 2 | Lookup name for eMoneyLastTxStatusID (e.g. Settled) |
| eMoneyHolderAmount | FiatDwhDB | HolderAmount | YES | 2 | Amount in the eToro Money holder account |
| eMoneyLastStatusTime | FiatDwhDB | TransactionOccured | YES | 2 | Timestamp of eMoney transaction |
| eMoneyProviderTransactionID | FiatDwhDB | ProviderTransactionID | YES | 2 | External provider transaction ID from eToro Money system |
| eMoneyAccountProgram | FiatDwhDB | AccountProgram | YES | 2 | eToro Money account program (iban/card) |
| eMoneyAccountSubProgram | FiatDwhDB | AccountSubProgram | YES | 2 | eToro Money account sub-program (e.g. IBAN Standard UK) |
| eMoneyCurrencyBalanceID | FiatDwhDB | CurrencyBalanceID | YES | 2 | Currency balance account ID in eToro Money system |
| eMoneyProviderCurrencyBalanceID | FiatDwhDB | ProviderCurrencyBalanceID | YES | 2 | Provider-side currency balance ID |
| eMoneyHolderID | FiatDwhDB | HolderID | YES | 2 | eToro Money holder account ID |
| eMoneyIsValidETM | FiatDwhDB | IsValidETM | YES | 2 | Flag indicating valid eToro Money account (1=valid) |
| eMoneyEntity | FiatDwhDB | eMoneyEntity | YES | 2 | eToro Money legal entity (e.g. eToro Money UK, eToro Money Malta, eToro Money AUS) |
| IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | NO | 2 | Flag from EXW_DimUser indicating test/internal account |
| IsRequestDone | SP_EXW_C2F_E2E | — | — | 2 | Computed: CASE WHEN a matching #requestdone row exists THEN 1 ELSE 0 END |
| TribeHolderAmount | FiatDwhDB.Tribe | HolderAmount | YES | 2 | Tribe (eToro Money) holder amount; mirrors eMoneyHolderAmount for cross-validation |
| TribeTxDateTime | FiatDwhDB.Tribe | WorkDate | YES | 2 | Tribe transaction date |
| DepositID | DWH_dbo.Fact_BillingDeposit | DepositID | NO | 2 | Populated only for EtoroPosition (TargetPlatformID=3) path; NULL for IbanAccount |
| DepositDateTime | DWH_dbo.Fact_BillingDeposit | PaymentDate | YES | 2 | Deposit payment date (EtoroPosition path only) |
| DepositModificationTime | DWH_dbo.Fact_BillingDeposit | ModificationDate | YES | 2 | Deposit last modification time (EtoroPosition path only) |
| DepositLastStatusID | DWH_dbo.Fact_BillingDeposit | PaymentStatusID | YES | 2 | Deposit payment status ID (EtoroPosition path only) |
| DepositLastStatus | DWH_dbo.Dim_PaymentStatus | Name | YES | 2 | Deposit payment status name (EtoroPosition path only) |
| DepositUSD | DWH_dbo.Fact_BillingDeposit | AmountUSD | YES | 2 | Deposit amount in USD (EtoroPosition path only) |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | NO | 2 | Point-in-time customer regulation via Dim_Range date join |
| Regulation | DWH_dbo.Dim_Regulation | Name | YES | 2 | Regulation name lookup |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | NO | 2 | Point-in-time customer country via Dim_Range date join |
| Country | DWH_dbo.Dim_Country | Name | NO | 2 | Country name lookup |
| CustomerRegionID | SP_EXW_C2F_E2E | — | — | 2 | CASE: Fact_SnapshotCustomer.RegionID when CountryID=219 (USA) ELSE NULL |
| State | SP_EXW_C2F_E2E | — | — | 2 | CASE: Dim_State_and_Province.Name when CountryID=219 (USA) ELSE NULL |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | NO | 2 | Point-in-time customer validity flag |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | NO | 2 | Point-in-time credit report validity flag |
| PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | NO | 2 | Point-in-time player level (club tier) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | YES | 2 | Player level name (Bronze, Silver, Gold, Platinum, Diamond) |
| PlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | NO | 2 | Point-in-time player status |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | YES | 2 | Player status name (Normal, etc.) |
| WalletEntity | EXW_dbo.EXW_WalletEntity | WalletEntity | YES | 2 | eToro legal entity responsible for the wallet (eToroUK, eToroAUS, etc.) |
| AccountManager | DWH_dbo.Dim_Manager | FirstName + LastName | YES | 2 | Concatenated FirstName + ' ' + LastName from Dim_Manager; account manager assigned to customer |
| UpdateDate | SP_EXW_C2F_E2E | — | — | 2 | GETDATE() at time of SP execution; batch watermark |
