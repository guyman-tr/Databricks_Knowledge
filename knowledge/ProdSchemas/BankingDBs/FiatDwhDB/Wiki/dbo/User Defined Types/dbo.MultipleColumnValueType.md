# dbo.MultipleColumnValueType

> User-defined table type that extends ColumnValueType with a RowId for multi-row dynamic column updates.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with RowId + ColumnName + Value triples |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MultipleColumnValueType is a table-valued parameter type that extends the ColumnValueType pattern to support updating multiple rows simultaneously. Each entry identifies a specific row (via RowId), the column to update (ColumnName), and the new value (Value). This enables batch updates across multiple records in a single procedure call.

This type exists because the simpler ColumnValueType only works for single-row updates. When the application needs to update different columns on different rows (e.g., updating statuses for multiple accounts), it constructs a batch of (RowId, ColumnName, Value) triples and passes them through this type.

Data flows through this type when the application performs bulk administrative corrections or batch updates. The consuming procedures (MultipleInsertColumnValues, MultipleInsertColumnValuesV2) iterate over the entries, grouping by RowId, and execute dynamic SQL for each row's updates.

---

## 2. Business Logic

### 2.1 Multi-Row Dynamic Update Pattern

**What**: Extension of the generic column update pattern to handle multiple rows in a single call.

**Columns/Parameters Involved**: `RowId`, `ColumnName`, `Value`

**Rules**:
- RowId identifies which row in the target table to update (typically the PK value)
- ColumnName specifies which column on that row to modify
- Value provides the new value as a string
- Multiple entries with the same RowId update multiple columns on the same row
- The consuming procedure groups by RowId and builds per-row UPDATE statements

**Diagram**:
```
Input TVP rows:
  RowId=100, ColumnName="Status", Value="1"
  RowId=100, ColumnName="Email",  Value="a@b.com"
  RowId=200, ColumnName="Status", Value="2"
       |
       v
MultipleInsertColumnValues(V2)
       |
       v
Row 100: UPDATE SET Status='1', Email='a@b.com'
Row 200: UPDATE SET Status='2'
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RowId | bigint | NO | - | CODE-BACKED | Primary key value of the target row to update. Used to identify which specific row receives the column update. NOT NULL ensures every update targets a valid row. |
| 2 | ColumnName | varchar(max) | YES | - | CODE-BACKED | Name of the target database column to update on the identified row. Must match an actual column name in the target table. |
| 3 | Value | varchar(max) | YES | - | CODE-BACKED | String representation of the new value to assign. Cast/converted by the consuming procedure based on the target column's data type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.MultipleInsertColumnValues | @ColumnValues parameter | Parameter Type | Accepts batch of row-column-value triples (legacy version) |
| dbo.MultipleInsertColumnValuesV2 | @ColumnValues parameter | Parameter Type | Accepts batch of row-column-value triples (current version) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.MultipleInsertColumnValues | Stored Procedure | TVP parameter type for multi-row updates (legacy) |
| dbo.MultipleInsertColumnValuesV2 | Stored Procedure | TVP parameter type for multi-row updates (current) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update different columns on multiple rows
```sql
DECLARE @Updates dbo.MultipleColumnValueType;
INSERT INTO @Updates (RowId, ColumnName, Value)
VALUES (100, 'FullName', 'Jane Smith'),
       (100, 'Nickname', 'JS'),
       (200, 'FullName', 'John Doe');
EXEC dbo.MultipleInsertColumnValuesV2 @ColumnValues = @Updates;
```

### 8.2 Batch status update across multiple records
```sql
DECLARE @Updates dbo.MultipleColumnValueType;
INSERT INTO @Updates (RowId, ColumnName, Value)
VALUES (1001, 'StatusType', '1'),
       (1002, 'StatusType', '2'),
       (1003, 'StatusType', '0');
EXEC dbo.MultipleInsertColumnValuesV2 @ColumnValues = @Updates;
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'MultipleColumnValueType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MultipleColumnValueType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.MultipleColumnValueType.sql*
