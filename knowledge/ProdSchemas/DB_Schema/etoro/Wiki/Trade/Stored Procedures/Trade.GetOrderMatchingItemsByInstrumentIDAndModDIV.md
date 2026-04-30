# Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV

> Combined OME data SP returning 3 result sets (position trees + OME orders + entry orders + exit orders) with modulo-based sharding for distributed Order Matching Engine instances.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.OMEMatchingTableType TVP) |
| **Partition** | N/A |
| **Indexes** | Creates #PositionHeaders with CLUSTERED INDEX cix on (TreeID, RootHedgeServerID) |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentIDAndModDIV` is the primary combined OME data retrieval SP that returns multiple result sets in a single call: (1) position tree data for SL/TP management, (2) root-level OME orders, (3) entry orders, and (4) exit orders - all filtered by instrument and modulo sharding config. It is the "all-in-one" version superseding the individual GetOrderMatchingItemsByInstrumentID_* SPs.

**WHY:** OME instances run in distributed mode, each responsible for a modulo bucket of order IDs/position IDs (`OrderID % ModDivider = ModResult` and `PositionID % ModDivider = ModResult`). This sharding distributes matching load across multiple OME instances. The combined SP minimizes DB round-trips by returning all needed data in one call.

**HOW:**
1. Load TVP (OMEMatchingTableType with HandleSlTp, HandleOrders, ModDivider, ModResult) into #instrumentsTable.
2. Read Maintenance.Feature FeatureID=22 for @IsReal multiplier (tree ID convention).
3. **Result set 1 - Position Trees (HandleSlTp=1):** Join PositionTreeInfo + PositionTbl + CustomerStatic, filter `(PositionID * @IsReal) = TreeID AND StatusID=1 AND inst.HandleSlTp=1 AND PositionID % ModDivider = ModResult`. Aggregate hedge units. Returns DISTINCT rows.
4. **Result set 2 - OME Orders (HandleOrders=1):** Trade.Orders with `ParentOrderID=0 AND OrderID % ModDivider = ModResult AND inst.HandleOrders=1`. Amount divided by 100 (cents to dollars).
5. **Result set 3 - Entry Orders (HandleOrders=1):** Trade.OrdersEntry with `OrderID % ModDivider = ModResult AND inst.HandleOrders=1`.
6. **Result set 4 (Exit Orders):** Trade.OrdersExit joined with Trade.Position with `OrderID % ModDivider = ModResult AND inst.HandleOrders=1`.

Note: Change log comment shows this was created 2019-03-13 ("Free Stocks" / FB 53719) with TRY/CATCH and DEADLOCK_PRIORITY HIGH added.

---

## 2. Business Logic

### 2.1 Modulo-Based Sharding (ModDivider / ModResult)

**What:** The ModDivider/ModResult pattern enables horizontal scaling of the OME. Multiple OME instances each receive a different ModResult for the same ModDivider, partitioning the work.

**Columns/Parameters Involved:** `ModDivider`, `ModResult` (in TVP)

**Rules:**
- `PositionID % inst.ModDivider = inst.ModResult` -> position trees for this OME shard
- `OrderID % inst.ModDivider = inst.ModResult` -> orders for this OME shard
- Example: ModDivider=4, ModResult=0 -> this OME handles positions/orders where ID mod 4 = 0 (25% of total)
- Caller (OME orchestration) sets ModDivider to total OME instance count and ModResult to this instance's shard number

### 2.2 HandleSlTp vs HandleOrders Flags

**What:** The TVP distinguishes two processing responsibilities per instrument: SL/TP tree management (HandleSlTp) and order matching (HandleOrders). An OME instance can be configured for one, both, or neither per instrument.

**Columns/Parameters Involved:** `HandleSlTp`, `HandleOrders` (in TVP)

**Rules:**
- `HandleSlTp=1`: This OME instance handles trailing SL/TP for this instrument -> position tree data returned (result set 1)
- `HandleOrders=1`: This OME instance handles order matching for this instrument -> OME orders (2), entry orders (3), exit orders (4) returned
- Allows different OME instances to specialize in SL/TP vs order matching per instrument

### 2.3 Feature Flag FeatureID=22 - Tree ID Convention

**What:** Same pattern as GetOrderMatchingItemsByInstrumentID_OmeTrees. See that procedure's Section 2.1.

