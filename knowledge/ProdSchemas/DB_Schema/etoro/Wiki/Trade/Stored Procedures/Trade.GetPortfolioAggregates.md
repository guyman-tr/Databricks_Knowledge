# Trade.GetPortfolioAggregates

> Returns 8 result sets powering the Portfolio Breakdowns API - account info, mirror metadata, open/close orders, redeem positions, and pre-aggregated instrument+granular position data for both manual and copy-trade portfolios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + optional @InstrumentIDs + @MirrorIDs filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPortfolioAggregates` is the primary data layer for the Portfolio Breakdowns API (`GET /portfolios/instrument-aggregates`, `GET /portfolios/positions`, `GET /portfolios/account-totals`, etc.). It assembles a complete portfolio snapshot for a customer in a single DB round-trip by returning 8 result sets: account info, mirror metadata, manual/mirror open orders, close orders, redeem positions, and two pre-computed aggregate result sets (manual portfolio and copy-trade portfolios) grouped by instrument and by sub-instrument-attributes (IsBuy, IsSettled, PnLVersion).

**WHY:** The Trading API's portfolio page must display current portfolio value, positions grouped by instrument, copy-trade allocation, frozen cash, and pending orders. A single SP call is far more efficient than N separate queries. The aggregation is done in SQL (not in application memory) because the DB already has all position data resident in buffer pool; materializing granular aggregates with weighted averages (InitForexRate * Units, Leverage * LotCount, etc.) in the DB avoids shipping thousands of raw rows to the application layer.

**HOW:**
1. Two dynamic SQL queries build and populate memory-optimized table variables `@AllOpenOrders` (Trade.AllOpenOrdersTableType_MOT) and `@UserPositions` (Trade.UserPositionsTableType_MOT) with optional instrument/mirror filters applied dynamically (avoiding OR EXISTS patterns that prevent plan reuse).
2. From `@AllOpenOrders`: FrozenCash is computed, then RS1 (account+FrozenCash), RS3 (manual open orders), RS4 (mirror open orders).
3. RS2: Mirrors metadata directly from Trade.Mirror WHERE CID=@CID.
4. RS5: Close orders joined PositionTbl to resolve InstrumentID.
5. RS6: Redeem positions (RedeemStatus>0) from @UserPositions.
6. `@GranularAggregates` and `@InstrumentAggregates` computed from @UserPositions via INSERT+GROUP BY.
7. RS7: Manual portfolio (MirrorID=0) - InstrumentAggregates JOIN GranularAggregates JOIN Trade.Instrument + Trade.InstrumentMetaData.
8. RS8: Mirror portfolio (MirrorID>0) - same join pattern but filtered to MirrorID > 0.

**Confluence Source:** "HLD - Portfolio Breakdowns" (TRAD space, page 13817511999, last modified 2026-02-05) - full API specification including lite/full detail levels, filtering semantics, and response models.

---

## 2. Business Logic

### 2.1 Dynamic SQL for Filter-Conditional Queries

**What:** Dynamic SQL is used for both @AllOpenOrders and @UserPositions population to avoid the `(@Flag = 0 OR EXISTS(...))` anti-pattern which forces SQL Server to choose a non-optimal plan. When no filters are provided, the WHERE clause is clean; when filters are provided, AND EXISTS is appended.

**Columns/Parameters Involved:** `@HasInstrumentFilter`, `@HasMirrorFilter`, `@InstrumentIDs`, `@MirrorIDs`

**Rules:**
- `@HasInstrumentFilter = CASE WHEN EXISTS (SELECT 1 FROM @InstrumentIDs) THEN 1 ELSE 0 END`
- `@HasMirrorFilter = CASE WHEN EXISTS (SELECT 1 FROM @MirrorIDs) THEN 1 ELSE 0 END`
- When @HasInstrumentFilter=1: `AND EXISTS (SELECT 1 FROM @InstrumentIDs IDs WHERE IDs.ID = InstrumentID)` appended
- When @HasMirrorFilter=1: `AND EXISTS (SELECT 1 FROM @MirrorIDs MDs WHERE MDs.ID = ISNULL(MirrorID, 0))` appended
- MirrorID=0 in @MirrorIDs = "include manual positions" (where MirrorID IS NULL OR MirrorID=0)
- sp_executesql used for safe parameterized execution

### 2.2 AllOpenOrders - Three Sources UNION ALL

**What:** Builds the open order summary from three tables into a memory-optimized table variable.

**Columns/Parameters Involved:** `OrderID`, `Amount`, `MirrorID`, `InstrumentID`

**Rules:**
- Source 1: `Trade.Orders` - pending entry orders; MirrorID=NULL (manual pending orders)
- Source 2: `Trade.OrderForOpen` WHERE `Dictionary.OrderForExecutionStatus.IsTerminal = 0` - open-for-execution orders not yet terminal; Amount = ISNULL(FrozenAmount, Amount)
- Source 3: `Trade.DelayedOrderForOpen` WHERE StatusID=1 - delayed open orders waiting for trigger

### 2.3 FrozenCash Calculation

**What:** Sum of all open order amounts = funds committed to pending opens (unavailable for trading).

**Rules:**
- `@FrozenCash = ISNULL(SUM(Amount), 0) FROM @AllOpenOrders`
- Included in RS1 alongside Credit and BonusCredit

### 2.4 Granular Aggregates Computation

**What:** Positions are grouped by (MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion) to produce position sub-groups within each instrument. These "PositionAggregates" are the full-detail granular breakdowns in the API response.

**Columns/Parameters Involved:** `TotalUnits`, `WeightedRateSum`, `InitialExposure`, `NetUnits`, `NetLots`, `TotalLeverages`

**Rules:**
- `WeightedRateSum = SUM(InitForexRate * Units)` - for avgOpenRate: WeightedRateSum / TotalUnits
- `InitialExposure = SUM(Units * InitForexRate * InitConversionRate)` - for avgConversionRate
- `TotalLeverages = SUM(Leverage * CASE WHEN AmountFormula=1 THEN LotCount ELSE Units END)` - AmountFormula=1=FixPerLot pricing model
- `NetUnits = SUM(CASE WHEN IsBuy=1 THEN Units ELSE -Units END)` - positive for net long, negative for net short
- Inserted into @GranularAggregates (Trade.GranularAggregatesTableType_MOT)

### 2.5 Instrument-Level Aggregates

**What:** Second aggregation: sums all granular groups within (MirrorID, InstrumentID) to produce instrument totals.

**Rules:**
- Groups @GranularAggregates by MirrorID, InstrumentID
- Net values (NetUnits, NetLots, etc.) sum across Buy/Sell groups to give true directional exposure
- Inserted into @InstrumentAggregates (Trade.InstrumentAggregatesTableType_MOT)

### 2.6 Close Orders Assembly (RS5)

**What:** Returns pending close orders (OrderForClose non-terminal + DelayedOrderForClose active) with resolved InstrumentID for per-instrument grouping.

**Rules:**
- OrderForClose: `IsTerminal=0 AND NOT EXISTS executed (PositionID IS NULL in anti-join)`
- DelayedOrderForClose: `StatusID=1`
- Joined to Trade.PositionTbl WHERE StatusID=1 AND PartitionCol=PositionID%50 to resolve InstrumentID
- Returns DISTINCT (InstrumentID, OrderID)

### 2.7 Mirror PendingForClosure Derivation

**What:** IsActive=0 means the mirror is pending closure (stop copy was requested but not yet finalized).

**Rules:**
- `PendingForClosure = CASE WHEN IsActive=1 THEN 0 ELSE 1 END`
- IsActive=1 = mirror running normally
- IsActive=0 = stop-copy in progress, pending finalization

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. All result sets are filtered to this customer. |
| 2 | @InstrumentIDs | dbo.IdIntList | YES | empty | CODE-BACKED | Optional instrument filter. Empty = all instruments. Applied dynamically to avoid OR EXISTS anti-pattern. |
| 3 | @MirrorIDs | dbo.IdIntList | YES | empty | CODE-BACKED | Optional mirror filter. Empty = all mirrors. 0 = include manual positions. Applied dynamically. |

**Output - Result Set 1 (Account Info + FrozenCash):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | Credit | MONEY | YES | - | CODE-BACKED | Account cash balance from Customer.Customer.Credit. |
| 5 | BonusCredit | MONEY | YES | - | CODE-BACKED | Bonus balance from Customer.Customer.BonusCredit. ISNULL=0 applied. |
| 6 | AccountCurrencyId | INT | NO | - | CODE-BACKED | Account denomination currency ID from Customer.Customer.CurrencyID. |
| 7 | FrozenCash | DECIMAL(18,2) | NO | 0 | CODE-BACKED | Sum of all pending open order amounts. Represents unavailable funds committed to open orders. |

**Output - Result Set 2 (Mirrors Metadata):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | MirrorID | INT | NO | - | CODE-BACKED | Copy relationship ID. |
| 9 | AvailableAmountCash | MONEY | YES | - | CODE-BACKED | Trade.Mirror.Amount - current available allocation cash. |
| 10 | ClosedPositionsNetProfit | MONEY | YES | - | CODE-BACKED | Trade.Mirror.NetProfit - cumulative net profit from closed copy positions. ISNULL=0. |
| 11 | InitialAmountInvestment | MONEY | YES | - | CODE-BACKED | Trade.Mirror.InitialInvestment - initial copy allocation amount. |
| 12 | DepositSummary | MONEY | YES | - | CODE-BACKED | Trade.Mirror.DepositSummary - total deposits into the copy. |
| 13 | WithdrawalSummary | MONEY | YES | - | CODE-BACKED | Trade.Mirror.WithdrawalSummary - total withdrawals from the copy. |
| 14 | PendingForClosure | BIT | NO | - | CODE-BACKED | Derived: 1 if IsActive=0 (stop-copy requested, finalization pending). |
| 15 | MirrorCalculationType | INT | YES | - | CODE-BACKED | Copy calculation method (proportional/fixed). |
| 16 | ParentCID | INT | NO | - | CODE-BACKED | Leader's customer ID. |
| 17 | ParentUserName | NVARCHAR | YES | - | CODE-BACKED | Leader's username. |
| 18 | StopLossPercentage | DECIMAL | YES | - | CODE-BACKED | Copy-level stop loss as percentage of allocation. |
| 19 | StopLossAmount | MONEY | YES | - | CODE-BACKED | Copy-level stop loss as dollar amount. |
| 20 | StartedCopyDate | DATETIME | YES | - | CODE-BACKED | When the copy started (Trade.Mirror.Occurred). |
| 21 | MirrorStatusID | INT | YES | - | CODE-BACKED | Mirror status ID from Trade.Mirror. |

**Output - Result Set 3 (Manual Open Orders):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 22 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument for grouping. |
| 23 | OrderID | BIGINT | NO | - | CODE-BACKED | Open order ID. DISTINCT applied. |
| 24 | Amount | MONEY | YES | - | CODE-BACKED | Frozen amount for this order. |

**Output - Result Set 4 (Mirror Open Orders):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 25 | MirrorID | INT | YES | - | CODE-BACKED | Mirror ID (>0). |
| 26 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument for grouping. |
| 27 | OrderID | BIGINT | NO | - | CODE-BACKED | Open order ID. DISTINCT applied. |
| 28 | Amount | MONEY | YES | - | CODE-BACKED | Frozen amount for this order. |

**Output - Result Set 5 (Close Orders by InstrumentID):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 29 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument resolved via Trade.PositionTbl join. |
| 30 | OrderID | BIGINT | NO | - | CODE-BACKED | Close order ID (from OrderForClose or DelayedOrderForClose). DISTINCT applied. |

**Output - Result Set 6 (Redeem Positions):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 31 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of position in redeem. |
| 32 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID where RedeemStatus > 0. DISTINCT applied. |

**Output - Result Sets 7 & 8 (Manual and Mirror Portfolio - same columns):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 33 | MirrorID | INT | - | - | CODE-BACKED | Present in RS8 only. 0 = manual (RS7 does not include MirrorID column). |
| 34 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID. |
| 35 | InstrumentTypeId | INT | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. |
| 36 | AssetCurrencyId | INT | YES | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID. The asset's denomination currency. |
| 37 | InstrumentTotalUnits | DECIMAL | YES | - | CODE-BACKED | Sum of units across all positions for this instrument. |
| 38 | InstrumentTotalAmount | MONEY | YES | - | CODE-BACKED | Sum of invested amounts. |
| 39 | InstrumentTotalFees | MONEY | YES | - | CODE-BACKED | Sum of fees (OpenTotalFees). |
| 40 | InstrumentTotalTaxes | MONEY | YES | - | CODE-BACKED | Sum of taxes (OpenTotalTaxes). |
| 41 | InstrumentTotalLots | DECIMAL | YES | - | CODE-BACKED | Sum of contracts/lots (LotCountDecimal). |
| 42 | InstrumentTotalLeverages | DECIMAL | YES | - | CODE-BACKED | Sum of (Leverage * Units or LotCount based on AmountFormula). Used for avgLeverage = TotalLeverages/TotalUnits. |
| 43 | InstrumentFirstOpenDate | DATETIME | YES | - | CODE-BACKED | Earliest position open date for this instrument. |
| 44 | InstrumentLastOpenDate | DATETIME | YES | - | CODE-BACKED | Most recent position open date for this instrument. |
| 45 | InstrumentNetUnits | DECIMAL | YES | - | CODE-BACKED | Directional units: +long, -short. True net exposure. |
| 46 | InstrumentNetLots | DECIMAL | YES | - | CODE-BACKED | Directional lots. |
| 47 | InstrumentNetOpenRateSum | DECIMAL | YES | - | CODE-BACKED | Directional sum of (OpenRate * Units). Used for avg net open rate. |
| 48 | InstrumentNetInitExposure | DECIMAL | YES | - | CODE-BACKED | Directional sum of (Units * OpenRate * ConversionRate). |
| 49 | IsBuy | BIT | NO | - | CODE-BACKED | Granular group direction (from GranularAggregates). |
| 50 | IsSettled | BIT | YES | - | CODE-BACKED | Granular group settlement type. |
| 51 | PnLVersion | INT | YES | - | CODE-BACKED | PnL calculation version for this group. Determines which equity calculation logic to use. |
| 52 | TotalUnits | DECIMAL | YES | - | CODE-BACKED | Granular group total units. |
| 53 | WeightedRateSum | DECIMAL | YES | - | CODE-BACKED | SUM(OpenRate * Units) for this granular group. Application divides by TotalUnits to get avgOpenRate. |
| 54 | InitialExposure | DECIMAL | YES | - | CODE-BACKED | SUM(Units * OpenRate * ConversionRate) for this granular group. |
| 55 | TotalAmount | MONEY | YES | - | CODE-BACKED | Granular group total invested. |
| 56 | TotalFees | MONEY | YES | - | CODE-BACKED | Granular group fees. |
| 57 | TotalTaxes | MONEY | YES | - | CODE-BACKED | Granular group taxes. |
| 58 | TotalLots | DECIMAL | YES | - | CODE-BACKED | Granular group lots. |
| 59 | TotalLeverages | DECIMAL | YES | - | CODE-BACKED | Granular group leverage sum. |
| 60 | FirstOpenDate | DATETIME | YES | - | CODE-BACKED | Earliest open in this granular group. |
| 61 | LastOpenDate | DATETIME | YES | - | CODE-BACKED | Most recent open in this granular group. |
| 62 | NetUnits | DECIMAL | YES | - | CODE-BACKED | Granular group net units (+buy, -sell). |
| 63 | NetLots | DECIMAL | YES | - | CODE-BACKED | Granular group net lots. |
| 64 | NetOpenRateSum | DECIMAL | YES | - | CODE-BACKED | Granular group directional rate sum. |
| 65 | NetInitExposure | DECIMAL | YES | - | CODE-BACKED | Granular group directional initial exposure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Lookup | Account credit, bonus, currency (RS1) |
| @CID | Trade.Mirror | Lookup | All mirrors for the customer (RS2) |
| @CID | Trade.Orders | Lookup | Manual pending entry orders (RS3) |
| @CID | Trade.OrderForOpen | Lookup | Non-terminal open-for-execution orders (RS3/RS4) |
| @CID | Trade.DelayedOrderForOpen | Lookup | Delayed open orders (RS3/RS4) |
| MirrorID=0 | Dictionary.OrderForExecutionStatus | Lookup | IsTerminal flag for RS3/RS4 filter |
| @CID | Trade.OrderForClose | Lookup | Non-terminal close orders (RS5) |
| @CID | Trade.DelayedOrderForClose | Lookup | Delayed close orders (RS5) |
| PositionID | Trade.CloseExecutionPlan | Anti-join | Excludes already-executed close orders from RS5 |
| PositionID | Trade.PositionTbl | Lookup | InstrumentID resolution for RS5; position list for @UserPositions |
| InstrumentID | Trade.ProviderToInstrument | Lookup | AmountFormula for leverage calculation |
| InstrumentID | Trade.Instrument | Lookup | SellCurrencyID for AssetCurrencyId (RS7/RS8) |
| InstrumentID | Trade.InstrumentMetaData | Lookup | InstrumentTypeID (RS7/RS8) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the Portfolio Breakdowns API endpoints (TAPI and Admin TAPI).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPortfolioAggregates (procedure)
|- Customer.Customer (table) - account balance
|- Trade.Mirror (table) - copy relationships
|- Trade.Orders (table) - pending entry orders
|- Trade.OrderForOpen (table) - open execution orders
|- Trade.DelayedOrderForOpen (table) - delayed open orders
|- Dictionary.OrderForExecutionStatus (table) - terminal status filter
|- Trade.OrderForClose (table) - close execution orders
|- Trade.DelayedOrderForClose (table) - delayed close orders
|- Trade.CloseExecutionPlan (table) - executed close anti-join
|- Trade.PositionTbl (table) - open positions
|- Trade.ProviderToInstrument (table) - AmountFormula
|- Trade.Instrument (table) - SellCurrencyID
|- Trade.InstrumentMetaData (table) - InstrumentTypeID
|- Trade.AllOpenOrdersTableType_MOT (UDT) - memory-optimized TVP
|- Trade.UserPositionsTableType_MOT (UDT) - memory-optimized TVP
|- Trade.GranularAggregatesTableType_MOT (UDT) - memory-optimized TVP
|- dbo.IdIntList (UDT) - input filter TVP
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Credit, BonusCredit, CurrencyID for RS1 |
| Trade.Mirror | Table | All mirrors for the customer (RS2) |
| Trade.Orders | Table | Manual pending entry orders |
| Trade.OrderForOpen | Table | Non-terminal open execution orders |
| Trade.DelayedOrderForOpen | Table | Delayed open orders (StatusID=1) |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal flag for order filtering |
| Trade.OrderForClose | Table | Non-terminal close orders for RS5 |
| Trade.DelayedOrderForClose | Table | Delayed close orders (StatusID=1) for RS5 |
| Trade.CloseExecutionPlan | Table | Anti-join to exclude already-executed close orders |
| Trade.PositionTbl | Table | Open positions (StatusID=1); InstrumentID for RS5 |
| Trade.ProviderToInstrument | Table | AmountFormula (0=unit-based, 1=FixPerLot) |
| Trade.Instrument | Table | SellCurrencyID (AssetCurrencyId) |
| Trade.InstrumentMetaData | Table | InstrumentTypeID |
| Trade.AllOpenOrdersTableType_MOT | User Defined Type | Memory-optimized table variable for open orders |
| Trade.UserPositionsTableType_MOT | User Defined Type | Memory-optimized table variable for positions |
| Trade.GranularAggregatesTableType_MOT | User Defined Type | Memory-optimized table variable for granular aggregates |
| Trade.InstrumentAggregatesTableType_MOT | User Defined Type | Memory-optimized table variable for instrument aggregates |
| dbo.IdIntList | User Defined Type | Input filter TVP for InstrumentIDs and MirrorIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by Portfolio Breakdowns API service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (memory-optimized table variable types have indexes defined in their type definitions).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Architecture | Conditional WHERE avoids OR EXISTS anti-pattern; better plan selection |
| Memory-optimized table variables | Performance | In-memory intermediate storage (AllOpenOrders, UserPositions, Granular/InstrumentAggregates) |
| sp_executesql | Safety | Parameterized dynamic SQL avoids injection; TVPs passed by reference |
| PositionTbl PartitionCol = PositionID%50 | Partition routing | Modulo-50 sharding for RealOpenPositions |
| IsTerminal = 0 | Filter | Excludes terminal (completed/cancelled/rejected) orders |
| RedeemStatus > 0 | Filter | RS6 only returns positions in redeem process |
| NOLOCK on all tables | Performance | Dirty read acceptable for portfolio snapshot |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get full portfolio for a customer (no filters)

```sql
DECLARE @instruments dbo.IdIntList
DECLARE @mirrors dbo.IdIntList
EXEC Trade.GetPortfolioAggregates
    @CID = 7234263,
    @InstrumentIDs = @instruments,
    @MirrorIDs = @mirrors
