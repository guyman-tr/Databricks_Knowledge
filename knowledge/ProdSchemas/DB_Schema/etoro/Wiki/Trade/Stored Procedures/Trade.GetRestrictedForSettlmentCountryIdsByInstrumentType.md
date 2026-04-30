# Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType

> Returns all (CountryID, InstrumentTypeID) pairs where copy-trade real stock settlement is restricted, ordered by InstrumentTypeID. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the granular settlement restriction matrix: which countries are restricted for which instrument types. While `Trade.GetRestrictedForSettlmentCountryIds` returns a simple country list (restricted for all instruments), this procedure returns a (country, instrument type) pair list - allowing the system to enforce restrictions at the instrument-type level. For example, a country might be restricted for Stocks (InstrumentTypeID=5) but not for Forex (InstrumentTypeID=1).

The data source is `Trade.CountryCopySettledResrictionsByInstrumentType` - a small lookup table populated externally (via ETL or manual scripts) that maps restricted (country, instrument type) combinations. The DISTINCT keyword handles any potential duplicates in the source table, and ORDER BY InstrumentTypeID provides a consistent ordering for the application layer.

---

## 2. Business Logic

### 2.1 Instrument-Type-Level Settlement Restrictions

**What**: Settlement restrictions can be applied per instrument type, not just per country, enabling fine-grained control.

**Columns/Parameters Involved**: `CountryID`, `InstrumentTypeID`

**Rules**:
- Each row means: customers from CountryID cannot use REAL settlement for instruments of InstrumentTypeID.
- InstrumentTypeID values (from Dictionary.CurrencyType): 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=Crypto (etc.).
- DISTINCT prevents duplicates if the source table has multiple entries for the same pair.
- ORDER BY InstrumentTypeID groups all restrictions for each instrument type together.
- A country restricted in GetRestrictedForSettlmentCountryIds may not appear here (and vice versa): they are separate restriction mechanisms for different use cases.

**Diagram**:
```
Example result:
  CountryID=52 (Croatia), InstrumentTypeID=5 (Stocks)  -> Stocks settlement restricted in Croatia
  CountryID=98 (Iran),    InstrumentTypeID=5 (Stocks)  -> Stocks settlement restricted in Iran
  CountryID=52 (Croatia), InstrumentTypeID=6 (Crypto)  -> Crypto settlement restricted in Croatia
  ...ordered by InstrumentTypeID

Application checks: (customer.CountryID, order.InstrumentTypeID) IN result?
  YES -> Block REAL settlement for this instrument type
  NO  -> Allow
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
| 1 | CountryID | INT | NO | - | CODE-BACKED | Country where settlement is restricted for the paired instrument type. Implicitly references Dictionary.Country. From Trade.CountryCopySettledResrictionsByInstrumentType. |
| 2 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type for which settlement is restricted in the paired country. Values: 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=Crypto (Dictionary.CurrencyType / InstrumentType). Result ordered by this column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID, InstrumentTypeID | Trade.CountryCopySettledResrictionsByInstrumentType | Reader | Complete source of restriction pairs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Settlement/copy-trade service | (none) | Application call | Loads instrument-type-level restriction matrix for REAL settlement enforcement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType (procedure)
+-- Trade.CountryCopySettledResrictionsByInstrumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CountryCopySettledResrictionsByInstrumentType | Table | SELECT DISTINCT CountryID, InstrumentTypeID ordered by InstrumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Settlement/copy-trade service | External application | Loads (country, instrument type) restriction matrix for granular REAL settlement blocking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| NOLOCK | Isolation hint | READ UNCOMMITTED - static lookup table |
| DISTINCT | Deduplication | Handles potential duplicate rows in source table |
| ORDER BY InstrumentTypeID | Sort | Consistent ordering for application layer consumption |

---

## 8. Sample Queries

### 8.1 Get all country-instrument-type settlement restrictions

```sql
EXEC Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType;
```

### 8.2 Equivalent inline query

```sql
SELECT DISTINCT CountryID, InstrumentTypeID
FROM Trade.CountryCopySettledResrictionsByInstrumentType WITH (NOLOCK)
ORDER BY InstrumentTypeID;
```

### 8.3 Check if a specific country-instrument combination is restricted

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Trade.CountryCopySettledResrictionsByInstrumentType WITH (NOLOCK)
    WHERE CountryID = 52 AND InstrumentTypeID = 5
) THEN 'RESTRICTED' ELSE 'ALLOWED' END AS SettlementStatus;
-- CountryID=52 (Croatia), InstrumentTypeID=5 (Stocks)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType.sql*
