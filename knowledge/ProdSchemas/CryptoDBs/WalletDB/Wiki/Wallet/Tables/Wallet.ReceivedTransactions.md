# Wallet.ReceivedTransactions

> Records every inbound blockchain transaction received into eToro wallets, capturing the sender address, amount, blockchain hash, and classification of the incoming funds for processing and compliance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 11 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table records every inbound blockchain transaction detected by the wallet system. Each row represents crypto funds arriving at an eToro-managed wallet address - whether from an external customer deposit, a redemption transfer, a conversion leg, or a funding operation. With ~2.48M rows, it is the definitive inbound transaction ledger.

This is the counterpart to `Wallet.SentTransactions`. While sent transactions are initiated by the system, received transactions are detected from the blockchain by the sync process (`Wallet.WalletSync`). The system monitors wallet addresses for incoming transactions and creates records here when detected. The `ReceivedTransactionTypeId` classifies the business purpose of the incoming funds.

Rows are created by `Wallet.StoreReceivedTransaction` when the sync process detects a new incoming transfer. The transaction's lifecycle is tracked in `Wallet.ReceivedTransactionStatuses`. Computed columns `NormalizedSenderAddress` and `NormalizedReceiverAddress` strip protocol prefixes for consistent matching.

---

## 2. Business Logic

### 2.1 Received Transaction Type Distribution

**What**: Incoming transactions are classified by their business purpose to determine the processing pipeline.

**Columns/Parameters Involved**: `ReceivedTransactionTypeId`, `WalletId`, `CryptoId`

