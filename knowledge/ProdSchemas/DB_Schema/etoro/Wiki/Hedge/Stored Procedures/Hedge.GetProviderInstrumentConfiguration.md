# Hedge.GetProviderInstrumentConfiguration

> Returns per-provider per-instrument order type overrides including limit offset percentage and GTD expiration, allowing the hedge engine to apply LP-specific order execution parameters at the instrument level.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full provider-instrument configuration table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetProviderInstrumentConfiguration` loads the fine-grained LP-and-instrument-level order execution configuration. While `Hedge.GetOrderTypeConfiguration` provides instrument-level order rules (from the entity-expansion model), this procedure provides an additional override layer: per-LP-type, per-instrument rules for order type, limit offset, and GTD expiration.

The distinction is provider-specificity: different LPs may require or support different order types for the same instrument. For example, LP type A may support GTD limit orders for crude oil futures while LP type B only accepts market orders. `LimitOffsetPercentage` defines how far from the reference price a limit order should be placed (as a percentage), and `GTDTimeSpanInSeconds` defines how long GTD orders stay live before expiry.

Data flows as follows: on startup, the hedge engine calls this procedure and loads the result into a cache keyed by (LiquidityProviderTypeID, InstrumentID). When building an order for a specific LP and instrument, it checks this cache for an override. If found, the LP-specific parameters supersede the general order type configuration from `Hedge.GetOrderTypeConfiguration`.

**Current state**: The underlying `Hedge.ProviderInstrumentConfiguration` table is currently empty (0 rows). The provider-instrument override layer is supported by the architecture but not actively configured. The hedge engine falls back to `Hedge.GetOrderTypeConfiguration` rules for all instruments.

---

## 2. Business Logic

### 2.1 Full Table Read - Provider-Instrument Override Layer

**What**: Returns every row from Hedge.ProviderInstrumentConfiguration without filtering. No parameters, no WHERE clause. The hedge engine loads the entire configuration in one call.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `InstrumentID`, `OrderType`, `LimitOffsetPercentage`, `GTDTimeSpanInSeconds`

**Rules**:
- No WHERE clause - all rows returned
- Uses WITH (NOLOCK) to avoid blocking during the configuration load
- An empty result set (current production state) means no LP-specific overrides are active - the hedge engine falls back to the general order type configuration
- The (LiquidityProviderTypeID, InstrumentID) composite key means one row per LP-instrument combination

**Diagram**:
```
Order placement for InstrumentID=50, LiquidityProviderTypeID=3:
  1. Check GetProviderInstrumentConfiguration cache:
     - If row (3, 50) exists -> use its OrderType, LimitOffsetPercentage, GTDTimeSpanInSeconds
     - If no row -> fall back to GetOrderTypeConfiguration result for InstrumentID=50
  2. Build FIX order with resolved parameters
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Hedge.ProviderInstrumentConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | VERIFIED | The LP type this override applies to. Combined with InstrumentID as the effective composite key. Allows different order execution rules per LP for the same instrument. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The instrument this override applies to. FK to Trade.Instrument. Combined with LiquidityProviderTypeID as the effective composite key. |
| 3 | OrderType | int | YES | - | VERIFIED | The FIX order type to use for this LP-instrument combination. Overrides the general order type from Hedge.GetOrderTypeConfiguration. Specific values map to FIX OrdType field (e.g., 1=Market, 2=Limit, 6=GTD). |
| 4 | LimitOffsetPercentage | decimal | YES | - | VERIFIED | Percentage offset from the reference price to place a limit order. A positive value places the limit inside the spread (e.g., 0.001 = 0.1% below ask for a buy limit). Specific computation depends on hedge engine logic. |
| 5 | GTDTimeSpanInSeconds | int | YES | - | VERIFIED | Expiration duration in seconds for GTD (Good Till Date) orders under this LP-instrument rule. After this period, unfilled GTD orders are cancelled. Overrides the general ExpirationInSeconds from Hedge.GetOrderTypeConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.ProviderInstrumentConfiguration | SELECT | Full table read; returns all LP-instrument order execution overrides. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load the LP-instrument override cache. Used as a second-level configuration override after the general order type configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetProviderInstrumentConfiguration (procedure)
└── Hedge.ProviderInstrumentConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderInstrumentConfiguration | Table | SELECTed with NOLOCK - source of all LP-instrument order execution overrides |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at startup to load per-LP per-instrument order execution parameter overrides |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The table uses WITH (NOLOCK). With 0 current rows, performance is not a concern. The composite PK (LiquidityProviderTypeID, InstrumentID) would make lookups efficient if the table grows.

### 7.2 Constraints

N/A for Stored Procedure. This procedure provides a narrower, provider-specific override layer complementing `Hedge.GetOrderTypeConfiguration`. The hedge engine's precedence rule: if a (LiquidityProviderTypeID, InstrumentID) row exists here, its OrderType/LimitOffsetPercentage/GTDTimeSpanInSeconds take precedence over the general configuration.

---

## 8. Sample Queries

### 8.1 Load all provider-instrument configurations
```sql
EXEC [Hedge].[GetProviderInstrumentConfiguration];
```

### 8.2 Direct table query
```sql
SELECT  LiquidityProviderTypeID,
        InstrumentID,
        OrderType,
        LimitOffsetPercentage,
        GTDTimeSpanInSeconds
FROM    [Hedge].[ProviderInstrumentConfiguration] WITH (NOLOCK)
ORDER BY LiquidityProviderTypeID, InstrumentID;
```

### 8.3 Find all instruments with GTD overrides for a specific provider
```sql
SELECT  InstrumentID,
        OrderType,
        GTDTimeSpanInSeconds
FROM    [Hedge].[ProviderInstrumentConfiguration] WITH (NOLOCK)
WHERE   LiquidityProviderTypeID = 3
  AND   GTDTimeSpanInSeconds IS NOT NULL
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetProviderInstrumentConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetProviderInstrumentConfiguration.sql*
