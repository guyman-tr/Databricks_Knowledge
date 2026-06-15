---
object: EXW_dbo.EXW_C2P_E2E
type: Table
schema: EXW_dbo
uc_target: _Not_Migrated
writer_sp: EXW_dbo.SP_EXW_C2F_E2E
load_pattern: FULL (DELETE + INSERT on every SP run)
primary_sources:
  - WalletConversionDB.C2F.Conversions
  - WalletConversionDB.C2F.ConversionStatuses
  - WalletConversionDB.C2F.CryptoTransactions
  - WalletConversionDB.C2F.EstimatedFiatTransactions
  - WalletDB.Wallet.SentTransactions
  - WalletDB.Wallet.Requests
secondary_sources:
  - Dealing_staging.etoro_Trade_AdminPositionLog (CompensationReasonID=134)
  - DWH_dbo.Dim_Position
  - DWH_dbo.Fact_CustomerAction (ActionTypeID=36 and ActionTypeID=1)
  - DWH_dbo.Fact_SnapshotCustomer + Dim_Range
  - WalletDB.Wallet.SentTransactionOutputs, SentTransactionStatuses, RequestStatuses, CustomerWalletsView
  - DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Manager, Dim_Label, Dim_Instrument, Dim_CompensationReason, Dim_ActionType
  - EXW_dbo.EXW_WalletEntity, EXW_dbo.EXW_DimUser
tier1_count: 25
tier2_count: 65
total_columns: 90
---

# Column Lineage — EXW_dbo.EXW_C2P_E2E

## Source Objects

| Source | Database | Repo | Path |
|--------|----------|------|------|
| C2F.Conversions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md |
| C2F.ConversionStatuses | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.ConversionStatuses.md |
| C2F.CryptoTransactions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md |
| C2F.EstimatedFiatTransactions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md |
| Wallet.SentTransactions | WalletDB | CryptoDBs | WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md |
| Wallet.Requests | WalletDB | CryptoDBs | WalletDB/Wiki/Wallet/Tables/Wallet.Requests.md |
| C2P.Positions | WalletConversionDB | CryptoDBs | WalletConversionDB/Wiki/C2P/Tables/C2P.Positions.md |

## Column Source Map

