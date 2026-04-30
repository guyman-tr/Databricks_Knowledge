# fiktivo.sqlmapoutput

> Artifact table created by the sqlmap SQL injection testing tool, used to store output data during security penetration testing of the database.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

sqlmapoutput is an artifact table created by sqlmap, an open-source penetration testing tool used to detect and exploit SQL injection vulnerabilities. This table is created by sqlmap during automated security testing to temporarily store extracted data or test output.

This table has no business function in the affiliate system. Its presence indicates that security penetration testing was performed against this database at some point. The table may have been left behind after testing and not cleaned up.

The table is empty (0 rows) and is not referenced by any views, functions, or stored procedures in the schema. It serves no operational purpose.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a utility artifact with no business rules.

---

## 3. Data Overview

Table is empty (0 rows). When populated by sqlmap during penetration testing, rows would contain arbitrary extracted data in the `data` column.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | int (IDENTITY) | NO | Auto-increment | CODE-BACKED | Auto-incrementing row identifier. Standard sqlmap output table structure. |
| 2 | data | nvarchar(4000) | YES | - | CODE-BACKED | Generic data storage column used by sqlmap to write extracted data during SQL injection testing. Supports up to 4000 Unicode characters per row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | id ASC | - | - | Active |

No compression, no fill factor customization. Standard sqlmap-generated table.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if table has any content
```sql
SELECT COUNT(*) AS RowCount
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
```

### 8.2 View all stored output data
```sql
SELECT id, data
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
ORDER BY id
```

### 8.3 Search for specific extraction patterns
```sql
SELECT id, data
FROM fiktivo.sqlmapoutput WITH (NOLOCK)
WHERE data LIKE '%password%' OR data LIKE '%admin%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sqlmapoutput | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.sqlmapoutput.sql*
