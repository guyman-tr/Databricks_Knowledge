# Trade.PositionEndedWithTOError

> Error queue table capturing position close or timeout ("TO") failures. Stores notification payloads and status for retry or manual resolution. Synonym Trade.SynPositionEndedWithTOError points here.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint IDENTITY, PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (PK CLUSTERED) |

---

## 1. Business Meaning

**WHAT**: Trade.PositionEndedWithTOError is an error queue table for positions that ended with timeout errors ("TO" = Timeout). When a position close, edit, or related operation times out (e.g., hedge close timeout, external service unresponsive), the failure context is persisted here. Each row stores the error notification payload (MessageType, Notificationtosend), a Status flag (0 = unprocessed), and Occurred timestamp.

**WHY**: Timeout errors require retry or manual intervention. Without this table, failed operations would be lost and positions could remain in inconsistent states. The table provides a durable queue: a job or operator can poll for Status=0 rows, retry the notification or operation, and update Status when processed. The synonym Trade.SynPositionEndedWithTOError likely allows abstraction if the physical table location changes.

**HOW**: Procedures in the position close/timeout pipeline (e.g., PositionCloseWithTimeout, FunPositionCloseWithTimeout) insert into this table when a timeout occurs. The Notificationtosend column (varchar(max)) likely holds JSON or XML with position ID, customer, error details, and retry parameters. A background job or operator reads rows with Status=0, sends notifications or retries, then updates Status. The table is empty (0 rows) in the live database, indicating no recent timeout failures or successful cleanup.

---

## 2. Business Logic

### 2.1 Error Queue Processing

**What**: Rows are inserted on timeout; a consumer processes and updates Status.

**Columns/Parameters Involved**: MessageType, Notificationtosend, Status, Occurred

**Rules**:
- Status = 0 (default): Unprocessed. Consumer should retry or send notification.
- Status = 1 or higher: Processed (convention may vary). Consumer updates after successful retry.
- MessageType: Categorizes the error (e.g., "PositionCloseTimeout", "EditSLTimeout").
- Notificationtosend: Full payload for the notification or retry request.

### 2.2 Synonym Usage

**What**: Trade.SynPositionEndedWithTOError points to this table.

**Rules**:
- Code may reference the synonym for abstraction. Both resolve to the same physical table.

---

## 3. Data Overview

| ID | MessageType | Notificationtosend | Status | Occurred | Meaning |
|----|-------------|-------------------|--------|----------|---------|
| (empty) | - | - | - | - | Table has 0 rows. No recent timeout errors. |

**Selection criteria**: Table is empty. When populated, rows would have MessageType, Notificationtosend (JSON/XML), Status=0 for unprocessed, Occurred timestamp.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | PK. Surrogate key. |
| 2 | MessageType | varchar(100) | YES | - | CODE-BACKED | Error category (e.g., timeout type). |
| 3 | Notificationtosend | varchar(max) | YES | - | CODE-BACKED | Full notification payload (JSON/XML) for retry or alerting. Stored on DICTIONARY TEXTIMAGE_ON. |
| 4 | Status | int | YES | 0 | CODE-BACKED | Processing state. 0 = unprocessed (default). Non-zero = processed. |
| 5 | Occurred | datetime | YES | getdate() | CODE-BACKED | When the timeout was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (none) | - | - | No explicit FKs. Notificationtosend may contain PositionID, CID refs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionCloseWithTimeout | INSERT | Writer | Inserts on close timeout |
| Trade.FunPositionCloseWithTimeout | INSERT | Writer | May insert on timeout |
| Trade.SynPositionEndedWithTOError | Synonym | Alias | Points to this table |
| (Retry/notification job) | SELECT, UPDATE | Reader/Modifier | Processes Status=0 rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEndedWithTOError (table)
└── Trade.SynPositionEndedWithTOError (synonym -> this table)
```

### 6.1 Objects This Depends On

No explicit FKs. Leaf table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionCloseWithTimeout | Procedure | INSERT on timeout |
| Trade.FunPositionCloseWithTimeout | Function | May insert on timeout |
| Trade.SynPositionEndedWithTOError | Synonym | Alias for this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionEndedWithTOError | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionEndedWithTOError | PRIMARY KEY | ID |
| DF (Status) | DEFAULT | 0 |
| DF (Occurred) | DEFAULT | getdate() |

### 7.3 Filegroups

Table and TEXTIMAGE_ON are on [DICTIONARY] filegroup.

---

## 8. Sample Queries

### 8.1 Unprocessed timeout errors (retry queue)
```sql
SELECT pe.ID, pe.MessageType, pe.Notificationtosend, pe.Occurred
FROM   Trade.PositionEndedWithTOError pe WITH (NOLOCK)
WHERE  pe.Status = 0
ORDER BY pe.Occurred ASC;
```

### 8.2 Via synonym
```sql
SELECT * FROM Trade.SynPositionEndedWithTOError WITH (NOLOCK) WHERE Status = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.PositionEndedWithTOError | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionEndedWithTOError.sql*
