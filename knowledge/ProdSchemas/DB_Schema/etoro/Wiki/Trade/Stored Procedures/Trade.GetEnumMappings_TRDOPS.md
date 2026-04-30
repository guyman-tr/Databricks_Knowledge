# Trade.GetEnumMappings_TRDOPS

> Returns all dictionary/enum lookup mappings needed by the Trading Operations (TradingOps) Tool API in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 5 result sets of dictionary values |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a bulk dictionary loader for the TradingOps Tool API. It returns five distinct result sets in a single database round-trip, each containing the complete contents of a dictionary/enum table. This allows the API to hydrate its in-memory enum mappings efficiently.

Without this procedure, the TradingOps API would need five separate queries to populate its dropdown lists and enum resolvers. Combining them into one call reduces connection overhead and ensures all mappings are loaded atomically at the same point in time.

The procedure is parameterless and returns all rows from each dictionary table, ordered by their primary key. It is designed to be called at application startup or periodically to refresh configuration caches.

---

## 2. Business Logic

### 2.1 Multi-ResultSet Dictionary Loader Pattern

**What**: Returns five complete dictionary tables as separate result sets.

**Columns/Parameters Involved**: No parameters - returns all rows from each dictionary.

**Rules**:
- Result set 1: `Dictionary.OverNightFeePattern` - overnight fee pattern types (ID, Name, Description)
- Result set 2: `Dictionary.InterestRate` - distinct interest rate types (ID, Name)
- Result set 3: `Dictionary.CurrencyType` - currency types (ID, Name)
- Result set 4: `Dictionary.SettlementTypes` - settlement types (ID, Type label)
- Result set 5: `Dictionary.ExchangeInfo` - exchange information (ID, Description)

**Diagram**:
```
Trade.GetEnumMappings_TRDOPS
  |
  +---> Result Set 1: Dictionary.OverNightFeePattern (full table)
  +---> Result Set 2: Dictionary.InterestRate (distinct IDs/Names)
  +---> Result Set 3: Dictionary.CurrencyType (full table)
  +---> Result Set 4: Dictionary.SettlementTypes (full table)
  +---> Result Set 5: Dictionary.ExchangeInfo (full table)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Result Set 1: OverNightFeePattern

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OverNightFeePatternID | INT | NO | - | CODE-BACKED | Primary key identifying the overnight fee calculation pattern |
| 2 | OverNightFeePatternName | VARCHAR | YES | - | CODE-BACKED | Display name of the overnight fee pattern (e.g., standard, weekend-adjusted) |
| 3 | Description | VARCHAR | YES | '' | CODE-BACKED | Human-readable description of the fee pattern; NULLs coalesced to empty string via ISNULL |

### Result Set 2: InterestRate

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateID | INT | NO | - | CODE-BACKED | Primary key identifying the interest rate type |
| 2 | InterestRateName | VARCHAR | YES | - | CODE-BACKED | Display name of the interest rate type; DISTINCT applied to remove duplicates |

### Result Set 3: CurrencyType

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyTypeID | INT | NO | - | CODE-BACKED | Primary key identifying the currency type |
| 2 | Name | VARCHAR | YES | - | CODE-BACKED | Currency type name (e.g., Fiat, Crypto) |

### Result Set 4: SettlementTypes

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettlementTypeID | INT | NO | - | CODE-BACKED | Primary key identifying the settlement type: 1=Real (stock ownership), 2=CFD, etc. |
| 2 | SettlementType | VARCHAR | YES | - | CODE-BACKED | Display name of the settlement type |

### Result Set 5: ExchangeInfo

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | INT | NO | - | CODE-BACKED | Primary key identifying the stock exchange |
| 2 | ExchangeDescription | VARCHAR | YES | - | CODE-BACKED | Display name/description of the exchange (e.g., NASDAQ, NYSE) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Result Set 1 | Dictionary.OverNightFeePattern | Lookup | Full table read for overnight fee pattern enum |
| Result Set 2 | Dictionary.InterestRate | Lookup | Distinct names/IDs for interest rate enum |
| Result Set 3 | Dictionary.CurrencyType | Lookup | Full table read for currency type enum |
| Result Set 4 | Dictionary.SettlementTypes | Lookup | Full table read for settlement type enum |
| Result Set 5 | Dictionary.ExchangeInfo | Lookup | Full table read for exchange info enum |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingOps Tool API | Startup/refresh | SP Call | Loads all enum mappings for dropdown lists and value resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEnumMappings_TRDOPS (procedure)
  +-- Dictionary.OverNightFeePattern (table)
  +-- Dictionary.InterestRate (table)
  +-- Dictionary.CurrencyType (table)
  +-- Dictionary.SettlementTypes (table)
  +-- Dictionary.ExchangeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OverNightFeePattern | Table | SELECT all rows |
| Dictionary.InterestRate | Table | SELECT DISTINCT rows |
| Dictionary.CurrencyType | Table | SELECT all rows |
| Dictionary.SettlementTypes | Table | SELECT all rows |
| Dictionary.ExchangeInfo | Table | SELECT all rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradingOps Tool API | Application | Calls at startup to load enum caches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetEnumMappings_TRDOPS;
```

### 8.2 Query a single dictionary directly
```sql
SELECT  SettlementTypeID, SettlementType
FROM    Dictionary.SettlementTypes WITH (NOLOCK)
ORDER BY SettlementTypeID;
```

### 8.3 Query overnight fee patterns with descriptions
```sql
SELECT  OverNightFeePatternID,
        OverNightFeePatternName,
        ISNULL(Description, '') AS Description
FROM    Dictionary.OverNightFeePattern WITH (NOLOCK)
ORDER BY OverNightFeePatternID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEnumMappings_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEnumMappings_TRDOPS.sql*
