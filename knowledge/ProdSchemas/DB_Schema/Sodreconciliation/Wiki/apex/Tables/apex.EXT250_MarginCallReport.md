# apex.EXT250_MarginCallReport

> Margin call report from Apex Clearing EXT250 extract: call amounts, types, and due dates per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily margin call report from Apex Clearing's EXT250 extract. Each row represents an active margin call on a customer account, including the call amount, call type, originating trade date, and due date. Margin calls are demands for the customer to deposit additional funds or securities when the account's equity falls below the required maintenance level.

The EXT250 data is critical for risk management and customer communication. Unmet margin calls can result in forced liquidation of positions. This data enables eToro to notify customers of margin calls, track their status, and take appropriate action before Apex initiates forced liquidation. It also provides a cross-check against the margin data in EXT981 (buying power) to validate margin call triggers.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT250 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Margin Call Types

**What**: Different call types have different urgency and resolution requirements.

**Columns Involved**: `CallType`, `CallAmount`, `DueDate`, `RegTDate`

**Rules**:
- CallType identifies the type of margin call (maintenance, Reg T, day trade, etc.)
- Maintenance calls must be met within a set number of business days (typically 2-5)
- Reg T calls relate to the initial 50% margin requirement and are due by RegTDate
- If a call is not met by DueDate, Apex may liquidate positions to restore margin compliance

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT250 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | AccountName | varchar(40) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 5 | CallAmount | decimal(18,2) | YES | - | CODE-BACKED | Dollar amount of the margin call that must be met. |
| 6 | CallType | varchar(2) | YES | - | CODE-BACKED | Type of margin call (maintenance, Reg T, day trade, etc.). |
| 7 | TradeDate | smalldatetime | YES | - | CODE-BACKED | Trade date that triggered the margin call. |
| 8 | DueDate | smalldatetime | YES | - | CODE-BACKED | Date by which the margin call must be met to avoid forced liquidation. |
| 9 | RegTDate | smalldatetime | YES | - | CODE-BACKED | Reg T date for the margin call (federal regulatory deadline). |

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
apex.EXT250_MarginCallReport (table)
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
| PK_EXT250_MarginCallReport | CLUSTERED PK | Id | - | - | Active |
| IX_EXT250_MarginCallReport_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT250_MarginCallReport | PRIMARY KEY | Unique Id per row |
| FK_EXT250_MarginCallReport_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get active margin calls

```sql
SELECT AccountNumber, AccountName, CallType, CallAmount, TradeDate, DueDate, RegTDate
FROM apex.EXT250_MarginCallReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 250 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY DueDate ASC, CallAmount DESC;
```

### 8.2 Find urgent margin calls due today or past due

```sql
SELECT AccountNumber, AccountName, CallType, CallAmount, DueDate
FROM apex.EXT250_MarginCallReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 250 AND Status = 2 ORDER BY ProcessDate DESC)
  AND DueDate <= CAST(GETDATE() AS date)
ORDER BY CallAmount DESC;
```

### 8.3 Summarize margin calls by type

```sql
SELECT CallType, COUNT(*) AS CallCount, SUM(CallAmount) AS TotalCallAmount,
       AVG(CallAmount) AS AvgCallAmount
FROM apex.EXT250_MarginCallReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 250 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY CallType
ORDER BY TotalCallAmount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT250_MarginCallReport | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT250_MarginCallReport.sql*
