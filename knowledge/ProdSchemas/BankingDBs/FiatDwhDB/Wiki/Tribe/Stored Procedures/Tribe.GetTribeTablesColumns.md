# Tribe.GetTribeTablesColumns

> Returns the latest column definitions for each Tribe table using ROW_NUMBER partitioned by TableHierarchyId.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CTE with ROW_NUMBER to get latest columns per table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetTribeTablesColumns returns the most recent column definition for each Tribe table. Uses a CTE with ROW_NUMBER() partitioned by TableHierarchyId, ordered by Created DESC, to select only the latest record per table. Returns TableName and ColumnsInfo.

---

## 2. Business Logic

### 2.1 Latest-Per-Group Query

**Rules**:
- CTE partitions by TableHierarchyId, orders by Created DESC
- WHERE RowNumber = 1 selects only the latest column definition
- WITH(NOLOCK) for non-blocking reads

---

## 3. Data Overview

N/A.

---

## 4. Elements

No parameters. Returns TableName + ColumnsInfo for each Tribe table.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Tribe.TablesColumns | Read | Source of column definitions |

### 5.2 Referenced By (other objects point to this)

Not analyzed.

---

## 6. Dependencies

Depends on: Tribe.TablesColumns.

---

## 7. Technical Details

N/A.

---

## 8. Sample Queries

### 8.1 Get all table columns
```sql
EXEC Tribe.GetTribeTablesColumns;
```

### 8.2 Manual equivalent
```sql
;WITH ColumnsInfo AS (
    SELECT TableName, Columns AS ColumnsInfo,
           ROW_NUMBER() OVER (PARTITION BY TableHierarchyId ORDER BY Created DESC) AS rn
    FROM Tribe.TablesColumns WITH (NOLOCK)
)
SELECT TableName, ColumnsInfo FROM ColumnsInfo WHERE rn = 1;
```

### 8.3 Find specific table
```sql
-- Use the procedure output to filter
DECLARE @r TABLE (TableName nvarchar(4000), ColumnsInfo varchar(max));
INSERT INTO @r EXEC Tribe.GetTribeTablesColumns;
SELECT * FROM @r WHERE TableName LIKE '%AccountsActivities%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.GetTribeTablesColumns | Type: Stored Procedure*
