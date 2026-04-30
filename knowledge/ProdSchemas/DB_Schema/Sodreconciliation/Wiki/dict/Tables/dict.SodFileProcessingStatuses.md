# dict.SodFileProcessingStatuses

> Lookup table defining the processing status values for SOD file imports from Apex Clearing.

| Property | Value |
|----------|-------|
| **Schema** | dict |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This is a simple dictionary/lookup table that defines the possible processing statuses for Apex Clearing SOD (Start-of-Day) file imports. When the SOD Azure Function processes a file from Azure Blob Storage, it records the processing outcome using one of these status values in the `apex.SodFiles.Status` column.

The status tracks the lifecycle of each file from initial detection (Unknown/InProgress) through successful import (Success) or failure (Fail/Invalid).

---

## 2. Business Logic

### 2.1 File Processing Status Lifecycle

**What**: Each SOD file progresses through statuses as it is processed.

**Columns/Parameters Involved**: `Id`, `Value`

**Rules**:
- 0 = Unknown: Default initial state when a file record is first created
- 1 = InProgress: File is currently being parsed and imported (note: typo "InPogress" in data)
- 2 = Success: File was successfully parsed and all data loaded into the corresponding EXT table
- 3 = Fail: File processing failed (error details in SodFiles.ErrorMessage)
- 4 = Invalid: File format is not recognized (e.g., unknown extract number)

**Diagram**:
```
[0 Unknown] -> [1 InProgress] -> [2 Success]
                              -> [3 Fail]
                              -> [4 Invalid]
```

---

## 3. Data Overview

| Id | Value | Meaning |
|---|---|---|
| 0 | Unknown | Default initial state. File detected but not yet processed. |
| 1 | InPogress | File is currently being parsed and imported by the SOD Azure Function. (Note: historical typo - should be "InProgress".) |
| 2 | Success | File successfully parsed and data loaded into the corresponding apex.EXT* table. |
| 3 | Fail | File processing failed due to an error (parsing failure, timeout, infrastructure issue). Details in SodFiles.ErrorMessage. |
| 4 | Invalid | File format not recognized - the extract number doesn't match any known apex.EXT* table mapping. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | VERIFIED | Status identifier. 0=Unknown, 1=InProgress, 2=Success, 3=Fail, 4=Invalid. Referenced by apex.SodFiles.Status via FK. |
| 2 | Value | varchar(32) | YES | - | VERIFIED | Human-readable status label. Used for display in the SOD Reconciliation UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| apex.SodFiles | Status | FK (ON DELETE CASCADE) | Each SOD file record references a processing status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from Status column |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SodFileProcessingStatuses | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all statuses

```sql
SELECT Id, Value FROM dict.SodFileProcessingStatuses WITH (NOLOCK) ORDER BY Id;
```

### 8.2 Count files by status

```sql
SELECT s.Value AS Status, COUNT(*) AS FileCount
FROM apex.SodFiles f WITH (NOLOCK)
JOIN dict.SodFileProcessingStatuses s WITH (NOLOCK) ON f.Status = s.Id
GROUP BY s.Value ORDER BY FileCount DESC;
```

### 8.3 Find failed files with error details

```sql
SELECT f.Id, f.BlobUrl, f.ProcessDate, f.ErrorMessage
FROM apex.SodFiles f WITH (NOLOCK)
WHERE f.Status = 3
ORDER BY f.ProcessDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | File processing flow: Data Factory -> Blob Storage -> Event Grid -> Azure Function -> parse and store in DB with status tracking |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dict.SodFileProcessingStatuses | Type: Table | Source: Sodreconciliation/Sodreconciliation/dict/Tables/dict.SodFileProcessingStatuses.sql*
