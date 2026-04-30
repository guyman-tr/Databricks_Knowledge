# MoneyBus.Containers

> Stores the JSON execution state (SAGA container) for each transaction's processing pipeline, holding the full request context, user details, and creditor/debitor account information as the transaction progresses through hold-debit-credit steps.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | TransactionID (BIGINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on TransactionID) |

---

## 1. Business Meaning

MoneyBus.Containers stores the runtime execution state for each transaction's processing pipeline. The ContainerData JSON blob holds the complete SAGA orchestration context including the user identity (GCID, CID), the full TransactionRequestMessage with creditor and debitor account details, and the execution progress state. This enables the transaction service to resume processing from any step if interrupted.

This table exists to support the stateful SAGA pattern used by the transaction execution microservice. The transaction pipeline (hold -> debit -> credit) is asynchronous and may span multiple service calls across account providers. By persisting the full request context to this table, the service can reconstruct and resume a partially-completed transaction.

Data flows through ContainerUpsert (MERGE pattern - creates on first step, updates on subsequent steps), ContainerGet (reads current state), and ContainerDelete (cleans up after completion). The TransactionID is the clustered PK, providing direct one-to-one access aligned with the transaction service's lookup pattern.

---

## 2. Business Logic

### 2.1 Transaction SAGA State Persistence

**What**: The ContainerData JSON captures the full transaction request context and execution progress.

**Columns/Parameters Involved**: `ContainerData`, `TransactionID`, `Modified`

**Rules**:
- Key JSON fields: _transactionId, User (GCID, CID), TransactionRequestMessage (transactionId, creditor.accountId/accountTypeId, debitor.accountId/accountTypeId)
- The User object contains both GCID (Global Customer ID) and CID (Customer ID) - both identity dimensions
- creditor/debitor sub-objects within TransactionRequestMessage carry the specific account IDs and types for each side of the transfer
- Modified=NULL means the container was created but only the initial step has run
- The container is deleted after the transaction reaches a terminal state (Success, Decline, Technical, Canceled)

---

## 3. Data Overview

| ID | TransactionID | Created | Modified | ContainerData (excerpt) | Meaning |
|---|---|---|---|---|---|
| 4336715 | 7747402 | 2026-04-15 13:11:21 | NULL | User GCID=35795776, creditor accountTypeId=3 (IBAN) | New transaction container - initial step in progress, IBAN credit flow |
| 4336703 | 7747386 | 2026-04-15 13:10:53 | 2026-04-15 13:10:54 | User GCID=44945990, creditor accountTypeId=1 (Trading) | Container updated 1 second after creation - deposit flow (IBAN -> Trading) |
| 4336684 | 7747359 | 2026-04-15 13:10:12 | 2026-04-15 13:10:13 | User GCID=29173772, creditor accountTypeId=1 (Trading) | Another deposit flow, quickly progressing through pipeline |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Not the clustered key (TransactionID is). |
| 2 | TransactionID | bigint | NO | - | CODE-BACKED | FK to MoneyBus.Transactions.ID. One-to-one relationship - each transaction has exactly one container. Clustered PK for optimal access by the transaction service. |
| 3 | Created | datetime | NO | - | CODE-BACKED | UTC timestamp when the container was first created (pipeline start). Set to GETUTCDATE() by ContainerUpsert. |
| 4 | Modified | datetime | YES | - | CODE-BACKED | UTC timestamp of the last container update. NULL when the container was just created and no subsequent step has completed. Updated by ContainerUpsert via MERGE. |
| 5 | ContainerData | nvarchar(max) | YES | - | CODE-BACKED | JSON blob containing the full SAGA execution state: _transactionId, User identity, TransactionRequestMessage with creditor/debitor account details, and pipeline progress. Updated on each step completion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionID | MoneyBus.Transactions | Implicit FK (1:1) | Links the container state to the transaction being processed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.ContainerGet | (whole table) | Reader | Reads container state for pipeline resumption |
| MoneyBus.ContainerUpsert | (whole table) | Writer/Modifier | Creates/updates container via MERGE |
| MoneyBus.ContainerDelete | (whole table) | Deleter | Removes container after pipeline completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.Containers (table)
└── MoneyBus.Transactions (table) [via TransactionID]
    └── MoneyBus.TransactionsGroup (table) [via GroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | TransactionID references Transactions.ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.ContainerGet | Stored Procedure | Reader |
| MoneyBus.ContainerUpsert | Stored Procedure | Writer/Modifier (MERGE) |
| MoneyBus.ContainerDelete | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Containers | CLUSTERED PK | TransactionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Containers | PRIMARY KEY | Clustered on TransactionID - one container per transaction, optimized for transaction-based lookups |

---

## 8. Sample Queries

### 8.1 Get container with transaction context
```sql
SELECT c.TransactionID, c.Created, c.Modified, c.ContainerData,
       t.StatusID, t.StatusReasonID, t.CreditorTypeID, t.DebitorTypeID
FROM MoneyBus.Containers c WITH (NOLOCK)
JOIN MoneyBus.Transactions t WITH (NOLOCK) ON t.ID = c.TransactionID AND t.PartitionCol = c.TransactionID % 100
WHERE c.TransactionID = @TransactionID;
```

### 8.2 Find stale containers (transactions still in process with old containers)
```sql
SELECT c.TransactionID, c.Created,
       DATEDIFF(MINUTE, c.Created, GETUTCDATE()) AS AgeMinutes
FROM MoneyBus.Containers c WITH (NOLOCK)
JOIN MoneyBus.Transactions t WITH (NOLOCK) ON t.ID = c.TransactionID AND t.PartitionCol = c.TransactionID % 100
WHERE t.StatusID = 1 AND c.Created < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY c.Created ASC;
```

### 8.3 Check container creation rate (recent activity)
```sql
SELECT CAST(Created AS DATE) AS Day, COUNT(*) AS ContainersCreated
FROM MoneyBus.Containers WITH (NOLOCK)
WHERE Created > DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(Created AS DATE)
ORDER BY Day DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.Containers | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.Containers.sql*
