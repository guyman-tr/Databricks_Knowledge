---
object: EXW_dbo.EXW_RedeemReconciliation
type: Table
schema: EXW_dbo
uc_target: _Not_Migrated
writer_sp: EXW_dbo.SP_EXW_RedeemReconciliation
load_pattern: INCREMENTAL (DELETE matching PositionIDs + INSERT; daily for @date window + 60-day re-run of incomplete rows)
primary_sources:
  - etoro.Billing.Redeem (via BI_DB_dbo.External_etoro_Billing_Redeem)
  - etoro.Billing.vWithdrawToFunding (via BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding)
  - etoro.Billing.Withdraw (via BI_DB_dbo.External_etoro_Billing_Withdraw)
secondary_sources:
  - EXW_dbo.EXW_FactRedeemTransactions (wallet-side join on PositionID)
  - EXW_Wallet.SentTransactionReplaces (BitGo replacement exclusion)
  - EXW_dbo.EXW_FactTransactions (AMLProviderStatus for ReceivedTXAMLStatus)
  - EXW_dbo.EXW_InternalWallet (CryptoName lookup by CryptoId)
  - EXW_dbo.EXW_DimUser (IsTestAccount via RealCID)
  - DWH_dbo.Dim_Position (isCFD: IsSettled=0 check)
  - BI_DB_dbo.External_etoro_Dictionary_* (RedeemStatus, RedeemReason, CashoutStatus, CashoutReason, CashoutType)
  - BI_DB_dbo.V_GermanBaFin (IsGermanBaFin — currently COMMENTED OUT, always 0)
tier1_count: 34
tier2_count: 24
total_columns: 58
---

# Column Lineage — EXW_dbo.EXW_RedeemReconciliation

## Source Objects

| Source | Database | Repo | Path |
|--------|----------|------|------|
| Billing.Redeem | etoro | DB_Schema | etoro/Wiki/Billing/Tables/Billing.Redeem.md |
| Billing.Withdraw | etoro | DB_Schema | etoro/Wiki/Billing/Tables/Billing.Withdraw.md |
| EXW_FactRedeemTransactions | EXW_dbo | Databricks_Knowledge | knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactRedeemTransactions.md |

## Column Source Map

