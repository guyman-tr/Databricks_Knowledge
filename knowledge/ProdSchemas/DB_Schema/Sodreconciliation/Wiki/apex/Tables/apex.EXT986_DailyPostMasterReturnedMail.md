# apex.EXT986_DailyPostMasterReturnedMail

> Returned mail tracking from Apex Clearing EXT986 extract: accounts with undeliverable postal mail.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily returned mail notifications from Apex Clearing's EXT986 extract. Each row represents an account where postal mail (statements, confirmations, tax documents, etc.) was returned as undeliverable. The data includes the account details, the type of mail that was returned, and the address on file at the time of return.

The EXT986 data supports regulatory compliance (FINRA Rule 3150 and SEC Rule 17a-3) by tracking accounts with bad addresses. Firms are required to investigate and update addresses when mail is returned. This data also helps prevent potential fraud and identity theft by flagging accounts where the registered address may no longer be valid.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT986 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

No complex multi-column business logic. See individual element descriptions.

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT986 file import. CASCADE DELETE. |
| 3 | Firm | varchar(10) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 4 | AccountNumber | varchar(13) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 5 | MailTypeID | varchar(4) | YES | - | NAME-INFERRED | Code identifying the type of mail that was returned (statement, confirm, tax doc, etc.). |
| 6 | MailTypeDescription | varchar(50) | YES | - | CODE-BACKED | Description of the returned mail type. |
| 7 | ProcessDate | datetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 8 | CorrespondentCode | varchar(17) | YES | - | CODE-BACKED | Correspondent firm code. |
| 9 | OfficeCode | varchar(10) | YES | - | CODE-BACKED | Apex office/branch code. |
| 10 | AccountName | varchar(40) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 11 | AddressLine1 | varchar(40) | YES | - | CODE-BACKED | Primary address line where mail was sent. MASKED (PII). |
| 12 | AddressLine2 | varchar(40) | YES | - | CODE-BACKED | Secondary address line. MASKED (PII). |
| 13 | AddressLine3 | varchar(40) | YES | - | CODE-BACKED | Third address line. MASKED (PII). |
| 14 | AddressLine4 | varchar(40) | YES | - | CODE-BACKED | Fourth address line. MASKED (PII). |
| 15 | City | varchar(20) | YES | - | CODE-BACKED | City of the address. MASKED (PII). |
| 16 | State | varchar(5) | YES | - | CODE-BACKED | State code of the address. |
| 17 | ZipCode | varchar(9) | YES | - | CODE-BACKED | ZIP code of the address. MASKED (PII). |

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
apex.EXT986_DailyPostMasterReturnedMail (table)
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
| PK_EXT986_DailyPostMasterReturnedMail | CLUSTERED PK | Id | - | - | Active |
| IX_EXT986_DailyPostMasterReturnedMail_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT986_DailyPostMasterReturnedMail | PRIMARY KEY | Unique Id per row |
| FK_EXT986_DailyPostMasterReturnedMail_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get returned mail from the latest import

```sql
SELECT AccountNumber, AccountName, MailTypeDescription, AddressLine1, City, State, ZipCode, ProcessDate
FROM apex.EXT986_DailyPostMasterReturnedMail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 986 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Count returned mail by type

```sql
SELECT MailTypeID, MailTypeDescription, COUNT(*) AS ReturnCount
FROM apex.EXT986_DailyPostMasterReturnedMail WITH (NOLOCK)
WHERE ProcessDate >= '2026-04-01'
GROUP BY MailTypeID, MailTypeDescription
ORDER BY ReturnCount DESC;
```

### 8.3 Find accounts with repeated returned mail

```sql
SELECT AccountNumber, COUNT(DISTINCT SodFileId) AS OccurrenceCount
FROM apex.EXT986_DailyPostMasterReturnedMail WITH (NOLOCK)
WHERE ProcessDate >= '2026-03-01'
GROUP BY AccountNumber
HAVING COUNT(DISTINCT SodFileId) > 1
ORDER BY OccurrenceCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT986_DailyPostMasterReturnedMail | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT986_DailyPostMasterReturnedMail.sql*
