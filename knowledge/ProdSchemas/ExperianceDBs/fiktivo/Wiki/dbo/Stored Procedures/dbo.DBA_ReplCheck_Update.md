# dbo.DBA_ReplCheck_Update

> Upserts a timestamp into every published ReplCheck* table to verify that SQL Server replication is alive and current.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | ReplCheck* tables (sys.tables filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a DBA heartbeat procedure for SQL Server transactional replication monitoring. It scans sys.tables for all tables whose name starts with "ReplCheck" and that are marked as published (is_published = 1). For each such table it executes an UPSERT: UPDATE ... SET LastUpdated = getdate(); if no row was touched it falls through to INSERT. By running this SP on a schedule (e.g. every minute via SQL Agent), a replication monitor can query the subscriber side to confirm that the row arrived and measure latency.

---

## 2. Business Logic

- Queries sys.tables for tables matching name LIKE 'ReplCheck%' AND is_published = 1.
- Builds a dynamic UPSERT string for each table: UPDATE ... SET LastUpdated = getdate(); IF @@ROWCOUNT = 0 INSERT ... (LastUpdated).
- Iterates each table sequentially using a WHILE loop and executes the dynamic SQL via EXEC(@SQL).
- SET NOCOUNT ON suppresses row-count messages.
- No transaction or error handling; each EXEC is independent.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure takes no parameters |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | sys.tables | Read | Discovers all published ReplCheck tables |
| Dynamic EXEC | ReplCheck* tables | Write | Upserts a LastUpdated timestamp into each heartbeat table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DBA_ReplCheck_Update
  ├── sys.tables              (System catalog, READ)
  └── ReplCheck* tables       (Dynamic targets, WRITE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| sys.tables | System Catalog View | Enumerates published ReplCheck heartbeat tables |
| ReplCheck* tables | Tables (dynamic) | Receive the upserted LastUpdated timestamp |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Execute the replication heartbeat update
EXEC dbo.DBA_ReplCheck_Update;

-- Verify which tables will be targeted
SELECT name FROM sys.tables
WHERE name LIKE 'ReplCheck%' AND is_published = 1;

-- Check heartbeat timestamp on subscriber after execution
SELECT * FROM ReplCheck_Affiliates;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.DBA_ReplCheck_Update | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DBA_ReplCheck_Update.sql*
