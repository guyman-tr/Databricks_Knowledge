# Trade.OrderStatusCheckResultTbl

> Memory-optimized single-column TVP holding order status check result codes (e.g. pass/fail or status IDs).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Result |
| **Partition** | N/A |
| **Indexes** | 1 (ix1 nonclustered on Result) |

---

## 1. Business Meaning

Trade.OrderStatusCheckResultTbl is a memory-optimized table-valued parameter type with a single integer column (Result). It holds the outcome of order-status checks: typically a status code or result flag indicating whether an order validation or status check passed or failed.

This type exists to return or pass status-check results from validation logic. Procedures such as OrderForCloseUpdate and OrderForOpenUpdate declare a variable of this type and populate it during order status validation.

The type flows as a local table variable. Validation logic inserts one or more result codes; consuming code reads the table to determine next steps.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column result list.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Result | int | NO | - | CODE-BACKED | Status check result code (e.g. validation pass/fail or status ID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Result may semantically map to order-status or validation codes.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseUpdate | @StatusIDCheck | Local variable (TVP) | Holds order status check results during close update |
| Trade.OrderForOpenUpdate | @StatusIDCheck | Local variable (TVP) | Holds order status check results during open update |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseUpdate | Stored Procedure | Local table variable for status check results |
| Trade.OrderForOpenUpdate | Stored Procedure | Local table variable for status check results |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| ix1 | NONCLUSTERED | Result |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate with single result

```sql
DECLARE @StatusIDCheck Trade.OrderStatusCheckResultTbl;
INSERT INTO @StatusIDCheck (Result) VALUES (1);
```

### 8.2 Populate multiple result codes

```sql
INSERT INTO @StatusIDCheck (Result)
VALUES (0), (1), (2);
```

### 8.3 Use in validation flow

```sql
DECLARE @StatusIDCheck Trade.OrderStatusCheckResultTbl;
INSERT INTO @StatusIDCheck (Result)
SELECT CASE WHEN @IsValid = 1 THEN 0 ELSE -1 END;
-- Procedure logic reads @StatusIDCheck to decide next steps
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderStatusCheckResultTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrderStatusCheckResultTbl.sql*
