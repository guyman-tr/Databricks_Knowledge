# Dictionary.InterestRateOld

> Legacy lookup table storing the original per-currency overnight interest rates before the system was enhanced with buy/sell splits, instrument type dimensions, and temporal versioning.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | InterestRateID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.InterestRateOld is the legacy version of the interest rate configuration table. It stores a single interest rate per currency without the multi-dimensional breakdown (instrument type, settlement type, buy/sell split) that the current Dictionary.InterestRate provides. This table was the original rate source before the overnight fee engine was enhanced.

This table is retained for backward compatibility and historical reference. Some legacy procedures or reports may still reference it. The current system uses Dictionary.InterestRate (with its composite key and temporal versioning) for all active fee calculations.

The table contains 14 rows — one per major currency used in the platform's interest rate calculations (USD, EUR, GBP, CHF, NOK, SEK, DKK, CAD, HKD, AUD, AUS, JPY, SGD, AED).

---

## 2. Business Logic

### 2.1 Legacy Single-Rate Model

**What**: The original interest rate model used a single rate per currency, without buy/sell distinction or instrument type granularity.

**Columns/Parameters Involved**: `InterestRateID`, `InterestRateName`, `InterestRate`

**Rules**:
- One rate per currency — same rate applied to both buy and sell positions
- No instrument type dimension — same rate for CFD, stocks, and crypto
- No temporal versioning — rate changes overwrote previous values with no history
- Superseded by Dictionary.InterestRate which adds: buy/sell splits, markups, instrument type, settlement type, and system versioning

---

## 3. Data Overview

| InterestRateID | InterestRateName | InterestRate | Meaning |
|---|---|---|---|
| 1 | IR USD | 0.01918710 | US Dollar overnight rate — the benchmark rate for USD-denominated instruments |
| 2 | IR EUR | -0.00371000 | Euro overnight rate — negative rate means EUR positions earned a swap credit (reflecting ECB negative interest rate era) |
| 3 | IR GBP | 0.00498310 | British Pound rate — reflects Bank of England base rate |
| 4 | IR CHF | -0.00782300 | Swiss Franc rate — negative reflecting SNB negative interest rate policy |
| 11 | IR AUS | 0.00004700 | Australian market-specific rate — near-zero, separate from AUD (ID=10) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateID | int | NO | - | CODE-BACKED | Currency identifier for the rate: 1=USD, 2=EUR, 3=GBP, 4=CHF, 5=NOK, 6=SEK, 7=DKK, 8=CAD, 9=HKD, 10=AUD, 11=AUS, 12=JPY, 13=SGD, 14=AED. Same ID space as Dictionary.InterestRate. |
| 2 | InterestRateName | varchar(50) | NO | - | CODE-BACKED | Human-readable currency rate label: "IR USD", "IR EUR", etc. |
| 3 | InterestRate | decimal(16,8) | NO | - | CODE-BACKED | Legacy single overnight rate value. Positive=customer pays, negative=customer earns. This was the only rate value before buy/sell splits were introduced. Many rows are now 0, indicating the rate was migrated to the new table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy procedures | InterestRateID | Implicit | Some older procedures may still reference this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.InterestRateOld (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No active dependents found — superseded by Dictionary.InterestRate.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestRate | CLUSTERED PK | InterestRateID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InterestRate | PRIMARY KEY | Unique rate per currency, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all legacy interest rates
```sql
SELECT  InterestRateID, InterestRateName, InterestRate
FROM    Dictionary.InterestRateOld WITH (NOLOCK)
ORDER BY InterestRateID;
```

### 8.2 Compare legacy vs current rates
```sql
SELECT  o.InterestRateName,
        o.InterestRate          AS LegacyRate,
        n.InterestRateBuy       AS CurrentBuyRate,
        n.InterestRateSell      AS CurrentSellRate
FROM    Dictionary.InterestRateOld o WITH (NOLOCK)
LEFT JOIN Dictionary.InterestRate n WITH (NOLOCK)
        ON o.InterestRateID = n.InterestRateID
        AND n.InstrumentTypeID = 4 AND n.SettlementTypeID = 0
ORDER BY o.InterestRateID;
```

### 8.3 Find currencies with negative legacy rates
```sql
SELECT  InterestRateID, InterestRateName, InterestRate
FROM    Dictionary.InterestRateOld WITH (NOLOCK)
WHERE   InterestRate < 0
ORDER BY InterestRate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InterestRateOld | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InterestRateOld.sql*
