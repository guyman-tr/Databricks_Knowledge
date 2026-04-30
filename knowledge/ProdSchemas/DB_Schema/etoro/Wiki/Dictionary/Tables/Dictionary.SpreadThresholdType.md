# Dictionary.SpreadThresholdType

## 1. Business Meaning

**What it is**: A lookup table defining the unit of measurement for spread threshold configurations. Determines whether spread thresholds are measured in NOP (Number of Pips) or NOE (Number of Entries/ticks).

**Why it exists**: The price/spread monitoring system tracks whether an instrument's spread exceeds acceptable limits. Spread thresholds can be expressed in two different units depending on the instrument type and monitoring approach. This table classifies which unit system a given threshold configuration uses.

**How it works**: The `Price.SpreadThresholdConfiguration` table and `Trade.InstrumentSpread` table reference this type to specify how their threshold values should be interpreted. NOP (Number of Pips) is the standard forex/CFD measurement, while NOE (Number of Entries) counts raw price tick entries.

---

## 2. Business Logic

### Threshold Measurement Types
| ID | Name | Meaning |
|----|------|---------|
| 1 | NOP | Number of Pips — spread threshold measured in pip units (standard for forex/CFD instruments) |
| 2 | NOE | Number of Entries — spread threshold measured in raw tick/entry count (used for monitoring price feed density) |

---

## 3. Data Overview

| SpreadThresholdTypeID | Name | Business Meaning |
|----------------------|------|------------------|
| 1 | NOP | Spread measured in pips |
| 2 | NOE | Spread measured in tick entries |

*2 rows — binary spread measurement unit classification*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SpreadThresholdTypeID** | int | NOT NULL | — | Primary key. Threshold measurement unit: 1=NOP (Number of Pips), 2=NOE (Number of Entries). | `MCP` |
| **Name** | varchar(25) | NOT NULL | — | Short abbreviation for the measurement unit. Used in configuration UIs and spread monitoring dashboards. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Price.SpreadThresholdConfiguration | SpreadThresholdTypeID | Implicit FK | Spread threshold rules scoped by measurement unit |
| Trade.InstrumentSpread | SpreadThresholdTypeID | Implicit FK | Per-instrument spread configuration with threshold type |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Price.SpreadThresholdConfiguration` — spread monitoring threshold rules
- `Trade.InstrumentSpread` — per-instrument spread configuration

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SpreadThresholdTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Fill Factor | 95% |
| Row Count | 2 |

---

## 8. Sample Queries

```sql
-- Get all threshold types
SELECT  SpreadThresholdTypeID, Name
FROM    Dictionary.SpreadThresholdType WITH (NOLOCK)
ORDER BY SpreadThresholdTypeID;

-- Spread configurations by threshold type
SELECT  STT.Name AS ThresholdType, COUNT(*) AS ConfigCount
FROM    Price.SpreadThresholdConfiguration STC WITH (NOLOCK)
JOIN    Dictionary.SpreadThresholdType STT WITH (NOLOCK) ON STT.SpreadThresholdTypeID = STC.SpreadThresholdTypeID
GROUP BY STT.Name;

-- Instrument spreads using pip-based thresholds
SELECT  IS2.InstrumentID, IS2.SpreadThresholdTypeID
FROM    Trade.InstrumentSpread IS2 WITH (NOLOCK)
WHERE   IS2.SpreadThresholdTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Spread threshold types are a dealing desk configuration feature for price monitoring.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (2 rows), codebase traced (2 consumer tables: Price.SpreadThresholdConfiguration, Trade.InstrumentSpread)*
