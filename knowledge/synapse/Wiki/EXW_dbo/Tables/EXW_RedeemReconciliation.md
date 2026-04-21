# EXW_dbo.EXW_RedeemReconciliation

> Incremental reconciliation table for crypto redemption requests, joining the eToro billing system (Billing.Redeem, Billing.Withdraw) with the wallet/blockchain execution side (EXW_FactRedeemTransactions). One row per redemption attempt per position, with `etoro - *` columns sourced from the eToro platform and `Wallet - *` columns sourced from the blockchain wallet system. The two sides are matched on PositionID; the EntryAppears column classifies reconciliation completeness. Covers the full redemption lifecycle from request submission through blockchain send and receive confirmation.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Reconciliation) |
| **Production Sources** | etoro.Billing.Redeem (primary) + etoro.Billing.vWithdrawToFunding + etoro.Billing.Withdraw + EXW_dbo.EXW_FactRedeemTransactions (wallet side) |
| **Writer SP** | EXW_dbo.SP_EXW_RedeemReconciliation |
| **Refresh** | Incremental — daily @date run (LastModificationDate = @date) + 60-day re-run of rows with missing received transactions |
| **Row Count** | Not measured (covers historical redeems with @date windowing) |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_RedeemReconciliation is the primary reconciliation table for crypto redemption events. A redemption is the reverse of a deposit: a customer converts a trading position back into cryptocurrency, which is then sent to their external wallet address. This table reconciles two independent systems that must agree for a successful redemption:

- **eToro platform side** (`etoro - *` columns): The billing and trading system records — what the platform requested, approved, and expected
- **Wallet/blockchain side** (`Wallet - *` columns): The actual blockchain execution — what was sent to the blockchain and what the destination wallet received

The `EntryAppears` column classifies each row as `BothSidesEntry` (both systems have matching records), `OnlyEtoroSideEntry` (eToro has a record but no blockchain send exists — typically early-stage or non-blockchain redeems), or `NoUserReceiveEntry` (blockchain was sent but no received transaction was detected — monitoring the in-flight state).

**Business context**: The SP was authored in 2018 (Guy Manova) and incrementally enhanced through 2024. It processes redeems modified on a specific date (@date parameter) plus rechecks the last 60 days of rows missing received confirmation. The German BaFin (IsGermanBaFin) logic is currently disabled (source query commented out → always 0).

---

## 2. Business Logic

### 2.1 EntryAppears Classification

**What**: EntryAppears classifies the reconciliation completeness of each row.

**Columns/Parameters Involved**: `EntryAppears`, `etoro - RedeemStatus` (RedeemStatusID)

**Rules**:
- `BothSidesEntry`: `wr.PositionID IS NOT NULL` (wallet match exists) AND `RedeemStatusID IN (7,8)` (TransactionInProcess or TransactionDone)
- `OnlyEtoroSideEntry`: No wallet match, or RedeemStatusID NOT IN (7,8)
- `NoUserReceiveEntry` (applied via UPDATE after INSERT): EntryAppears=BothSidesEntry AND `[Wallet - SentAmount] IS NOT NULL` AND `[Wallet - ReceivedAmount] IS NULL` — blockchain send went through but no received transaction detected yet

### 2.2 XBT Unit Normalization (CryptoID=228)

**What**: Bitcoin satoshi amounts are normalized to standard units for XBT (CryptoID=228).

**Columns/Parameters Involved**: `etoro - RedeemAmount`, `etoro - RedeemFee`

**Rules**:
- IF `etoro - CryptoID` = 228 THEN `etoro - RedeemAmount` = Units × 1,000,000; `etoro - RedeemFee` = RedeemFee × 1,000,000
- All other CryptoIDs: values pass through unchanged

### 2.3 Wallet-Side Conditional Population

**What**: All `Wallet - *` columns are NULL unless the eToro redemption status indicates a blockchain transfer was initiated.

**Columns/Parameters Involved**: All `Wallet - *` columns, `etoro - RedeemStatus`