**Rules:**
- Feature 22 enabled: @IsReal=1, TreeID = PositionID (positive)
- Feature 22 disabled: @IsReal=-1, TreeID = -PositionID (negative)

### 2.4 Amount Unit Conversion

**What:** Trade.Orders stores Amount in cents. This SP converts to dollars (Amount/100) for the OME.

**Columns/Parameters Involved:** `Amount` (in result set 2)

### 2.5 Error Handling and Deadlock Priority

**What:** The SP uses TRY/CATCH with THROW and sets DEADLOCK_PRIORITY HIGH, indicating it runs in a high-concurrency, latency-sensitive OME context.

**Rules:**
- `SET DEADLOCK_PRIORITY HIGH`: This SP's transaction is less likely to be chosen as the deadlock victim
- `BEGIN TRY ... BEGIN CATCH THROW`: Exceptions are re-raised to caller for OME to handle

### 2.6 IsDiscounted Column Difference

**What:** This SP returns IsDiscounted (from PositionTreeInfo) in result set 1 (position trees), and also in entry orders (result set 3). The individual OmeTrees SP does NOT include IsDiscounted in result set 1, but this version does.

**Columns/Parameters Involved:** `IsDiscounted`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.OMEMatchingTableType | NO | - | CODE-BACKED | TVP with columns: InstrumetID INT (typo - missing 'n'), HandleSlTp BIT, HandleOrders BIT, ModDivider INT, ModResult INT. Defines the instruments and sharding config for this OME instance. See Trade.OMEMatchingTableType documentation. |

**Result Set 1 - Position Trees (HandleSlTp=1, PositionID % ModDivider = ModResult):**

| # | Element | Source | Description |
|---|---------|--------|-------------|
| 1 | InstrumentID | TVP join | Instrument ID |
| 2 | PositionID | Trade.PositionTbl | Tree head position ID (selected by @IsReal multiplier) |
| 3 | CID | Trade.PositionTbl | Customer ID |
| 4 | InitDateTime | Trade.PositionTbl | Position open timestamp |
| 5 | StopRate | Trade.PositionTbl | Current stop-loss rate |
| 6 | LimitRate | Trade.PositionTbl | Current take-profit rate |
| 7 | IsBuy | Trade.PositionTbl | Direction flag |
| 8 | RootHedgeServerID | Trade.PositionTbl | Root hedge server ID |
| 9 | TreeID | Trade.PositionTreeInfo | Copy-trade tree ID |
| 10 | IsTslEnabled | Trade.PositionTreeInfo | Trailing SL enabled flag |
| 11 | SLManualVer (-> StopLossVersion) | Trade.PositionTreeInfo | Manual SL version counter |
| 12 | NextThresHold (-> TrailingStopLossThreshold) | Trade.PositionTreeInfo | Next TSL price threshold |
| 13 | SLManualVerTimestamp (-> StopLossVersionTimestamp) | Trade.PositionTreeInfo | SL version timestamp |
| 14 | AmountInUnitsDecimal | Windowed SUM | Total hedge-eligible units (IsComputeForHedge=1) per TreeID/RootHedgeServerID |
| 15 | Leverage | Trade.PositionTbl | Leverage multiplier |
| 16 | IsDiscounted | Trade.PositionTreeInfo | Fee discount flag (Note: OmeTrees SP does NOT include this; this SP does) |

**Result Set 2 - OME Orders (HandleOrders=1, ParentOrderID=0, OrderID % ModDivider = ModResult):**

| # | Element | Source | Description |
|---|---------|--------|-------------|
| 1-29 | (Same as GetOrderMatchingItemsByInstrumentID_OMEOrders output) | Trade.Orders | All OME order fields; Amount in dollars (Amount/100). See OMEOrders documentation for full column list. |

**Result Set 3 - Entry Orders (HandleOrders=1, OrderID % ModDivider = ModResult):**

| # | Element | Source | Description |
|---|---------|--------|-------------|
| 1-16 | (Similar to GetOrderMatchingItemsByInstrumentID_EntryOrders output) | Trade.OrdersEntry | Pending entry orders; Note: does NOT include SettlementTypeID (unlike EntryOrders SP). Includes IsDiscounted (not in EntryOrders SP). |

**Result Set 4 - Exit Orders (HandleOrders=1, OrderID % ModDivider = ModResult):**

