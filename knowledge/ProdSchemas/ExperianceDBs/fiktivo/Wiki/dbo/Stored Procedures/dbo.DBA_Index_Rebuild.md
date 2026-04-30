# dbo.DBA_Index_Rebuild

> Iterates a pre-populated temp table of tables and indexes, checks current fragmentation via sys.dm_db_index_physical_stats, and executes online index rebuilds for any index exceeding the configured fragmentation threshold.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | #TablesReIndex (caller-provided temp table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a DBA maintenance procedure used to reduce index fragmentation on specified tables without taking the database offline. It is designed to be called as part of a scheduled maintenance job. The caller is responsible for creating and populating the temporary table #TablesReIndex with the tables, index names, and fragmentation thresholds to inspect before calling this SP. The procedure then performs online index rebuilds (REBUILD WITH (ONLINE = ON)), pausing 15 seconds between each rebuild to reduce I/O pressure on production workloads.

---

## 2. Business Logic

- Expects the caller to have already created the temp table #TablesReIndex with columns: ID (INT IDENTITY), TableName (varchar), IndexName (varchar), ReIndexFragPercent (INT).
- Outer WHILE loop iterates each row in #TablesReIndex.
- For each table, resolves the object_id dynamically via EXEC and queries sys.dm_db_index_physical_stats to find indexes whose avg_fragmentation_in_percent exceeds the threshold.
- IndexName = 'all' is a wildcard that matches every index on the table.
- Inner WHILE loop rebuilds indexes one at a time (lowest Itype and IndexID first) using dynamic SQL: ALTER INDEX [...] ON <table> REBUILD WITH (ONLINE = ON).
- @Debug = 1 (default) prints intermediate diagnostic SELECT output including object IDs and the #Indexes working table contents.
- @DoNotRunRebuild = 1 prints the generated SQL without executing it (dry-run mode).
- A 15-second WAITFOR DELAY is inserted between each rebuild to throttle I/O.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @Debug | BIT | IN | 1 | High | When 1, emits diagnostic SELECT output at each step |
| 2 | @DoNotRunRebuild | BIT | IN | 0 | High | When 1, prints SQL but does not execute rebuilds (dry run) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | sys.dm_db_index_physical_stats | Read | Retrieves current fragmentation statistics per index |
| JOIN | sys.indexes | Read | Resolves index names and types for each object |
| Dynamic EXEC | Caller-specified tables | Write | Issues ALTER INDEX REBUILD on target tables |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DBA_Index_Rebuild
  ├── #TablesReIndex          (Temp table, caller-created)
  ├── sys.dm_db_index_physical_stats  (DMV, READ)
  └── sys.indexes             (System catalog, READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| #TablesReIndex | Temp Table (caller-created) | Drives the list of tables and indexes to inspect |
| sys.dm_db_index_physical_stats | DMV | Provides fragmentation percentage per index |
| sys.indexes | System Catalog View | Resolves index name and type |

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
-- Standard usage: create the config table, then call the SP
CREATE TABLE #TablesReIndex (
    ID INT NOT NULL IDENTITY(1,1),
    TableName VARCHAR(100),
    IndexName VARCHAR(100),
    ReIndexFragPercent INT
);
INSERT INTO #TablesReIndex (TableName, IndexName, ReIndexFragPercent)
VALUES ('dbo.tblaff_Affiliates', 'all', 10),
       ('dbo.tblaff_CPA',        'all', 15);

EXEC dbo.DBA_Index_Rebuild @Debug = 1, @DoNotRunRebuild = 0;
DROP TABLE #TablesReIndex;

-- Dry-run to preview what would be rebuilt
CREATE TABLE #TablesReIndex (
    ID INT NOT NULL IDENTITY(1,1),
    TableName VARCHAR(100),
    IndexName VARCHAR(100),
    ReIndexFragPercent INT
);
INSERT INTO #TablesReIndex VALUES ('dbo.tblaff_Leads', 'all', 5);
EXEC dbo.DBA_Index_Rebuild @Debug = 0, @DoNotRunRebuild = 1;
DROP TABLE #TablesReIndex;

-- Target a single named index on a table
CREATE TABLE #TablesReIndex (
    ID INT NOT NULL IDENTITY(1,1),
    TableName VARCHAR(100),
    IndexName VARCHAR(100),
    ReIndexFragPercent INT
);
INSERT INTO #TablesReIndex VALUES ('dbo.DeferredMessages', 'Ran2', 20);
EXEC dbo.DBA_Index_Rebuild @Debug = 1, @DoNotRunRebuild = 0;
DROP TABLE #TablesReIndex;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.DBA_Index_Rebuild | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DBA_Index_Rebuild.sql*
