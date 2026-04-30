# apex.EXT989_DailyElectronicCommunicationPreferenceExtract

> E-delivery preferences from Apex Clearing EXT989 extract: statement, confirm, prospectus, proxy, and tax delivery settings per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily electronic communication preference data from Apex Clearing's EXT989 extract. Each row represents an account's delivery preferences for various document types -- statements, trade confirmations, prospectuses, proxy materials, and tax documents. The data indicates whether each document type is delivered electronically or via physical mail.

The EXT989 data supports regulatory compliance and operational efficiency. Brokers must maintain accurate records of customer communication preferences to ensure proper delivery of required documents. This data also feeds into cost analysis (paper vs electronic delivery) and helps identify accounts that have opted out of e-delivery.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT989 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Multi-Document Delivery Preferences

**What**: Each account has independent preferences for five document types.

**Columns Involved**: `StatementStatus`, `ConfirmStatus`, `ProspectusStatus`, `ProxyStatus`, `TaxStatus`

**Rules**:
- Each status field indicates the delivery preference for that document type (electronic, paper, suppressed, etc.)
- An account may have mixed preferences (e.g., electronic statements but paper tax documents)
- ClosedIndicator and ClosedReason track accounts that have been closed from e-delivery

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT989 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | RegisteredRepCode | varchar(3) | YES | - | CODE-BACKED | Registered representative code assigned to the account. |
| 5 | StatementStatus | varchar(20) | YES | - | CODE-BACKED | E-delivery preference for account statements. |
| 6 | ConfirmStatus | varchar(20) | YES | - | CODE-BACKED | E-delivery preference for trade confirmations. |
| 7 | ProspectusStatus | varchar(20) | YES | - | CODE-BACKED | E-delivery preference for prospectus documents. |
| 8 | ProxyStatus | varchar(20) | YES | - | CODE-BACKED | E-delivery preference for proxy materials. |
| 9 | TaxStatus | varchar(20) | YES | - | CODE-BACKED | E-delivery preference for tax documents (1099s, etc.). |
| 10 | ClosedIndicator | varchar(1) | YES | - | CODE-BACKED | Flag indicating if the e-delivery enrollment has been closed. |
| 11 | ClosedReason | varchar(1) | YES | - | NAME-INFERRED | Reason code for why the e-delivery enrollment was closed. |
| 12 | EmailAddress | varchar(255) | YES | - | CODE-BACKED | Email address for electronic delivery. MASKED (PII). |
| 13 | LastUpdated | smalldatetime | YES | - | CODE-BACKED | Date the preferences were last updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT989_DailyElectronicCommunicationPreferenceExtract (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT989_DailyElectronicCommunicationPreferenceExtract | CLUSTERED PK | Id | - | - | Active |
| IX_EXT989_DailyElectronicCommunicationPreferenceExtract_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT989_DailyElectronicCommunicationPreferenceExtract | PRIMARY KEY | Unique Id per row |
| FK_EXT989_DailyElectronicCommunicationPreferenceExtract_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get delivery preferences from the latest import

```sql
SELECT AccountNumber, StatementStatus, ConfirmStatus, ProspectusStatus, ProxyStatus, TaxStatus, EmailAddress
FROM apex.EXT989_DailyElectronicCommunicationPreferenceExtract WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 989 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Count accounts by delivery preference combinations

```sql
SELECT StatementStatus, ConfirmStatus, TaxStatus, COUNT(*) AS AccountCount
FROM apex.EXT989_DailyElectronicCommunicationPreferenceExtract WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 989 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY StatementStatus, ConfirmStatus, TaxStatus
ORDER BY AccountCount DESC;
```

### 8.3 Find accounts with closed e-delivery enrollment

```sql
SELECT AccountNumber, ClosedIndicator, ClosedReason, EmailAddress, LastUpdated
FROM apex.EXT989_DailyElectronicCommunicationPreferenceExtract WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 989 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ClosedIndicator IS NOT NULL
ORDER BY LastUpdated DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT989_DailyElectronicCommunicationPreferenceExtract | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT989_DailyElectronicCommunicationPreferenceExtract.sql*
