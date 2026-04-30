# C2F.InsertCryptoTransaction

> Records the blockchain transaction for a conversion's crypto side, with deduplication to prevent double-insertion of the same on-chain transaction.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into C2F.CryptoTransactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertCryptoTransaction records the blockchain-level proof that the crypto portion of a conversion was executed. It stores the on-chain transaction hash, destination address, transferred amount, and network fee. The procedure looks up the conversion by CorrelationId and includes deduplication - it only inserts if no crypto transaction exists yet for that conversion.

Called by the saga orchestrator after the blockchain transaction step completes successfully.

---

## 2. Business Logic

### 2.1 Dedup via LEFT JOIN Anti-Pattern

**What**: Uses a single INSERT...SELECT with LEFT JOIN to atomically check and insert.

**Columns/Parameters Involved**: `@CorrelationId`, `@BlockchainTransactionId`

**Rules**:
- INSERT FROM Conversions WHERE CorrelationId AND NOT EXISTS (Conversions LEFT JOIN CryptoTransactions WHERE ct.Id IS NOT NULL)
- If a CryptoTransaction already exists for this conversion, the NOT EXISTS prevents re-insertion
- Additionally, CryptoTransactions has UNIQUE constraint on BlockchainTransactionId

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Identifies the conversion. Used to look up Conversions.Id for the ConversionId FK. |
| 2 | @BlockchainTransactionId | varchar(100) | NO | - | VERIFIED | On-chain transaction hash. Stored in CryptoTransactions.BlockchainTransactionId (UNIQUE). |
| 3 | @ToAddress | varchar(64) | NO | - | VERIFIED | Blockchain destination address. |
| 4 | @Amount | decimal(36,18) | NO | - | VERIFIED | Crypto amount transferred on-chain. |
| 5 | @BlockchainFee | decimal(36,18) | NO | - | VERIFIED | Network fee charged for the transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | C2F.Conversions | SELECT (lookup) | Finds ConversionId by CorrelationId |
| - | C2F.CryptoTransactions | INSERT target + dedup check | Creates crypto tx row if not exists |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.InsertCryptoTransaction (procedure)
├── C2F.Conversions (table)
└── C2F.CryptoTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | SELECT - lookup by CorrelationId |
| C2F.CryptoTransactions | Table | INSERT + EXISTS check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record a crypto transaction
```sql
EXEC C2F.InsertCryptoTransaction
    @CorrelationId = 'BD637018-99FC-40AD-A466-773D7274F16C',
    @BlockchainTransactionId = '0x123abc...',
    @ToAddress = '0x1A968A2887Dd6658eD6E68F46De36D13BA69C2e3',
    @Amount = 100.0, @BlockchainFee = 0.000045
```

### 8.2 Verify crypto transaction was recorded
```sql
SELECT ct.* FROM C2F.CryptoTransactions ct WITH (NOLOCK)
INNER JOIN C2F.Conversions c WITH (NOLOCK) ON c.Id = ct.ConversionId
WHERE c.CorrelationId = @CorrelationId
```

### 8.3 Check for missing crypto transactions
```sql
SELECT c.Id, c.CorrelationId FROM C2F.Conversions c WITH (NOLOCK)
LEFT JOIN C2F.CryptoTransactions ct WITH (NOLOCK) ON ct.ConversionId = c.Id
WHERE ct.Id IS NULL ORDER BY c.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.InsertCryptoTransaction | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.InsertCryptoTransaction.sql*
