# fiktivo.sqlmapoutput

> Utility output table used for capturing text-based results from SQL operations, likely created as part of stored procedure output or data export functionality.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This is a simple two-column utility table designed to capture text-based output from SQL operations. It serves as a generic sink for string data produced by stored procedures or administrative scripts that need to write results to a table rather than returning them directly.

The table name "sqlmapoutput" suggests it may have been created for use by stored procedures that map/transform data and write results line-by-line. The table could also serve as a staging area for data export operations where results are accumulated before being read by an external process.

The table is currently empty (0 rows) and no views or stored procedures in the fiktivo schema reference it, indicating it may be used by cross-schema procedures or external scripts, or it may be a legacy artifact.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | INT IDENTITY | NO | auto-increment | NAME-INFERRED | Auto-incrementing row identifier. Preserves the order in which output lines were written. |
| 2 | data | NVARCHAR(4000) | YES | - | NAME-INFERRED | Text content of the output line. NVARCHAR(4000) allows storing up to 4000 Unicode characters per row, suitable for capturing query results, log messages, or formatted output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | id ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read all output lines in order
```sql
SELECT id, data
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
ORDER BY id ASC
```

### 8.2 Search for specific output content
```sql
SELECT id, data
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
WHERE data LIKE '%search_term%'
ORDER BY id ASC
```

### 8.3 Get latest output entries
```sql
SELECT TOP 20 id, data
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
ORDER BY id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 3.8/10 (Elements: 0/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sqlmapoutput | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.sqlmapoutput.sql*