**Rules**:
- Wallet columns populated only when `RedeemStatusID IN (7, 8)` (7=TransactionInProcess, 8=TransactionDone)
- For all other statuses, all Wallet columns are NULL — this indicates OnlyEtoroSideEntry rows

### 2.4 60-Day Re-Run Logic

**What**: Rows with missing received transaction data are periodically reprocessed to catch late-arriving blockchain events.

**Columns/Parameters Involved**: `Wallet - ReceivedTransactionID`, `etoro - RequestDateID`

**Rules**:
- On each daily SP run, positions are added to the re-run set if: `[Wallet - ReceivedTransactionID] IS NULL` AND etoro-RequestDateID > @datecutID (within 60 days) AND blockchain tx is not in SentTransactionReplaces
- ALSO re-run: rows where ReceivedTransactionID IS NOT NULL BUT `[Wallet - RedeemStatus]` = 'Completed' AND `etoro - RedeemStatus` ≠ 'TransactionDone' OR `etoro - CashoutStatus` ≠ 'Processed'
- The DELETE + INSERT pattern removes affected PositionIDs first, then reinsertes with fresh source data

### 2.5 Deduplication

**What**: A position may have multiple Redeem rows (e.g., after re-attempts). The latest wallet-side record is selected.

**Columns/Parameters Involved**: `RedeemID`, `Wallet - RedeemStatus`, `Wallet - ReceivedTransactionID`

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY RedeemID ORDER BY `[Wallet - RedeemStatus]`, `[Wallet - ReceivedTransactionID]` DESC) = 1
- Selects the row with the best Wallet-side RedeemStatus and latest ReceivedTransactionID for each RedeemID

---

## 3. Data Overview

| PositionID | EntryAppears | etoro - RedeemStatus | etoro - RedeemAmount | Wallet - SentAmount | Wallet - ReceivedAmount | etoro - CryptoID | CryptoName |
|---|---|---|---|---|---|---|---|
| 1234567890 | BothSidesEntry | TransactionDone | 0.500000 | 0.499755 | 0.499755 | 4 | XRP |
| 9876543210 | BothSidesEntry | TransactionDone | 0.012500 | 0.012456 | 0.012456 | 2 | BTC |
| 1111111111 | OnlyEtoroSideEntry | PositionPending | 10.000000 | NULL | NULL | 4 | XRP |
| 2222222222 | NoUserReceiveEntry | TransactionDone | 0.250000 | 0.249876 | NULL | 64 | ETH |