| DWH Column | Source Table | Source Column | Rename | Tier | Transformation |
|-----------|-------------|---------------|--------|------|----------------|
| PositionID | Billing.Redeem | PositionID | NO | 1 | Passthrough |
| EntryAppears | SP_EXW_RedeemReconciliation | — | — | 2 | CASE: 'BothSidesEntry' (wr.PositionID not null AND RedeemStatusID IN 7,8), 'OnlyEtoroSideEntry'; then UPDATE to 'NoUserReceiveEntry' for BothSides without received amount |
| IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | NO | 2 | Lookup via RealCID join |
| RedeemID | Billing.Redeem | RedeemID | NO | 1 | Passthrough |
| etoro - CID | Billing.Redeem | CID | YES | 1 | Passthrough |
| etoro - RedeemStatus | Billing.Redeem / Dictionary.RedeemStatus | RedeemStatusID / Name | YES | 1 | Lookup name; values: PositionPending, Rejected, Approved, ReadyToRedeem, PositionClosing, PositionClosed, TransactionInProcess, TransactionDone, Terminated |
| etoro - RedeemReason | Billing.Redeem / Dictionary.RedeemReason | RedeemReasonID / Name | YES | 1 | Lookup name; NULL for completed redeems |
| etoro - RedeemAmount | Billing.Redeem | Units | YES | 1 | Passthrough with XBT correction: IF CryptoID=228 THEN Units * 1,000,000 ELSE Units |
| etoro - RedeemFee | Billing.Redeem | RedeemFee | YES | 1 | Passthrough with XBT correction: IF CryptoID=228 THEN RedeemFee * 1,000,000 ELSE RedeemFee |
| etoro - BlockchainFee | Billing.Redeem | BlockchainFee | YES | 1 | Passthrough |
| etoro - AmountOnRequestUSD | Billing.Redeem | AmountOnRequest | YES | 1 | Passthrough (renamed) |
| eToro - AmountOnCloseUSD | Billing.Redeem | AmountOnClose | YES | 1 | Passthrough (renamed; column name has capital T typo matching DDL) |
| etoro - FundingID | Billing.Redeem | FundingID | YES | 1 | Passthrough |
| etoro - InstrumentID | Billing.Redeem | InstrumentID | YES | 1 | Passthrough |
| etoro - RequestDate | Billing.Redeem | RequestDate | YES | 1 | Passthrough |
| etoro - ModificationDate | Billing.Redeem | LastModificationDate | YES | 1 | Passthrough (renamed) |
| etoro - WithdrawToFundingID | Billing.Redeem | WithdrawToFundingID | YES | 1 | Passthrough |
| etoro - ManagerOpsID | Billing.Redeem | ManagerOpsID | YES | 1 | Passthrough |
| etoro - ManagerID | Billing.Redeem | ManagerID | YES | 1 | Passthrough |
| etoro - Remark | Billing.Redeem | Remark | YES | 1 | Passthrough |
| etoro - CryptoID | Billing.Redeem | CryptoID | YES | 1 | Passthrough |
| etoro - WithdrawID | Billing.vWithdrawToFunding | WithdrawID | YES | 2 | Passthrough from WithdrawToFunding view (no upstream wiki) |
| etoro - Amount | Billing.vWithdrawToFunding | Amount | YES | 2 | Passthrough from WithdrawToFunding view |
| etoro - CashoutType | Dictionary.CashoutType | CashoutTypeName | YES | 2 | Lookup name |
| etoro - ProcessorValueDate | Billing.vWithdrawToFunding | ProcessorValueDate | YES | 2 | Passthrough from WithdrawToFunding view |
| etoro - DepotID | Billing.vWithdrawToFunding | DepotID | YES | 2 | Passthrough from WithdrawToFunding view |
| etoro - Approved | Billing.Withdraw | Approved | YES | 1 | Passthrough |
| etoro - CashoutStatus | Billing.Withdraw / Dictionary.CashoutStatus | CashoutStatusID / Name | YES | 1 | Lookup name from Dictionary.CashoutStatus |
| etoro - CashoutReason | Billing.Withdraw / Dictionary.CashoutReason | CashoutReasonID / Name | YES | 1 | Lookup name from Dictionary.CashoutReason |
| Wallet - CryptoId | EXW_FactRedeemTransactions | CryptoId | NO | 1 | Passthrough from EXW_FactRedeemTransactions (conditional: NULL if RedeemStatusID NOT IN 7,8) |
| Wallet - SendingWalletID | EXW_FactRedeemTransactions | SendingWalletID | NO | 1 | Passthrough (conditional) |
| Wallet - RedeemID | EXW_FactRedeemTransactions | RedeemID | NO | 1 | Passthrough (conditional) |
| Wallet - PositionID | EXW_FactRedeemTransactions | PositionID | NO | 1 | Passthrough (conditional) |
| Wallet - RequestingGCID | EXW_FactRedeemTransactions | RequestingGcid | YES | 1 | Passthrough (conditional) |
| Wallet - RequestedAmount | EXW_FactRedeemTransactions | RequestedAmount | NO | 1 | Passthrough (conditional) |
| Wallet - RedeemStatus | EXW_FactRedeemTransactions | FinalRedeemStatus | NO | 2 | Passthrough (conditional); FinalRedeemStatus is SP-derived in EXW_FactRedeemTransactions |
| Wallet - SentTransactionID | EXW_FactRedeemTransactions | SentTransactionID | NO | 1 | Passthrough (conditional) |
| Wallet - BlockchainTransactionID | EXW_FactRedeemTransactions | BlockchainTransactionID | NO | 1 | Passthrough (conditional) |
| Wallet - SenderAddress | EXW_FactRedeemTransactions | SendingAddress | YES | 2 | Passthrough (conditional); T2 in EXW_FactRedeemTransactions |
| Wallet - ReceiverAddress | EXW_FactRedeemTransactions | ReceiveAddress | YES | 1 | Passthrough (conditional); T1 from WalletDB.Wallet.SentTransactionOutputs |
| Wallet - SentAmount | EXW_FactRedeemTransactions | SentAmount | NO | 1 | Passthrough (conditional) |
| Wallet - SentTXEtoroFees | EXW_FactRedeemTransactions | SentEtoroFees | YES | 2 | Passthrough (conditional); T2 in EXW_FactRedeemTransactions |
| Wallet - SentTTXBlockchainFees | EXW_FactRedeemTransactions | SentBlockchainFees | YES | 2 | Passthrough (conditional; column name has double T typo in DDL: SentTTXBlockchainFees) |
| Wallet - SumAmountInBlockchainTransaction | EXW_FactRedeemTransactions | TotalSentAmountInBCTX | YES | 2 | Passthrough (conditional); always NULL in source |
| Wallet - ReceivedTransactionID | EXW_FactRedeemTransactions | ReceivedTransactionID | NO | 1 | Passthrough (conditional) |
| Wallet - ReceivedAmount | EXW_FactRedeemTransactions | ReceivedAmount | NO | 1 | Passthrough (conditional) |
| Wallet - ReceivedTXBlockchainFees | EXW_FactRedeemTransactions | ReceivedBlockchainFees | YES | 2 | Passthrough (conditional); always NULL in source (deprecated) |
| Wallet - SumReceivedInBCTX - with Dupes | EXW_FactRedeemTransactions | TotalrxAmountInBCTX | YES | 2 | Passthrough (conditional) |
| Wallet - CountDupes | EXW_FactRedeemTransactions | CountReceivedTXInBCTX | YES | 2 | Passthrough (conditional) |
| Wallet - SumReceivedInBCTX - deduped | EXW_FactRedeemTransactions | ReceivedInAllTXTable | YES | 2 | Passthrough (conditional) |
| Wallet - ReceivedTXAMLStatus | EXW_FactTransactions | AMLProviderStatus | YES | 2 | Lookup via ReceivedTransactionID = TranID AND ActionTypeID=2 |
| CryptoName | EXW_dbo.EXW_InternalWallet | CryptoName | NO | 2 | Lookup by CryptoId |
| UpdateDate | SP_EXW_RedeemReconciliation | — | — | 2 | GETDATE() at SP execution time |
| Wallet - EffectiveBlockchainFees | EXW_FactRedeemTransactions | EffectiveBlockchainFees | YES | 2 | Passthrough (conditional); T2 in EXW_FactRedeemTransactions |
| etoro - RequestDateID | SP_EXW_RedeemReconciliation | — | — | 2 | CAST(CONVERT(VARCHAR(8), RequestDate, 112) AS INT) |
| etoro - ModificationDateID | SP_EXW_RedeemReconciliation | — | — | 2 | CAST(CONVERT(VARCHAR(8), LastModificationDate, 112) AS INT) |
| isCFD | DWH_dbo.Dim_Position | PositionID | — | 2 | 'Y' if PositionID found in Dim_Position with IsSettled=0 and CloseDateID >= @dateend, else 'No' |
| IsGermanBaFin | BI_DB_dbo.V_GermanBaFin | CID | — | 2 | 1 if CID in GermanBafin set, else 0; source query currently commented out → always 0 |
