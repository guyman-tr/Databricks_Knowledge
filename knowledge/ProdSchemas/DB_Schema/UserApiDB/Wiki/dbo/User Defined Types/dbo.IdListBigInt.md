# dbo.IdListBigInt (UDT)

> Table-valued parameter type for passing lists of BIGINT IDs to stored procedures (for tables with BIGINT primary keys).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Id (single column, BIGINT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.IdListBigInt is the BIGINT version of dbo.IdList. Used when passing lists of large integer IDs that exceed INT range, such as identity columns from high-volume tables.

---

## 2. Business Logic

No complex business logic. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | YES | - | CODE-BACKED | BIGINT identifier for tables with large identity columns. |

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

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @ids dbo.IdListBigInt
INSERT INTO @ids VALUES (9999999999), (8888888888)
SELECT * FROM @ids
```

### 8.2 Use in JOIN
```sql
DECLARE @ids dbo.IdListBigInt
INSERT INTO @ids VALUES (123456789012)
SELECT t.* FROM SomeTable t JOIN @ids i ON t.BigID = i.Id
```

### 8.3 Populate from query
```sql
DECLARE @ids dbo.IdListBigInt
INSERT INTO @ids SELECT SomeBigIntColumn FROM SomeTable WITH (NOLOCK) WHERE SomeCondition = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: dbo.IdListBigInt | Type: User Defined Type | Source: UserApiDB/UserApiDB/dbo/User Defined Types/dbo.IdListBigInt.sql*
