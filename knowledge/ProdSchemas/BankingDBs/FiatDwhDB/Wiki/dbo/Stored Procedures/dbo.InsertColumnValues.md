# dbo.InsertColumnValues

> Dynamic SQL utility procedure that constructs and executes an INSERT statement from column-value pairs passed via the ColumnValueType TVP.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Dynamic INSERT built from @TableName + ColumnValueType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertColumnValues is a generic utility that dynamically constructs and executes an INSERT statement. The caller provides a target table name and a set of column-name/value pairs via the ColumnValueType TVP. The procedure builds the INSERT SQL string and executes it via EXEC().

This enables inserting rows into any table without dedicated INSERT procedures. Used for one-off data corrections and administrative operations.

**Security Note**: Uses dynamic SQL with string concatenation - the @TableName and column values are directly interpolated into the SQL string without parameterization. This is a SQL injection risk if exposed to untrusted input.

---

## 2. Business Logic

### 2.1 Dynamic SQL Construction

**What**: Builds INSERT INTO @TableName (col1,col2) VALUES ('val1','val2') from TVP data.

**Rules**:
- Concatenates column names from TVP (ordered alphabetically)
- Wraps all values in single quotes (treats everything as string)
- Executes via EXEC(@SQLString) - not parameterized
- Single-row INSERT only (one row from TVP columns)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TableName | varchar(max) | NO | - | CODE-BACKED | Target table name for the INSERT. Injected directly into SQL string. |
| 2 | @ColumnValueType | ColumnValueType | NO | READONLY | CODE-BACKED | TVP with column-name/value pairs. See dbo.ColumnValueType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Any table (dynamic) | Write | Dynamic INSERT target |
| @param | dbo.ColumnValueType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.InsertColumnValues (procedure)
└── dbo.ColumnValueType (type)
└── [dynamic target table]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ColumnValueType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a row into a table
```sql
DECLARE @cols dbo.ColumnValueType;
INSERT INTO @cols VALUES ('Description', 'Test Merchant'), ('Created', '2026-04-14');
EXEC dbo.InsertColumnValues @TableName = 'dbo.FiatMerchants', @ColumnValueType = @cols;
```

### 8.2 View generated SQL (procedure also SELECTs the SQL string)
```sql
DECLARE @cols dbo.ColumnValueType;
INSERT INTO @cols VALUES ('Name', 'Test'), ('AccountProgramId', '1');
EXEC dbo.InsertColumnValues @TableName = 'dbo.SubPrograms', @ColumnValueType = @cols;
-- First result set shows the generated SQL string
```

### 8.3 Check the type structure
```sql
SELECT * FROM sys.table_types WHERE name = 'ColumnValueType';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.InsertColumnValues | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.InsertColumnValues.sql*
