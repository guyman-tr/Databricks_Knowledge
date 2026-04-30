# History.GetPriceWorkingInterval

> Thin pass-through view exposing only the DateFrom and DateTo columns of History.PriceWorkingInterval - provides a stable, minimal interface for querying price working intervals without exposing the full underlying table schema.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | No PK - view over History.PriceWorkingInterval |
| **Base Objects** | History.PriceWorkingInterval |

---

## 1. Business Meaning

History.GetPriceWorkingInterval is a minimal projection view over History.PriceWorkingInterval - the audit table recording the time windows during which the pricing engine was active. The view exposes only the two date columns (DateFrom, DateTo) that define each working interval, hiding any other columns in the underlying table.

History.PriceWorkingInterval records when the pricing system starts and stops operating - used by the risk and pricing teams to correlate price data availability with market hours, system maintenance windows, and pricing engine restarts. This view provides a clean query interface for callers that only need the date range, without needing to know the full table structure.

No procedures or objects in the SSDT repo reference this view (1 file = itself) - it is likely consumed by application code, reporting tools, or external queries that connect directly to the database.

---

## 2. Business Logic

### 2.1 Pass-Through Projection

**What**: Selects DateFrom and DateTo from History.PriceWorkingInterval with no filtering or transformation.

**Columns/Parameters Involved**: `DateFrom`, `DateTo`

**Rules**:
- Returns all rows from History.PriceWorkingInterval - no WHERE clause, no aggregation
- Callers must apply their own date range filters
- The view does not include other columns from PriceWorkingInterval (e.g., any IDs or metadata columns)
- No NOLOCK hint in the view definition

---

## 3. Data Overview

Reflects the data of History.PriceWorkingInterval. See History.PriceWorkingInterval documentation for row counts and date ranges.

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | DateFrom | DATETIME (inherited) | - | CODE-BACKED | Start of the pricing working interval. Inherited from History.PriceWorkingInterval.DateFrom. |
| 2 | DateTo | DATETIME (inherited) | - | CODE-BACKED | End of the pricing working interval. Inherited from History.PriceWorkingInterval.DateTo. NULL if the pricing engine is still active for this interval. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.PriceWorkingInterval | SELECT (all rows, DateFrom+DateTo only) | Base table providing the pricing interval data. |

### 5.2 Referenced By (other objects point to this)

No SSDT objects reference this view. Consumed by application code or external reporting.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetPriceWorkingInterval (view)
  -> History.PriceWorkingInterval (table) [documented]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PriceWorkingInterval | Table | Base table - all rows selected, DateFrom+DateTo projected |

### 6.2 Objects That Depend On This

None found in SSDT repo.

---

## 7. Technical Details

### 7.1 View Definition

```sql
CREATE VIEW History.GetPriceWorkingInterval AS
  SELECT
    DateFrom,
    DateTo
  FROM History.PriceWorkingInterval
```

---

## 8. Sample Queries

### 8.1 View all price working intervals
```sql
SELECT DateFrom, DateTo
FROM History.GetPriceWorkingInterval
ORDER BY DateFrom DESC;
```

### 8.2 Find intervals overlapping a specific time
```sql
SELECT DateFrom, DateTo
FROM History.GetPriceWorkingInterval
WHERE DateFrom <= '2024-01-15 10:00:00'
    AND (DateTo IS NULL OR DateTo >= '2024-01-15 10:00:00');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 in SSDT repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetPriceWorkingInterval | Type: View | Source: etoro/etoro/History/Views/History.GetPriceWorkingInterval.sql*
