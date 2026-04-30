# Trade.TinyIntList

> A table-valued parameter type for passing batches of small integer values (0-255) to stored procedures, typically used for filtering by type or status codes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Val (tinyint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.TinyIntList is a table-valued parameter (TVP) type for passing sets of small integer values into stored procedures. The tinyint range (0-255) makes it ideal for filtering by dictionary-backed codes such as status IDs, type IDs, or other enumerated classification values.

This type exists to support set-based filtering by category. Rather than accepting a single type or status value, procedures can accept a list of types/statuses and process all matching records in one pass.

Application services populate this type with a set of classification codes - for example, multiple InstrumentTypeIDs or status values - and pass it to procedures that JOIN against it to filter their working dataset.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type used purely as a parameter container.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Val | tinyint | NO | - | CODE-BACKED | A small integer value (0-255) representing a classification code. The semantic meaning depends on the consuming procedure - typically a Dictionary-backed type ID or status code used for set-based filtering. No primary key constraint, so duplicates are technically allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a generic container type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsChangesForDataApi | @InstrumentTypeIDs | Parameter (TVP) | Filters position changes by a set of instrument type codes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsChangesForDataApi | Stored Procedure | READONLY parameter for filtering by instrument type codes |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate a TinyIntList

```sql
DECLARE @Types Trade.TinyIntList;
INSERT INTO @Types (Val) VALUES (1), (5), (10);
```

### 8.2 Use TinyIntList to filter position changes by instrument type

```sql
DECLARE @InstrTypeIDs Trade.TinyIntList;
INSERT INTO @InstrTypeIDs (Val) VALUES (1), (2), (10);

EXEC Trade.GetPositionsChangesForDataApi
    @InstrumentTypeIDs = @InstrTypeIDs;
```

### 8.3 Join a TinyIntList against a dictionary table for label resolution

```sql
DECLARE @StatusCodes Trade.TinyIntList;
INSERT INTO @StatusCodes (Val) VALUES (1), (2);

SELECT  s.Val AS StatusID,
        ds.Name AS StatusName
FROM    @StatusCodes s
JOIN    Dictionary.PositionStatus ds WITH (NOLOCK) ON ds.ID = s.Val;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TinyIntList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.TinyIntList.sql*