| DWH Column | Source Table | Source Column | Rename | Tier | Transformation |
|-----------|-------------|---------------|--------|------|----------------|
| CorrelationID | C2F.Conversions | CorrelationId | YES | 1 | Passthrough |
| ConversionID | C2F.Conversions | Id | YES | 1 | Passthrough |
| TargetPlatformID | C2F.Conversions | TargetPlatformId | YES | 1 | Passthrough (filtered to =3 EtoroPosition) |
| TargetPlatform | Dictionary.FiatConversionTargets | Name | YES | 2 | Lookup — always "EtoroPosition" for C2P |
| ConversionCycle | SP_EXW_C2F_E2E | — | — | 2 | CASE: Full Cycle (all 6 checks pass) ELSE Other |
| LastModificationTime | SP_EXW_C2F_E2E | — | — | 2 | GREATEST of 7 event timestamps including admin log and position open |
| LastModificationDate | SP_EXW_C2F_E2E | — | — | 2 | CAST(LastModificationTime AS DATE) |
| LastModificationDateID | SP_EXW_C2F_E2E | — | — | 2 | CAST(FORMAT(date,'yyyyMMdd') AS INT) |
| GCID | Wallet.Requests | Gcid | YES | 1 | Passthrough (from RequestTypeId=9 requests) |
| RealCID | EXW_dbo.EXW_DimUser | RealCID | NO | 2 | Lookup via EXW_DimUser on GCID |
| RequestID | Wallet.Requests | Id | YES | 1 | Passthrough |
| RequestTime | Wallet.Requests | Timestamp | YES | 1 | Passthrough |
| RequestLastStatusID | Wallet.RequestStatuses | RequestStatusId | YES | 2 | Last status via ROW_NUMBER() |
| RequestLastStatus | WalletDB.Dictionary.RequestStatuses | Name | YES | 2 | Lookup name |
| RequestLastStatusTime | Wallet.RequestStatuses | Timestamp | YES | 2 | Timestamp of last status |
| WalletRequestType | WalletDB.Dictionary.RequestTypes | Name | YES | 2 | Lookup — always "ConversionToPosition" for RequestTypeId=9 |
| SentTransactionID | Wallet.SentTransactions | Id | YES | 1 | Passthrough (filtered to TransactionTypeId=12) |
| SentWalletID | Wallet.SentTransactions | WalletId | YES | 1 | Passthrough |
| SentTransactionTime | Wallet.SentTransactions | Occurred | YES | 1 | Passthrough |
| SentBlockchainFee | Wallet.SentTransactions | BlockchainFee | YES | 1 | Passthrough |
| FromAddress | Wallet.CustomerWalletsView | Address | YES | 2 | Source wallet address of customer |
| ToAddress | Wallet.SentTransactionOutputs | ToAddress | YES | 2 | Output destination address from SentTransactionOutputs |
| BlockchainTransactionID | C2F.CryptoTransactions | BlockchainTransactionId | YES | 1 | Passthrough (from #LastStatusC2P which is #LastStatus filtered to TargetPlatformID=3) |
| BlockchainFee | C2F.CryptoTransactions | BlockchainFee | NO | 1 | Passthrough |
| SentAmount | Wallet.SentTransactionOutputs | Amount | YES | 2 | From SentTransactionOutputs (no upstream wiki) |
| SentLastStatusID | Wallet.SentTransactionStatuses | StatusId | YES | 2 | Last status via ROW_NUMBER() |
| SentLastStatus | WalletDB.Dictionary.TransactionStatus | Name | YES | 2 | Lookup name |
| SentLastStatusTime | Wallet.SentTransactionStatuses | Occurred | YES | 2 | Timestamp of last sent status |
| WalletTransactionType | EXW_Dictionary.TransactionTypes | Name | YES | 2 | Lookup from EXW_Dictionary (always ConversionToFiat=12) |
| EstimatedFiatAmount | C2F.EstimatedFiatTransactions | FiatAmount | YES | 1 | Passthrough |
| EstimatedUsdAmount | C2F.EstimatedFiatTransactions | UsdAmount | YES | 1 | Passthrough |
| EstimatedCryptoToUsdRate | C2F.EstimatedFiatTransactions | CryptoToUsdRate | YES | 1 | Passthrough |
| EstimatedFiatToUsdRate | C2F.EstimatedFiatTransactions | FiatToUsdRate | YES | 1 | Passthrough |
| EstimatedCryptoToFiatRate | C2F.EstimatedFiatTransactions | CryptoToFiatRate | YES | 1 | Passthrough |
| EstimatedTime | C2F.EstimatedFiatTransactions | Occurred | YES | 1 | Passthrough |
| CryptoID | Wallet.Requests | CryptoId | YES | 1 | Passthrough (RequestCryptoID from Wallet.Requests; same value as C2F.Conversions.CryptoId) |
| Crypto | Wallet.CryptoTypes | Name | YES | 2 | Lookup name |
| FiatCurrencyID | C2F.Conversions | FiatId | YES | 1 | Passthrough (from #LastStatusC2P.FiatID) |
| FiatCurrency | Wallet.FiatTypes | FiatName | YES | 2 | Lookup name — always USD (FiatCurrencyID=1) for EtoroPosition |
| CryptoAmount | C2F.Conversions | CryptoAmount | NO | 1 | Passthrough |
| TotalFeePercentage | C2F.Conversions | ConversionFeePercentage | YES | 1 | Passthrough |
| TotalFeeUSD | SP_EXW_C2F_E2E | — | — | 2 | Computed: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage |
| ConversionTime | C2F.Conversions | Occurred | YES | 1 | Passthrough |
| CryptoTransactionTime | C2F.CryptoTransactions | Occurred | YES | 1 | Passthrough |
| ConversionStatusID | C2F.ConversionStatuses | StatusId | YES | 1 | Passthrough (last status row) |
| ConversionStatus | Dictionary.ConversionToFiatStatuses | Name | YES | 2 | Lookup name |
| ConversionStatusTime | C2F.ConversionStatuses | Occurred | YES | 2 | Timestamp of last status row |
| PositionID | Dealing_staging.etoro_Trade_AdminPositionLog | PositionID | NO | 2 | From AdminPositionLog (CompensationReasonID=134), joined via RequestCorrelationID=AdminPositionRequestID |
| AdminLogAmountUnits | Dealing_staging.etoro_Trade_AdminPositionLog | AmountInUnits | YES | 2 | Units amount from the admin position log entry |
| HedgeServerID | Dealing_staging.etoro_Trade_AdminPositionLog | HedgeServerID | NO | 2 | Hedge server that processed the position open |
| AdminLogRequestOccurred | Dealing_staging.etoro_Trade_AdminPositionLog | RequestOccurred | YES | 2 | Timestamp when position open was requested |
| AdminLogExecutionOccurred | Dealing_staging.etoro_Trade_AdminPositionLog | ExecutionOccurred | YES | 2 | Timestamp when position open was executed |
| AdminLogRate | Dealing_staging.etoro_Trade_AdminPositionLog | Rate | YES | 2 | Exchange rate at time of position open |
| AdminLogRateTime | Dealing_staging.etoro_Trade_AdminPositionLog | RateTime | YES | 2 | Timestamp of the rate used for position open |
| CompensationCreditID | Dealing_staging.etoro_Trade_AdminPositionLog | CompensationCreditID | NO | 2 | Credit transaction ID linking position open to compensation |
| PositionUSD | DWH_dbo.Dim_Position | Amount | YES | 2 | Position USD value from Dim_Position.Amount |
| PositionUnits | DWH_dbo.Dim_Position | AmountInUnitsDecimal | YES | 2 | Decimal units amount from Dim_Position |
| PositionInitialUnits | DWH_dbo.Dim_Position | InitialUnits | YES | 2 | Initial units at position open |
| PositionInitialAmountCents | DWH_dbo.Dim_Position | InitialAmountCents | YES | 2 | Initial position value in cents |
| PositionOpenTime | DWH_dbo.Dim_Position | OpenOccurred | YES | 2 | Timestamp when position was opened |
| InstrumentID | Dealing_staging.etoro_Trade_AdminPositionLog / DWH_dbo.Dim_Position | InstrumentID | NO | 2 | Trading instrument FK |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | YES | 2 | Instrument name (e.g. BTC/USD, SOL/USD) from Dim_Instrument |
| CompensationReasonID | DWH_dbo.Fact_CustomerAction | CompensationReasonID | NO | 2 | Always 134 (Crypto Transfer) for C2P conversions |
| CompensationReason | DWH_dbo.Dim_CompensationReason | Name | YES | 2 | Always "Crypto Transfer" for CompensationReasonID=134 |
| FactActionCompensationOccurred | DWH_dbo.Fact_CustomerAction | Occurred | YES | 2 | Occurred for ActionTypeID=36 (compensation credit) |
| FactActionCompensationAmountUSD | DWH_dbo.Fact_CustomerAction | Amount | YES | 2 | Amount for ActionTypeID=36 (positive USD value credited) |
| FactActionPositionOpenOccurred | DWH_dbo.Fact_CustomerAction | Occurred | YES | 2 | Occurred for ActionTypeID=1 (position open debit) |
| FactActionPositionOpenAmountUSD | DWH_dbo.Fact_CustomerAction | Amount | YES | 2 | Amount for ActionTypeID=1 (negative — debit for position opening) |
| FactActionPositionOpenInitialUnits | DWH_dbo.Fact_CustomerAction | InitialUnits | YES | 2 | Initial units for ActionTypeID=1 (position open) |
| IsAirDrop | DWH_dbo.Fact_CustomerAction | IsAirDrop | YES | 2 | IsAirDrop flag from Fact_CustomerAction where ActionTypeID=1; always 1 for C2P positions |
| Commission | DWH_dbo.Fact_CustomerAction | Commission | YES | 2 | Commission from Fact_CustomerAction where ActionTypeID=1 |
| FullCommission | DWH_dbo.Fact_CustomerAction | FullCommission | YES | 2 | Full commission from Fact_CustomerAction where ActionTypeID=1 |
| IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | NO | 2 | Flag from EXW_DimUser |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | NO | 2 | Point-in-time regulation via Dim_Range date join |
| Regulation | DWH_dbo.Dim_Regulation | Name | YES | 2 | Regulation name lookup |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | NO | 2 | Point-in-time customer country |
| Country | DWH_dbo.Dim_Country | Name | NO | 2 | Country name lookup |
| CustomerRegionID | SP_EXW_C2F_E2E | — | — | 2 | CASE: RegionID for USA only |
| State | SP_EXW_C2F_E2E | — | — | 2 | CASE: Dim_State_and_Province.Name for USA only |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | NO | 2 | Point-in-time validity flag |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | NO | 2 | Point-in-time Client_Balance flag |
| PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | NO | 2 | Point-in-time player level |
| Club | DWH_dbo.Dim_PlayerLevel | Name | YES | 2 | Club name lookup |
| PlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | NO | 2 | Point-in-time player status |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | YES | 2 | Player status name |
| WalletEntity | EXW_dbo.EXW_WalletEntity | WalletEntity | YES | 2 | eToro legal entity |
| AccountManager | DWH_dbo.Dim_Manager | FirstName + LastName | YES | 2 | Concatenated name |
| LabelID | DWH_dbo.Fact_SnapshotCustomer | LabelID | NO | 2 | Customer label from point-in-time snapshot |
| Lable | DWH_dbo.Dim_Label | Name | YES | 2 | Label name (column name has typo: "Lable" not "Label") |
| UpdateDate | SP_EXW_C2F_E2E | — | — | 2 | GETDATE() at SP execution time |
