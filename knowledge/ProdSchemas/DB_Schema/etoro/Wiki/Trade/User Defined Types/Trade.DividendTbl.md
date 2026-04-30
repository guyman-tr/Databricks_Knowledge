# Trade.DividendTbl

> Single-column TVP carrying DividendIDs for batch dollar conversion rate queries.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DividendID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.DividendTbl is a minimal table-valued parameter that holds a list of DividendIDs. It is used by Trade.GetRateInDollarsForDividends to batch-query dollar conversion rates for a set of dividends. Each row is one dividend; the procedure returns the rate-in-dollars for each.

DividendID references Trade.IndexDividends. The procedure uses the TVP to avoid multiple round trips when fetching conversion rates for many dividends at once.

---

## 2. Business Logic

### 2.1 Batch rate lookup

**What**: The TVP passes a set of DividendIDs. GetRateInDollarsForDividends returns the USD conversion rate for each dividend in one call.

**Columns/Parameters Involved**: DividendID

**Rules**: DividendID must exist in Trade.IndexDividends. Duplicate DividendIDs may be allowed depending on procedure logic.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | No | - | 10 | Dividend identifier (Trade.IndexDividends) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.IndexDividends (DividendID) | Implicit reference to dividend |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.GetRateInDollarsForDividends | Parameter @Dividends |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.GetRateInDollarsForDividends

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Pass dividend list to get rates

```sql
DECLARE @Dividends Trade.DividendTbl;
INSERT INTO @Dividends (DividendID) VALUES (1), (2), (3), (4);
EXEC Trade.GetRateInDollarsForDividends @Dividends = @Dividends;
```

### 8.2 Build from IndexDividends filter

```sql
DECLARE @D Trade.DividendTbl;
INSERT INTO @D (DividendID)
SELECT DividendID FROM Trade.IndexDividends WHERE ExDate >= '2025-01-01';
EXEC Trade.GetRateInDollarsForDividends @Dividends = @D;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name, c.max_length
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'DividendTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.GetRateInDollarsForDividends procedure*
*Object: Trade.DividendTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DividendTbl.sql*
