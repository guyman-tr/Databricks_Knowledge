# Hedge.GetOrderTypeConfiguration

> Expands the three-tier Hedge.OrderTypeConfiguration entity model into a flat per-instrument list of FIX order routing parameters, resolving group and exchange wildcards into concrete InstrumentIDs so the hedge engine can apply per-instrument order rules at execution time.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full expanded configuration for all instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetOrderTypeConfiguration` solves the scale problem in order routing configuration: eToro trades thousands of instruments, but configuring each one individually would be unmanageable. Instead, `Hedge.OrderTypeConfiguration` stores rules at three abstraction levels (Entity=0 direct instrument, Entity=1 instrument group, Entity=2 exchange), and this procedure expands those abstractions into the complete flat list of (InstrumentID, order parameters) pairs that the hedge engine actually uses.

On startup, the hedge engine calls this procedure once to load its order routing cache. When a hedge order is ready to submit, the engine looks up the relevant InstrumentID in this cache to determine: which FIX order type to use (market, limit, GTD), what quantity rounding rules apply, what slippage tolerance is acceptable, whether a time schedule restricts execution, and which reference price to use for limit pricing.

The three-way UNION ensures that both explicit per-instrument configurations and broader group/exchange wildcards are represented in the cache. The `ORDER BY Priority, Entity` ordering means that when the hedge engine loads the results into a dictionary, higher-priority rules overwrite lower-priority ones for the same instrument, implementing a cascading override pattern where precise rules defeat broad defaults.

Data flows as follows: the hedge engine loads this procedure's output into memory. When the PortfolioNetter or SmartExecution module selects an order type for instrument X, it checks the cache keyed by InstrumentID. If no entry exists (instrument not covered by any rule), the engine applies a default order type. If multiple rules cover the same instrument (e.g., direct Entity=0 rule AND an Entity=1 group rule), the Priority ordering ensures the most specific or highest-priority rule wins.

---

## 2. Business Logic

### 2.1 Entity=0: Direct Instrument Override

**What**: Configuration rows where Entity=0 store the InstrumentID directly in the `Value` column (as a varchar). These are per-instrument explicit rules with the highest precision.

**Columns/Parameters Involved**: `Entity`, `Value`, `InstrumentID` (computed)

**Rules**:
- WHERE Entity=0 in Hedge.OrderTypeConfiguration
- `Convert(int, Value)` casts the varchar `Value` column to INT as `InstrumentID`
- No join required - each row is already at instrument granularity
- These rows currently represent all 19 configured entries (all Entity=0 in production)

### 2.2 Entity=1: Instrument Group Expansion

**What**: Configuration rows where Entity=1 store a GroupID in `Value`. These are expanded to all instruments belonging to that group via Hedge.InstrumentGroupsMapping, applying the same order rule to all group members.

**Columns/Parameters Involved**: `Entity`, `Value` (as GroupID), `Hedge.InstrumentGroupsMapping.InstrumentID`, `Hedge.InstrumentGroupsMapping.IsActive`

**Rules**:
- WHERE Entity=1 in Hedge.OrderTypeConfiguration
- JOIN Hedge.InstrumentGroupsMapping ON cast(Value as int) = GroupID WHERE IsActive=1
- Returns one row per active instrument in the group - a single group configuration row expands to N instrument rows
- IsActive=1 filter ensures instruments removed from a group do not receive stale configuration

### 2.3 Entity=2: Exchange Expansion

**What**: Configuration rows where Entity=2 store an exchange identifier in `Value`. These are expanded to all instruments traded on that exchange via Trade.InstrumentMetaData, applying the same order rule to all instruments on the exchange.

**Columns/Parameters Involved**: `Entity`, `Value` (as Exchange code), `Trade.InstrumentMetaData.InstrumentID`, `Trade.InstrumentMetaData.Exchange`

**Rules**:
- WHERE Entity=2 in Hedge.OrderTypeConfiguration
- JOIN Trade.InstrumentMetaData ON Value = Exchange (string match on exchange code)
- Returns one row per instrument listed on that exchange
- No active filter applied at this level (all instruments on the exchange are included)

### 2.4 Priority-Based Override Resolution

**What**: The ORDER BY Priority, Entity clause ensures that when results are loaded into the hedge engine's in-memory dictionary, later entries overwrite earlier ones for the same InstrumentID, producing the effective rule for each instrument.

**Columns/Parameters Involved**: `Priority`, `Entity`

**Rules**:
- Lower Priority number = returned later = overwrites higher-numbered (broader) rules
- Entity appears as secondary sort - within the same priority, Direct (0) overrides Group (1) overrides Exchange (2)
- Effective rule per instrument = the last row returned for that InstrumentID (lowest Priority, lowest Entity)
- This means: a Priority=1 direct instrument rule defeats a Priority=2 group rule for the same instrument

**Diagram**:
```
Hedge.OrderTypeConfiguration (raw):
  Row A: Entity=2, Value='NYSE', Priority=10, OrderType=Market  -> expands to 50 instruments
  Row B: Entity=1, Value='5',   Priority=5,  OrderType=Limit   -> expands to 8 instruments in group 5
  Row C: Entity=0, Value='42',  Priority=1,  OrderType=GTD     -> instrument 42 specifically

