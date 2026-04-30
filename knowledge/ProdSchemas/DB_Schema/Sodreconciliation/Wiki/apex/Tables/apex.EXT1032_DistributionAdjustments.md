# apex.EXT1032_DistributionAdjustments

> IRA distribution adjustments from Apex Clearing EXT1032 extract.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily IRA distribution adjustment data from Apex Clearing's EXT1032 extract. Each row represents an adjustment to a prior IRA distribution, such as recharacterizations, corrections, or excess contribution removals. These adjustments modify previously reported distribution amounts and must be tracked for accurate IRS reporting on Form 5498 and 1099-R.

The EXT1032 data is important for IRA compliance and tax reporting accuracy. When a distribution is adjusted after the fact (e.g., a rollover correction, excess contribution returned, or recharacterization), this extract captures those changes so that year-end tax forms can be corrected and customer records updated.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1032 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

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
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1032 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | Description | nvarchar(30) | YES | - | CODE-BACKED | Description of the distribution adjustment. |
| 5 | TransactionType | varchar(8) | YES | - | CODE-BACKED | Transaction type code for the adjustment (recharacterization, correction, etc.). |
| 6 | SecurityNumber | varchar(7) | YES | - | CODE-BACKED | Security number associated with the adjustment. MASKED (PII). |
| 7 | Amount | decimal(28,10) | YES | - | CODE-BACKED | Dollar amount of the distribution adjustment. |
| 8 | ProcessDate | datetime2(7) | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 9 | BatchEntryCode | varchar(5) | YES | - | NAME-INFERRED | Batch entry code identifying the processing batch for the adjustment. |

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
apex.EXT1032_DistributionAdjustments (table)
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
| PK_EXT1032_DistributionAdjustments | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1032_DistributionAdjustments_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1032_DistributionAdjustments | PRIMARY KEY | Unique Id per row |
| FK_EXT1032_DistributionAdjustments_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get distribution adjustments from the latest import

```sql
SELECT AccountNumber, Description, TransactionType, Amount, ProcessDate
FROM apex.EXT1032_DistributionAdjustments WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1032 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Summarize adjustments by transaction type

```sql
SELECT TransactionType, COUNT(*) AS AdjustmentCount, SUM(Amount) AS TotalAmount
FROM apex.EXT1032_DistributionAdjustments WITH (NOLOCK)
WHERE ProcessDate >= '2026-01-01'
GROUP BY TransactionType
ORDER BY TotalAmount DESC;
```

### 8.3 Find large distribution adjustments

```sql
SELECT AccountNumber, TransactionType, Amount, Description, ProcessDate
FROM apex.EXT1032_DistributionAdjustments WITH (NOLOCK)
WHERE ABS(Amount) > 10000
ORDER BY ABS(Amount) DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1032_DistributionAdjustments | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1032_DistributionAdjustments.sql*
