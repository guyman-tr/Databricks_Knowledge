# Trade.GetOnePip

> Calculates the value of one pip (smallest price movement) for an instrument based on its decimal precision from Trade.InstrumentPrecision.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(18,10) - one pip value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetOnePip returns the monetary value of one pip (percentage in point) for a given trading instrument. A pip is the smallest standard price movement unit. For forex pairs with 4 decimal places, one pip = 0.0001. For JPY pairs with 2 decimal places, one pip = 0.01. For crypto with 2 decimals, one pip = 0.01.

This function exists because pip values vary by instrument based on their price precision. The function looks up the instrument's precision from the Trade.InstrumentPrecision view and computes 1 / 10^precision. This standardized pip value is used for stop-loss/take-profit calculations, spread measurements, and price movement analysis.

---

## 2. Business Logic

### 2.1 Pip Calculation

**What**: One pip = 1 / 10^precision

**Columns/Parameters Involved**: `@instrumentId`, `Trade.InstrumentPrecision.Precision`

**Rules**:
- Looks up Precision from Trade.InstrumentPrecision (view) for the given InstrumentID
- Calculates rate multiplier: POWER(10.0, Precision)
- Returns 1.0 / rateMultiplier
- Example: Precision=4 -> pip = 0.0001, Precision=2 -> pip = 0.01

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentId | INT | NO | - | CODE-BACKED | The trading instrument. Looked up in Trade.InstrumentPrecision for decimal precision. |
| 2 | Return value | DECIMAL(18,10) | YES | - | CODE-BACKED | Value of one pip for the instrument. 0.0001 for 4-decimal instruments, 0.01 for 2-decimal instruments, etc. NULL if instrument not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentId | Trade.InstrumentPrecision | SELECT/WHERE | Looks up Precision value for the instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOnePip (function)
  └── Trade.InstrumentPrecision (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentPrecision | View | SELECT Precision WHERE InstrumentID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(18,10) | Return type | High precision for small pip values |

---

## 8. Sample Queries

### 8.1 Get pip value for EUR/USD

```sql
SELECT Trade.GetOnePip(1) AS PipValue;
-- Returns: 0.0001 (4-decimal forex pair)
```

### 8.2 Compare pip values across instrument types

```sql
SELECT  imd.InstrumentID,
        imd.InstrumentDisplayName,
        Trade.GetOnePip(imd.InstrumentID) AS OnePip
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE   imd.InstrumentID IN (1, 5, 1001, 100001)
        AND imd.Tradable = 1;
```

### 8.3 Calculate spread in pips

```sql
SELECT  cp.InstrumentID,
        i.SymbolFull,
        cp.BuyPrice - cp.SellPrice AS SpreadRaw,
        (cp.BuyPrice - cp.SellPrice) / NULLIF(Trade.GetOnePip(cp.InstrumentID), 0) AS SpreadInPips
FROM    Trade.CurrencyPrice cp WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON cp.InstrumentID = i.InstrumentID
WHERE   cp.InstrumentID IN (1, 5, 1001);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOnePip | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetOnePip.sql*
