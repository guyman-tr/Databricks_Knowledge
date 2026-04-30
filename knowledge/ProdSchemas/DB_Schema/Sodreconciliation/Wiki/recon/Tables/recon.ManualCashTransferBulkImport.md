# recon.ManualCashTransferBulkImport

> Stores uploaded bulk import files for manual cash transfer operations between accounts, tracking the file content, uploader identity, and timestamp.

| Property | Value |
|----------|-------|
| **Schema** | recon |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 PK + 1 NC on Timestamp) |

---

## 1. Business Meaning

This table stores the raw uploaded files used for bulk manual cash transfers between accounts. When operations staff need to move cash between multiple accounts (e.g., to correct reconciliation breaks), they can upload a CSV/Excel file containing the transfer instructions. The binary file content is stored here for audit purposes, along with who uploaded it and when.

Each bulk import file generates individual transfer records in `recon.ManualCashTransferTransactionLog`. Currently contains 27 bulk import records.

---

## 2. Business Logic

No complex multi-column business logic. Simple file storage with audit metadata.

---

## 3. Data Overview

27 rows. Each represents a bulk cash transfer file upload.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Primary key for the bulk import record. |
| 2 | Content | varbinary(max) | YES | - | CODE-BACKED | Raw binary content of the uploaded file (CSV/Excel). Stored for audit trail and potential re-processing. |
| 3 | FileName | varchar(50) | NO | - | CODE-BACKED | Original filename of the uploaded file. |
| 4 | Initiator | varchar(50) | YES | - | CODE-BACKED | Username or identity of the person who uploaded the file. |
| 5 | Timestamp | datetimeoffset(7) | NO | - | CODE-BACKED | When the file was uploaded. Uses datetimeoffset for timezone-aware audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| recon.ManualCashTransferTransactionLog | BulkImportId | FK | Individual transfer records link back to the bulk import file |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| recon.ManualCashTransferTransactionLog | Table | FK from BulkImportId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualCashTransferBulkImport | CLUSTERED PK | Id | - | - | Active |
| IX_ManualCashTransferBulkImport_Timestamp | NC | Timestamp | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List recent bulk imports

```sql
SELECT Id, FileName, Initiator, Timestamp
FROM recon.ManualCashTransferBulkImport WITH (NOLOCK)
ORDER BY Timestamp DESC;
```

### 8.2 Count transfers per bulk import

```sql
SELECT bi.FileName, bi.Initiator, bi.Timestamp, COUNT(tl.Id) AS TransferCount
FROM recon.ManualCashTransferBulkImport bi WITH (NOLOCK)
LEFT JOIN recon.ManualCashTransferTransactionLog tl WITH (NOLOCK) ON bi.Id = tl.BulkImportId
GROUP BY bi.FileName, bi.Initiator, bi.Timestamp
ORDER BY bi.Timestamp DESC;
```

### 8.3 Find imports by a specific user

```sql
SELECT Id, FileName, Timestamp
FROM recon.ManualCashTransferBulkImport WITH (NOLOCK)
WHERE Initiator = 'admin@etoro.com'
ORDER BY Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: recon.ManualCashTransferBulkImport | Type: Table | Source: Sodreconciliation/Sodreconciliation/recon/Tables/recon.ManualCashTransferBulkImport.sql*
