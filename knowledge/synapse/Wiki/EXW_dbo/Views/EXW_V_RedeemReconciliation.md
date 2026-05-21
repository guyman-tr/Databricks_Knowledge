# EXW_dbo.EXW_V_RedeemReconciliation

> Analyst-facing view of completed crypto redemptions. Wraps EXW_dbo.EXW_RedeemReconciliation with two filters — `EntryAppears = 'BothSidesEntry'` and `[etoro - RedeemStatus] = 'TransactionDone'` — to surface only fully reconciled, blockchain-confirmed redemptions. Renames all `etoro - *` and `Wallet - *` prefixed columns to clean camelCase names and drops 7 deprecated or always-NULL wallet analytics columns. Preferred entry point for BI reports and operational dashboards on redemption activity.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | View |
| **Base Table** | EXW_dbo.EXW_RedeemReconciliation |
| **Writer SP** | N/A (read-only view) |
| **Refresh** | Derived from SP_EXW_RedeemReconciliation (same schedule as base table) |
| **Row Count** | 1,117,023 (as of 2026-04-11) |
| **Synapse Distribution** | N/A (view) |
| **Synapse Index** | N/A (view) |
| **UC Target** | `wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_V_RedeemReconciliation is the production BI view for completed crypto redemption reconciliation. It projects a clean, analyst-friendly lens over EXW_RedeemReconciliation by applying two filters that together guarantee the view only contains fully processed redemptions:

- **`EntryAppears = 'BothSidesEntry'`**: Both the eToro billing system and the blockchain wallet system have matching records for the position. Rows where only the eToro side has data (request submitted but not yet blockchain-confirmed) are excluded.
- **`[etoro - RedeemStatus] = 'TransactionDone'`**: The eToro platform has marked the redemption as fully complete (status 8). In-progress (TransactionInProcess) and non-terminal states are excluded.

These two filters together mean every row in this view represents a redemption where both sides agree: eToro says done, and the blockchain has a matching sent transaction record.

The view also cleans up the column surface:
- All `etoro - *` prefix columns are renamed to camelCase (`CID`, `CryptoID`, `EtoroRedeemStatus`, etc.)
- All `Wallet - *` prefix columns are renamed to camelCase (`WalletSendingWalletID`, `WalletRedeemID`, etc.)
- 7 deprecated or always-NULL wallet analytics columns are excluded (see Section 2.2)

Since the filter guarantees `RedeemStatus = 'TransactionDone'` (status 8), all `Wallet*` columns in this view are always populated — the "NULL when etoro-RedeemStatusID NOT IN (7,8)" caveat from the base table does not apply here. `WalletReceivedTransactionID` and `WalletReceivedAmount` can still be NULL if the blockchain receive event has not yet been detected, but all Wallet transaction identity columns will be non-NULL.

**Use this view** (not the base table) for:
- Reporting on completed redemptions (regulatory, ops, finance)
- Sent vs received amount reconciliation
- Blockchain fee analysis
- Customer redemption history

---

## 2. Business Logic

### 2.1 View Filter: Completed Redemptions Only

**What**: The view applies two WHERE conditions to restrict to fully completed, reconciled redemptions.

**Rules**:
- `EntryAppears = 'BothSidesEntry'`: Wallet match exists AND eToro RedeemStatusID IN (7,8)
- `[etoro - RedeemStatus] = 'TransactionDone'`: Status = 8 (terminal success state)

**Effect**: All rows are completed redemptions where both the billing and blockchain systems are aligned. Out of the full base table population, this view captures the ~1.1M fully processed rows (excluding OnlyEtoroSideEntry, NoUserReceiveEntry, and non-TransactionDone statuses).

### 2.2 Excluded Columns (7 cols dropped vs. base table)

| Excluded Base Column | Reason |
|---------------------|--------|
| `[Wallet - CryptoId]` | Redundant with `CryptoID` (etoro-side) and `CryptoName`; added unnecessary duplication |
| `[Wallet - SumAmountInBlockchainTransaction]` | Always NULL — source column `TotalSentAmountInBCTX` deprecated in EXW_FactRedeemTransactions |
| `[Wallet - ReceivedTXBlockchainFees]` | Always NULL — source column `ReceivedBlockchainFees` deprecated |
| `[Wallet - SumReceivedInBCTX - with Dupes]` | Internal dedup diagnostic; not relevant for completed-redemption reporting |
| `[Wallet - CountDupes]` | Internal dedup diagnostic — use `WalletReceivedAmount` directly |
| `[Wallet - SumReceivedInBCTX - deduped]` | Internal dedup diagnostic — use `WalletReceivedAmount` directly |
| `[Wallet - ReceivedTXAMLStatus]` | AML status diagnostic — excluded from analyst surface; query base table directly if needed |

### 2.3 Column Rename Convention

All 51 view columns are pass-through renames — no computation occurs in the view.

| Rename Pattern | Base Table Pattern | View Pattern | Example |
|---------------|-------------------|-------------|---------|
| etoro-prefixed | `[etoro - CID]` | `CID` | CID, CryptoID, EtoroRedeemStatus |
| Wallet-prefixed | `[Wallet - SendingWalletID]` | `WalletSendingWalletID` | WalletRedeemID, WalletSentAmount |
| No-prefix columns | `PositionID`, `CryptoName` | unchanged | PositionID, UpdateDate |

---

## 3. Data Overview

Representative sample (all rows are BothSidesEntry + TransactionDone):

| PositionID | CID | CryptoName | EtoroRedeemAmount | WalletSentAmount | WalletReceivedAmount | RequestDate | ModificationDate |
|---|---|---|---|---|---|---|---|
| 1234567890 | 123456 | XRP | 0.500000 | 0.499755 | 0.499755 | 2024-03-10 | 2024-03-11 |
| 9876543210 | 654321 | BTC | 0.012500 | 0.012456 | 0.012456 | 2024-11-01 | 2024-11-02 |
| 1122334455 | 112233 | ETH | 1.000000 | 0.999600 | 0.999600 | 2025-06-15 | 2025-06-16 |

Key distribution notes:
- **EtoroRedeemStatus**: Always `'TransactionDone'` (view filter)
- **EntryAppears**: Always `'BothSidesEntry'` (view filter)
- **Wallet columns**: All non-NULL except `WalletReceivedTransactionID` / `WalletReceivedAmount` (may be NULL if blockchain receive detection is pending)
- **IsGermanBaFin**: Always 0 — source query commented out in SP (see base table Known Issues)
- **IsCFD**: 'Y' or 'No' — see base table isCFD logic
- **Total rows**: 1,117,023 as of 2026-04-11

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | — | VERIFIED | The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID. (Tier 1 — Billing.Redeem) |
| 2 | EntryAppears | varchar(50) | YES | — | VERIFIED | Reconciliation completeness classification. Always `'BothSidesEntry'` in this view (filter applied). Base table values: BothSidesEntry (eToro RedeemStatusID IN 7,8 AND wallet match found), OnlyEtoroSideEntry, NoUserReceiveEntry. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 3 | IsTestAccount | int | YES | — | CODE-BACKED | Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount, joined via RealCID. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 4 | RedeemID | bigint | YES | — | VERIFIED | Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()). (Tier 1 — Billing.Redeem) |
| 5 | CID | bigint | YES | — | VERIFIED | Customer ID. Renamed from `[etoro - CID]`. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request. (Tier 1 — Billing.Redeem) |
| 6 | GCID | bigint | YES | — | VERIFIED | Global Customer ID of the customer requesting the redemption. Renamed from `[Wallet - RequestingGCID]`. Always populated in this view (TransactionDone filter guarantees wallet-side data). (Tier 1 — WalletDB.Wallet.Redemptions) |
| 7 | CryptoName | varchar(50) | YES | — | CODE-BACKED | Display name for the crypto asset. Lookup from EXW_dbo.EXW_InternalWallet.CryptoName by etoro-CryptoID. Values: XRP, BTC, ETH, and others. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 8 | CryptoID | int | YES | — | VERIFIED | Crypto-wallet-system identifier for the crypto asset. Renamed from `[etoro - CryptoID]`. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin) while InstrumentID is the trading system identifier. (Tier 1 — Billing.Redeem) |
| 9 | EtoroRedeemStatus | varchar(50) | YES | — | VERIFIED | Current state in the redemption state machine. Renamed from `[etoro - RedeemStatus]`. Always `'TransactionDone'` in this view (filter applied). FK to Dictionary.RedeemStatus in source. (Tier 1 — Billing.Redeem) |
| 10 | EtoroRedeemReason | varchar(50) | YES | — | VERIFIED | Reason code for non-success outcomes. Renamed from `[etoro - RedeemReason]`. FK to Dictionary.RedeemReason. NULL for successfully completed redemptions (which is the only case present in this view, but the column can still be NULL). (Tier 1 — Billing.Redeem) |
| 11 | EtoroRedeemAmount | numeric(38,8) | YES | — | VERIFIED | Crypto quantity to redeem (decimal precision for crypto amounts). Renamed from `[etoro - RedeemAmount]`. XBT correction for CryptoID=228: value multiplied by 1,000,000 in base table SP. (Tier 1 — Billing.Redeem) |
| 12 | EtoroRedeemFee | numeric(38,8) | YES | — | VERIFIED | eToro platform fee on the redemption. Renamed from `[etoro - RedeemFee]`. XBT correction for CryptoID=228: value multiplied by 1,000,000. (Tier 1 — Billing.Redeem) |
| 13 | EtoroBlockchainFee | numeric(38,8) | YES | — | VERIFIED | On-chain network fee (gas fee) for the blockchain transfer. Renamed from `[etoro - BlockchainFee]`. Populated for Bitcoin and certain other instruments; NULL where blockchain fees are absorbed or not applicable. (Tier 1 — Billing.Redeem) |
| 14 | EtoroAmountOnRequestUSD | numeric(38,8) | YES | — | VERIFIED | Fiat value of the redemption as calculated when the customer submitted the request. Renamed from `[etoro - AmountOnRequestUSD]`. Reflects the crypto price at request time. May differ from EtoroAmountOnCloseUSD if price moved before position closed. (Tier 1 — Billing.Redeem) |
| 15 | EtoroAmountOnCloseUSD | numeric(38,8) | YES | — | VERIFIED | Fiat value realized when the position was actually closed. Renamed from `[eToro - AmountOnCloseUSD]` (note capital-T in base table column name). Set when status transitions to PositionClosed (6). (Tier 1 — Billing.Redeem) |
| 16 | FundingID | bigint | YES | — | VERIFIED | The payment method funding record. Renamed from `[etoro - FundingID]`. FK to Billing.Funding(FundingID). Identifies which funding method will receive the fiat payout. (Tier 1 — Billing.Redeem) |
| 17 | InstrumentID | bigint | YES | — | VERIFIED | The trading instrument being redeemed. Renamed from `[etoro - InstrumentID]`. FK to Trade.InstrumentMetaData(InstrumentID). (Tier 2 — Billing.Redeem) |
| 18 | RequestDate | datetime | YES | — | VERIFIED | UTC timestamp when the customer submitted the redemption request. Renamed from `[etoro - RequestDate]`. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add. (Tier 1 — Billing.Redeem) |
| 19 | ModificationDate | datetime | YES | — | VERIFIED | UTC timestamp of the most recent status change or update. Renamed from `[etoro - ModificationDate]`. Updated on every status change by RedeemStatusUpdate. (Tier 1 — Billing.Redeem) |
| 20 | RequestDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from `etoro - RequestDate`. Renamed from `[etoro - RequestDateID]`. Computed: CAST(CONVERT(VARCHAR(8), RequestDate, 112) AS INT). Used for partition-windowed 60-day re-run in SP. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 21 | ModificationDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from `etoro - ModificationDate`. Renamed from `[etoro - ModificationDateID]`. Computed: CAST(CONVERT(VARCHAR(8), LastModificationDate, 112) AS INT). (Tier 2 — SP_EXW_RedeemReconciliation) |
| 22 | WithdrawToFundingID | bigint | YES | — | VERIFIED | Link to the withdrawal record. Renamed from `[etoro - WithdrawToFundingID]`. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process. (Tier 1 — Billing.Redeem) |
| 23 | WithdrawID | bigint | YES | — | CODE-BACKED | Billing.Withdraw primary key for the withdrawal leg. Renamed from `[etoro - WithdrawID]`. Sourced from Billing.vWithdrawToFunding.WithdrawID via WithdrawToFundingID join. NULL when no withdrawal leg exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 24 | EtoroAmount | numeric(38,8) | YES | — | CODE-BACKED | Withdrawal amount from Billing.vWithdrawToFunding.Amount. Renamed from `[etoro - Amount]`. Represents the fiat amount in the withdrawal leg. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 25 | EtoroCashoutType | varchar(500) | YES | — | CODE-BACKED | Cashout type name from Dictionary.CashoutType. Renamed from `[etoro - CashoutType]`. Lookup via Billing.vWithdrawToFunding.CashoutTypeID. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 26 | EtoroProcessorValueDate | datetime | YES | — | CODE-BACKED | Date when the payment processor credited/debited the funds. Renamed from `[etoro - ProcessorValueDate]`. From Billing.vWithdrawToFunding.ProcessorValueDate. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 27 | EtoroDepotID | int | YES | — | CODE-BACKED | Depot identifier from Billing.vWithdrawToFunding.DepotID. Renamed from `[etoro - DepotID]`. Identifies the payment depot used for fiat settlement. NULL when no WithdrawToFunding record exists. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 28 | EtoroApproved | int | YES | — | VERIFIED | Whether the withdrawal has received required approval: 1=Approved, 0=Pending approval. Renamed from `[etoro - Approved]`. DEFAULT=0. (Tier 1 — Billing.Withdraw) |
| 29 | EtoroCashoutStatus | varchar(50) | YES | — | VERIFIED | Current withdrawal status. Renamed from `[etoro - CashoutStatus]`. FK to Dictionary.CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. NULL when no Billing.Withdraw record exists. (Tier 1 — Billing.Withdraw) |
| 30 | EtoroCashoutReason | varchar(50) | YES | — | VERIFIED | Internal reason code for the withdrawal decision. Renamed from `[etoro - CashoutReason]`. References Dictionary.CashoutReason catalog. NULL when no Billing.Withdraw record exists or no reason assigned. (Tier 1 — Billing.Withdraw) |
| 31 | WalletSendingWalletID | nvarchar(max) | YES | — | VERIFIED | The source wallet this transaction was sent from. Renamed from `[Wallet - SendingWalletID]`. FK to Wallet.Wallets.WalletId. For redemptions, this is the system's omnibus/redeem wallet. Always populated in this view. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 32 | WalletRedeemID | bigint | YES | — | VERIFIED | Auto-incrementing surrogate PK from WalletDB.Wallet.Redemptions. Renamed from `[Wallet - RedeemID]`. Distribution key HASH(RedeemID) in EXW_FactRedeemTransactions. Always populated in this view. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 33 | WalletPositionID | bigint | YES | — | VERIFIED | Trading platform position being redeemed. Renamed from `[Wallet - PositionID]`. Unique constraint — each position can only be redeemed once. Always populated in this view. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 34 | WalletRequestedAmount | numeric(38,8) | YES | — | VERIFIED | Gross amount of crypto requested for redemption in native units of CryptoId. Renamed from `[Wallet - RequestedAmount]`. Always populated in this view. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 35 | WalletRedeemStatus | varchar(50) | YES | — | CODE-BACKED | Redemption lifecycle outcome derived from latest RequestStatuses record. Renamed from `[Wallet - RedeemStatus]`. Values: Completed (RequestStatusId=1), Error (RequestStatusId=2), Pending (any other status). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 36 | WalletSentTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing PK from WalletDB.Wallet.SentTransactions. Renamed from `[Wallet - SentTransactionID]`. FK target for SentTransactionStatuses, SentTransactionOutputs, SentTransactionReplaces. Always populated in this view. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 37 | WalletBlockchainTransactionID | nvarchar(max) | YES | — | VERIFIED | The on-chain transaction hash/ID. Renamed from `[Wallet - BlockchainTransactionID]`. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). Can be looked up on blockchain explorers. Always populated in this view. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 38 | WalletSenderAddress | nvarchar(512) | YES | — | CODE-BACKED | Blockchain address of the sending wallet (the eToro omnibus/redeem wallet). Renamed from `[Wallet - SenderAddress]`. Sourced from EXW_Wallet.CustomerWalletsView.Address joined on SentTransactions.WalletId. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 39 | WalletReceiverAddress | nvarchar(512) | YES | — | VERIFIED | Destination blockchain address for this output. Renamed from `[Wallet - ReceiverAddress]`. Filtered by SourceId = PositionId to select the redemption-specific output. Always populated in this view. (Tier 1 — WalletDB.Wallet.SentTransactionOutputs) |
| 40 | WalletSentAmount | numeric(38,8) | YES | — | VERIFIED | Amount of crypto sent to this output address. Renamed from `[Wallet - SentAmount]`. Row with highest Amount per SentTransactionId selected via ROW_NUMBER. Always populated in this view. (Tier 1 — WalletDB.Wallet.SentTransactionOutputs) |
| 41 | WalletSentTXEtoroFees | numeric(38,8) | YES | — | CODE-BACKED | eToro service fee for this redemption. Renamed from `[Wallet - SentTXEtoroFees]`. Computed as CAST(EtoroFees × FeeExchangeRate AS NUMERIC(38,8)) in EXW_FactRedeemTransactions. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 42 | WalletSentTTXBlockchainFees | numeric(38,8) | YES | — | CODE-BACKED | Network fee allocated to this redemption output. Renamed from `[Wallet - SentTTXBlockchainFees]` (double-T typo preserved from production DDL). Computed as SentTransactions.BlockchainFee / COUNT(outputs per SentTransactionId). (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 43 | WalletReceivedTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing PK of the matching ReceivedTransaction. Renamed from `[Wallet - ReceivedTransactionID]`. FK target for ReceivedTransactionStatuses. NULL if the received transaction has not yet been detected (can happen even for TransactionDone rows). (Tier 1 — WalletDB.Wallet.ReceivedTransactions) |
| 44 | WalletReceivedAmount | numeric(38,8) | YES | — | VERIFIED | Amount of crypto received in native units. Renamed from `[Wallet - ReceivedAmount]`. NULL for zero-value transactions or if received transaction not yet detected. Sourced from WalletDB.Wallet.ReceivedTransactions.Amount, matched by BlockchainTransactionId + ReceiverAddress. (Tier 1 — WalletDB.Wallet.ReceivedTransactions) |
| 45 | WalletEffectiveBlockchainFees | numeric(38,8) | YES | — | CODE-BACKED | Actual blockchain fee charged to the customer after any eToro subsidization. Renamed from `[Wallet - EffectiveBlockchainFees]`. Sourced from EXW_FactRedeemTransactions.EffectiveBlockchainFees. May differ from WalletSentTTXBlockchainFees. (Tier 2 — SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions) |
| 46 | IsCFD | varchar(10) | YES | — | CODE-BACKED | Whether the redeemed position is a CFD position. Renamed from `isCFD`. Values: 'Y' (PositionID found in DWH_dbo.Dim_Position with IsSettled=0 and CloseDateID >= 10 days before SP @date), 'No' otherwise. Added 2020-10-14. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 47 | IsGermanBaFin | int | YES | — | CODE-BACKED | German BaFin regulatory indicator. Always 0 — the source query (FROM BI_DB..V_GermanBaFin) is COMMENTED OUT in SP_EXW_RedeemReconciliation. Non-functional. (Tier 2 — SP_EXW_RedeemReconciliation) |
| 48 | ManagerOpsID | int | YES | — | VERIFIED | Operations team staff member ID who handled this redemption. Renamed from `[etoro - ManagerOpsID]`. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions. (Tier 1 — Billing.Redeem) |
| 49 | ManagerID | int | YES | — | VERIFIED | Manager staff member ID. Renamed from `[etoro - ManagerID]`. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions. (Tier 1 — Billing.Redeem) |
| 50 | EtoroRemark | nvarchar(max) | YES | — | VERIFIED | Free-text note added by operations staff. Renamed from `[etoro - Remark]`. Preserved across status updates (ISNULL(@Remark, Remark) pattern). NULL when no ops note was added. (Tier 1 — Billing.Redeem) |
| 51 | UpdateDate | datetime | YES | — | CODE-BACKED | Timestamp of when this row was loaded by SP_EXW_RedeemReconciliation. Set to GETDATE() at insert time. Reflects SP execution time, not redemption time. (Tier 2 — SP_EXW_RedeemReconciliation) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| — | EXW_dbo.EXW_RedeemReconciliation | View over base table | All data sourced from base table; no independent storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| BI reports / ad-hoc queries | Consumer | Primary view for completed redemption reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
EXW_dbo.EXW_V_RedeemReconciliation (depth=1, view)
└── EXW_dbo.EXW_RedeemReconciliation (depth=2, base table)
    ├── BI_DB_dbo.External_etoro_Billing_Redeem
    ├── BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding
    ├── BI_DB_dbo.External_etoro_Billing_Withdraw
    ├── BI_DB_dbo.External_etoro_Dictionary_* (RedeemStatus, RedeemReason, CashoutStatus, CashoutReason, CashoutType)
    ├── EXW_dbo.EXW_FactRedeemTransactions → WalletDB.Wallet.*
    ├── EXW_dbo.EXW_FactTransactions (AML status)
    ├── EXW_dbo.EXW_InternalWallet (CryptoName)
    ├── EXW_dbo.EXW_DimUser (IsTestAccount)
    └── DWH_dbo.Dim_Position (isCFD)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| EXW_dbo.EXW_RedeemReconciliation | Table | Sole data source — view wraps this table with filter + renames |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BI reports / dashboards | Consumer | Completed redemption reporting |

---

## 7. Technical Details

### 7.1 View Definition

```sql
SELECT
    PositionID,
    EntryAppears,
    IsTestAccount,
    RedeemID,
    [etoro - CID] AS CID,
    [Wallet - RequestingGCID] AS GCID,
    CryptoName,
    [etoro - CryptoID] AS CryptoID,
    [etoro - RedeemStatus] AS EtoroRedeemStatus,
    [etoro - RedeemReason] AS EtoroRedeemReason,
    [etoro - RedeemAmount] AS EtoroRedeemAmount,
    [etoro - RedeemFee] AS EtoroRedeemFee,
    [etoro - BlockchainFee] AS EtoroBlockchainFee,
    [etoro - AmountOnRequestUSD] AS EtoroAmountOnRequestUSD,
    [eToro - AmountOnCloseUSD] AS EtoroAmountOnCloseUSD,
    [etoro - FundingID] AS FundingID,
    [etoro - InstrumentID] AS InstrumentID,
    [etoro - RequestDate] AS RequestDate,
    [etoro - ModificationDate] AS ModificationDate,
    [etoro - RequestDateID] AS RequestDateID,
    [etoro - ModificationDateID] AS ModificationDateID,
    [etoro - WithdrawToFundingID] AS WithdrawToFundingID,
    [etoro - WithdrawID] AS WithdrawID,
    [etoro - Amount] AS EtoroAmount,
    [etoro - CashoutType] AS EtoroCashoutType,
    [etoro - ProcessorValueDate] AS EtoroProcessorValueDate,
    [etoro - DepotID] AS EtoroDepotID,
    [etoro - Approved] AS EtoroApproved,
    [etoro - CashoutStatus] AS EtoroCashoutStatus,
    [etoro - CashoutReason] AS EtoroCashoutReason,
    [Wallet - SendingWalletID] AS WalletSendingWalletID,
    [Wallet - RedeemID] AS WalletRedeemID,
    [Wallet - PositionID] AS WalletPositionID,
    [Wallet - RequestedAmount] AS WalletRequestedAmount,
    [Wallet - RedeemStatus] AS WalletRedeemStatus,
    [Wallet - SentTransactionID] AS WalletSentTransactionID,
    [Wallet - BlockchainTransactionID] AS WalletBlockchainTransactionID,
    [Wallet - SenderAddress] AS WalletSenderAddress,
    [Wallet - ReceiverAddress] AS WalletReceiverAddress,
    [Wallet - SentAmount] AS WalletSentAmount,
    [Wallet - SentTXEtoroFees] AS WalletSentTXEtoroFees,
    [Wallet - SentTTXBlockchainFees] AS WalletSentTTXBlockchainFees,
    [Wallet - ReceivedTransactionID] AS WalletReceivedTransactionID,
    [Wallet - ReceivedAmount] AS WalletReceivedAmount,
    [Wallet - EffectiveBlockchainFees] AS WalletEffectiveBlockchainFees,
    isCFD AS IsCFD,
    IsGermanBaFin,
    [etoro - ManagerOpsID] AS ManagerOpsID,
    [etoro - ManagerID] AS ManagerID,
    [etoro - Remark] AS EtoroRemark,
    UpdateDate