-- Returns 8 result sets
```

### 8.2 Filter to specific instrument

```sql
DECLARE @instruments dbo.IdIntList
INSERT @instruments VALUES (1001)  -- AAPL
DECLARE @mirrors dbo.IdIntList
EXEC Trade.GetPortfolioAggregates
    @CID = 7234263,
    @InstrumentIDs = @instruments,
    @MirrorIDs = @mirrors
```

### 8.3 Manual positions only (MirrorID=0 filter)

```sql
DECLARE @instruments dbo.IdIntList
DECLARE @mirrors dbo.IdIntList
INSERT @mirrors VALUES (0)  -- 0 = manual positions
EXEC Trade.GetPortfolioAggregates
    @CID = 7234263,
    @InstrumentIDs = @instruments,
    @MirrorIDs = @mirrors
```

---

## 9. Atlassian Knowledge Sources

**Confluence: "HLD - Portfolio Breakdowns"** (TRAD space, page ID 13817511999, last modified 2026-02-05)
- This document is the HLD for the Portfolio Breakdown API endpoints that consume this SP.
- Key insights: lite/full detail level support; GET /portfolios/instrument-aggregates, /positions, /account-totals, /instrument-ids endpoints; both TAPI (external) and Admin TAPI (internal) surfaces; 20 req/min rate limit; mirrorId=0 represents manual positions.
- The 8 result sets from this SP map directly to the API response structure: RS1=account totals, RS2=mirror metadata, RS3/RS4=open orders (for FrozenCash and openOrders arrays), RS5=close orders, RS6=redeemPositionIds, RS7/RS8=instrument aggregates + granular position aggregates.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 65 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPortfolioAggregates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPortfolioAggregates.sql*
