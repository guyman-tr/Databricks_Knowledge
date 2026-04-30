# Trade.LeverageRestrictionsByCountry

> Defines which leverage levels are allowed per country and instrument. Used with LeverageRestrictionsByCustomer to resolve effective leverage for a customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CountryID, InstrumentID, PossibleLeverage (PK CLUSTERED) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.LeverageRestrictionsByCountry stores the set of allowed leverage values for each (CountryID, InstrumentID) pair. Each row represents one possible leverage level; IsDefault marks which level is the default for that pair. Regulators often limit maximum leverage by jurisdiction, so this table enforces country-level restrictions. Trade.GetLeverageRestrictionsByCid uses it by joining to Customer.CustomerStatic on CountryID to return the allowed leverage options for a given customer.

---

## 2. Business Logic

### 2.1 Possible Leverage Set

**What**: Defines the discrete leverage values a customer in a given country can use for an instrument.

**Columns/Parameters Involved**: `CountryID`, `InstrumentID`, `PossibleLeverage`, `IsDefault`

**Rules**:
- Multiple rows per (CountryID, InstrumentID)—one per allowed leverage (e.g., 1, 2, 5, 10, 25, 50, 100, 200, 400)
- Exactly one row per (CountryID, InstrumentID) should have IsDefault = 1
- PK enforces uniqueness on (CountryID, InstrumentID, PossibleLeverage)

### 2.2 Resolution Flow

**What**: For a given CID, Trade.GetLeverageRestrictionsByCid resolves CountryID via Customer.CustomerStatic, then selects all rows for that country and instrument.

**Rules**:
- Country-level restrictions are returned first; customer-specific overrides (LeverageRestrictionsByCustomer) are returned as a second result set
- Customer-level takes precedence when both exist

---

## 3. Data Overview

| CountryID | InstrumentID | PossibleLeverage | IsDefault |
|-----------|--------------|------------------|-----------|
| 54 | 1 | 1 | 0 |
| 54 | 1 | 2 | 0 |
| 54 | 1 | 5 | 0 |
| 54 | 1 | 10 | 0 |
| 54 | 1 | 25 | 0 |
| 54 | 1 | 50 | 1 |
| 54 | 1 | 100 | 0 |
| 54 | 1 | 200 | 0 |
| 54 | 1 | 400 | 0 |
| 54 | 2 | 1 | 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country. References Dictionary.Country (or similar) |
| 2 | InstrumentID | int | NO | - | VERIFIED | Instrument. References Trade.Instrument.InstrumentID |
| 3 | PossibleLeverage | int | NO | - | VERIFIED | Allowed leverage value (e.g., 1, 2, 5, 10, 25, 50, 100, 200, 400) |
| 4 | IsDefault | int | NO | - | VERIFIED | 1 = default leverage for this (CountryID, InstrumentID); 0 = not default |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Dictionary.Country | CountryID | Implicit; country must exist |
| Trade.Instrument | InstrumentID | Implicit |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| Trade.GetLeverageRestrictionsByCid | LeverageRestrictionsByCountry | Reader; joins on CountryID from Customer |

---

## 6. Dependencies

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Dictionary.Country | CountryID domain |
| Trade.Instrument | InstrumentID domain |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| Trade.GetLeverageRestrictionsByCid | Returns country-based leverage options for a CID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|------------|------|-------------|-------|
| PK_TradeLeverageRestrictionsByCountry | CLUSTERED | CountryID ASC, InstrumentID ASC, PossibleLeverage ASC | PK |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_TradeLeverageRestrictionsByCountry | PRIMARY KEY | CountryID, InstrumentID, PossibleLeverage |

---

## 8. Sample Queries

```sql
SELECT CountryID, InstrumentID, PossibleLeverage, IsDefault
FROM Trade.LeverageRestrictionsByCountry WITH (NOLOCK)
WHERE CountryID = 54 AND InstrumentID = 1
ORDER BY PossibleLeverage;

SELECT countryRest.InstrumentID, countryRest.PossibleLeverage, countryRest.IsDefault
FROM Trade.LeverageRestrictionsByCountry countryRest WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cust WITH (NOLOCK) ON countryRest.CountryID = cust.CountryID
WHERE cust.CID = @CID
ORDER BY countryRest.InstrumentID, countryRest.PossibleLeverage;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 8.0/10*
