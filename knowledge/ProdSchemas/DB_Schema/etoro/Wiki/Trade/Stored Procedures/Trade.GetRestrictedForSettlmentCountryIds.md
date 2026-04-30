# Trade.GetRestrictedForSettlmentCountryIds

> Returns all CountryIDs where real stock settlement is restricted (IsSettlementRestricted=1 in Dictionary.Country). No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the list of countries where eToro restricts real stock settlement. "Settlement restricted" means customers from these countries cannot hold or receive real stock positions (SettlementTypeID=1/REAL) - they can only trade CFD (Contract for Difference) equivalents. This is typically driven by regulatory requirements: certain jurisdictions prohibit brokers from offering actual stock ownership to retail customers.

The procedure is a simple configuration reader - it returns a list of CountryIDs the application uses to block REAL settlement for customers from these countries. It is the country-level complement to `Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType`, which provides the more granular per-instrument-type restriction list.

---

## 2. Business Logic

### 2.1 Settlement Restriction Flag

**What**: A single flag in Dictionary.Country marks countries where settlement (real stock ownership) is blocked.

**Columns/Parameters Involved**: `Dictionary.Country.IsSettlementRestricted`, `CountryID`

**Rules**:
- IsSettlementRestricted=1: customers from this country cannot receive real stock settlement.
- IsSettlementRestricted=0/NULL: no settlement restriction for this country.
- The returned CountryID list is used by the trading engine to downgrade REAL orders to CFD for restricted-country customers.

**Diagram**:
```
Dictionary.Country WHERE IsSettlementRestricted=1
  -> CountryID list (e.g., [US, AU, IL, ...])
  -> Application checks: customer.CountryID IN this list?
     YES -> Block REAL settlement, force CFD
     NO  -> Allow REAL settlement
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | INT | NO | - | CODE-BACKED | Country identifier where real stock settlement is restricted. FK to Dictionary.Country. Application uses this list to enforce CFD-only trading for customers from these countries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Reader (cross-schema) | Source of settlement restriction flag; WHERE IsSettlementRestricted=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Settlement restriction service | (none) | Application call | Called at startup or on cache refresh to load the restricted country list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRestrictedForSettlmentCountryIds (procedure)
+-- Dictionary.Country (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table (Dictionary schema) | SELECT CountryID WHERE IsSettlementRestricted=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Settlement/trading service | External application | Loads restricted country list for CFD-only enforcement |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED - configuration table, acceptable for dirty reads |
| IsSettlementRestricted=1 | Business filter | Only countries with explicit restriction flag |

---

## 8. Sample Queries

### 8.1 Get all settlement-restricted countries

```sql
EXEC Trade.GetRestrictedForSettlmentCountryIds;
```

### 8.2 Equivalent inline query

```sql
SELECT CountryID
FROM Dictionary.Country WITH (NOLOCK)
WHERE IsSettlementRestricted = 1;
```

### 8.3 Look up country names for restricted countries

```sql
SELECT c.CountryID, c.CountryName
FROM Dictionary.Country c WITH (NOLOCK)
WHERE c.IsSettlementRestricted = 1
ORDER BY c.CountryName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRestrictedForSettlmentCountryIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRestrictedForSettlmentCountryIds.sql*
