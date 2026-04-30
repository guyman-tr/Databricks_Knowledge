# dbo.ProcessDateTable

> Simple configuration/tracking table that stores process dates with associated status codes, used to record which dates have been processed by the SOD reconciliation pipeline.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, no PK) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

This table is a **legacy/abandoned** process tracking table. Live data shows only 10 rows, all with StatusID=0, covering dates from 2021-09-07 to 2022-01-21. No new rows have been added since early 2022, confirming the table is no longer in active use.

The table was likely used during early SOD reconciliation development to manually track which business dates had been processed. It has since been superseded by the `apex.SodFiles` table, which provides comprehensive file-level processing tracking with proper status FK (to dict.SodFileProcessingStatuses), timestamps, error messages, and format identification.

The table lacks a primary key, indexes, or foreign keys, and all StatusID values are 0 (no status lookup table exists), further confirming this was a quick utility table that was abandoned once the proper SodFiles tracking mechanism was built.

---

## 2. Business Logic

### 2.1 Process Date Tracking

**What**: Records which dates have been queued or processed by the reconciliation pipeline.

**Columns/Parameters Involved**: `ProcessDate`, `StatusID`

**Rules**:
- ProcessDate stores the business date being processed (nullable datetime)
- StatusID tracks the processing state for that date (nullable int)
- No uniqueness constraint exists on ProcessDate, so duplicate date entries are possible
- No FK constrains StatusID to any lookup table

---

## 3. Data Overview

10 rows. Tracks historical process dates, all with StatusID=0:

| ID | ProcessDate | StatusID | Meaning |
|---|---|---|---|
| 1 | 2021-09-07 | 0 | First tracked process date. StatusID=0 for all rows (status meaning unknown - no lookup table). |
| 4 | 2021-12-01 | 0 | December 2021 processing date. |
| 8 | 2022-01-03 | 0 | First business day of 2022. |
| 10 | 2022-01-21 | 0 | Most recent entry (ID=10). Table appears to no longer be actively used. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate identifier for each process date entry. Not defined as a primary key. |
| 2 | ProcessDate | datetime | YES | - | NAME-INFERRED | The business date being tracked for reconciliation processing. |
| 3 | StatusID | int | YES | - | NAME-INFERRED | Processing status code for this date. Likely maps to states such as pending, in-progress, or complete, though no FK constraint enforces this. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. No foreign key constraints are defined.

### 5.2 Referenced By (other objects point to this)

No known dependents in the database schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ProcessDateTable (table)
  (no dependencies)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

No known dependents.

---

## 7. Technical Details

### 7.1 Indexes

None. The table has no primary key, unique constraints, or indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | IDENTITY | ID is IDENTITY(1,1) -- auto-increments but is not a PK |

---

## 8. Sample Queries

### 8.1 View all process dates and statuses

```sql
SELECT ID, ProcessDate, StatusID
FROM dbo.ProcessDateTable WITH (NOLOCK)
ORDER BY ProcessDate DESC;
```

### 8.2 Find dates with a specific status

```sql
SELECT ProcessDate, StatusID
FROM dbo.ProcessDateTable WITH (NOLOCK)
WHERE StatusID = 2
ORDER BY ProcessDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table.

---

*Generated: 2026-04-11 | Quality: 5.0/10 (Elements: 6/10, Logic: 4/10, Relationships: 4/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 2/11*
*Object: dbo.ProcessDateTable | Type: Table | Source: Sodreconciliation/Sodreconciliation/dbo/Tables/dbo.ProcessDateTable.sql*
