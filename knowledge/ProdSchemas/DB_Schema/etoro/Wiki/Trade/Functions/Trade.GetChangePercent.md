# Trade.GetChangePercent

> Calculates the percentage change between two decimal values, with divide-by-zero protection, returning the result rounded to 2 decimal places.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,2) - percentage change |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetChangePercent is a general-purpose utility function that calculates the percentage change between two values. It is used across the trading platform wherever percentage differences need to be computed - price changes, rate changes, position value changes, etc.

This function exists to provide a safe, consistent percentage calculation with built-in divide-by-zero protection. When the previous value is 0, the function returns 0 instead of causing an arithmetic error. The result is always rounded to 2 decimal places.

---

## 2. Business Logic

### 2.1 Percentage Change Formula

**What**: Standard percentage change with zero-division safety.

**Columns/Parameters Involved**: `@NewVal`, `@PrevVal`

**Rules**:
- If @PrevVal = 0, return 0 (prevents divide-by-zero)
- Otherwise: ROUND(((NewVal - PrevVal) / ABS(PrevVal)) * 100, 2)
- Uses ABS(PrevVal) in denominator to handle negative base values correctly
- Result in percentage points (e.g., 5.25 means 5.25%)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NewVal | DECIMAL(16,8) | NO | - | CODE-BACKED | New/current value to compare. |
| 2 | @PrevVal | DECIMAL(16,8) | NO | - | CODE-BACKED | Previous/base value to compare against. If 0, function returns 0 (divide-by-zero protection). |
| 3 | Return value | DECIMAL(16,2) | NO | - | CODE-BACKED | Percentage change rounded to 2 decimal places. Positive = increase, negative = decrease. 0 if previous value was 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure calculation function.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetChangePercent (function)
(no dependencies - leaf node, pure calculation)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(16,2) | Return type | Percentage rounded to 2 decimal places |
| IF @PrevVal = 0 | Safety | Divide-by-zero protection |

---

## 8. Sample Queries

### 8.1 Calculate simple percentage change

```sql
SELECT Trade.GetChangePercent(155.75, 150.50) AS PctChange;
-- Returns: 3.49 (3.49% increase)
```

### 8.2 Handle zero base case

```sql
SELECT Trade.GetChangePercent(100.0, 0.0) AS PctChange;
-- Returns: 0 (safe, no divide-by-zero)
```

### 8.3 Calculate price change percentage for instruments

```sql
SELECT  cp.InstrumentID,
        i.SymbolFull,
        Trade.GetChangePercent(cp.BuyPrice, cp.PreviousClose) AS DailyPctChange
FROM    Trade.CurrencyPrice cp WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON cp.InstrumentID = i.InstrumentID
WHERE   cp.InstrumentID IN (1, 5, 1001);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetChangePercent | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetChangePercent.sql*
