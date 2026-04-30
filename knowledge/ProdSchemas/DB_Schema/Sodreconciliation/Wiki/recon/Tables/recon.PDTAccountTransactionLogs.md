# recon.PDTAccountTransactionLogs

> Audit log of Pattern Day Trader (PDT) account blocking/unblocking operations, tracking when accounts are restricted for PDT violations and when restrictions expire.

| Property | Value |
|----------|-------|
| **Schema** | recon |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 PK + 1 NC on Timestamp) |

---

## 1. Business Meaning

This table logs Pattern Day Trader (PDT) account blocking and unblocking operations. Under SEC/FINRA rules, accounts that execute 4 or more day trades within 5 business days with less than $25,000 in equity are classified as Pattern Day Traders and may be restricted from further day trading.

When the reconciliation system identifies a PDT violation or when operations staff manually block/unblock accounts for PDT reasons, the action is logged here with the customer ID, blocking dates, reason, and who initiated it. Currently contains only 2 records, suggesting this is a rarely-used but important compliance feature.

---

## 2. Business Logic

### 2.1 PDT Account Blocking Lifecycle

**What**: Tracks the blocking window for PDT-restricted accounts.

**Columns/Parameters Involved**: `BlockingStartDate`, `BlockingExpirationDate`, `Operation`

**Rules**:
- BlockingStartDate: When the PDT restriction begins
- BlockingExpirationDate: When the restriction automatically expires (typically 90 calendar days)
- Operation: Integer code for the type of operation (block, unblock, extend, etc.)
- Both dates use datetimeoffset for timezone-aware tracking

---

## 3. Data Overview

2 rows. PDT blocking is a rare compliance action.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Primary key for the PDT log entry. |
| 2 | AccountId | varchar(50) | NO | - | CODE-BACKED | Apex account identifier (MASKED for PII). The account being blocked/unblocked for PDT. |
| 3 | CID | int | NO | - | CODE-BACKED | eToro Customer ID. Links to the customer in eToro's main database. |
| 4 | BlockingStartDate | datetimeoffset(7) | YES | - | CODE-BACKED | When the PDT restriction begins. NULL if this is an unblock operation. |
| 5 | BlockingExpirationDate | datetimeoffset(7) | YES | - | CODE-BACKED | When the PDT restriction automatically expires. NULL if indefinite or unblock. |
| 6 | Reason | nvarchar(4000) | YES | - | CODE-BACKED | Free-text justification for the blocking/unblocking action. Compliance documentation. |
| 7 | Timestamp | datetimeoffset(7) | NO | - | CODE-BACKED | When this operation was performed. |
| 8 | Initiator | varchar(50) | YES | - | CODE-BACKED | Username/identity of the person or system that initiated the operation. |
| 9 | Operation | int | NO | - | NAME-INFERRED | Operation type code. Likely: block, unblock, extend, modify. Exact values not determined from code - no lookup table exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (standalone audit log).

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PDTAccountTransactionLogs | CLUSTERED PK | Id | - | - | Active |
| IX_PDTAccountTransactionLogs_Timestamp | NC | Timestamp | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 View all PDT operations

```sql
SELECT AccountId, CID, Operation, BlockingStartDate, BlockingExpirationDate, Reason, Initiator, Timestamp
FROM recon.PDTAccountTransactionLogs WITH (NOLOCK)
ORDER BY Timestamp DESC;
```

### 8.2 Find currently blocked accounts

```sql
SELECT AccountId, CID, BlockingStartDate, BlockingExpirationDate, Reason
FROM recon.PDTAccountTransactionLogs WITH (NOLOCK)
WHERE BlockingExpirationDate > SYSDATETIMEOFFSET()
ORDER BY BlockingExpirationDate;
```

### 8.3 Find operations by initiator

```sql
SELECT Initiator, COUNT(*) AS OperationCount
FROM recon.PDTAccountTransactionLogs WITH (NOLOCK)
GROUP BY Initiator;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: recon.PDTAccountTransactionLogs | Type: Table | Source: Sodreconciliation/Sodreconciliation/recon/Tables/recon.PDTAccountTransactionLogs.sql*
