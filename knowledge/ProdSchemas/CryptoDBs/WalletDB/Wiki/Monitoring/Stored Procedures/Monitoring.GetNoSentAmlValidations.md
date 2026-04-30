# Monitoring.GetNoSentAmlValidations

> Detects sent transactions to external addresses that have no corresponding AML validation record, indicating a gap in outbound anti-money-laundering screening.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sent transactions missing AML validation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetNoSentAmlValidations is the outbound counterpart to GetNoReceivedAmlValidations. It identifies sent transactions that were processed (SentTransactionStatuses.StatusId=1) but lack a corresponding AML validation (IsSend=1). Only external sends (TransactionTypeId IN (1, 13)) to non-internal addresses are checked.

Without this procedure, outbound transactions that bypassed AML screening would go undetected, creating regulatory and compliance exposure for the platform.

The procedure joins SentTransactions with SentTransactionOutputs to get destination addresses, filters out sends to internal wallet addresses, and checks for missing AML validations within the last 24 hours.

---

## 2. Business Logic

### 2.1 Missing Outbound AML Detection

**What**: Finds sent transactions without AML validation records.

**Columns/Parameters Involved**: `TransactionTypeId`, `NormalizedToAddress`, `AmlValidations.Id`

**Rules**:
- Only TransactionTypeId IN (1, 13) - specific send types requiring AML
- SentTransactionStatuses.StatusId = 1 - processed sends
- Destination address (NormalizedToAddress) must NOT be an internal wallet address (LEFT JOIN CustomerWalletsView IS NULL)
- No matching AML validation with IsSend=1 and matching CorrelationId (LEFT JOIN AmlValidations IS NULL)
- Dictionary.TransactionTypes joined for readable type names

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | SentTransaction ID. |
| 2 | BlockchainTransactionId | NVARCHAR | YES | - | CODE-BACKED | On-chain transaction hash. |
| 3 | WalletId | BIGINT | NO | - | CODE-BACKED | Source wallet identifier. |
| 4 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Transaction correlation ID. |
| 5 | TransactionTypeId | TINYINT | NO | - | CODE-BACKED | Type of send transaction (1 or 13). |
| 6 | TransactionType | NVARCHAR | NO | - | CODE-BACKED | Human-readable name from Dictionary.TransactionTypes. |
| 7 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. |
| 8 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the send transaction occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.SentTransactions | FROM (read) | Source of sent transaction records |
| Query body | Wallet.SentTransactionStatuses | JOIN | Filters to processed sends (StatusId=1) |
| Query body | Wallet.SentTransactionOutputs | JOIN | Gets destination addresses |
| Query body | Dictionary.TransactionTypes | JOIN | Transaction type names |
| Query body | Wallet.CustomerWalletsView | LEFT JOIN | Excludes internal addresses |
| Query body | Wallet.AmlValidations | LEFT JOIN | Detects missing AML records |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetNoSentAmlValidations (procedure)
  ├── Wallet.SentTransactions (table)
  ├── Wallet.SentTransactionStatuses (table)
  ├── Wallet.SentTransactionOutputs (table)
  ├── Dictionary.TransactionTypes (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FROM - sent records |
| Wallet.SentTransactionStatuses | Table | JOIN - processed status |
| Wallet.SentTransactionOutputs | Table | JOIN - destination addresses |
| Dictionary.TransactionTypes | Table | JOIN - type names |
| Wallet.CustomerWalletsView | View | LEFT JOIN - internal address exclusion |
| Wallet.AmlValidations | Table | LEFT JOIN - missing AML detection |

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

### 8.1 Run the compliance check
```sql
EXEC Monitoring.GetNoSentAmlValidations;
```

### 8.2 Check recent send AML coverage
```sql
SELECT COUNT(DISTINCT st.Id) AS TotalSends,
  SUM(CASE WHEN av.Id IS NOT NULL THEN 1 ELSE 0 END) AS WithAml
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Wallet.SentTransactionStatuses sts WITH (NOLOCK) ON sts.SentTransactionId = st.Id AND sts.StatusId = 1
LEFT JOIN Wallet.AmlValidations av WITH (NOLOCK) ON av.CorrelationId = st.CorrelationId AND av.IsSend = 1
WHERE st.Occurred >= DATEADD(HOUR, -24, GETUTCDATE()) AND st.TransactionTypeId IN (1, 13);
```

### 8.3 View transaction type distribution
```sql
SELECT tt.Name, COUNT(*) AS Count
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = st.TransactionTypeId
WHERE st.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY tt.Name ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetNoSentAmlValidations | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetNoSentAmlValidations.sql*
