# dbo.ColumnValueType

> User-defined table type that provides a generic column-name/value pair structure for dynamic column updates in stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with ColumnName + Value pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ColumnValueType is a table-valued parameter (TVP) type that enables dynamic, flexible column updates without requiring a dedicated stored procedure for each column. It provides a generic key-value interface where callers specify which column to update and what value to set.

This type exists to support a generic data patching pattern where individual columns of a row need to be updated independently. Without it, every column modification would require either a separate stored procedure or a monolithic procedure accepting every possible column as a parameter.

Data flows through this type when application code constructs a list of column-name/value pairs and passes them to InsertColumnValues. The procedure then dynamically builds and executes UPDATE statements for each pair. This is commonly used for one-off column updates or administrative corrections.

---

## 2. Business Logic

### 2.1 Generic Column Update Pattern

**What**: A dynamic update mechanism that allows any column on any table to be updated via name-value pairs.

**Columns/Parameters Involved**: `ColumnName`, `Value`

**Rules**:
- The caller provides the column name as a string, and the value as a string representation
- The consuming procedure (InsertColumnValues) uses dynamic SQL to apply the update
- Both fields are varchar(max) to accommodate any column name length and any serialized value

**Diagram**:
```
Application Code
      |
      v
[ColumnValueType TVP]     ->  { ColumnName: "Status", Value: "Active" }
      |                        { ColumnName: "Email",  Value: "x@y.com" }
      v
dbo.InsertColumnValues (SP)
      |
      v
Dynamic SQL: UPDATE [Table] SET [ColumnName] = [Value]
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ColumnName | varchar(max) | YES | - | CODE-BACKED | Name of the target database column to be updated. Must match an actual column name in the target table. Used by dynamic SQL in InsertColumnValues to construct the SET clause. |
| 2 | Value | varchar(max) | YES | - | CODE-BACKED | String representation of the value to assign to the target column. Cast/converted by the consuming procedure as needed for the target column's data type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.InsertColumnValues | @ColumnValues parameter | Parameter Type | Accepts a set of column-value pairs for single-row dynamic updates |
| dbo.MultipleInsertColumnValues | @ColumnValues parameter | Parameter Type | Accepts column-value pairs (legacy version, superseded by V2) |
| dbo.MultipleInsertColumnValuesV2 | @ColumnValues parameter | Parameter Type | Accepts column-value pairs (current version for multi-row updates) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertColumnValues | Stored Procedure | TVP parameter type for dynamic column updates |
| dbo.MultipleInsertColumnValues | Stored Procedure | TVP parameter type (legacy version) |
| dbo.MultipleInsertColumnValuesV2 | Stored Procedure | TVP parameter type (current version) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for a single column update
```sql
DECLARE @Updates dbo.ColumnValueType;
INSERT INTO @Updates (ColumnName, Value) VALUES ('Status', '1');
EXEC dbo.InsertColumnValues @ColumnValues = @Updates;
```

### 8.2 Populate the TVP with multiple column updates
```sql
DECLARE @Updates dbo.ColumnValueType;
INSERT INTO @Updates (ColumnName, Value)
VALUES ('FullName', 'John Doe'),
       ('Nickname', 'JD'),
       ('SortCode', '123456');
EXEC dbo.InsertColumnValues @ColumnValues = @Updates;
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'ColumnValueType' AND tt.schema_id = SCHEMA_ID('dbo');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ColumnValueType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.ColumnValueType.sql*
