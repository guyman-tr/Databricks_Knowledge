# BackOffice.GetUsedMarginInLine

> Inline table-valued function returning the total used margin in cents for a customer as a single-row table, combining open position amounts and mirror cash - the set-based, CROSS APPLY-friendly variant of the used margin calculation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(UsedMargin INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUsedMarginInLine` calculates the same used margin metric as `BackOffice.GetUsedMargin` (cents, open positions + mirror cash) but as an inline TVF instead of a scalar function. Inline TVFs execute as subqueries in the optimizer's query plan, allowing SQL Server to expand them inline rather than calling a separate scalar function for each row - this can significantly improve performance in queries that join or apply the function across multiple customers.

The function is designed for use with `CROSS APPLY` or `OUTER APPLY` in multi-customer queries:
```sql
OUTER APPLY BackOffice.GetUsedMarginInLine(c.CID) AS margin
```

Like `GetUsedMargin` (but unlike `GetUsedMarginBigInt`), this function filters to StatusID=1 (open positions only). It uses subquery syntax rather than variables, computed in a single expression within a derived table, making it a truly inline set-based operation.

---

## 2. Business Logic

### 2.1 Inline Used Margin Computation

**What**: A single-row result computed via subqueries in a derived table, combining open position collateral and mirror cash.

**Columns/Parameters Involved**: `@CID`, `AmountInOpenPositions`, `TotalMirrorCash`, `UsedMargin`

**Rules**:
- Inner derived table computes two subqueries:
  - `AmountInOpenPositions = (SELECT CAST(SUM(Amount) * 100 AS INTEGER) FROM Trade.PositionTbl WITH (NOLOCK) WHERE CID = @CID AND StatusID = 1)`
  - `TotalMirrorCash = (SELECT CAST(SUM(Amount) * 100 AS INTEGER) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = @CID)`
- Outer SELECT: `ISNULL(AmountInOpenPositions, 0) + ISNULL(TotalMirrorCash, 0) AS UsedMargin`
- The `StatusID = 1` filter matches `GetUsedMargin` (after the 2024 MIMOPSA-13899 fix) - only open positions counted.
- Returns a single row with one column: `UsedMargin` (INTEGER, cents).
- Unlike scalar functions, inline TVFs can be used in CROSS APPLY without per-row scalar execution overhead.

**Diagram**:
```
@CID
  |
  v (derived table)
  AmountInOpenPositions = SUM(Amount)*100 FROM Trade.PositionTbl WHERE StatusID=1
  TotalMirrorCash = SUM(Amount)*100 FROM Trade.Mirror
  |
  v (outer select)
  ISNULL(AmountInOpenPositions,0) + ISNULL(TotalMirrorCash,0) AS UsedMargin
  |
  v
Returns: single row { UsedMargin: INTEGER (cents) }
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose total used margin to calculate. Filters both Trade.PositionTbl (WHERE StatusID=1) and Trade.Mirror. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UsedMargin | INT | NO | 0 | CODE-BACKED | Total used margin in cents (INTEGER). Sum of: (1) open position amounts (StatusID=1 only) from Trade.PositionTbl * 100, plus (2) mirror/copy-trade cash from Trade.Mirror * 100. Returns 0 (via ISNULL wrappers) if the customer has no open positions or mirror allocations. Same behavioral semantics as GetUsedMargin (StatusID=1 filter) but returned as a table column for CROSS APPLY usage. Note: INTEGER, same overflow risk as GetUsedMargin for high-value accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionTbl | Table read | SUM(Amount) WHERE CID=@CID AND StatusID=1 (open positions only). Amount in dollars; *100 for cents. |
| @CID | Trade.Mirror | Table read | SUM(Amount) WHERE CID=@CID. Mirror/copy-trading cash allocations. Amount in dollars; *100 for cents. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Designed for CROSS APPLY usage in multi-customer BackOffice queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUsedMarginInLine (function)
├── Trade.PositionTbl (table) [cross-schema]
└── Trade.Mirror (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Subquery: CAST(SUM(Amount)*100 AS INTEGER) WHERE CID=@CID AND StatusID=1. Direct table access (not via view). |
| Trade.Mirror | Table | Subquery: CAST(SUM(Amount)*100 AS INTEGER) WHERE CID=@CID. |

### 6.2 Objects That Depend On This

No dependents found in BackOffice stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. Note: Returns INTEGER - same overflow risk as GetUsedMargin. For large accounts use GetUsedMarginBigInt.

---

## 8. Sample Queries

### 8.1 Get used margin for a single customer via CROSS APPLY

```sql
SELECT margin.UsedMargin, margin.UsedMargin / 100.0 AS UsedMarginUSD
FROM BackOffice.GetUsedMarginInLine(12345) WITH (NOLOCK) margin;
```

### 8.2 Use with CROSS APPLY across multiple customers (primary use case)

```sql
SELECT
    c.CID,
    margin.UsedMargin / 100.0 AS UsedMarginUSD
FROM BackOffice.Customer c WITH (NOLOCK)
CROSS APPLY BackOffice.GetUsedMarginInLine(c.CID) margin
WHERE c.CID IN (12345, 67890, 11111);
```

### 8.3 Compare inline vs. scalar function results

```sql
SELECT
    BackOffice.GetUsedMargin(12345) AS ScalarResult,
    margin.UsedMargin AS InlineResult
FROM BackOffice.GetUsedMarginInLine(12345) WITH (NOLOCK) margin;
-- Both should return the same value (both filter to StatusID=1)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUsedMarginInLine | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUsedMarginInLine.sql*
