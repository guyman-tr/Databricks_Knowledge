# Wallet.Job_LogicApp_DeleteOldRows_ProcessingRecords

> Scheduled cleanup job that deletes expired processing records in batches of 2000, freeing distributed lock entries whose expiration time has passed.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE from ProcessingRecords WHERE ExpirationTime < today |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a scheduled maintenance job called by Azure Logic Apps. It cleans up expired processing lock records from Wallet.ProcessingRecords. When background processes lock records for exclusive processing (via LockRecordsForProcess), those locks have an expiration time. After expiration, the records are no longer useful and accumulate. This job deletes them in batches of 2000 to avoid long-running transactions, looping until all expired records are removed.

---

## 2. Business Logic

### 2.1 Batched Deletion Loop

**What**: Deletes expired records in 2000-row batches to avoid lock escalation.

**Rules**:
- DELETE TOP (2000) WHERE ExpirationTime < today's date
- WHILE @@ROWCOUNT > 0: continues looping until no more expired records
- Batching prevents table locks on the potentially large ProcessingRecords table

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | Parameterless cleanup job. Uses GETDATE() internally for expiration comparison. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ProcessingRecords | DELETE | Removes expired lock records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| LogicAppJobsUser | - | EXECUTE | Scheduled cleanup via Azure Logic App |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Job_LogicApp_DeleteOldRows_ProcessingRecords (procedure)
+-- Wallet.ProcessingRecords (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ProcessingRecords | Table | DELETE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| LogicAppJobsUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the cleanup
```sql
EXEC Wallet.Job_LogicApp_DeleteOldRows_ProcessingRecords;
```

### 8.2 Check how many records would be cleaned
```sql
SELECT COUNT(*) FROM Wallet.ProcessingRecords WITH (NOLOCK) WHERE ExpirationTime < CAST(GETDATE() AS DATE);
```

### 8.3 Check current lock records
```sql
SELECT TOP 10 * FROM Wallet.ProcessingRecords WITH (NOLOCK) ORDER BY ExpirationTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Job_LogicApp_DeleteOldRows_ProcessingRecords | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.Job_LogicApp_DeleteOldRows_ProcessingRecords.sql*
