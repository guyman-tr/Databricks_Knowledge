# apex.EXT1043_LargeTraderIds

> SEC Large Trader ID tracking from Apex Clearing EXT1043 extract per account (SEC Rule 13h-1).

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily Large Trader ID data from Apex Clearing's EXT1043 extract. Each row represents an account's Large Trader ID assignment under SEC Rule 13h-1. A Large Trader is any person (or entity) whose transactions in NMS securities equal or exceed 2 million shares or $20 million in a single day, or 20 million shares or $200 million in a calendar month. Large Traders must register with the SEC and obtain an LTID.

The EXT1043 data supports SEC compliance by tracking which accounts have been assigned Large Trader IDs, the effective and end dates of those assignments, and the reason for the assignment. Broker-dealers are required to maintain records of LTIDs and report them to the SEC upon request.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1043 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Large Trader Lifecycle

**What**: LTIDs have effective and end dates tracking their active period.

**Columns Involved**: `LargeTraderID`, `LargeTraderEffectiveDate`, `LargeTraderEndDate`, `ActionCode`, `LargeTraderReasonCode`

**Rules**:
- LargeTraderID is the SEC-assigned identifier
- LargeTraderEffectiveDate is when the LTID became active
- LargeTraderEndDate is when the LTID was deactivated (NULL if still active)
- ActionCode indicates the current action (add, update, delete)
- LargeTraderReasonCode provides the reason for the assignment or change

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1043 file import. CASCADE DELETE. |
| 3 | ProcessDate | datetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 4 | ClientNumber | varchar(4) | YES | - | CODE-BACKED | Apex client number identifier. |
| 5 | CorrespondentID | int | YES | - | CODE-BACKED | Correspondent firm identifier. |
| 6 | BranchCode | varchar(3) | YES | - | CODE-BACKED | Branch/office code. |
| 7 | AccountCode | varchar(5) | YES | - | CODE-BACKED | Account code. MASKED (PII). |
| 8 | AccountName | varchar(60) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 9 | LargeTraderCountNumber | int | YES | - | NAME-INFERRED | Count of Large Trader IDs associated with this account. |
| 10 | ActionCode | char(1) | YES | - | CODE-BACKED | Action code for the record (A=Add, U=Update, D=Delete). |
| 11 | RecordTypeCode | varchar(3) | YES | - | NAME-INFERRED | Record type code within the extract. |
| 12 | LargeTraderID | varchar(35) | YES | - | CODE-BACKED | SEC Large Trader ID assigned to the account. |
| 13 | LargeTraderReasonCode | varchar(35) | YES | - | CODE-BACKED | Reason code for the Large Trader ID assignment or change. |
| 14 | LargeTraderEffectiveDate | datetime | YES | - | CODE-BACKED | Date the Large Trader ID became effective. |
| 15 | LargeTraderEndDate | datetime | YES | - | CODE-BACKED | Date the Large Trader ID was deactivated. NULL if still active. |
| 16 | UpdatedLastTimestamp | datetime | YES | - | CODE-BACKED | Timestamp of the last update to this Large Trader record. |

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
apex.EXT1043_LargeTraderIds (table)
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
| PK_EXT1043_LargeTraderIds | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1043_LargeTraderIds_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1043_LargeTraderIds | PRIMARY KEY | Unique Id per row |
| FK_EXT1043_LargeTraderIds_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get active Large Trader IDs

```sql
SELECT AccountCode, AccountName, LargeTraderID, LargeTraderEffectiveDate,
       LargeTraderEndDate, LargeTraderReasonCode, ActionCode
FROM apex.EXT1043_LargeTraderIds WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1043 AND Status = 2 ORDER BY ProcessDate DESC)
  AND LargeTraderEndDate IS NULL
ORDER BY AccountCode;
```

### 8.2 Find recent Large Trader changes

```sql
SELECT AccountCode, AccountName, LargeTraderID, ActionCode, LargeTraderReasonCode,
       UpdatedLastTimestamp
FROM apex.EXT1043_LargeTraderIds WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1043 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ActionCode IN ('A', 'U')
ORDER BY UpdatedLastTimestamp DESC;
```

### 8.3 Count Large Trader IDs by action type

```sql
SELECT ActionCode, COUNT(*) AS RecordCount
FROM apex.EXT1043_LargeTraderIds WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1043 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY ActionCode
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1043_LargeTraderIds | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1043_LargeTraderIds.sql*
