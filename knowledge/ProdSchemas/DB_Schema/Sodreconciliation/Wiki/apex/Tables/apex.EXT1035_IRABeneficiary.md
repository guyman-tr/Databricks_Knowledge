# apex.EXT1035_IRABeneficiary

> IRA beneficiary designations from Apex Clearing EXT1035 extract: names, percentages, tax IDs, and addresses.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily IRA beneficiary designation data from Apex Clearing's EXT1035 extract. Each row represents a single beneficiary designated on an IRA account, including the beneficiary's name, percentage allocation, tax ID, date of birth, address, and the type of beneficiary (primary or contingent). An IRA account may have multiple rows -- one per beneficiary.

The EXT1035 data is critical for IRA administration and compliance. Beneficiary designations determine who inherits the IRA assets upon the account holder's death and affect how inherited IRA distributions are calculated. This data must be maintained accurately to honor the account holder's wishes and comply with IRS rules for inherited IRAs.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1035 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Beneficiary Allocation

**What**: Beneficiaries share the IRA assets based on percentage allocations.

**Columns Involved**: `BeneficiaryCode`, `BeneficiaryPercent`

**Rules**:
- BeneficiaryCode distinguishes primary from contingent beneficiaries
- BeneficiaryPercent indicates each beneficiary's share of the account
- Primary beneficiary percentages should total 100%
- Contingent beneficiaries inherit only if all primary beneficiaries predecease the account holder

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1035 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(8) | YES | - | CODE-BACKED | Apex IRA account number. MASKED (PII). |
| 4 | AccountName | varchar(58) | YES | - | CODE-BACKED | IRA account holder name. MASKED (PII). |
| 5 | BeneficiaryFirstName | varchar(20) | YES | - | CODE-BACKED | Beneficiary's first name. MASKED (PII). |
| 6 | BeneficiaryLastName | varchar(20) | YES | - | CODE-BACKED | Beneficiary's last name. MASKED (PII). |
| 7 | BeneficiaryCode | varchar(1) | YES | - | CODE-BACKED | Beneficiary type code (P=Primary, C=Contingent). |
| 8 | BeneficiaryPercent | varchar(15) | YES | - | CODE-BACKED | Percentage of IRA assets allocated to this beneficiary (stored as string). |
| 9 | BeneficiaryTaxID | varchar(9) | YES | - | CODE-BACKED | Beneficiary's tax identification number (SSN). MASKED (PII). |
| 10 | BeneficiaryBirthdate | datetime | YES | - | CODE-BACKED | Beneficiary's date of birth. MASKED (PII). |
| 11 | BeneficiaryStreetAddress | varchar(30) | YES | - | CODE-BACKED | Beneficiary's street address. MASKED (PII). |
| 12 | BeneficiaryCity | varchar(20) | YES | - | CODE-BACKED | Beneficiary's city. MASKED (PII). |
| 13 | BeneficiaryState | varchar(2) | YES | - | CODE-BACKED | Beneficiary's state code. |
| 14 | BeneficiaryZip | varchar(5) | YES | - | CODE-BACKED | Beneficiary's ZIP code. MASKED (PII). |
| 15 | IRACode | varchar(4) | YES | - | CODE-BACKED | IRA type code (Traditional, Roth, SEP, SIMPLE, etc.). |
| 16 | Closed | varchar(1) | YES | - | CODE-BACKED | Account closed indicator. |

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
apex.EXT1035_IRABeneficiary (table)
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
| PK_EXT1035_IRABeneficiary | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1035_IRABeneficiary_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1035_IRABeneficiary | PRIMARY KEY | Unique Id per row |
| FK_EXT1035_IRABeneficiary_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get beneficiary designations from the latest import

```sql
SELECT AccountNumber, AccountName, BeneficiaryFirstName, BeneficiaryLastName,
       BeneficiaryCode, BeneficiaryPercent, IRACode
FROM apex.EXT1035_IRABeneficiary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1035 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, BeneficiaryCode, BeneficiaryPercent DESC;
```

### 8.2 Find accounts with multiple beneficiaries

```sql
SELECT AccountNumber, COUNT(*) AS BeneficiaryCount
FROM apex.EXT1035_IRABeneficiary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1035 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY AccountNumber
HAVING COUNT(*) > 1
ORDER BY BeneficiaryCount DESC;
```

### 8.3 Summarize beneficiary types by IRA code

```sql
SELECT IRACode, BeneficiaryCode, COUNT(*) AS BeneficiaryCount
FROM apex.EXT1035_IRABeneficiary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1035 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY IRACode, BeneficiaryCode
ORDER BY IRACode, BeneficiaryCode;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1035_IRABeneficiary | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1035_IRABeneficiary.sql*
