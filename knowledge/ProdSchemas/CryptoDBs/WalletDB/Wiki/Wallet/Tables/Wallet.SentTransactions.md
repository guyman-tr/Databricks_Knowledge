# Wallet.SentTransactions

> Records every outbound blockchain transaction sent from eToro wallets, capturing the on-chain transaction hash, source wallet, transaction type, fees, and correlation to the parent request.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 8 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table is the definitive record of every outbound blockchain transaction broadcast from eToro wallets. Each row represents a single on-chain transaction - a crypto transfer that was signed and submitted to a blockchain network. With ~1.86M rows, it covers all outbound fund movements including customer withdrawals, redemptions, conversions, funding operations, and staking.

This is the bridge between eToro's internal request system and the blockchain. While `Wallet.Requests` tracks the business intent, this table tracks the actual on-chain execution. The `BlockchainTransactionId` is the on-chain hash that can be verified on any blockchain explorer. The `CorrelationId` links back to the parent request.

Rows are created by `Wallet.StoreSentTransaction` after the blockchain provider (BitGo/CUG) broadcasts the transaction. The transaction's lifecycle (pending -> confirmed -> verified) is tracked in the child table `Wallet.SentTransactionStatuses`. Output details (destination addresses, amounts) are in `Wallet.SentTransactionOutputs`.

---

## 2. Business Logic

### 2.1 Transaction Type Distribution

**What**: Sent transactions serve diverse business purposes, classified by TransactionTypeId.

**Columns/Parameters Involved**: `TransactionTypeId`, `WalletId`, `CryptoId`

