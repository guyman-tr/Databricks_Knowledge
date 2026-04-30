# Dictionary.SpreadType

## 1. Business Meaning

**What it is**: A lookup table defining how spread values are expressed for instruments. Spread can be measured either in absolute pips or as a percentage of the market rate.

**Why it exists**: Different instrument classes use different spread conventions. Forex instruments typically use pip-based spreads (e.g., "2 pips"), while some instruments use percentage-based spreads (e.g., "0.5% of rate"). This table classifies which convention applies so the spread engine interprets the configured spread values correctly.

**How it works**: The `Trade.InstrumentSpread` table references this type to indicate how each instrument's spread values should be interpreted. The trading engine reads the spread type to determine whether to add a fixed pip amount or calculate a percentage markup when constructing bid/ask prices.

---

## 2. Business Logic

### Spread Types
| ID | Name | Description | Calculation |
|----|------|-------------|-------------|
| 1 | SpreadInPips | Spread values in pips | Add fixed pip value to mid-price |
| 2 | PrecentageSpread | Spread as percentage of rate | Multiply rate × percentage to get spread amount |

### Example
For an instrument at mid-price 1.3000:
- **SpreadInPips** = 2 pips → Bid: 1.2999, Ask: 1.3001
- **PrecentageSpread** = 0.1% → Spread = 0.0013 → Bid: 1.29935, Ask: 1.30065

---

## 3. Data Overview

| SpreadTypeID | Name | Description | Business Meaning |
|-------------|------|-------------|------------------|
| 1 | SpreadInPips | Spread values in pips | Absolute pip-based spread (forex standard) |
| 2 | PrecentageSpread | Spread as percentage of rate | Proportional spread (% of market rate) |

*2 rows — binary spread measurement convention*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SpreadTypeID** | int | NOT NULL | — | Primary key. Spread convention: 1=SpreadInPips (absolute), 2=PrecentageSpread (proportional). | `MCP` |
| **Name** | varchar(50) | NOT NULL | — | Spread type identifier used in configuration. Note: "PrecentageSpread" (original spelling preserved). | `MCP` |
| **Description** | varchar(300) | NULL | — | Human-readable description explaining how the spread values should be interpreted. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Trade.InstrumentSpread | SpreadTypeID | Implicit FK | Per-instrument spread measurement convention |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Trade.InstrumentSpread` — instrument spread configuration

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SpreadTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 2 |

---

## 8. Sample Queries

```sql
-- Get all spread types
SELECT  SpreadTypeID, Name, Description
FROM    Dictionary.SpreadType WITH (NOLOCK)
ORDER BY SpreadTypeID;

-- Instruments by spread type
SELECT  ST.Name AS SpreadType, COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentSpread ISP WITH (NOLOCK)
JOIN    Dictionary.SpreadType ST WITH (NOLOCK) ON ST.SpreadTypeID = ISP.SpreadTypeID
GROUP BY ST.Name;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Spread types are a dealing desk configuration concept.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.0 — MCP verified (2 rows), codebase traced (1 consumer: Trade.InstrumentSpread)*