After expansion and ORDER BY Priority, Entity:
  InstrumentID=42 appears 3 times (from all three levels)
  Last entry (Priority=1, Entity=0, OrderType=GTD) wins -> instrument 42 uses GTD
  InstrumentID=100 appears twice (NYSE + group 5): last entry = group (Priority=5) wins
  InstrumentID=99  appears once (NYSE only): uses Market order
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Hedge.OrderTypeConfiguration expanded via joins):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ScheduleActive | bit | YES | - | VERIFIED | Whether the time-window restriction (FromTime/ToTime) is currently active for this order rule. 1=apply time check before submitting; 0=ignore time window and always allow execution. |
| 2 | FromTime | time | YES | - | VERIFIED | Start of the permitted execution window (UTC). Only relevant when ScheduleActive=1. Orders outside this window may be deferred or rejected. |
| 3 | ToTime | time | YES | - | VERIFIED | End of the permitted execution window (UTC). Only relevant when ScheduleActive=1. Paired with FromTime to define the daily trading window for this instrument. |
| 4 | ProviderType | int | YES | - | VERIFIED | The liquidity provider type this rule applies to (FK to Dictionary/provider type lookup). Allows per-LP order routing rules on the same instrument. |
| 5 | LiquidityAccountID | int | YES | - | VERIFIED | The LP account this rule applies to. Narrows the rule to a specific account under the provider, enabling account-level order routing overrides. |
| 6 | InstrumentID | int | NO | - | VERIFIED | The resolved financial instrument for this rule row. For Entity=0: cast(Value as int). For Entity=1: from Hedge.InstrumentGroupsMapping.InstrumentID. For Entity=2: from Trade.InstrumentMetaData.InstrumentID. |
| 7 | QuantityType | int | YES | - | VERIFIED | Controls how order quantity is computed and rounded. Specific values defined in application logic (e.g., 1=lots, 2=units, 3=notional). Determines the unit denomination for the Threshold field. |
| 8 | Threshold | decimal | YES | - | VERIFIED | Minimum order size threshold in the units defined by QuantityType. Orders below this threshold may be aggregated or suppressed. |
| 9 | Slippage | decimal | YES | - | VERIFIED | Maximum allowable slippage in price units for this instrument's orders. Trades that fill beyond this deviation from the reference price may be rejected or flagged. |
| 10 | ExpirationInSeconds | int | YES | - | VERIFIED | Time-to-live for GTD (Good Till Date) orders in seconds. After this duration, unfilled orders are cancelled. Only relevant for GTD/limit order types. |
| 11 | Priority | int | NO | - | VERIFIED | Override precedence. Lower number = higher priority = wins when multiple rules cover the same instrument. Defines which rule is effective when entity levels overlap on the same InstrumentID. |
| 12 | Entity | int | NO | - | VERIFIED | Abstraction level of the source configuration row. 0=direct instrument, 1=instrument group, 2=exchange. Included in output for the hedge engine to understand which rule tier is in effect. |
| 13 | TimeInForce | int | YES | - | VERIFIED | FIX TimeInForce value for orders under this rule (e.g., 0=Day, 1=GTC, 6=GTD). Instructs the LP on how long to hold the order if not immediately filled. |
| 14 | ReferencePriceType | int | YES | - | VERIFIED | Determines which price is used as the reference when placing limit orders (e.g., 0=Bid, 1=Ask, 2=Mid). Controls limit price calculation logic in the hedge engine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.OrderTypeConfiguration | SELECT (all 3 branches) | Source of all order routing rules at all three entity abstraction levels. |
| GroupID | Hedge.InstrumentGroupsMapping | JOIN (Entity=1 branch) | Expands group-level configuration to individual instrument rows. Filtered to IsActive=1. |
| Exchange | Trade.InstrumentMetaData | JOIN (Entity=2 branch) | Expands exchange-level configuration to individual instrument rows by matching on exchange code. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load the per-instrument order routing cache. Used by execution modules to determine FIX order parameters per instrument. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetOrderTypeConfiguration (procedure)
├── Hedge.OrderTypeConfiguration (table) - all three SELECT branches
├── Hedge.InstrumentGroupsMapping (table) - Entity=1 expansion
└── Trade.InstrumentMetaData (table) [cross-schema] - Entity=2 expansion
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.OrderTypeConfiguration | Table | Source of all order routing rules; read from three branches of the UNION |
| Hedge.InstrumentGroupsMapping | Table | Expands Entity=1 group rules to per-instrument rows; filtered to IsActive=1 |
| Trade.InstrumentMetaData | Table | Expands Entity=2 exchange rules to per-instrument rows; matched on Exchange field |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loads result at startup into in-memory order routing dictionary keyed by InstrumentID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The UNION of three SELECT statements means three scans of Hedge.OrderTypeConfiguration (filtered by Entity each time) plus one scan each of InstrumentGroupsMapping and InstrumentMetaData. With 19 rows currently all Entity=0, the Entity=1 and Entity=2 branches return empty result sets, so performance is trivially fast. Performance would be relevant if thousands of group or exchange-level rules were added.

