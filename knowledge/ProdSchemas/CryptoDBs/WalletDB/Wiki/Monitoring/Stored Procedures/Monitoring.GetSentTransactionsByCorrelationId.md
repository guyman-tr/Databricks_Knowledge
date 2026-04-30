# Monitoring.GetSentTransactionsByCorrelationId

> Retrieves sent transaction records matching a specific correlation ID, enabling investigation of individual transaction flows.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sent transactions for a given CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetSentTransactionsByCorrelationId is a diagnostic lookup procedure used to investigate specific transaction flows. When an alert is triggered by another monitoring procedure, this procedure allows drilling into the sent transactions associated with a particular correlation ID to understand what happened.

Without this procedure, investigators would need to manually query the SentTransactions table with the correct NOLOCK hints and column selection.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple filtered lookup by CorrelationId.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The correlation ID to search for. Links to the broader transaction flow. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | SentTransaction ID. |
| 2 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the sent transaction was recorded. |
| 3 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Matching correlation ID (echo of input). |
| 4 | BlockchainTransactionId | NVARCHAR | YES | - | CODE-BACKED | On-chain transaction hash/ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.SentTransactions | FROM (read) | Source of sent transaction records |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools for investigation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetSentTransactionsByCorrelationId (procedure)
  └── Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FROM - sent records |

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

### 8.1 Look up a specific correlation
```sql
EXEC Monitoring.GetSentTransactionsByCorrelationId @CorrelationId = '00000000-0000-0000-0000-000000000000';
```

### 8.2 Find all statuses for a sent transaction
```sql
SELECT sts.StatusId, sts.Occurred, sts.DetailsJson
FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
WHERE sts.SentTransactionId = 12345 ORDER BY sts.Occurred;
```

### 8.3 Cross-reference with received transactions
```sql
SELECT st.Id AS SentId, st.CorrelationId, rt.Id AS ReceivedId, rt.Amount
FROM Wallet.SentTransactions st WITH (NOLOCK)
LEFT JOIN Wallet.ReceivedTransactions rt WITH (NOLOCK) ON rt.CorrelationId = st.CorrelationId
WHERE st.CorrelationId = '00000000-0000-0000-0000-000000000000';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetSentTransactionsByCorrelationId | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetSentTransactionsByCorrelationId.sql*
