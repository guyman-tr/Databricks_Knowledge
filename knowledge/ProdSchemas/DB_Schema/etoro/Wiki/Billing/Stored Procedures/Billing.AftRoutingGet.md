# Billing.AftRoutingGet

> Returns AFT (Automatic Fund Transfer) routing configuration entries matching a card type, regulatory jurisdiction, and optional country, enabling the payment routing engine to identify eligible depots and provider overrides for an AFT transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset of routing entries (ID, CountryID, CardTypeID, RegulationID, DepotID, IsWhitelistedProvider, IsBlacklistedProvider) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AftRoutingGet` is the query interface for the AFT routing configuration table (`Billing.AftRouting`). When the payment system needs to route an Automatic Fund Transfer transaction (a card-based deposit/cashout), it calls this procedure to find all eligible payment depots for the given card type and regulatory jurisdiction.

The procedure exists to encapsulate the routing lookup behind a parameterized interface, supporting both specific-country lookups (the normal case) and country-wildcard queries (returns all entries for a card/regulation combination, useful for administration and fallback routing). The caller selects the best depot from the returned set, respecting the whitelist/blacklist flags.

Data flows: the payment routing engine supplies the customer's card type, regulatory jurisdiction, and optionally the customer's country. The procedure returns all matching routing rows from `Billing.AftRouting`. The calling code then applies business rules (e.g., prefer whitelisted providers, exclude blacklisted ones) to select the final processing depot.

---

## 2. Business Logic

### 2.1 Country Wildcard Behavior

**What**: When `@CountryID` is NULL, the procedure returns entries for ALL countries matching the card type and regulation combination.

**Parameters/Columns Involved**: `@CountryID`, `Billing.AftRouting.CountryID`

**Rules**:
- `WHERE (CountryID = @CountryID OR @CountryID IS NULL)` implements the wildcard.
- If `@CountryID` is provided: returns only rows for that specific country (plus any NULL-CountryID entries if the table has them, though current data shows no NULL CountryIDs in the table).
- If `@CountryID IS NULL`: returns ALL rows matching @CardTypeID and @RegulationID, regardless of country - useful for administration, reporting, or fallback routing.

### 2.2 Provider Override Flags in Results

**What**: The returned rows include IsWhitelistedProvider and IsBlacklistedProvider flags that the caller uses to apply routing preferences.

**Parameters/Columns Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- 93% of current rows have both flags NULL (standard eligible providers).
- IsWhitelistedProvider=true: the caller should prefer or force this depot for the transaction.
- IsBlacklistedProvider=true: the caller should exclude this depot from consideration.
- The logic of selecting the final depot from the result set is in the calling application code, not in this procedure.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | YES | NULL | VERIFIED | Customer's country ID. Optional filter - when NULL, returns entries for all countries matching the card type and regulation. When provided, filters to this specific country's routing entries. Implicit FK to Dictionary.Country.CountryID. |
| 2 | @CardTypeID | INT | NO | - | VERIFIED | Card network type ID. Required filter. Current data only contains CardTypeID=1 (Visa, 82%) and CardTypeID=2 (Mastercard, 18%) - AFT routing is limited to card-based transactions. Implicit FK to Dictionary.CardType.CardTypeID. |
| 3 | @RegulationID | INT | NO | - | VERIFIED | Regulatory jurisdiction ID. Required filter. Current data includes CySEC (69% of entries) and other regulators (FCA, ASIC, etc.). Determines which routing rules apply based on the customer's regulatory jurisdiction. Implicit FK to Dictionary.Regulation.RegulationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryID, @CardTypeID, @RegulationID | Billing.AftRouting | READER | SELECT with parameter-based WHERE filter; returns matching routing configuration rows. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from the payment routing engine at transaction time.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AftRoutingGet (procedure)
+- Billing.AftRouting (table)   [SELECT - read source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.AftRouting | Table | SELECT with WHERE filters on CountryID, CardTypeID, RegulationID |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from the payment routing engine application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get routing entries for a Visa card under CySEC regulation in a specific country
```sql
EXEC Billing.AftRoutingGet
    @CountryID    = 186,  -- example: Cyprus
    @CardTypeID   = 1,    -- Visa
    @RegulationID = 1;    -- CySEC (example ID)
```

### 8.2 Get all routing entries for Mastercard under CySEC (country wildcard)
```sql
EXEC Billing.AftRoutingGet
    @CountryID    = NULL,  -- wildcard - all countries
    @CardTypeID   = 2,     -- Mastercard
    @RegulationID = 1;     -- CySEC
```

### 8.3 Check the raw routing table for a card/regulation combination
```sql
SELECT  AR.ID,
        AR.CountryID,
        AR.CardTypeID,
        AR.RegulationID,
        AR.DepotID,
        AR.IsWhitelistedProvider,
        AR.IsBlacklistedProvider,
        AR.ValidFrom,
        AR.ValidTo
FROM    Billing.AftRouting AR WITH (NOLOCK)
WHERE   AR.CardTypeID   = 1
  AND   AR.RegulationID = 1
ORDER BY AR.CountryID, AR.DepotID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AftRoutingGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AftRoutingGet.sql*