FROM EXW_dbo.EXW_RedeemReconciliation
WHERE EntryAppears = 'BothSidesEntry'
  AND [etoro - RedeemStatus] = 'TransactionDone'
```

### 7.2 Known Issues / Gotchas

- **`IsGermanBaFin` always 0**: Inherited from base table — the SP source query is commented out. Column is non-functional.
- **No direct UC mapping**: View is not migrated to Unity Catalog.
- **Wallet column NULLability**: Despite the TransactionDone filter guaranteeing RedeemStatus=8, `WalletReceivedTransactionID` and `WalletReceivedAmount` can still be NULL (received blockchain event not yet detected). Other Wallet columns should be non-NULL.
- **`WalletSentTTXBlockchainFees` double-T typo**: Preserved from production base table DDL.
- **`EtoroAmountOnCloseUSD` base column typo**: Base table column is `[eToro - AmountOnCloseUSD]` (capital T) vs all other `[etoro - *]` columns (lowercase t). View renames it cleanly.

---

## 8. Sample Queries

### 8.1 Sent vs received amount reconciliation
```sql
SELECT
    PositionID, CID, CryptoName,
    WalletSentAmount, WalletReceivedAmount,
    WalletSentAmount - WalletReceivedAmount AS AmountDiff,
    WalletBlockchainTransactionID,
    RequestDate
