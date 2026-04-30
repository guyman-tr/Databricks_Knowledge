# Price.GetInstrumentsOMPDThresholdByExchangeIds

> Returns OMPD threshold values (InstrumentID, ThresholdType, Value) for instruments belonging to specified exchanges, with optional filtering to active thresholds only - the exchange-scoped read API for OMPD threshold management.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Exchanges (TVP filter), @ActiveOnlyThresholds (active filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentsOMPDThresholdByExchangeIds retrieves OMPD (Order Management Price Deviation) threshold values for a set of instruments, filtered by their exchange membership. OMPD is the protection mechanism that prevents order execution when the market price has moved beyond a configured threshold since the order was placed.

This procedure is the exchange-scoped variant of the OMPD threshold read API. It allows pricing administrators to query "what are the OMPD thresholds for all instruments on NASDAQ?" or "show me active-only thresholds for all CME instruments" by passing exchange IDs via a TVP.

A key feature: when `@Exchanges` TVP is empty, the filter is bypassed and ALL instruments' thresholds are returned. This dual behavior makes the procedure flexible: use it as an exchange filter when you pass exchange IDs, or as a "get all" call when you pass an empty TVP.

---

## 2. Business Logic

### 2.1 Optional Exchange Filter via TVP

**What**: The @Exchanges TVP can be empty (get all) or populated (filter by exchange).

**Columns/Parameters Involved**: `@Exchanges`, `@ExchangeIDsExists`

**Rules**:
- `@ExchangeIDsExists` is computed once at the start: 1 if `@Exchanges` contains rows, 0 if empty
- The LEFT JOIN: `LEFT JOIN @Exchanges e ON IMD.ExchangeID = e.ExchangeID AND @ExchangeIDsExists = 1`
  - When @ExchangeIDsExists=0: the join condition `AND @ExchangeIDsExists = 1` is always FALSE, so no rows match and e.ExchangeID is always NULL
  - When @ExchangeIDsExists=1: normal LEFT JOIN by exchange ID
- The WHERE filter: `(@ExchangeIDsExists = 0 OR e.ExchangeID IS NOT NULL)`
  - When @ExchangeIDsExists=0: condition evaluates to TRUE for all rows - no exchange filtering
  - When @ExchangeIDsExists=1: only rows where e.ExchangeID IS NOT NULL (matched the exchange) are returned

### 2.2 Active Thresholds Filter

**What**: @ActiveOnlyThresholds controls whether only currently active thresholds are returned.

**Columns/Parameters Involved**: `@ActiveOnlyThresholds`, `Price.OMPDActiveThreshold`

**Rules**:
- DEFAULT 1 = active-only thresholds by default
- INNER JOIN with `Price.OMPDActiveThreshold AT ON AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType`
  - This join matches TV rows against AT on BOTH InstrumentID AND ThresholdType
  - Since OMPDActiveThreshold selects exactly one ThresholdType per instrument, this join effectively returns only the active-type value row per instrument (not the inactive stored value)
- WHERE filter: `(@ActiveOnlyThresholds = 0 OR AT.InstrumentID IS NOT NULL)`
  - When @ActiveOnlyThresholds=1: INNER JOIN result means AT.InstrumentID is always NOT NULL for matched rows -> passes filter
  - When @ActiveOnlyThresholds=0: all TV rows pass (including those for inactive threshold types)
  - Note: The INNER JOIN is unconditional; the @ActiveOnlyThresholds parameter only affects whether unmatched rows (inactive types without an active entry) are filtered out in the WHERE clause

### 2.3 Result: ThresholdType and Value

**What**: Returns the raw InstrumentID, ThresholdType, and Value from OMPDThresholdValues.

**Rules**:
- ThresholdType: 1=Pips (absolute deviation in pips), 2=Percentage (% deviation)
- Value: decimal(20,2) - the threshold amount (e.g., 40.00 pips or 50.00%)
- See Price.OMPDThresholdValues and Dictionary.OMPDThresholdType for full type definitions

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Exchanges | Price.ExchangeIDList READONLY | NOT NULL (but can be empty) | - | CODE-BACKED | Table-valued parameter containing ExchangeID values to filter instruments by exchange. Pass an empty TVP to retrieve thresholds for ALL instruments (exchange filter bypassed). Pass one or more ExchangeID values to restrict to instruments on those exchanges. Type: Price.ExchangeIDList (single-column TVP: ExchangeID INT). |
| 2 | @ActiveOnlyThresholds | BIT | NOT NULL | 1 | CODE-BACKED | When 1 (default): returns only the currently active threshold type per instrument (the type designated in Price.OMPDActiveThreshold). When 0: returns all threshold values regardless of active/inactive status - useful for seeing all configured threshold types per instrument. |

**Result set columns** (3 columns):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | InstrumentID | TV.InstrumentID | The instrument's ID |
| 2 | ThresholdType | TV.ThresholdType | Threshold unit type: 1=Pips (absolute pips deviation), 2=Percentage (% deviation). FK to Dictionary.OMPDThresholdType. |
| 3 | Value | TV.Value | The threshold amount. For Pips: absolute pips (e.g., 40.00). For Percentage: percent (e.g., 50.00). Orders deviating beyond this value are flagged/rejected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Exchanges | Price.ExchangeIDList | TVP type | Input exchange filter type |
| InstrumentID | Price.OMPDThresholdValues | READER | Primary source of threshold values |
| InstrumentID | Trade.InstrumentMetaData | INNER JOIN | Resolves instrument to ExchangeID for the exchange filter |
| InstrumentID + ThresholdType | Price.OMPDActiveThreshold | INNER JOIN | Filters to active threshold type per instrument (when @ActiveOnlyThresholds=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (OMPD configuration API) | @Exchanges | CALLER | Called by admin tools to query OMPD thresholds for exchange-specific instrument sets |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentsOMPDThresholdByExchangeIds (procedure)
+-- Price.OMPDThresholdValues (table) - threshold values source
+-- Trade.InstrumentMetaData (table) - exchange ID lookup
+-- Price.OMPDActiveThreshold (table) - active threshold type selector
+-- Price.ExchangeIDList (UDT) - TVP type definition
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.OMPDThresholdValues | Table | FROM source - all threshold values |
| Trade.InstrumentMetaData | Table | INNER JOIN - provides ExchangeID for exchange filter |
| Price.OMPDActiveThreshold | Table | INNER JOIN - restricts to active threshold type per instrument |
| Price.ExchangeIDList | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (OMPD configuration API) | External | Calls to retrieve OMPD thresholds filtered by exchange |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

All table reads use WITH (NOLOCK). The @Exchanges TVP uses READONLY (required for TVP parameters). The INNER JOIN on OMPDActiveThreshold is always applied (not conditional on @ActiveOnlyThresholds); the parameter only affects the WHERE clause filter. This means even when @ActiveOnlyThresholds=0, only instruments that HAVE an active threshold entry will be returned - instruments in OMPDThresholdValues with no corresponding OMPDActiveThreshold row are excluded by the INNER JOIN. This is a subtle behavior difference from GetInstrumentsOMPDThresholdByInstrumentIds which does not join OMPDActiveThreshold.

---

## 8. Sample Queries

### 8.1 Get active OMPD thresholds for all instruments on specific exchanges

```sql
DECLARE @ExchangeList Price.ExchangeIDList;
INSERT INTO @ExchangeList VALUES (1), (2), (5);  -- exchange IDs
EXEC Price.GetInstrumentsOMPDThresholdByExchangeIds
    @Exchanges = @ExchangeList,
    @ActiveOnlyThresholds = 1;
```

### 8.2 Get all OMPD thresholds (both types) for all instruments

```sql
DECLARE @EmptyExchangeList Price.ExchangeIDList;
-- Leave empty to bypass exchange filter
EXEC Price.GetInstrumentsOMPDThresholdByExchangeIds
    @Exchanges = @EmptyExchangeList,
    @ActiveOnlyThresholds = 0;
```

### 8.3 Equivalent manual query for active thresholds by exchange

```sql
DECLARE @ExchangeIDsExists BIT = 1;
SELECT TV.InstrumentID, TV.ThresholdType, TV.Value
FROM Price.OMPDThresholdValues TV WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK)
    ON IMD.InstrumentID = TV.InstrumentID
INNER JOIN Price.OMPDActiveThreshold AT WITH (NOLOCK)
    ON AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType
WHERE IMD.ExchangeID IN (1, 2, 5);  -- replace with desired exchange IDs
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentsOMPDThresholdByExchangeIds | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetInstrumentsOMPDThresholdByExchangeIds.sql*