**Rules**:
- Type 1 (MoneyIn): 1.17M - 47% - customer deposits from external wallets
- Type 2 (Redeem): 1.10M - 44% - redemption transfers from trading position to wallet
- Type 3 (Funding): 78K - pool wallet funding from omnibus
- Type 4 (ConversionFromUser): 49K - user-initiated conversion incoming leg
- Type 5 (ConversionFromEtoro): 49K - eToro-initiated conversion incoming leg
- Type 6 (Payment): 24K - payment-related incoming
- Type 8 (StakeAndRewardsRefund): 1.4K - staking refunds
- See [Received Transaction Type](../../_glossary.md#received-transaction-type). FK to Dictionary.ReceivedTransactionTypes.

### 2.2 Address Normalization

**What**: Computed columns normalize sender and receiver addresses for consistent matching across address formats.

**Columns/Parameters Involved**: `SenderAddress`, `ReceiverAddress`, `NormalizedSenderAddress`, `NormalizedReceiverAddress`

**Rules**:
- Protocol prefixes before ':' are stripped (e.g., "bitcoin:bc1q..." -> "bc1q...")
- Query parameters after '?' are stripped (e.g., "addr?dt=123" -> "addr")
- Both computed columns are PERSISTED and indexed for lookup performance
- Enables matching regardless of how the blockchain provider formats the address

---

## 3. Data Overview

| Id | WalletId | CryptoId | Amount | ReceivedTransactionTypeId | BlockchainTransactionId (truncated) | Meaning |
|---|---|---|---|---|---|---|
| 2525976 | 0E06BADB-... | 4 (XRP) | 1.2225 | 1 (MoneyIn) | A616C4F15D83... | Customer deposit of 1.22 XRP from external wallet |
| 2525975 | 9C6A8A09-... | 64 (SOL) | 0 | 1 (MoneyIn) | 4NbpcQt2iZej... | SOL zero-amount transaction - likely a wallet activation or token account creation |
| 2525974 | B3BD90F9-... | 2 (ETH) | 3.275 | 1 (MoneyIn) | 0x39a2a64e4d... | Customer deposit of 3.27 ETH - the 0x prefix identifies it as an Ethereum transaction |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. FK target for Wallet.ReceivedTransactionStatuses. |
| 2 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this received transaction was detected and recorded by the system. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The eToro wallet that received the funds. FK to Wallet.WalletPool.WalletId. Used to identify the owning customer. |
| 4 | SenderAddress | nvarchar(512) | YES | - | CODE-BACKED | The blockchain address that sent the funds. NULL when the sender cannot be determined (e.g., coinbase transactions). Used for AML screening. |
| 5 | ReceiverAddress | nvarchar(512) | YES | - | CODE-BACKED | The specific blockchain address within the wallet that received the funds. A wallet may have multiple addresses. |
| 6 | Amount | decimal(36,18) | YES | - | VERIFIED | Amount of crypto received in native units. NULL for zero-value transactions (e.g., token approvals). |
| 7 | BlockchainFee | decimal(36,18) | YES | - | CODE-BACKED | Network fee associated with this incoming transaction. Usually the sender's fee, recorded for reference. |
| 8 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to the parent request in Wallet.Requests.CorrelationId for system-initiated receives (redemptions, conversions). NULL for unexpected external deposits. |
| 9 | BlockchainTransactionId | nvarchar(100) | YES | - | VERIFIED | On-chain transaction hash. Format varies by blockchain (0x-prefixed hex for ETH, base58 for SOL, uppercase hex for XRP). Used for blockchain explorer lookups. |
| 10 | BlockchainTransactionDate | datetime | YES | - | CODE-BACKED | Timestamp of the transaction on the blockchain itself (block time). May differ from Occurred which is when the system detected it. |
| 11 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency received. FK to Wallet.CryptoTypes.CryptoID. |
| 12 | ReceivedTransactionTypeId | tinyint | NO | 1 | VERIFIED | Business classification: 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. See [Received Transaction Type](../../_glossary.md#received-transaction-type). FK to Dictionary.ReceivedTransactionTypes. Default 1 (MoneyIn). |
| 13 | NormalizedSenderAddress | computed | - | - | CODE-BACKED | Computed PERSISTED column stripping protocol prefix and query parameters from SenderAddress for consistent matching. |
| 14 | NormalizedReceiverAddress | computed | - | - | CODE-BACKED | Computed PERSISTED column stripping protocol prefix and query parameters from ReceiverAddress for consistent matching. |
| 15 | ProviderTransactionId | varchar(128) | YES | - | CODE-BACKED | Transaction identifier assigned by the custody provider (BitGo/CUG). May differ from the blockchain hash. Used for provider API reconciliation. |
| 16 | ReceiveRequestCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to a ReceiveTransaction request (RequestTypeId=8) when the incoming transaction is processed as a formal request. Distinct from CorrelationId which links to the originating request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies the cryptocurrency received |
| WalletId | Wallet.WalletPool | FK | Identifies the receiving wallet |
| ReceivedTransactionTypeId | Dictionary.ReceivedTransactionTypes | FK | Classifies the business purpose |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ReceivedTransactionStatuses | ReceivedTransactionId | FK | Tracks status lifecycle |
| Wallet.StoreReceivedTransaction | - | Writer | Creates received transaction records |
| Wallet.GetReceivedTransactions | - | Reader | Queries transaction history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ReceivedTransactions (table)
├── Wallet.CryptoTypes (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.WalletPool (table)
│     └── Wallet.BlockchainCryptos (table)
└── Dictionary.ReceivedTransactionTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.WalletPool | Table | FK target for WalletId |
| Dictionary.ReceivedTransactionTypes | Table | FK target for ReceivedTransactionTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactionStatuses | Table | FK on ReceivedTransactionId |
| Wallet.StoreReceivedTransaction | Stored Procedure | Inserts records |
| Wallet.GetReceivedTransactions | Stored Procedure | Reads transaction history |
| Wallet.GetReceivedTransactionByBlockchainId | Stored Procedure | Looks up by blockchain hash |
| Wallet.GetPendingReceivedTransactions | Stored Procedure | Finds unprocessed receives |
| Wallet.GetBounceBackInProcessReceiveTransactions | Stored Procedure | Finds bounceback candidates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReceivedTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_ReceivedTransactions_CorrelationId | NC | CorrelationId | - | - | Active |
| IX_Wallet_ReceivedTransactions_BlockchainTransactionId_NormalizedReceiverAddress | NC | BlockchainTransactionId, NormalizedReceiverAddress | - | - | Active |
| IX_ReceivedTransactions_WalletId_BlockchainTransactionId | NC | WalletId, BlockchainTransactionId | - | - | Active |
| IX_ReceivedTransactions_ReceiveRequestCorrelationId | NC | ReceiveRequestCorrelationId | Id, WalletId, SenderAddress, Amount, BlockchainFee, CryptoId | - | Active |
| IX_Wallet_ReceivedTransactions_CryptoId_Inc | NC | CryptoId | WalletId, SenderAddress, ReceiverAddress, Amount, CorrelationId, BlockchainTransactionId, BlockchainTransactionDate, ReceivedTransactionTypeId, NormalizedReceiverAddress | - | Active |
| +5 additional composite indexes | NC | Various | Various | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_ReceivedTransactions__Occurred | DEFAULT | getutcdate() |
| DF (ReceivedTransactionTypeId) | DEFAULT | 1 (MoneyIn) |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | WalletId -> Wallet.WalletPool.WalletId |
| FK_...ReceivedTransactionTypeId | FK | ReceivedTransactionTypeId -> Dictionary.ReceivedTransactionTypes.Id |

---

## 8. Sample Queries

### 8.1 Recent incoming transactions for a wallet
```sql
SELECT rt.Id, rt.Amount, ct.Name AS Crypto, rtt.Name AS TxType,
    rt.SenderAddress, rt.BlockchainTransactionId, rt.BlockchainTransactionDate
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON rt.CryptoId = ct.CryptoID
JOIN Dictionary.ReceivedTransactionTypes rtt WITH (NOLOCK) ON rt.ReceivedTransactionTypeId = rtt.Id
WHERE rt.WalletId = '0E06BADB-7A8B-453A-82EB-34A465284F37'
ORDER BY rt.Id DESC
```

### 8.2 Find transaction by blockchain hash
```sql
SELECT rt.Id, rt.WalletId, rt.Amount, rt.CryptoId, rt.ReceivedTransactionTypeId
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
WHERE rt.BlockchainTransactionId = 'A616C4F15D83614938A3C8E21BEC1C4370757C2D69E7CB99B0931C142DDE17ED'
```

### 8.3 Incoming volume by type
```sql
SELECT rtt.Name AS TxType, COUNT(*) AS TxCount, SUM(rt.Amount) AS TotalAmount
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Dictionary.ReceivedTransactionTypes rtt WITH (NOLOCK) ON rt.ReceivedTransactionTypeId = rtt.Id
WHERE rt.Occurred > DATEADD(DAY, -30, GETUTCDATE())
GROUP BY rtt.Name
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ReceivedTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ReceivedTransactions.sql*
