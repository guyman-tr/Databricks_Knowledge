# Tribe.InsertTableColumnsInfo

> Inserts column definition metadata for a Tribe table, resolving TableHierarchyId from TablesHierarchy by table name.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Lookup TablesHierarchy.Id + INSERT into TablesColumns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertTableColumnsInfo records column definitions for a Tribe table. First resolves the TableHierarchyId from TablesHierarchy by @tableName, then inserts a new TablesColumns record. Not idempotent - every call creates a new record (allows tracking column changes over time).

---

## 2. Business Logic

### 2.1 Hierarchy Resolution + Insert

**Rules**:
- Looks up TablesHierarchy.Id by TableName (WITH NOLOCK)
- INSERTs into TablesColumns with resolved Id + table name + column info
- Multiple records per table are expected (historical)

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tableName | nvarchar(max) | NO | - | CODE-BACKED | Table name to register columns for. |
| 2 | @columnsInfo | nvarchar(max) | NO | - | CODE-BACKED | Serialized column definitions. |

---

## 5. Relationships

Reads: TablesHierarchy. Writes: TablesColumns.

---

## 6. Dependencies

Depends on: TablesHierarchy, TablesColumns.

---

## 7-9. Standard SP sections. No Atlassian sources.

---

## 8. Sample Queries

### 8.1 Register columns
```sql
EXEC Tribe.InsertTableColumnsInfo @tableName = 'AccountsActivities_AccountActivity-833937',
    @columnsInfo = 'FileDate,WorkDate,HolderId,AccountId,...';
```

### 8.2 Verify
```sql
SELECT TOP 1 * FROM Tribe.TablesColumns WITH (NOLOCK)
WHERE TableName = 'AccountsActivities_AccountActivity-833937' ORDER BY Created DESC;
```

### 8.3 Check hierarchy resolution
```sql
SELECT Id, TableName FROM Tribe.TablesHierarchy WITH (NOLOCK)
WHERE TableName = 'AccountsActivities_AccountActivity-833937';
```

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.InsertTableColumnsInfo | Type: Stored Procedure*