Key distribution notes (from SP and data):
- **EntryAppears**: BothSidesEntry (for RedeemStatusID=7,8 with wallet match), OnlyEtoroSideEntry (early/non-blockchain redeems), NoUserReceiveEntry (in-flight or late-confirm)
- **Wallet columns**: NULL for all OnlyEtoroSideEntry rows (RedeemStatusID not in 7,8)
- **IsGermanBaFin**: Always 0 — source query (V_GermanBaFin) is commented out in SP
- **isCFD**: 'Y' for positions found in Dim_Position with IsSettled=0 and recent CloseDateID; 'No' otherwise
- **Re-run window**: Last 60 days of rows with missing received transactions are reprocessed on each run

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | — | VERIFIED | The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID. (Tier 1 — Billing.Redeem) |
| 2 | EntryAppears | varchar(50) | YES | — | VERIFIED | Reconciliation completeness classification. Values: BothSidesEntry (eToro RedeemStatusID IN 7,8 AND wallet match found), OnlyEtoroSideEntry (no wallet match or status not yet at blockchain stage), NoUserReceiveEntry (updated post-insert: blockchain send exists but no received confirmation). (Tier 2 — SP_EXW_RedeemReconciliation) |
| 3 | IsTestAccount | int | YES | — | CODE-BACKED | Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount, joined via RealCID. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 4 | RedeemID | bigint | YES | — | VERIFIED | Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()). (Tier 1 — Billing.Redeem) |
| 5 | etoro - CID | bigint | YES | — | VERIFIED | Customer ID. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request. (Tier 1 — Billing.Redeem) |
| 6 | etoro - RedeemStatus | varchar(50) | YES | — | VERIFIED | Current state in the redemption state machine. FK to Dictionary.RedeemStatus. Transitions validated by Dictionary.RedeemStatusStateMachine in RedeemStatusUpdate. Values: 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New. DWH note: stores the status name from Dictionary.RedeemStatus, not the ID. (Tier 1 — Billing.Redeem) |
| 7 | etoro - RedeemReason | varchar(50) | YES | — | VERIFIED | Reason code for non-success outcomes. FK to Dictionary.RedeemReason. Set by RedeemStatusUpdate when redemption fails or is cancelled. Values: 1=RreTradeBlocked, 2=RreFundingBlocked, 7=RejectedByOps, 8=FailedByTrading, 9=FailedByWallet, 10=CanceledByOps, 11-14=ServerErrors, 15=CanceledByUser, etc. NULL for successfully completed redemptions (status=8). DWH note: stores the reason name from Dictionary.RedeemReason, not the ID. (Tier 1 — Billing.Redeem) |
| 8 | etoro - RedeemAmount | numeric(38,8) | YES | — | VERIFIED | Crypto quantity to redeem (decimal precision for crypto amounts). Set on INSERT via @Units. May be updated to actual closed amount when status=6: `Units = IIF(@RedeemStatusID = 6, ISNULL(@Units, Units), Units)` in RedeemStatusUpdate. DWH note: renamed Units → RedeemAmount; XBT correction for CryptoID=228: value multiplied by 1,000,000. (Tier 1 — Billing.Redeem) |
| 9 | etoro - RedeemFee | numeric(38,8) | YES | — | VERIFIED | eToro platform fee on the redemption. Set on INSERT via @Fee (maps to column RedeemFee). DWH note: XBT correction for CryptoID=228: value multiplied by 1,000,000. (Tier 1 — Billing.Redeem) |
| 10 | etoro - BlockchainFee | numeric(38,8) | YES | — | VERIFIED | On-chain network fee (gas fee) for the blockchain transfer. Populated for Bitcoin (e.g., 0.000256 BTC) and certain other instruments. NULL for instruments where blockchain fees are absorbed or not applicable. (Tier 1 — Billing.Redeem) |
| 11 | etoro - AmountOnRequestUSD | numeric(38,8) | YES | — | VERIFIED | Fiat value of the redemption as calculated when the customer submitted the request. Set on INSERT via @Amount. Reflects the crypto price at request time. May differ from AmountOnClose if price moves before the position closes. (Tier 1 — Billing.Redeem) |
| 12 | eToro - AmountOnCloseUSD | numeric(38,8) | YES | — | VERIFIED | Fiat value realized when the position was actually closed. Set by RedeemStatusUpdate when status transitions to 6 (PositionClosed): `AmountOnClose = IIF(@RedeemStatusID = 6, @Amount, AmountOnClose)`. NULL until PositionClosed state is reached. Note: column name has capital-T typo ("eToro" not "etoro") matching the production DDL. (Tier 1 — Billing.Redeem) |
| 13 | etoro - FundingID | bigint | YES | — | VERIFIED | The payment method funding record. FK to Billing.Funding(FundingID). Indexed (IX_BillingRedeem_FundingID). Identifies which funding method will receive the fiat payout. Set on INSERT. (Tier 1 — Billing.Redeem) |
| 14 | etoro - InstrumentID | bigint | YES | — | VERIFIED | The trading instrument being redeemed. FK to Trade.InstrumentMetaData(InstrumentID). Used by multiple procedures for instrument-specific business logic. (Tier 1 — Billing.Redeem) |
| 15 | etoro - RequestDate | datetime | YES | — | VERIFIED | UTC timestamp when the customer submitted the redemption request. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add. (Tier 1 — Billing.Redeem) |
| 16 | etoro - ModificationDate | datetime | YES | — | VERIFIED | UTC timestamp of the most recent status change or update. Set to GETUTCDATE() on INSERT and updated on every status change by RedeemStatusUpdate. Part of covering index (ix_BillingRedeem_Covering). DWH note: renamed from Billing.Redeem.LastModificationDate. (Tier 1 — Billing.Redeem) |
| 17 | etoro - WithdrawToFundingID | bigint | YES | — | VERIFIED | Link to the withdrawal record. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process. (Tier 1 — Billing.Redeem) |
| 18 | etoro - ManagerOpsID | int | YES | — | VERIFIED | Operations team staff member ID who handled this redemption. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions. (Tier 1 — Billing.Redeem) |
| 19 | etoro - ManagerID | int | YES | — | VERIFIED | Manager staff member ID. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions. (Tier 1 — Billing.Redeem) |
| 20 | etoro - Remark | nvarchar(max) | YES | — | VERIFIED | Free-text note added by operations staff. Set by RedeemStatusUpdate via @Remark. Preserved across updates (ISNULL(@Remark, Remark) pattern). (Tier 1 — Billing.Redeem) |
| 21 | etoro - CryptoID | int | YES | — | VERIFIED | Crypto-wallet-system identifier for the crypto asset. Set on INSERT. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin, 18=another asset) while InstrumentID is the trading system identifier. (Tier 1 — Billing.Redeem) |
| 22 | etoro - WithdrawID | bigint | YES | — | CODE-BACKED | Billing.Withdraw primary key for the withdrawal leg associated with this redemption. Sourced from Billing.vWithdrawToFunding.WithdrawID via the WithdrawToFundingID join. NULL when no withdrawal leg exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 23 | etoro - Amount | numeric(38,8) | YES | — | CODE-BACKED | Withdrawal amount from Billing.vWithdrawToFunding.Amount. Represents the fiat amount in the withdrawal leg. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 24 | etoro - CashoutType | varchar(500) | YES | — | CODE-BACKED | Cashout type name from Dictionary.CashoutType. Lookup from Billing.vWithdrawToFunding.CashoutTypeID. NULL when no WithdrawToFunding record exists or no CashoutType match. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 25 | etoro - ProcessorValueDate | datetime | YES | — | CODE-BACKED | Date when the payment processor credited/debited the funds. From Billing.vWithdrawToFunding.ProcessorValueDate. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 26 | etoro - DepotID | int | YES | — | CODE-BACKED | Depot identifier from Billing.vWithdrawToFunding.DepotID. Identifies the payment depot used for fiat settlement. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 27 | etoro - Approved | int | YES | — | VERIFIED | Whether the withdrawal has received required approval (e.g., compliance/operations sign-off): 1=Approved, 0=Pending approval. DEFAULT=0. Included in covering index for filtered queries. (Tier 1 — Billing.Withdraw) |
| 28 | etoro - CashoutStatus | varchar(50) | YES | — | VERIFIED | Current withdrawal status. FK to Dictionary.CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. DWH note: stores the status name from Dictionary.CashoutStatus, not the ID. NULL when no Billing.Withdraw record exists. (Tier 1 — Billing.Withdraw) |
| 29 | etoro - CashoutReason | varchar(50) | YES | — | VERIFIED | Internal reason code for the withdrawal decision (e.g., why it was cancelled or flagged). References an internal catalog. DWH note: stores the reason name from Dictionary.CashoutReason, not the ID. NULL when no Billing.Withdraw record exists or no reason assigned. (Tier 1 — Billing.Withdraw) |
| 30 | Wallet - CryptoId | int | YES | — | VERIFIED | The cryptocurrency being redeemed. Implicit reference to Wallet.CryptoTypes.CryptoID. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.Redemptions via EXW_FactRedeemTransactions) |
| 31 | Wallet - SendingWalletID | nvarchar(max) | YES | — | VERIFIED | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.SentTransactions via EXW_FactRedeemTransactions) |
| 32 | Wallet - RedeemID | bigint | YES | — | VERIFIED | Auto-incrementing surrogate primary key. Renamed from WalletDB.Wallet.Redemptions.Id. Distribution key for HASH(RedeemID). DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.Redemptions via EXW_FactRedeemTransactions) |
| 33 | Wallet - PositionID | bigint | YES | — | VERIFIED | Trading platform position being redeemed. Unique constraint - each position can only be redeemed once. NULL only for legacy records. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.Redemptions via EXW_FactRedeemTransactions) |
| 34 | Wallet - RequestingGCID | bigint | YES | — | VERIFIED | Global Customer ID of the customer requesting the redemption. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.Redemptions via EXW_FactRedeemTransactions) |
| 35 | Wallet - RequestedAmount | numeric(38,8) | YES | — | VERIFIED | Gross amount of crypto requested for redemption. In native units of CryptoId. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.Redemptions via EXW_FactRedeemTransactions) |
| 36 | Wallet - RedeemStatus | varchar(50) | YES | — | CODE-BACKED | Redemption lifecycle outcome derived from latest RequestStatuses record in EXW_FactRedeemTransactions. Values: Completed (RequestStatusId=1), Error (RequestStatusId=2), Pending (any other status). NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 37 | Wallet - SentTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. Renamed from WalletDB.Wallet.SentTransactions.Id. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.SentTransactions via EXW_FactRedeemTransactions) |
| 38 | Wallet - BlockchainTransactionID | nvarchar(max) | YES | — | VERIFIED | The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). Stored as nvarchar(4000) on insert despite nvarchar(max) DDL type. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.SentTransactions via EXW_FactRedeemTransactions) |
| 39 | Wallet - SenderAddress | nvarchar(512) | YES | — | CODE-BACKED | Blockchain address of the sending wallet (the eToro omnibus/redeem wallet). Sourced from EXW_Wallet.CustomerWalletsView.Address joined on SentTransactions.WalletId. NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 40 | Wallet - ReceiverAddress | nvarchar(512) | YES | — | VERIFIED | Destination blockchain address for this output. Renamed from WalletDB.Wallet.SentTransactionOutputs.ToAddress; filtered by SourceId = PositionId to select the redemption-specific output. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.SentTransactionOutputs via EXW_FactRedeemTransactions) |
| 41 | Wallet - SentAmount | numeric(38,8) | YES | — | VERIFIED | Amount of crypto sent to this output address. Renamed from WalletDB.Wallet.SentTransactionOutputs.Amount; row with highest Amount per SentTransactionId selected via ROW_NUMBER. DWH note: NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.SentTransactionOutputs via EXW_FactRedeemTransactions) |
| 42 | Wallet - SentTXEtoroFees | numeric(38,8) | YES | — | CODE-BACKED | eToro service fee for this redemption. Computed in EXW_FactRedeemTransactions as CAST(EtoroFees × FeeExchangeRate AS NUMERIC(38,8)). NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 43 | Wallet - SentTTXBlockchainFees | numeric(38,8) | YES | — | CODE-BACKED | Network fee allocated to this redemption output. Computed as SentTransactions.BlockchainFee / COUNT(outputs per SentTransactionId). NULL when etoro-RedeemStatusID NOT IN (7,8). Note: column name has double-T typo ("SentTTXBlockchainFees") matching production DDL. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 44 | Wallet - SumAmountInBlockchainTransaction | numeric(38,8) | YES | — | CODE-BACKED | Total sent amount in the blockchain transaction from EXW_FactRedeemTransactions.TotalSentAmountInBCTX. Always NULL — deprecated column retained for schema backward compatibility in EXW_FactRedeemTransactions. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 45 | Wallet - ReceivedTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing primary key of the matching ReceivedTransaction. FK target for Wallet.ReceivedTransactionStatuses. Renamed from WalletDB.Wallet.ReceivedTransactions.Id. NULL if the received transaction has not yet been detected. DWH note: also NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.ReceivedTransactions via EXW_FactRedeemTransactions) |
| 46 | Wallet - ReceivedAmount | numeric(38,8) | YES | — | VERIFIED | Amount of crypto received in native units. NULL for zero-value transactions (e.g., token approvals). Sourced from WalletDB.Wallet.ReceivedTransactions.Amount, matched by BlockchainTransactionId + ReceiverAddress = ReceiveAddress. DWH note: also NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 1 — WalletDB.Wallet.ReceivedTransactions via EXW_FactRedeemTransactions) |
| 47 | Wallet - ReceivedTXBlockchainFees | numeric(38,8) | YES | — | CODE-BACKED | Received blockchain fees from EXW_FactRedeemTransactions.ReceivedBlockchainFees. Always NULL — deprecated column retained for schema backward compatibility. Do not use. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 48 | Wallet - SumReceivedInBCTX - with Dupes | numeric(38,8) | YES | — | CODE-BACKED | Total amount received in the blockchain transaction, including duplicate outputs. Computed as MAX(ReceivedAmount) GROUP BY ReceivedTransactionID in EXW_FactRedeemTransactions. NULL if ReceivedTransactionID is NULL. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 49 | Wallet - CountDupes | int | YES | — | CODE-BACKED | Count of outputs in the received blockchain transaction. Computed as COUNT(ReceivedAmount) GROUP BY ReceivedTransactionID in EXW_FactRedeemTransactions. Used with SumReceivedInBCTX-with-Dupes to compute the deduped value. NULL if ReceivedTransactionID is NULL. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 50 | Wallet - SumReceivedInBCTX - deduped | numeric(38,8) | YES | — | CODE-BACKED | Per-output average received amount (TotalrxAmountInBCTX / CountReceivedTXInBCTX). Represents ReceivedAmount normalized across all outputs of the blockchain tx. NULL if ReceivedTransactionID is NULL. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 51 | Wallet - ReceivedTXAMLStatus | varchar(50) | YES | — | CODE-BACKED | AML (Anti-Money Laundering) provider status for the received transaction. Sourced from EXW_dbo.EXW_FactTransactions.AMLProviderStatus, joined via ReceivedTransactionID = TranID AND ActionTypeID=2. NULL when no received transaction or no AML check result. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 52 | CryptoName | varchar(50) | YES | — | CODE-BACKED | Display name for the crypto asset. Lookup from EXW_dbo.EXW_InternalWallet.CryptoName by etoro-CryptoID. Values: XRP, BTC, ETH, and others. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 53 | UpdateDate | datetime | YES | — | CODE-BACKED | Timestamp of when this row was loaded by SP_EXW_RedeemReconciliation. Set to GETDATE() at insert time. Reflects SP execution time, not redemption time. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 54 | Wallet - EffectiveBlockchainFees | numeric(38,8) | YES | — | CODE-BACKED | Actual blockchain fee charged to the customer after any eToro subsidization. Sourced from EXW_FactRedeemTransactions.EffectiveBlockchainFees (from TransactionsView). May differ from SentTTXBlockchainFees. NULL when etoro-RedeemStatusID NOT IN (7,8). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 55 | etoro - RequestDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from `etoro - RequestDate`. Computed: CAST(CONVERT(VARCHAR(8), RequestDate, 112) AS INT). Used as partition cutoff for the 60-day re-run window check. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 56 | etoro - ModificationDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from `etoro - ModificationDate`. Computed: CAST(CONVERT(VARCHAR(8), LastModificationDate, 112) AS INT). (Tier 2 — SP_EXW_RedeemReconciliation) |
| 57 | isCFD | varchar(10) | YES | — | CODE-BACKED | Indicates whether the redeemed position is a CFD position. Values: 'Y' (PositionID found in DWH_dbo.Dim_Position with IsSettled=0 and CloseDateID >= 10 days before @date), 'No' otherwise. Added 2020-10-14 for CFD project. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 58 | IsGermanBaFin | int | YES | — | CODE-BACKED | German BaFin regulatory indicator. 1 if customer is subject to German BaFin regulation per BI_DB..V_GermanBaFin, else 0. Note: the source query (FROM BI_DB..V_GermanBaFin) is COMMENTED OUT in SP — always returns 0 for all rows. Added 2020-11-24. (Tier 2 — SP_EXW_RedeemReconciliation) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Implicit | Trading position being redeemed (also used for isCFD check) |
| etoro - CID | Customer.CustomerStatic | Implicit | Customer who submitted the redemption |
| etoro - FundingID | Billing.Funding | Implicit | Payment method for fiat payout |
| etoro - InstrumentID | Trade.InstrumentMetaData | Implicit | Trading instrument being redeemed |
| etoro - WithdrawToFundingID | Billing.WithdrawToFunding | Implicit | Withdrawal processing record |
| etoro - CryptoID | EXW_dbo.EXW_InternalWallet | Implicit | Crypto asset (denormalized as CryptoName) |
| Wallet - ReceivedTransactionID | EXW_dbo.EXW_FactTransactions | Implicit | AML status lookup (ActionTypeID=2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EXW_dbo.EXW_V_RedeemReconciliation | — | View | Export/reporting view wrapping this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
EXW_dbo.EXW_RedeemReconciliation (depth=3)
├── BI_DB_dbo.External_etoro_Billing_Redeem → etoro.Billing.Redeem
├── BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding → etoro.Billing.vWithdrawToFunding
├── BI_DB_dbo.External_etoro_Billing_Withdraw → etoro.Billing.Withdraw
├── BI_DB_dbo.External_etoro_Dictionary_* (RedeemStatus, RedeemReason, CashoutStatus, CashoutReason, CashoutType)
├── EXW_dbo.EXW_FactRedeemTransactions (wallet-side join on PositionID)
│     └── WalletDB.Wallet.Redemptions, SentTransactions, SentTransactionOutputs, ReceivedTransactions
├── EXW_Wallet.SentTransactionReplaces (BitGo replacement exclusion)
├── EXW_dbo.EXW_FactTransactions (AMLProviderStatus via ReceivedTransactionID)
├── EXW_dbo.EXW_InternalWallet (CryptoName lookup)
├── EXW_dbo.EXW_DimUser (IsTestAccount via RealCID)
└── DWH_dbo.Dim_Position (isCFD check: IsSettled=0 and recent CloseDateID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BI_DB_dbo.External_etoro_Billing_Redeem | External Table | Primary eToro redemption records |
| BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding | External Table | Withdrawal-to-funding details (Amount, DepotID, etc.) |
| BI_DB_dbo.External_etoro_Billing_Withdraw | External Table | Withdraw record (Approved, CashoutStatusID, CashoutReasonID) |
| BI_DB_dbo.External_etoro_Dictionary_RedeemStatus | External Table | Lookup name for RedeemStatusID |
| BI_DB_dbo.External_etoro_Dictionary_RedeemReason | External Table | Lookup name for RedeemReasonID |
| BI_DB_dbo.External_etoro_Dictionary_CashoutStatus | External Table | Lookup name for CashoutStatusID |
| BI_DB_dbo.External_etoro_Dictionary_CashoutReason | External Table | Lookup name for CashoutReasonID |
| BI_DB_dbo.External_etoro_Dictionary_CashoutType | External Table | Lookup CashoutTypeName |
| EXW_dbo.EXW_FactRedeemTransactions | Table | Wallet-side redemption execution (sent/received tx, amounts, fees) |
| EXW_Wallet.SentTransactionReplaces | External Table | BitGo replacement detection |
| EXW_dbo.EXW_FactTransactions | Table | AMLProviderStatus for received transactions |
| EXW_dbo.EXW_InternalWallet | Table | CryptoName lookup by CryptoId |
| EXW_dbo.EXW_DimUser | Table | IsTestAccount via RealCID |
| DWH_dbo.Dim_Position | Table | isCFD classification (IsSettled, CloseDateID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EXW_dbo.EXW_V_RedeemReconciliation | View | Export wrapper for BI/reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (heap) | HEAP | — | — | — | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DISTRIBUTION | HASH | HASH(PositionID) — routes rows by trading position |

### 7.3 ETL Notes

SP_EXW_RedeemReconciliation is called with @date DATE parameter. It processes:
1. All Billing.Redeem rows with LastModificationDate = @date (daily window)
2. Re-run: existing EXW_RedeemReconciliation rows within last 60 days where ReceivedTransactionID IS NULL (or both-sides row with status mismatch)
3. The SP uses DELETE + INSERT (not MERGE), first removing PositionIDs in scope, then reinserting
4. A final UPDATE marks BothSidesEntry rows with SentAmount but no ReceivedAmount as NoUserReceiveEntry

### 7.4 Known Issues / Gotchas

- **IsGermanBaFin always 0**: The query populating #GermanBafin is commented out. Column is currently non-functional.
- **`eToro - AmountOnCloseUSD` capital-T typo**: This column name differs from all other `etoro - *` columns (capital "T" in eToro). This is a production DDL typo — must be quoted exactly as `[eToro - AmountOnCloseUSD]` in queries.
- **`Wallet - SentTTXBlockchainFees` double-T typo**: Production DDL has "SentTTX" instead of "SentTX". Quote as `[Wallet - SentTTXBlockchainFees]`.
- **Column names with spaces**: All `etoro - *` and `Wallet - *` columns require bracket quoting.
- **`Wallet - SumAmountInBlockchainTransaction` always NULL**: Source column (TotalSentAmountInBCTX) is deprecated and always NULL in EXW_FactRedeemTransactions.
- **`Wallet - ReceivedTXBlockchainFees` always NULL**: Source column (ReceivedBlockchainFees) is deprecated.

---

## 8. Sample Queries

### 8.1 Reconciliation status summary
```sql
SELECT EntryAppears, COUNT(1) cnt
FROM EXW_dbo.EXW_RedeemReconciliation
WHERE IsTestAccount = 0
GROUP BY EntryAppears
ORDER BY cnt DESC
```

### 8.2 Amount discrepancy check (sent vs received)
```sql
SELECT PositionID, [etoro - CID], CryptoName,
    [Wallet - SentAmount], [Wallet - ReceivedAmount],
    [Wallet - SentAmount] - [Wallet - ReceivedAmount] AS AmountDiff,
    [etoro - RequestDate], EntryAppears
FROM EXW_dbo.EXW_RedeemReconciliation
WHERE EntryAppears = 'BothSidesEntry'
    AND [Wallet - ReceivedAmount] IS NOT NULL
    AND ABS(CAST([Wallet - SentAmount] AS FLOAT) - CAST([Wallet - ReceivedAmount] AS FLOAT)) > 0.000001
ORDER BY AmountDiff DESC
```

### 8.3 NoUserReceiveEntry rows needing follow-up
```sql
SELECT PositionID, [etoro - CID], CryptoName,
    [Wallet - BlockchainTransactionID],
    [Wallet - SentAmount], [Wallet - ReceivedAmount],
    [etoro - RequestDate], [etoro - ModificationDate]
FROM EXW_dbo.EXW_RedeemReconciliation
WHERE EntryAppears = 'NoUserReceiveEntry'
    AND IsTestAccount = 0
ORDER BY [etoro - ModificationDate] DESC
```

### 8.4 CFD vs non-CFD redemption summary
```sql
SELECT isCFD, CryptoName, COUNT(1) cnt,
    SUM(CAST([etoro - AmountOnCloseUSD] AS FLOAT)) total_usd
FROM EXW_dbo.EXW_RedeemReconciliation
WHERE [etoro - RedeemStatus] = 'TransactionDone'
    AND IsTestAccount = 0
GROUP BY isCFD, CryptoName
ORDER BY total_usd DESC
```

---
