# apex.EXT1036_W8Recertification

> W-8 form recertification tracking from Apex Clearing EXT1036 extract for foreign account holders.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily W-8 recertification tracking data from Apex Clearing's EXT1036 extract. Each row represents a foreign account holder's W-8 form status, including the form type, certification date, expiration date, Chapter 3 and Chapter 4 FATCA codes, and GIIN (Global Intermediary Identification Number). W-8 forms are IRS documents that foreign persons use to certify their non-US tax status and claim treaty benefits.

The EXT1036 data is critical for tax compliance. W-8 forms expire (typically after 3 years) and must be recertified. If a W-8 form expires, the firm must apply 30% backup withholding on US-source income. This data enables eToro to proactively identify accounts approaching W-8 expiration and initiate the recertification process before withholding becomes required.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1036 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 W-8 Expiration Tracking

**What**: W-8 forms have certification and expiration dates that drive withholding behavior.

**Columns Involved**: `W8CertificationDate`, `W8ExpirationDate`, `W8Code`, `USAWithholdingCode`

**Rules**:
- W8CertificationDate is when the form was signed/certified by the account holder
- W8ExpirationDate is when the W-8 form expires (typically 3 years after certification)
- W8Code indicates the type of W-8 form (W-8BEN, W-8BEN-E, W-8IMY, etc.)
- USAWithholdingCode determines the withholding rate for US-source income
- Accounts with expired W-8 forms are subject to 30% backup withholding

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1036 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(8) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | Name | varchar(77) | YES | - | CODE-BACKED | Account holder name. |
| 5 | Ch31042Code | varchar(2) | YES | - | NAME-INFERRED | Chapter 3 (IRS Code Section 1042) status code for tax treaty purposes. |
| 6 | Ch41042Code | varchar(2) | YES | - | NAME-INFERRED | Chapter 4 (FATCA) status code for foreign financial institution classification. |
| 7 | USAWithholdingCode | varchar(1) | YES | - | CODE-BACKED | US tax withholding rate code applied to the account. |
| 8 | W8Code | varchar(1) | YES | - | CODE-BACKED | W-8 form type code (BEN, BEN-E, IMY, ECI, EXP). |
| 9 | W8CertificationDate | datetime | YES | - | CODE-BACKED | Date the W-8 form was certified/signed by the account holder. |
| 10 | GIINNumber | varchar(19) | YES | - | CODE-BACKED | Global Intermediary Identification Number for FATCA reporting. |
| 11 | ForeignTaxID | varchar(25) | YES | - | CODE-BACKED | Foreign tax identification number of the account holder. |
| 12 | Closed | varchar(1) | YES | - | CODE-BACKED | Account closed indicator. |
| 13 | W8ExpirationDate | datetime | YES | - | CODE-BACKED | Date the W-8 form expires. Accounts with expired forms face 30% withholding. |

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
apex.EXT1036_W8Recertification (table)
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
| PK_EXT1036_W8Recertification | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1036_W8Recertification_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1036_W8Recertification | PRIMARY KEY | Unique Id per row |
| FK_EXT1036_W8Recertification_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get W-8 status from the latest import

```sql
SELECT AccountNumber, Name, W8Code, W8CertificationDate, W8ExpirationDate,
       USAWithholdingCode, GIINNumber
FROM apex.EXT1036_W8Recertification WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1036 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find accounts with expiring W-8 forms (next 90 days)

```sql
SELECT AccountNumber, Name, W8Code, W8CertificationDate, W8ExpirationDate
FROM apex.EXT1036_W8Recertification WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1036 AND Status = 2 ORDER BY ProcessDate DESC)
  AND W8ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 90, GETDATE())
  AND Closed IS NULL
ORDER BY W8ExpirationDate ASC;
```

### 8.3 Count accounts by W-8 form type

```sql
SELECT W8Code, Closed, COUNT(*) AS AccountCount
FROM apex.EXT1036_W8Recertification WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1036 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY W8Code, Closed
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1036_W8Recertification | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1036_W8Recertification.sql*
