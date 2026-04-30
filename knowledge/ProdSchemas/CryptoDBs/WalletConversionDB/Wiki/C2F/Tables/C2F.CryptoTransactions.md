# C2F.CryptoTransactions

> Records the blockchain-side transaction for each crypto-to-fiat conversion, capturing the on-chain transaction hash, destination address, amount, and network fee as proof of the crypto sell operation.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 UNIQUE NC on BlockchainTransactionId) |

---

## 1. Business Meaning

C2F.CryptoTransactions stores the blockchain-level proof that the crypto portion of a conversion was executed. Each row records the on-chain transaction hash, the destination address, the crypto amount transferred, and the network fee charged. This is the "source side" of the conversion - confirming that crypto left the customer's wallet.

Not every conversion has a crypto transaction (16,128 rows vs 17,039 conversions) - conversions that fail before the crypto transfer step won't have an entry here. The UNIQUE constraint on BlockchainTransactionId prevents the same blockchain transaction from being recorded twice, providing idempotency.

Created by `C2F.InsertCryptoTransaction`, which looks up the conversion by CorrelationId and includes a deduplication check to prevent double-insertion.

---

## 2. Business Logic

### 2.1 Blockchain Transaction Deduplication

**What**: InsertCryptoTransaction prevents duplicate entries using both CorrelationId lookup and existence check.

**Columns/Parameters Involved**: `ConversionId`, `BlockchainTransactionId`

**Rules**:
- INSERT ... FROM Conversions WHERE CorrelationId AND NOT EXISTS (CryptoTransactions for that ConversionId)
- UNIQUE constraint on BlockchainTransactionId provides database-level enforcement
- One crypto transaction per conversion (1:1 relationship when present)

### 2.2 Multi-Chain Transaction Format

**What**: BlockchainTransactionId and ToAddress formats vary by blockchain.

**Columns/Parameters Involved**: `BlockchainTransactionId`, `ToAddress`

**Rules**:
- Ethereum: BlockchainTransactionId = "0x..." (66-char hex), ToAddress = "0x..." (42-char hex)
- Ripple/XRP: BlockchainTransactionId = uppercase hex, ToAddress includes "?dt=..." destination tag
- Other chains follow their native transaction ID and address formats

---

## 3. Data Overview

| Id | ConversionId | BlockchainTransactionId | ToAddress | Amount | BlockchainFee | Meaning |
|----|-------------|------------------------|-----------|--------|---------------|---------|
| 16128 | 17039 | 668BC44E...E76FD5 | rsoeQdApfu41...?dt=3393117367 | 100 | 0.000045 | XRP/Ripple transaction with destination tag. Network fee is minimal (0.000045 XRP). |
| 16127 | 17036 | 0x723fbb...e7d751 | 0x1A968A...C2e3 | 158.191059 | 0.00000006 | Ethereum-based transaction. Nearly zero blockchain fee. Same destination address as #16126 (omnibus wallet). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | FK to C2F.Conversions.Id. Links the blockchain transaction to its parent conversion. One crypto transaction per conversion (when present). |
| 3 | BlockchainTransactionId | varchar(100) | NO | - | VERIFIED | On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. |
| 4 | ToAddress | varchar(64) | NO | - | VERIFIED | Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags as "?dt=..."). Repeated addresses across transactions suggest omnibus wallet patterns. |
| 5 | Amount | decimal(36,18) | NO | - | VERIFIED | Quantity of cryptocurrency transferred on-chain. Matches or closely tracks C2F.Conversions.CryptoAmount for the same conversion. |
| 6 | BlockchainFee | decimal(36,18) | NO | - | VERIFIED | Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. |
| 7 | Occurred | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | C2F.Conversions | Explicit FK | Links crypto transaction to parent conversion |

### 5.2 Referenced By (other objects point to this)

No other tables reference this table directly. GetConversionSummary LEFT JOINs to it.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.InsertCryptoTransaction | Stored Procedure | WRITER - creates crypto tx rows |
| C2F.GetConversionSummary | Stored Procedure | READER - LEFT JOIN for crypto amounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Transactions_Id | CLUSTERED | Id ASC | - | - | Active |
| UNIQUE_BlockchainTransactionId | UNIQUE NC | BlockchainTransactionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Transactions_Id | PRIMARY KEY | DATA_COMPRESSION = PAGE |
| UNIQUE_BlockchainTransactionId | UNIQUE | Prevents duplicate blockchain tx recording |
| FK_C2F_CryptoTransactions_ConversionId_C2F_Conversions_Id | FOREIGN KEY | ConversionId -> C2F.Conversions.Id |
| C2F_CryptoTransactions_Occurred | DEFAULT | GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get crypto transaction for a conversion
```sql
SELECT ct.BlockchainTransactionId, ct.ToAddress, ct.Amount, ct.BlockchainFee, ct.Occurred
FROM C2F.CryptoTransactions ct WITH (NOLOCK)
WHERE ct.ConversionId = @ConversionId
```

### 8.2 Find crypto transaction by blockchain hash
```sql
SELECT ct.*, c.Gcid, c.CorrelationId
FROM C2F.CryptoTransactions ct WITH (NOLOCK)
INNER JOIN C2F.Conversions c WITH (NOLOCK) ON c.Id = ct.ConversionId
WHERE ct.BlockchainTransactionId = @TxHash
```

### 8.3 Conversions missing crypto transactions
```sql
SELECT c.Id, c.Gcid, c.CorrelationId, c.Occurred
FROM C2F.Conversions c WITH (NOLOCK)
LEFT JOIN C2F.CryptoTransactions ct WITH (NOLOCK) ON ct.ConversionId = c.Id
WHERE ct.Id IS NULL
ORDER BY c.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.CryptoTransactions | Type: Table | Source: WalletConversionDB/C2F/Tables/C2F.CryptoTransactions.sql*
