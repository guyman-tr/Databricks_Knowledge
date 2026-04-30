# apex.EXT1033_RMDReport

> Required Minimum Distribution (RMD) report from Apex Clearing EXT1033 extract for IRA accounts.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily Required Minimum Distribution (RMD) report from Apex Clearing's EXT1033 extract. Each row represents an IRA account's RMD status, including the calculated RMD amount, remaining RMD to be distributed, the fair market value (FMV) used for the calculation, and the life expectancy factor. RMDs are mandatory distributions that IRA holders must take beginning at a certain age, as required by the IRS.

The EXT1033 data is critical for IRA compliance monitoring. Failure to take required minimum distributions results in a significant IRS penalty (currently 25% of the shortfall). This data enables eToro to notify customers of their RMD obligations and track whether distributions have been taken.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1033 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 RMD Calculation

**What**: The RMD is calculated from fair market value and life expectancy factor.

**Columns Involved**: `RMD`, `RMDRemaining`, `FMV`, `Factor`

**Rules**:
- RMD = FMV (prior year-end) / Factor (life expectancy divisor)
- RMDRemaining tracks how much of the year's RMD has yet to be distributed
- Factor is based on IRS Uniform Lifetime Table or Joint Life Table
- Values are stored as varchar strings and may need conversion for calculations

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1033 file import. CASCADE DELETE. |
| 3 | Correspondent | varchar(52) | YES | - | CODE-BACKED | Correspondent firm identifier/name. |
| 4 | Branch | varchar(3) | YES | - | CODE-BACKED | Branch/office code. |
| 5 | Account | varchar(8) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 6 | RepCode | varchar(7) | YES | - | CODE-BACKED | Registered representative code. |
| 7 | AccountName | nvarchar(56) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 8 | AddressLine1 | nvarchar(35) | YES | - | CODE-BACKED | Primary address line. MASKED (PII). |
| 9 | AddressLine2 | nvarchar(35) | YES | - | CODE-BACKED | Secondary address line. MASKED (PII). |
| 10 | AddressLine3 | nvarchar(35) | YES | - | CODE-BACKED | Third address line. MASKED (PII). |
| 11 | AddressLine4 | nvarchar(35) | YES | - | CODE-BACKED | Fourth address line. MASKED (PII). |
| 12 | City | nvarchar(35) | YES | - | CODE-BACKED | City of the account holder's address. MASKED (PII). |
| 13 | ST | varchar(2) | YES | - | CODE-BACKED | State code. |
| 14 | ZipCode | varchar(5) | YES | - | CODE-BACKED | ZIP code. MASKED (PII). |
| 15 | ForeignID | varchar(2) | YES | - | NAME-INFERRED | Foreign account identifier or country code. |
| 16 | RMD | varchar(25) | YES | - | CODE-BACKED | Required Minimum Distribution amount for the year (stored as string). |
| 17 | RMDRemaining | varchar(25) | YES | - | CODE-BACKED | Remaining RMD amount yet to be distributed (stored as string). |
| 18 | FMV | varchar(25) | YES | - | CODE-BACKED | Fair Market Value of the IRA as of prior year-end (stored as string). |
| 19 | Factor | varchar(25) | YES | - | CODE-BACKED | Life expectancy factor from IRS tables (stored as string). |
| 20 | Closed | nchar(1) | YES | - | CODE-BACKED | Account closed indicator. |
| 21 | IRACode | varchar(4) | YES | - | CODE-BACKED | IRA type code (Traditional, Roth, SEP, SIMPLE, etc.). |
| 22 | RestrictionCode | nchar(1) | YES | - | CODE-BACKED | Account restriction code. |
| 23 | ProcessDate | datetime2(7) | YES | - | CODE-BACKED | Business date of the Apex extract file. |

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
apex.EXT1033_RMDReport (table)
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
| PK_EXT1033_RMDReport | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1033_RMDReport_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1033_RMDReport | PRIMARY KEY | Unique Id per row |
| FK_EXT1033_RMDReport_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get RMD status from the latest import

```sql
SELECT Account, AccountName, IRACode, RMD, RMDRemaining, FMV, Factor, ProcessDate
FROM apex.EXT1033_RMDReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1033 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY Account;
```

### 8.2 Find accounts with unfulfilled RMD obligations

```sql
SELECT Account, AccountName, RMD, RMDRemaining, FMV, IRACode
FROM apex.EXT1033_RMDReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1033 AND Status = 2 ORDER BY ProcessDate DESC)
  AND RMDRemaining IS NOT NULL AND RMDRemaining <> '0' AND RMDRemaining <> '0.00'
ORDER BY Account;
```

### 8.3 Count accounts by IRA type

```sql
SELECT IRACode, COUNT(*) AS AccountCount
FROM apex.EXT1033_RMDReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1033 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY IRACode
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1033_RMDReport | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1033_RMDReport.sql*
