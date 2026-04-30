# Trade.DeleteIndexDividendsTbl

> Simple table-valued parameter type for passing DividendIDs to bulk-delete index dividend records from the IndexDividends table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DividendID (int) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.DeleteIndexDividendsTbl is a minimal table type used to pass a list of DividendIDs to Trade.DeleteIndexDividends. Index dividends track dividend payments for index-based instruments such as ETFs and indices. This type enables bulk removal of index dividend records in a single procedure call.

Without this type, the deletion procedure would need to accept a comma-separated string or multiple parameters. The TVP approach allows set-based operations and efficient bulk deletion.

The procedure receives the TVP, JOINs or uses IN/EXISTS against it, and deletes matching rows from the IndexDividends table. Typically used during maintenance or when correcting data that was loaded incorrectly.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column list type for DividendID.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Identifier of the index dividend record to delete. References Trade.IndexDividends or equivalent. Each row in the TVP corresponds to one record to remove. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | Implicit | Index dividend record to delete |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DeleteIndexDividends | Parameter (TVP) | Parameter | Receives DividendIDs for bulk deletion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteIndexDividends | Stored Procedure | READONLY parameter for bulk dividend deletion |

---

## 7. Technical Details

### 7.1 Indexes

None (heap).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk delete specific index dividends

```sql
DECLARE @ToDelete Trade.DeleteIndexDividendsTbl;
INSERT INTO @ToDelete (DividendID) VALUES (101), (102), (103);
EXEC Trade.DeleteIndexDividends @DividendIDs = @ToDelete;
```

### 8.2 Delete index dividends from a query result

```sql
DECLARE @ToDelete Trade.DeleteIndexDividendsTbl;
INSERT INTO @ToDelete (DividendID)
SELECT DividendID
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  InstrumentID = 42 AND ExDate < '2024-01-01';

EXEC Trade.DeleteIndexDividends @DividendIDs = @ToDelete;
```

### 8.3 Pass empty set (no-op)

```sql
DECLARE @ToDelete Trade.DeleteIndexDividendsTbl;
-- No INSERT; procedure handles empty TVP
EXEC Trade.DeleteIndexDividends @DividendIDs = @ToDelete;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteIndexDividendsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DeleteIndexDividendsTbl.sql*