**Rules**:
- Type 1 (CustomerMoneyOut): 828K - 45% - customer-initiated withdrawals to external wallets
- Type 0 (Redeem): 771K - 42% - transfers from omnibus to customer wallets (position-to-crypto)
- Type 4 (Funding): 78K - pool wallet pre-funding from omnibus
- Type 5/6 (ConversionMoneyIn/Out): ~98K - crypto swap legs
- Type 13 (ManualUserMoneyOut): 29K - operations-approved manual withdrawals
- Type 12 (ConversionToFiat): 16K - crypto sold for fiat
- See [Transaction Type](../../_glossary.md#transaction-type). FK to Dictionary.TransactionTypes.

### 2.2 Blockchain Fee Tracking

**What**: The actual network fee paid for each transaction is recorded for cost analysis and billing.

**Columns/Parameters Involved**: `BlockchainFee`, `CryptoId`

**Rules**:
- BlockchainFee is in the crypto's native units (e.g., BTC for Bitcoin transactions)
- Defaults to 0 for transactions where the fee is unknown at creation time
- Updated after the transaction is confirmed on-chain with the actual fee
- Used for financial reconciliation and customer fee billing

---

## 3. Data Overview

| Id | BlockchainTransactionId (truncated) | WalletId | TransactionTypeId | CryptoId | BlockchainFee | Meaning |
|---|---|---|---|---|---|---|
| 1907239 | 37cqS8sdJALVD... | C0D5EF83-... | 1 (CustomerMoneyOut) | 64 (SOL) | 0.000011 | Customer withdrawal of SOL. Low fee reflects Solana's efficient transaction model. |
| 1907238 | 1fd45c4c5c8b... | 425803D4-... | 1 (CustomerMoneyOut) | 21 (XLM) | 0.0045 | Customer withdrawal of Stellar. Same wallet as next entry. |
| 1907237 | 88de2acd7172... | 425803D4-... | 1 (CustomerMoneyOut) | 21 (XLM) | 0.0045 | Another XLM withdrawal from same wallet - consecutive sends indicate batch processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. |
| 2 | BlockchainTransactionId | nvarchar(100) | NO | - | VERIFIED | The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet. |
| 4 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. |
| 5 | CorrelationId | uniqueidentifier | YES | - | VERIFIED | Links to the parent request in Wallet.Requests.CorrelationId. Enables tracing from business request to on-chain transaction. NULL for pre-correlation-era transactions. |
| 6 | TransactionTypeId | tinyint | YES | - | VERIFIED | Business purpose: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. See [Transaction Type](../../_glossary.md#transaction-type). FK to Dictionary.TransactionTypes. |
| 7 | BlockchainFee | decimal(36,18) | NO | 0 | CODE-BACKED | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. |
| 8 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId for per-wallet per-crypto transaction history queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies the cryptocurrency sent |
| WalletId | Wallet.Wallets | FK | Identifies the source wallet |
| TransactionTypeId | Dictionary.TransactionTypes | FK | Classifies the business purpose |
| CorrelationId | Wallet.Requests | Implicit | Links to the parent request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SentTransactionStatuses | SentTransactionId | FK | Tracks status lifecycle (Pending -> Confirmed -> Verified) |
| Wallet.SentTransactionOutputs | SentTransactionId | FK | Stores output details (destination addresses, amounts, fees) |
| Wallet.SentTransactionReplaces | SentTransactionId | FK | Tracks RBF (Replace-By-Fee) transaction replacements |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SentTransactions (table)
├── Wallet.CryptoTypes (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.Wallets (table)
│     └── Wallet.BlockchainCryptos (table)
└── Dictionary.TransactionTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.Wallets | Table | FK target for WalletId |
| Dictionary.TransactionTypes | Table | FK target for TransactionTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactionStatuses | Table | FK on SentTransactionId |
| Wallet.SentTransactionOutputs | Table | FK on SentTransactionId |
| Wallet.SentTransactionReplaces | Table | FK on SentTransactionId |
| Wallet.StoreSentTransaction | Stored Procedure | Inserts transaction records |
| Wallet.GetSentTransactionByBlockchainId | Stored Procedure | Looks up by blockchain hash |
| Wallet.GetSentTransactionByCorrelationId | Stored Procedure | Looks up by request correlation |
| Wallet.GetSentTransactionByWalletId | Stored Procedure | Lists transactions for a wallet |
| Wallet.InsertSentTransactionStatus | Stored Procedure | References when inserting statuses |
| 10+ additional procedures | Stored Procedure | Various transaction queries and reports |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SentTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_SentTransactions_BlockchainTransactionId | NC UNIQUE | BlockchainTransactionId ASC | - | - | Active |
| IX_Wallet_SentTransactions_CorrelationId | NC | CorrelationId | - | - | Active |
| ix_SentTransactions_Occurred | NC | Occurred | - | - | Active |
| ix_SentTransactions_Occurred_INC_... | NC | Occurred | BlockchainTransactionId, WalletId | - | Active |
| IX_SentTransactions_Occurred_Inc_CryptoId_... | NC | Occurred | CryptoId, TransactionTypeId, WalletId | - | Active |
| IX_Wallet_SentTransactions__TransactionTypeId_Occurred | NC | TransactionTypeId, Occurred | - | - | Active |
| IX_Wallet_SentTransactions_WalletId_CryptoId_Occurred | NC | WalletId, CryptoId, Occurred DESC | - | - | Active |
| IX_Wallet_SentTransactions_WalletId_CryptoId_Occurred_Inc | NC | WalletId, CryptoId, Occurred DESC | BlockchainTransactionId, CorrelationId, TransactionTypeId, BlockchainFee | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_SentTransactions__Occurred | DEFAULT | getutcdate() |
| DF (BlockchainFee) | DEFAULT | 0 |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | WalletId -> Wallet.Wallets.WalletId |
| FK_...TransactionTypeId | FK | TransactionTypeId -> Dictionary.TransactionTypes.Id |

---

## 8. Sample Queries

### 8.1 Get recent sent transactions for a wallet with type names
```sql
SELECT st.Id, st.BlockchainTransactionId, tt.Name AS TransactionType,
    ct.Name AS Crypto, st.BlockchainFee, st.Occurred
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON st.TransactionTypeId = tt.Id
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON st.CryptoId = ct.CryptoID
WHERE st.WalletId = 'C0D5EF83-D2CD-4DA7-BABD-B57CA8F3BDA8'
ORDER BY st.Occurred DESC
```

### 8.2 Find a transaction by blockchain hash
```sql
SELECT st.Id, st.WalletId, st.TransactionTypeId, st.CryptoId, st.BlockchainFee, st.CorrelationId
FROM Wallet.SentTransactions st WITH (NOLOCK)
WHERE st.BlockchainTransactionId = '37cqS8sdJALVDh7oQy4W7SXMySqqYrBjSHGgbuhqSez6Yi9D1tL9dzdY8NHLD7Vd1rgs9Z6RyQRuWVbpji7L2gFE'
```

### 8.3 Transaction volume by type and crypto
```sql
SELECT tt.Name AS TransactionType, ct.Name AS Crypto, COUNT(*) AS TxCount
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON st.TransactionTypeId = tt.Id
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON st.CryptoId = ct.CryptoID
WHERE st.Occurred > DATEADD(DAY, -30, GETUTCDATE())
GROUP BY tt.Name, ct.Name
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SentTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SentTransactions.sql*