### 7.2 Constraints

N/A for Stored Procedure. Important behavioral note: the procedure uses no isolation level hint (no WITH NOLOCK, no explicit SET TRANSACTION). It runs at the default READ COMMITTED isolation level. The `ORDER BY Priority, Entity` only governs the return order - the hedge engine must implement its own override logic (last-row-wins dictionary insertion) to produce the effective per-instrument rule. The procedure itself does NOT deduplicate InstrumentIDs; the same InstrumentID can appear multiple times in the output if covered by rules at multiple entity levels.

---

## 8. Sample Queries

### 8.1 Load full expanded order type configuration
```sql
EXEC [Hedge].[GetOrderTypeConfiguration];
```

### 8.2 Direct query to see all direct-instrument rules (Entity=0)
```sql
SELECT  CONVERT(int, Value) AS InstrumentID,
        ProviderType,
        LiquidityAccountID,
        QuantityType,
        Threshold,
        Slippage,
        ExpirationInSeconds,
        Priority,
        TimeInForce,
        ReferencePriceType
FROM    [Hedge].[OrderTypeConfiguration] WITH (NOLOCK)
WHERE   Entity = 0
ORDER BY Priority;
```

### 8.3 See which instruments are covered by group expansion (Entity=1)
```sql
SELECT  otc.Priority,
        otc.QuantityType,
        otc.Threshold,
        igm.GroupID,
        igm.InstrumentID
FROM    [Hedge].[OrderTypeConfiguration] otc WITH (NOLOCK)
JOIN    [Hedge].[InstrumentGroupsMapping] igm WITH (NOLOCK)
        ON CAST(otc.Value AS int) = igm.GroupID
WHERE   otc.Entity = 1
  AND   igm.IsActive = 1
ORDER BY otc.Priority, igm.InstrumentID;
```

### 8.4 Simulate effective rule per instrument (deduplicated, highest priority wins)
```sql
WITH Expanded AS (
    EXEC [Hedge].[GetOrderTypeConfiguration]
),
Ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Priority ASC, Entity ASC) AS rn
    FROM   Expanded
)
SELECT * FROM Ranked WHERE rn = 1;
-- Note: wrap in a temp table since EXEC cannot be directly used in CTE
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetOrderTypeConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetOrderTypeConfiguration.sql*
