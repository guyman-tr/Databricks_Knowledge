# BackOffice.JUNK_GetMostPopularLeverage

> DEPRECATED inline table-valued function returning each customer's most frequently used leverage multiplier within a date range, based on closed positions in History.Position.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(CID, Leverage) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetMostPopularLeverage` returns one row per customer with the leverage multiplier they used most frequently during a specified date range. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "Between @DateFrom and @DateTo, which leverage multiplier did each customer use most often on their closed positions?" It uses a two-step CTE approach: first count positions by CID+Leverage, then use ROW_NUMBER() to pick the top leverage per customer.

**Business use case**: Leverage preference analysis was used by the risk and compliance teams to understand customer risk appetite, for regulatory reporting on leverage usage patterns, and for product decisions about default leverage settings.

**Leverage multiplier**: The ratio applied to a trade - e.g., Leverage=2 means the position uses 2x the capital (1:2 leverage). Higher leverage = higher risk. eToro offered leverages typically from 1x to 400x depending on asset class and regulation.

---

## 2. Business Logic

### 2.1 Most Popular Leverage per Customer (ROW_NUMBER Ranking)

**What**: CTE-based ROW_NUMBER ranking to find the single most common leverage for each customer.

**Columns/Parameters Involved**: `@DateFrom`, `@DateTo`, `CID`, `Leverage`, `Total`, `Pos`

**Rules**:
- CTE 1 (LeverageCount): Groups `History.Position` by `CID, Leverage` WHERE `InitDateTime BETWEEN @DateFrom AND @DateTo`, counts rows per group as `Total`.
- CTE 2 (LeverageCountNumbered): Assigns `ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Total DESC)` as `Pos`. Ties broken arbitrarily by SQL Server.
- Final SELECT: Filters to `Pos = 1` - returns only the most-used leverage per customer.
- Customers with no positions in the date range do not appear in results.
- Uses `WITH (NOLOCK)` for read performance.

**Diagram**:
```
@DateFrom, @DateTo
  |
  v
History.Position WITH (NOLOCK)
  WHERE InitDateTime BETWEEN @DateFrom AND @DateTo
  GROUP BY CID, Leverage
  COUNT(*) AS Total -> LeverageCount CTE
  |
  v
ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Total DESC) AS Pos
  -> LeverageCountNumbered CTE
  |
  WHERE Pos = 1
  |
  v
Returns: CID | Leverage (most frequent leverage per customer)
```

### 2.2 Date Range Semantics

**What**: The date range uses InitDateTime (position open date), not CloseDateTime.

**Rules**:
- `InitDateTime BETWEEN @DateFrom AND @DateTo` includes positions opened in the range.
- Positions still open at the end of the range are included if their InitDateTime is within range.
- Positions opened before @DateFrom that closed after @DateFrom are excluded.
- This means the function reports on positions initiated during the period, regardless of close status.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the date range (inclusive). Filters History.Position on InitDateTime >= @DateFrom. |
| 2 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the date range (inclusive). Filters History.Position on InitDateTime <= @DateTo. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. One row per customer who had at least one position opened in the date range. |
| 2 | Leverage | INT/DECIMAL | NO | - | CODE-BACKED | The leverage multiplier used most frequently by this customer during the date range. Ties between equal-count leverages are broken arbitrarily by ROW_NUMBER ordering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Leverage, InitDateTime | History.Position | Table read | Source of closed position records. Grouped by CID+Leverage with date filter on InitDateTime. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetMostPopularLeverage (function)
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Source data. Grouped by CID, Leverage; filtered by InitDateTime date range. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK). Tie-breaking for equal-count leverages is non-deterministic.

---

## 8. Sample Queries

### 8.1 Most popular leverage for all customers in Q1 2023

```sql
SELECT CID, Leverage
FROM BackOffice.JUNK_GetMostPopularLeverage('2023-01-01', '2023-03-31')
ORDER BY CID;
```

### 8.2 Distribution of most popular leverages

```sql
SELECT Leverage, COUNT(*) AS CustomerCount
FROM BackOffice.JUNK_GetMostPopularLeverage('2023-01-01', '2023-12-31')
GROUP BY Leverage
ORDER BY CustomerCount DESC;
```

### 8.3 Most popular leverage for a specific customer

```sql
SELECT CID, Leverage
FROM BackOffice.JUNK_GetMostPopularLeverage(DATEADD(MONTH, -6, GETDATE()), GETDATE())
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetMostPopularLeverage | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetMostPopularLeverage.sql*