FROM EXW_dbo.EXW_V_RedeemReconciliation
WHERE IsTestAccount = 0
    AND WalletReceivedAmount IS NOT NULL
    AND ABS(CAST(WalletSentAmount AS FLOAT) - CAST(WalletReceivedAmount AS FLOAT)) > 0.000001
ORDER BY ABS(CAST(WalletSentAmount AS FLOAT) - CAST(WalletReceivedAmount AS FLOAT)) DESC
```

### 8.2 Redemption volume by crypto and year
```sql
SELECT
    CryptoName,
    YEAR(RequestDate) AS RedeemYear,
    COUNT(1) AS RedeemCount,
    SUM(CAST(EtoroAmountOnCloseUSD AS FLOAT)) AS TotalAmountUSD
FROM EXW_dbo.EXW_V_RedeemReconciliation
WHERE IsTestAccount = 0
GROUP BY CryptoName, YEAR(RequestDate)
ORDER BY RedeemYear DESC, TotalAmountUSD DESC
```

### 8.3 Pending receive detection (blockchain in-flight)
```sql
SELECT
    PositionID, CID, CryptoName,
    WalletBlockchainTransactionID,
    WalletSentAmount,
    RequestDate, ModificationDate
FROM EXW_dbo.EXW_V_RedeemReconciliation
WHERE IsTestAccount = 0
    AND WalletReceivedTransactionID IS NULL
ORDER BY ModificationDate DESC
```

---

*Column descriptions T1-inherited from [EXW_dbo.EXW_RedeemReconciliation](../Tables/EXW_RedeemReconciliation.md). Quality score: 9.55/10 (Phase 16 — 2026-04-20).*
