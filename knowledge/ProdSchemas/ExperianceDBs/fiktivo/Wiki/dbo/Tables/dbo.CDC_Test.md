# dbo.CDC_Test

> Empty test table used for validating Change Data Capture (CDC) configuration on the fiktivo database.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, unique NC index) |
| **Partition** | No |
| **Indexes** | 1 active (unique NC on ID) |

---

## 1. Business Meaning

This table exists solely for testing and validating Change Data Capture (CDC) functionality on the fiktivo database. CDC is a SQL Server feature that records insert, update, and delete activity on tables, enabling incremental data extraction for ETL pipelines and audit trails.

The table contains no production data (0 rows) and serves as a non-disruptive target for CDC configuration testing. It mirrors a minimal Dictionary-like structure with MarketingRegionID and Name columns, likely modeled after Dictionary.MarketingRegion for test purposes.

DBA teams use this table to verify that CDC capture jobs are running correctly, that change tracking infrastructure is operational, and that CDC-dependent downstream systems can consume change records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a CDC infrastructure test table with no business logic.

---

## 3. Data Overview

Table is empty (0 rows). This is expected - the table exists only for CDC infrastructure testing.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Has a unique nonclustered index but no formal PK constraint - the table uses a heap with a unique NC index pattern. |
| 2 | MarketingRegionID | tinyint | NO | - | NAME-INFERRED | Test column mimicking Dictionary.MarketingRegion structure. Would hold marketing region identifiers in a production context, but this table is never populated. |
| 3 | Name | varchar(50) | NO | - | NAME-INFERRED | Test column for a descriptive name. Mirrors a typical Dictionary table Name column. Never populated. |

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

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_CDC_Test_ID | NC UNIQUE | ID | - | - | Active |

Note: Table has no clustered index (heap). The unique NC index on ID provides uniqueness without clustering.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if CDC test table has data
```sql
SELECT COUNT(*) AS RowCount FROM dbo.CDC_Test WITH (NOLOCK)
```

### 8.2 Insert a test row for CDC validation
```sql
-- Used by DBAs to test CDC capture
-- INSERT INTO dbo.CDC_Test (MarketingRegionID, Name) VALUES (1, 'Test Region')
SELECT TOP 1 * FROM dbo.CDC_Test WITH (NOLOCK)
```

### 8.3 Check CDC capture instance exists for this table
```sql
SELECT *
FROM cdc.change_tables WITH (NOLOCK)
WHERE source_object_id = OBJECT_ID('dbo.CDC_Test')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 6/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CDC_Test | Type: Table | Source: fiktivo/dbo/Tables/dbo.CDC_Test.sql*