| # | Element | Source | Description |
|---|---------|--------|-------------|
| 1-8 | (Same as GetOrderMatchingItemsByInstrumentID_ExitOrders output) | Trade.OrdersExit + Trade.Position | Exit order + position data. Uses Trade.Position view (not PositionTbl) unlike ExitOrders SP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.OMEMatchingTableType | TVP Type | Rich TVP with sharding config |
| #PositionHeaders | Trade.PositionTreeInfo | JOIN | Tree SL/TP configuration |
| #PositionHeaders | Trade.PositionTbl | JOIN | Open positions with modulo shard filter |
| #PositionHeaders | Customer.CustomerStatic | JOIN | Customer country |
| Final SELECT RS1 | Trade.Position | VIEW JOIN | Hedge amount aggregation |
| FeatureID=22 | Maintenance.Feature | Lookup | Tree ID convention |
| RS2 | Trade.Orders | Lookup | Root OME orders |
| RS3 | Trade.OrdersEntry | Lookup | Pending entry orders |
| RS4 | Trade.OrdersExit | Lookup | Pending exit orders |
| RS4 JOIN | Trade.Position | VIEW | Open position data for exit orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV (procedure)
|- Trade.OMEMatchingTableType (user defined type) - TVP with sharding config
|- Trade.PositionTreeInfo (table) - tree SL/TP configuration
|- Trade.PositionTbl (table) - open positions
|- Customer.CustomerStatic (table) - customer country
|- Trade.Position (view) - aggregated position data
|- Maintenance.Feature (table) - FeatureID=22 for tree ID convention
|- Trade.Orders (table) - root OME orders
|- Trade.OrdersEntry (view) - pending entry orders
|- Trade.OrdersExit (table) - pending exit orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OMEMatchingTableType | User Defined Type | TVP type with HandleSlTp, HandleOrders, ModDivider, ModResult |
| Trade.PositionTreeInfo | Table | Tree SL/TP data for result set 1 |
| Trade.PositionTbl | Table | Open positions for result set 1 (tree heads) |
| Customer.CustomerStatic | Table | Country ID for result set 1 |
| Trade.Position | View | Windowed hedge amount aggregation for result set 1 + exit order position data for result set 4 |
| Maintenance.Feature | Table | Feature 22 for @IsReal multiplier |
| Trade.Orders | Table | Root OME orders for result set 2 (Amount/100 conversion) |
| Trade.OrdersEntry | View | Entry orders for result set 3 |
| Trade.OrdersExit | Table | Exit orders for result set 4 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Primary OME data SP called by OME application (trading-execution-services) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Temp table #PositionHeaders has CLUSTERED INDEX cix on (TreeID, RootHedgeServerID) to optimize the Trade.Position windowed aggregate join)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET DEADLOCK_PRIORITY HIGH | Session setting | This SP is high-priority for the OME; less likely to be deadlock victim |
| TRY/CATCH THROW | Error handling | Exceptions propagated to caller with full error context |
| PositionID % ModDivider = ModResult | Sharding filter | Modulo-based horizontal OME partitioning |
| OrderID % ModDivider = ModResult | Sharding filter | Same modulo sharding applied to order data |
| InstrumetID (typo) | Column name | The TVP column has a typo (missing 'n') - this is the actual column name in OMEMatchingTableType |

---

## 8. Sample Queries

### 8.1 Execute for instruments with sharding (OME shard 0 of 4)

```sql
DECLARE @instruments Trade.OMEMatchingTableType
-- Shard 0 of 4: handle SL/TP and orders for Bitcoin and Ethereum
INSERT INTO @instruments VALUES (1, 1, 1, 4, 0)  -- InstrumetID, HandleSlTp, HandleOrders, ModDivider, ModResult
INSERT INTO @instruments VALUES (2, 1, 1, 4, 0)

EXEC Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV
    @instrumentsTable = @instruments
```

### 8.2 Check feature 22 for tree ID convention

```sql
SELECT FeatureID, Value FROM Maintenance.Feature WITH (NOLOCK) WHERE FeatureID = 22
```

### 8.3 Simulate modulo sharding for position trees

```sql
-- Preview which positions this OME shard would process (ModDivider=4, ModResult=0):
SELECT TOP 20 PositionID, CID, InstrumentID, StatusID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE StatusID = 1 AND PositionID % 4 = 0
ORDER BY PositionID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV.sql*
