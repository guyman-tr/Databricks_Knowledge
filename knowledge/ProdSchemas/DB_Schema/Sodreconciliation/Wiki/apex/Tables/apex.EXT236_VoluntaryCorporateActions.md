# apex.EXT236_VoluntaryCorporateActions

> Voluntary corporate actions from Apex Clearing EXT236 extract: tender offers and rights with account-level share quantities.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily voluntary corporate action data from Apex Clearing's EXT236 extract. Each row represents a voluntary corporate action event at the account level -- tender offers, rights offerings, exchange offers, and other reorganizations where shareholder participation is optional. Unlike mandatory actions (EXT235), these require the account holder to elect whether to participate.

The EXT236 data enables eToro to notify customers of voluntary corporate actions affecting their holdings, track response deadlines, and ensure elections are submitted before cutoff dates. It provides account-level detail including the total shares eligible for participation and the action's terms.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT236 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Election Deadlines

**What**: Voluntary actions have critical cutoff dates.

**Columns Involved**: `ExpirationDate`, `ReorgCutOffDate`, `RecordDate`

**Rules**:
- ExpirationDate is the final date for shareholder elections
- ReorgCutOffDate is the internal Apex cutoff for submitting elections
- RecordDate determines which shareholders are eligible to participate
- ReorgCutOffDate is typically before ExpirationDate to allow processing time

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT236 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 5 | AccountName | varchar(40) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 6 | TotalShareQuantity | decimal(28,10) | YES | - | CODE-BACKED | Total shares held by the account that are eligible for the voluntary action. |
| 7 | OfficeName | varchar(55) | YES | - | CODE-BACKED | Office/branch name. |
| 8 | OfficeCode | varchar(6) | YES | - | CODE-BACKED | Apex office/branch code. |
| 9 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security subject to the corporate action. |
| 10 | Symbol | varchar(12) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 11 | ShortDescription | varchar(15) | YES | - | CODE-BACKED | Short description of the security. |
| 12 | ISIN | varchar(12) | YES | - | CODE-BACKED | International Securities Identification Number. |
| 13 | CorporateAction | varchar(50) | YES | - | CODE-BACKED | Type of voluntary corporate action (tender offer, rights offering, etc.). |
| 14 | CountryCode | varchar(2) | YES | - | CODE-BACKED | Country code for the security. |
| 15 | RecordDate | smalldatetime | YES | - | CODE-BACKED | Record date for determining eligible shareholders. |
| 16 | ExpirationDate | smalldatetime | YES | - | CODE-BACKED | Final date for shareholder elections. |
| 17 | ReorgCutOffDate | smalldatetime | YES | - | CODE-BACKED | Internal Apex cutoff date for submitting elections (before ExpirationDate). |
| 18 | ProcessDate | smalldatetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 19 | LastChangeDate | datetime | YES | - | CODE-BACKED | Date the corporate action record was last updated at Apex. |
| 20 | CorporateActionMessage | nvarchar(4000) | YES | - | CODE-BACKED | Detailed message describing the corporate action terms and options. |

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
apex.EXT236_VoluntaryCorporateActions (table)
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
| PK_EXT236_VoluntaryCorporateActions | CLUSTERED PK | Id | - | - | Active |
| IX_EXT236_VoluntaryCorporateActions_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT236_VoluntaryCorporateActions | PRIMARY KEY | Unique Id per row |
| FK_EXT236_VoluntaryCorporateActions_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get active voluntary corporate actions

```sql
SELECT CorporateAction, Symbol, Cusip, AccountNumber, TotalShareQuantity,
       RecordDate, ExpirationDate, ReorgCutOffDate
FROM apex.EXT236_VoluntaryCorporateActions WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 236 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ExpirationDate >= GETDATE()
ORDER BY ExpirationDate ASC;
```

### 8.2 Find actions approaching cutoff

```sql
SELECT CorporateAction, Symbol, AccountNumber, TotalShareQuantity,
       ReorgCutOffDate, ExpirationDate, CorporateActionMessage
FROM apex.EXT236_VoluntaryCorporateActions WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 236 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ReorgCutOffDate BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE())
ORDER BY ReorgCutOffDate ASC;
```

### 8.3 Summarize voluntary actions by type

```sql
SELECT CorporateAction, COUNT(DISTINCT Cusip) AS SecurityCount,
       COUNT(DISTINCT AccountNumber) AS AccountCount,
       SUM(TotalShareQuantity) AS TotalSharesEligible
FROM apex.EXT236_VoluntaryCorporateActions WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 236 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY CorporateAction
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT236_VoluntaryCorporateActions | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT236_VoluntaryCorporateActions.sql*
