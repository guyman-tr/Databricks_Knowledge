# Trade.LeverageRestrictionsByCustomer

> Per-customer leverage rules: lists the leverage ratios each customer is allowed for each instrument, with a flag for the default. Used when the customer's country rules are not sufficient and individual exemptions apply.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID, InstrumentID, PossibleLeverage (PK CLUSTERED) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.LeverageRestrictionsByCustomer stores customer-specific leverage restrictions. When a customer has individual leverage rules that differ from their country's defaults (e.g., due to a VIP program, compliance, or manual override), this table holds the allowed leverage values per instrument. Each row represents one allowed leverage ratio (e.g., 1, 2, 5, 10, 25, 50, 100, 200, 400) for a customer–instrument pair, with IsDefault marking the preferred default.

Trade.GetLeverageRestrictionsByCid returns both country-based and customer-based restrictions for a given CID. Customer restrictions take precedence when present; country restrictions apply otherwise.

---

## 2. Business Logic

### 2.1 Allowed Leverage Values

**What**: For each customer–instrument pair, multiple PossibleLeverage values define the allowed leverage ratios.

**Columns/Parameters Involved**: `CID`, `InstrumentID`, `PossibleLeverage`, `IsDefault`

**Rules**:
- One row per (CID, InstrumentID, PossibleLeverage) combination
- PossibleLeverage values observed: 1, 2, 5, 10, 25, 50, 100, 200, 400
- IsDefault = 1 marks the default leverage for that pair; IsDefault = 0 for other allowed values
- Exactly one IsDefault = 1 per (CID, InstrumentID)
- Customer rows override or supplement country rules when returned by GetLeverageRestrictionsByCid

### 2.2 Population

**What**: Rows are inserted by Trade.InsertNewTradingResourceDefault when creating default trading resources for a new customer.

**Columns/Parameters Involved**: `CID`, `InstrumentID`, `PossibleLeverage`, `IsDefault`

**Rules**:
- InsertNewTradingResourceDefault uses #Leverages_tmp (derived from Trade.Instrument) and only inserts where no row exists (LEFT JOIN ... WHERE L.InstrumentID IS NULL)
- Default leverages come from instrument-type configuration (e.g., InstrumentTypeID = 4)

---

## 3. Data Overview

| CID | InstrumentID | PossibleLeverage | IsDefault |
|-----|--------------|-----------------|-----------|
| 3635304 | 1 | 1 | 0 |
| 3635304 | 1 | 2 | 0 |
| 3635304 | 1 | 5 | 0 |
| 3635304 | 1 | 10 | 0 |
| 3635304 | 1 | 25 | 1 |
| 3635304 | 1 | 50 | 0 |
| 3635304 | 1 | 100 | 0 |
| 3635304 | 1 | 200 | 0 |
| 3635304 | 1 | 400 | 0 |
| 3635304 | 2 | 1 | 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. References Customer.CustomerStatic.CID |
| 2 | InstrumentID | int | NO | - | VERIFIED | Instrument. References Trade.Instrument.InstrumentID |
| 3 | PossibleLeverage | int | NO | - | VERIFIED | Allowed leverage ratio (e.g. 1, 2, 5, 10, 25, 50, 100, 200, 400) |
| 4 | IsDefault | int | NO | - | CODE-BACKED | 1 = default leverage for (CID, InstrumentID); 0 = other allowed value |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Customer.CustomerStatic | CID | Implicit; customer must exist |
| Trade.Instrument | InstrumentID | Implicit; instrument must exist |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| Trade.GetLeverageRestrictionsByCid | LeverageRestrictionsByCustomer | Reader—returns PossibleLeverage, IsDefault by CID |
| Trade.InsertNewTradingResourceDefault | LeverageRestrictionsByCustomer | Writer—inserts default leverage rows for new customers |

---

## 6. Dependencies

### 6.0 Chain

```
Customer.CustomerStatic ──► Trade.LeverageRestrictionsByCustomer
Trade.Instrument         ──► Trade.LeverageRestrictionsByCustomer
```

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Customer.CustomerStatic | CID domain |
| Trade.Instrument | InstrumentID and leverage defaults by instrument type |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| Trade.GetLeverageRestrictionsByCid | Returns customer-specific leverage rules for UI/trading |
| Trade.InsertNewTradingResourceDefault | Seeds default leverage when onboarding new customers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Status |
|------------|------|-------------|----------|--------|
| PK_TradeLeverageRestrictionsByCustomer | CLUSTERED | CID ASC, InstrumentID ASC, PossibleLeverage ASC | - | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_TradeLeverageRestrictionsByCustomer | PRIMARY KEY | CID, InstrumentID, PossibleLeverage |

---

## 8. Sample Queries

```sql
SELECT CID, InstrumentID, PossibleLeverage, IsDefault
FROM Trade.LeverageRestrictionsByCustomer WITH (NOLOCK)
WHERE CID = @CID
ORDER BY InstrumentID, PossibleLeverage;

SELECT c.InstrumentID, c.PossibleLeverage, c.IsDefault
FROM Trade.LeverageRestrictionsByCustomer c WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cust WITH (NOLOCK) ON c.CID = cust.CID
WHERE cust.CountryID = @CountryID
ORDER BY c.InstrumentID, c.PossibleLeverage;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 7.5/10*
