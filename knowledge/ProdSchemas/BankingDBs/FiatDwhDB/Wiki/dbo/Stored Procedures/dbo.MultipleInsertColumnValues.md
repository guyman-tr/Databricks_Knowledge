# dbo.MultipleInsertColumnValues

> Dynamic SQL utility that constructs and executes a multi-row INSERT from the MultipleColumnValueType TVP using STRING_AGG for value concatenation. Legacy version superseded by V2.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Dynamic multi-row INSERT from MultipleColumnValueType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MultipleInsertColumnValues extends InsertColumnValues to support multi-row INSERTs. Uses STRING_AGG to build INSERT ... VALUES (row1),(row2),... syntax from the MultipleColumnValueType TVP (which includes RowId for grouping). Executes via sp_executesql.

This is the legacy version. MultipleInsertColumnValuesV2 adds batch-size limiting (999 rows per INSERT) for large datasets.

---

## 2. Business Logic

### 2.1 Multi-Row Dynamic SQL

**Rules**:
- Gets column names from RowId=1 entries using STRING_AGG
- Groups values by RowId to build per-row value tuples
- Concatenates all rows with STRING_AGG
- Executes via sp_executesql (slightly safer than EXEC())
- No batch limiting - single INSERT for all rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TableName | nvarchar(max) | NO | - | CODE-BACKED | Target table name. |
| 2 | @MultipleColumnValueType | MultipleColumnValueType | NO | READONLY | CODE-BACKED | TVP with RowId + column-name/value triples. See dbo.MultipleColumnValueType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Any table (dynamic) | Write | Dynamic multi-row INSERT |
| @param | dbo.MultipleColumnValueType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.MultipleInsertColumnValues (procedure)
└── dbo.MultipleColumnValueType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MultipleColumnValueType | UDT | TVP parameter type |

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

### 8.1 Multi-row insert
```sql
DECLARE @data dbo.MultipleColumnValueType;
INSERT INTO @data VALUES (1, 'Description', 'Merchant A'), (1, 'Created', '2026-04-14'),
                         (2, 'Description', 'Merchant B'), (2, 'Created', '2026-04-14');
EXEC dbo.MultipleInsertColumnValues @TableName = 'dbo.FiatMerchants', @MultipleColumnValueType = @data;
```

### 8.2 Verify
```sql
SELECT TOP 5 * FROM dbo.FiatMerchants WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Use V2 for large datasets
```sql
-- For > 999 rows, use MultipleInsertColumnValuesV2 instead
EXEC dbo.MultipleInsertColumnValuesV2 @TableName = 'dbo.FiatMerchants', @MultipleColumnValueType = @data;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MultipleInsertColumnValues | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.MultipleInsertColumnValues.sql*
