# Dictionary.AllowedOpenOrderType

> Lookup table defining the 3 allowed open order input modes — All, UnitsOnly, and AmountOnly — controlling whether instruments accept position-open orders in units, dollar amounts, or both.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AllowedOpenOrderTypeID (TINYINT, no PK constraint) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.AllowedOpenOrderType controls how customers can specify position sizes when opening trades on different instruments. Some instruments only allow orders in units (e.g., "buy 10 shares"), some only in dollar amounts (e.g., "buy $500 worth"), and some allow both. This is configured per instrument via Trade.ProviderToInstrument.

This table is essential for the order validation pipeline. When a customer submits an open order, the system checks the instrument's AllowedOpenOrderTypeID to determine whether the order format (units vs amount) is permitted. Invalid combinations are rejected before reaching the execution engine.

Referenced by Trade.GetInstrumentDataForAPI (returns instrument configuration to the frontend), Trade.CheckValidInstruments (validates instrument trading rules), Trade.InsertInstrumentTradingData and Trade.InsertInstrumentRealTable (instrument setup), and Trade.GetPortfolioAggregates. The table has no PK or indexes — it's a simple heap with duplicate rows per ID (likely due to a data issue or intentional denormalization).

---

## 2. Business Logic

### 2.1 Order Input Modes

**What**: Controls how customers specify position sizes for different instruments.

**Columns/Parameters Involved**: `AllowedOpenOrderTypeID`, `AllowedOpenOrderTypeName`

**Rules**:
- **All (0)**: Both units and dollar amounts are accepted. Customer can choose to buy "10 units of AAPL" or "$500 of AAPL". Most flexible mode — used for popular instruments.
- **UnitsOnly (1)**: Only unit-based orders are accepted. Customer must specify "buy 10 shares" — dollar amount input is disabled on the frontend. Typically used for instruments where fractional units don't make business sense.
- **AmountOnly (2)**: Only dollar-amount orders are accepted. Customer must specify "buy $500 worth" — unit input is disabled. Used for instruments where the platform handles unit calculation (e.g., crypto, certain CFDs).

**Diagram**:
```
Order Input Validation:

  Customer submits order
       │
       ▼
  Check instrument's AllowedOpenOrderTypeID
       │
       ├── 0 (All)        → Accept units OR amount ✓
       │
       ├── 1 (UnitsOnly)  → Accept units only
       │                     Reject amount → Error ✗
       │
       └── 2 (AmountOnly) → Accept amount only
                             Reject units → Error ✗
```

---

## 3. Data Overview

| AllowedOpenOrderTypeID | AllowedOpenOrderTypeName | Meaning |
|---|---|---|
| 0 | All | Instrument accepts both unit-based and dollar-amount orders. Frontend shows both input modes. Maximum flexibility for the customer. |
| 1 | UnitsOnly | Instrument only accepts unit-based orders (e.g., "buy 10 shares"). Dollar-amount input is hidden in the UI. Used when fractional unit purchases aren't supported or desired. |
| 2 | AmountOnly | Instrument only accepts dollar-amount orders (e.g., "invest $500"). Unit input is hidden — the platform calculates the resulting units. Common for crypto and certain CFD instruments. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AllowedOpenOrderTypeID | tinyint | NO | - | CODE-BACKED | Identifier for the order input mode. 0=All (units+amount), 1=UnitsOnly, 2=AmountOnly. No PK constraint. Stored in Trade.ProviderToInstrument per instrument. Validated by Trade.CheckValidInstruments during order submission. |
| 2 | AllowedOpenOrderTypeName | char(50) | NO | - | CODE-BACKED | Fixed-width name (padded with spaces). Legacy char(50) type. Values: 'All', 'UnitsOnly', 'AmountOnly'. Returned by Trade.GetInstrumentDataForAPI for frontend rendering. Trim trailing spaces when displaying. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | AllowedOpenOrderTypeID | Implicit | Per-instrument order mode configuration |
| History.TradeProviderToInstrument | AllowedOpenOrderTypeID | Implicit | Historical instrument configuration |
| Trade.GetInstrumentDataForAPI | AllowedOpenOrderTypeID | SELECT | Returns to frontend for UI rendering |
| Trade.CheckValidInstruments | AllowedOpenOrderTypeID | WHERE | Validates order format during submission |
| Trade.InsertInstrumentTradingData | AllowedOpenOrderTypeID | INSERT | Sets order mode during instrument setup |
| Trade.InsertInstrumentRealTable | AllowedOpenOrderTypeID | INSERT | Sets order mode for real instruments |
| Trade.GetPortfolioAggregates | AllowedOpenOrderTypeID | SELECT | Portfolio instrument configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Stores AllowedOpenOrderTypeID per instrument |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reader — frontend instrument config |
| Trade.CheckValidInstruments | Stored Procedure | Reader — order validation |
| Trade.InsertInstrumentTradingData | Stored Procedure | Writer — instrument setup |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table is a heap on DICTIONARY filegroup.

### 7.2 Constraints

None. No PK, no unique constraints. Note: live data contains duplicate rows per ID (4 rows each for IDs 0, 1, 2) — likely a data quality issue.

---

## 8. Sample Queries

### 8.1 List distinct order types
```sql
SELECT  DISTINCT
        AllowedOpenOrderTypeID,
        RTRIM(AllowedOpenOrderTypeName) AS AllowedOpenOrderTypeName
FROM    Dictionary.AllowedOpenOrderType WITH (NOLOCK)
ORDER BY AllowedOpenOrderTypeID;
```

### 8.2 Count instruments by allowed order type
```sql
SELECT  RTRIM(aoot.AllowedOpenOrderTypeName) AS OrderType,
        COUNT(DISTINCT pti.InstrumentID) AS InstrumentCount
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN    (SELECT DISTINCT AllowedOpenOrderTypeID, AllowedOpenOrderTypeName
         FROM Dictionary.AllowedOpenOrderType WITH (NOLOCK)) aoot
        ON pti.AllowedOpenOrderTypeID = aoot.AllowedOpenOrderTypeID
GROUP BY RTRIM(aoot.AllowedOpenOrderTypeName);
```

### 8.3 Find instruments restricted to amount-only orders
```sql
SELECT  pti.InstrumentID,
        RTRIM(aoot.AllowedOpenOrderTypeName) AS OrderMode
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN    (SELECT DISTINCT AllowedOpenOrderTypeID, AllowedOpenOrderTypeName
         FROM Dictionary.AllowedOpenOrderType WITH (NOLOCK)) aoot
        ON pti.AllowedOpenOrderTypeID = aoot.AllowedOpenOrderTypeID
WHERE   aoot.AllowedOpenOrderTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AllowedOpenOrderType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AllowedOpenOrderType.sql*
