# Trade.GetLeverageRestrictionsByCid

> Returns the allowed leverage levels for a customer by combining country-based restrictions (from the customer's registered country) and any customer-specific overrides.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: two result sets (country restrictions, customer restrictions) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLeverageRestrictionsByCid retrieves the set of allowed leverage multipliers for a given customer. Regulators in different jurisdictions impose limits on maximum leverage (e.g., ESMA in Europe caps retail leverage at 30:1 for major FX pairs). This procedure returns two result sets: (1) the country-level leverage restrictions based on the customer's registered country, and (2) any customer-specific overrides (VIP exemptions, compliance restrictions, manual adjustments).

This procedure exists because the trading platform must enforce correct leverage limits before opening a position. When a customer selects an instrument, the UI and API services call this to determine which leverage options to present and which to allow. Without it, customers might select leverage levels prohibited by their jurisdiction or individual risk profile.

The Trading Settings API (TradingSettingsAPI) and BI admins (PROD_BIadmins) call this procedure. The application layer merges the two result sets, with customer-specific restrictions taking precedence over country restrictions when present.

---

## 2. Business Logic

### 2.1 Dual-Source Leverage Resolution

**What**: Returns two separate result sets - country-level and customer-level leverage restrictions - for the application to merge.

**Columns/Parameters Involved**: `@CID`, `Trade.LeverageRestrictionsByCountry`, `Trade.LeverageRestrictionsByCustomer`, `Customer.CustomerStatic.CountryID`

**Rules**:
- Result set 1 (country): Joins Trade.LeverageRestrictionsByCountry to Customer.CustomerStatic on CountryID to find the customer's country, then returns all allowed leverage levels for that country
- Result set 2 (customer): Directly queries Trade.LeverageRestrictionsByCustomer for the given CID
- The application merges these: if customer-specific entries exist for an instrument, they override country defaults
- Each result row includes InstrumentID, PossibleLeverage (the allowed multiplier), and IsDefault (which one is pre-selected)

**Diagram**:
```
@CID
  |
  +--> Customer.CustomerStatic (get CountryID)
  |         |
  |         v
  |    Trade.LeverageRestrictionsByCountry
  |         |
  |         v
  |    Result Set 1: Country leverage options
  |
  +--> Trade.LeverageRestrictionsByCustomer
            |
            v
       Result Set 2: Customer-specific overrides

Application merges: Customer > Country when both exist for an instrument.
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @CID | int | IN | - | CODE-BACKED | Customer ID to look up leverage restrictions for. Joined to Customer.CustomerStatic to resolve the customer's registered country for country-level restrictions. |

### 4.2 Result Set 1 (Country Restrictions)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | InstrumentID | int | NO | CODE-BACKED | The instrument these leverage options apply to. FK to Trade.Instrument. |
| 2 | PossibleLeverage | int | NO | CODE-BACKED | An allowed leverage multiplier for this instrument in the customer's country (e.g., 1, 2, 5, 10, 25, 50, 100, 200, 400). Multiple rows per instrument define the full set of allowed values. |
| 3 | IsDefault | bit | NO | CODE-BACKED | 1 if this leverage level is the default (pre-selected) for the country-instrument pair, 0 otherwise. Exactly one row per (CountryID, InstrumentID) should have IsDefault=1. |

### 4.3 Result Set 2 (Customer Restrictions)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | InstrumentID | int | NO | CODE-BACKED | The instrument these customer-specific leverage options apply to. |
| 2 | PossibleLeverage | int | NO | CODE-BACKED | An allowed leverage multiplier for this customer-instrument pair. Overrides country defaults when present. |
| 3 | IsDefault | bit | NO | CODE-BACKED | 1 if this is the default leverage for this customer-instrument pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.LeverageRestrictionsByCountry | SELECT (READER) | Reads country-level allowed leverage values |
| JOIN | Customer.CustomerStatic | SELECT (READER) | Resolves customer's CountryID from their CID |
| FROM | Trade.LeverageRestrictionsByCustomer | SELECT (READER) | Reads customer-specific leverage overrides |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingSettingsAPI | GRANT EXECUTE | Application User | Trading Settings API calls to present leverage options in UI |
| PROD_BIadmins | GRANT EXECUTE | Application User | BI admin processes for leverage analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLeverageRestrictionsByCid (procedure)
+-- Trade.LeverageRestrictionsByCountry (table)
+-- Trade.LeverageRestrictionsByCustomer (table)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeverageRestrictionsByCountry | Table | SELECT to get country-level leverage options for the customer's country |
| Trade.LeverageRestrictionsByCustomer | Table | SELECT to get customer-specific leverage overrides |
| Customer.CustomerStatic | Table | JOIN on CID to resolve the customer's CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradingSettingsAPI | Application User | Calls to determine allowed leverage for UI display |
| PROD_BIadmins | Application User | Calls for leverage analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get leverage restrictions for a specific customer

```sql
EXEC Trade.GetLeverageRestrictionsByCid @CID = 12345;
```

### 8.2 Preview country restrictions for a customer

```sql
SELECT  countryRest.InstrumentID,
        countryRest.PossibleLeverage,
        countryRest.IsDefault,
        cust.CountryID
FROM    Trade.LeverageRestrictionsByCountry countryRest WITH (NOLOCK)
        INNER JOIN Customer.CustomerStatic cust WITH (NOLOCK)
            ON countryRest.CountryID = cust.CountryID
WHERE   cust.CID = 12345
ORDER BY countryRest.InstrumentID, countryRest.PossibleLeverage;
```

### 8.3 Compare country vs customer restrictions for a CID

```sql
SELECT  'Country' AS Source,
        InstrumentID,
        PossibleLeverage,
        IsDefault
FROM    Trade.LeverageRestrictionsByCountry cr WITH (NOLOCK)
        INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cr.CountryID = cs.CountryID
WHERE   cs.CID = 12345
UNION ALL
SELECT  'Customer' AS Source,
        InstrumentID,
        PossibleLeverage,
        IsDefault
FROM    Trade.LeverageRestrictionsByCustomer WITH (NOLOCK)
WHERE   CID = 12345
ORDER BY InstrumentID, Source, PossibleLeverage;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLeverageRestrictionsByCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLeverageRestrictionsByCid.sql*
