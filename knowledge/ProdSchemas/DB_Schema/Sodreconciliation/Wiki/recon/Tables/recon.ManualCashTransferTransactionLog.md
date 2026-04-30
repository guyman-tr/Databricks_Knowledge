# recon.ManualCashTransferTransactionLog

> Audit log of individual manual cash transfer transactions between accounts, tracking source, destination, amount, comments, and the bulk import file they originated from.

| Property | Value |
|----------|-------|
| **Schema** | recon |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 1 NC on BulkImportId + 1 NC on Timestamp) |

---

## 1. Business Meaning

This table logs every individual manual cash transfer executed through the SOD reconciliation system. Each row represents a single transfer of funds from a source account to a destination account, typically performed to correct cash balance discrepancies found during reconciliation.

Transfers can originate from bulk import files (linked via BulkImportId to `ManualCashTransferBulkImport`) or be created individually through the UI. The table provides a complete audit trail of who initiated each transfer, when, and why (via Comments).

---

## 2. Business Logic

No complex multi-column business logic. Simple audit log for cash transfer operations.

---

## 3. Data Overview

4,300 rows. Each represents a single manual cash transfer between accounts.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Primary key for the transfer log entry. |
| 2 | SourceAccount | varchar(50) | YES | - | CODE-BACKED | Account number from which cash is debited. May be an internal/house account. |
| 3 | DestinationAccount | varchar(50) | NO | - | CODE-BACKED | Account number receiving the cash credit (MASKED for PII). |
| 4 | Amount | decimal(28,10) | NO | - | CODE-BACKED | Transfer amount. Positive = credit to destination. |
| 5 | Comments | nvarchar(4000) | YES | - | CODE-BACKED | Free-text reason/justification for the transfer. Used for audit documentation. |
| 6 | Timestamp | datetimeoffset(7) | NO | - | CODE-BACKED | When the transfer was executed. Timezone-aware. |
| 7 | Initiator | varchar(50) | YES | - | CODE-BACKED | Username/identity of the person who initiated the transfer. |
| 8 | BulkImportId | uniqueidentifier | YES | - | CODE-BACKED | FK to recon.ManualCashTransferBulkImport.Id. NULL for individually-created transfers; non-NULL for transfers from a bulk upload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BulkImportId | recon.ManualCashTransferBulkImport | FK | Links to the bulk import file this transfer came from |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
recon.ManualCashTransferTransactionLog (table)
└── recon.ManualCashTransferBulkImport (table) [BulkImportId FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| recon.ManualCashTransferBulkImport | Table | FK from BulkImportId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualCashTransferTransactionLog | CLUSTERED PK | Id | - | - | Active |
| IX_ManualCashTransferTransactionLog_BulkImportId | NC | BulkImportId | - | - | Active |
| IX_ManualCashTransferTransactionLog_Timestamp | NC | Timestamp | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ManualCashTransferTransactionLog_ManualCashTransferBulkImport_BulkImportId | FOREIGN KEY | BulkImportId -> recon.ManualCashTransferBulkImport.Id |

---

## 8. Sample Queries

### 8.1 View recent manual transfers

```sql
SELECT SourceAccount, DestinationAccount, Amount, Comments, Initiator, Timestamp
FROM recon.ManualCashTransferTransactionLog WITH (NOLOCK)
ORDER BY Timestamp DESC;
```

### 8.2 Find transfers from a bulk import

```sql
SELECT tl.SourceAccount, tl.DestinationAccount, tl.Amount, tl.Comments
FROM recon.ManualCashTransferTransactionLog tl WITH (NOLOCK)
WHERE tl.BulkImportId = '{bulk-import-id}'
ORDER BY tl.DestinationAccount;
```

### 8.3 Total amount transferred by initiator

```sql
SELECT Initiator, COUNT(*) AS TransferCount, SUM(Amount) AS TotalAmount
FROM recon.ManualCashTransferTransactionLog WITH (NOLOCK)
GROUP BY Initiator
ORDER BY TotalAmount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: recon.ManualCashTransferTransactionLog | Type: Table | Source: Sodreconciliation/Sodreconciliation/recon/Tables/recon.ManualCashTransferTransactionLog.sql*
