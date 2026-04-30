# Trade.GetPositionsByFilters

> Returns open position details for a customer with optional mirror, instrument, and position ID filtering using dynamic SQL to avoid OR EXISTS anti-patterns - the individual position data layer for the Portfolio API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + optional @MirrorIDs/@InstrumentIDs/@PositionIDs filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionsByFilters` returns per-position data for all open positions of a customer with optional filtering by MirrorID, InstrumentID, and/or specific PositionIDs. It provides all fields needed by the Portfolio API position endpoint (GET /portfolios/positions), including tree-level SL/TP/TSL from PositionTreeInfo, instrument symbol, and account currency.

**WHY:** The Portfolio API's positions endpoint supports multiple filter combinations (all positions, by mirror, by instrument, by specific IDs). The SP uses dynamic SQL to avoid the `OR EXISTS` anti-pattern so SQL Server generates efficient plans for each filter combination.

**HOW:** Same dynamic SQL pattern as GetPortfolioAggregates. Three optional filters each append `AND IN (SELECT ID FROM @TVP)` conditions. If @HasPositionFilter=1, an INNER JOIN to @PositionIDs with partition routing is added. Base query uses PositionTbl with PositionTreeInfo for SL/TP, Instrument for SellCurrencyID, InstrumentMetaData for Symbol, Customer.Customer for AccountCurrencyID.

---

## 2. Business Logic

### 2.1 Dynamic SQL for Filter Combinations

**What:** Three optional filter flags control what WHERE conditions are generated.

**Columns/Parameters Involved:** `@HasMirrorFilter`, `@HasInstrumentFilter`, `@HasPositionFilter`

**Rules:**
- If @HasPositionFilter=1: INNER JOIN @PositionIDs with partition routing (AND p.PartitionCol = pf.PositionID%50)
- If @HasMirrorFilter=1: `AND p.MirrorID IN (SELECT ID FROM @MirrorIDs)`
- If @HasInstrumentFilter=1: `AND p.InstrumentID IN (SELECT ID FROM @InstrumentIDs)`
- Base filter always: `WHERE p.CID = @CID AND p.StatusID = 1`

### 2.2 Tree-Level SL/TP/TSL from PositionTreeInfo

**What:** Stop loss, take profit, and TSL flag are resolved from Trade.PositionTreeInfo (tree-level settings that apply to the whole copy sub-tree).

**Rules:**
- `INNER JOIN Trade.PositionTreeInfo pti ON p.TreeID = pti.TreeID AND ABS(p.TreeID%50) = pti.PartitionCol`
- `pti.StopRate AS StopLoss` - tree-level SL
- `pti.LimitRate AS TakeProfit` - tree-level TP
- `pti.IsTslEnabled` - trailing SL enabled flag

### 2.3 SettlementTypeID with Backward Compatibility

**What:** SettlementTypeID may be NULL for older positions; falls back to IsSettled cast.

**Rules:**
- `ISNULL(p.SettlementTypeID, CAST(p.IsSettled AS TINYINT)) AS SettlementTypeID`
- IsSettled=1 -> SettlementTypeID=1 (real stock) as fallback for legacy rows

### 2.4 InitialUnits / InitialLotCount Fallback

**What:** InitialUnits/InitialLotCount may be NULL for positions opened before these columns were added.

**Rules:**
- `ISNULL(p.InitialUnits, ABS(p.AmountInUnitsDecimal)) AS InitialUnits`
- `ISNULL(p.InitialLotCount, ABS(p.LotCountDecimal)) AS InitialLotCount`
- ABS applied because these may be negative for short positions in older data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 2 | @MirrorIDs | dbo.IdIntList | YES | empty | CODE-BACKED | Optional mirror filter. Empty=all. |
| 3 | @InstrumentIDs | dbo.IdIntList | YES | empty | CODE-BACKED | Optional instrument filter. Empty=all. |
| 4 | @PositionIDs | Trade.PositionIDsTbl | YES | empty | CODE-BACKED | Optional specific position IDs filter. If provided, adds partition-routing INNER JOIN. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID. |
| 6 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 7 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument. |
| 8 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. NULL for manual. |
| 9 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Long, 0=Short. |
| 10 | Amount | MONEY | YES | - | CODE-BACKED | Current position amount. |
| 11 | Units | DECIMAL | YES | - | CODE-BACKED | ABS(AmountInUnitsDecimal) - always positive. |
| 12 | LotCount | DECIMAL | YES | - | CODE-BACKED | ABS(LotCountDecimal) - always positive. |
| 13 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier. |
| 14 | OpenRate | DECIMAL | YES | - | CODE-BACKED | InitForexRate alias. |
| 15 | ConversionRate | DECIMAL | YES | - | CODE-BACKED | InitConversionRate alias. |
| 16 | OpenDateTime | DATETIME | YES | - | CODE-BACKED | InitDateTime alias. |
| 17 | TotalFees | MONEY | YES | - | CODE-BACKED | OpenTotalFees. |
| 18 | TotalTaxes | MONEY | YES | - | CODE-BACKED | OpenTotalTaxes. |
| 19 | StopLoss | DECIMAL | YES | - | CODE-BACKED | Tree-level stop loss rate from Trade.PositionTreeInfo. |
| 20 | TakeProfit | DECIMAL | YES | - | CODE-BACKED | Tree-level take profit rate from Trade.PositionTreeInfo. |
| 21 | IsTslEnabled | BIT | YES | - | CODE-BACKED | Trailing stop loss flag from Trade.PositionTreeInfo. |
| 22 | IsSettled | BIT | YES | - | CODE-BACKED | Real stock (1) or CFD (0). |
| 23 | PnLVersion | INT | YES | - | CODE-BACKED | PnL calculation version. |
| 24 | OrderID | BIGINT | NO | 0 | CODE-BACKED | ISNULL(OrderID, 0). Opening order ID. |
| 25 | OrderType | INT | NO | 0 | CODE-BACKED | ISNULL(OrderType, 0). Order type ID. |
| 26 | InitialAmount | DECIMAL | YES | - | CODE-BACKED | InitialAmountCents / 100.0. Original invested amount in dollars. |
| 27 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | ISNULL(InitialUnits, ABS(AmountInUnitsDecimal)). Units at open. |
| 28 | InitialLotCount | DECIMAL | YES | - | CODE-BACKED | ISNULL(InitialLotCount, ABS(LotCountDecimal)). Lots at open. |
| 29 | SettlementTypeID | INT | YES | - | CODE-BACKED | ISNULL(SettlementTypeID, CAST(IsSettled AS TINYINT)). |
| 30 | OpenPositionActionType | INT | YES | - | CODE-BACKED | OpenActionType - how position was opened (manual, copy, etc.). |
| 31 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Instrument trading symbol from Trade.InstrumentMetaData. |
| 32 | SellCurrencyID | INT | YES | - | CODE-BACKED | Asset denomination currency from Trade.Instrument. |
| 33 | EndOfWeekFee | MONEY | NO | 0 | CODE-BACKED | ISNULL(EndOfWeekFee, 0). |
| 34 | AccountCurrencyID | INT | NO | 1 | CODE-BACKED | ISNULL(c.CurrencyID, 1) - account currency (defaults to USD=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionTbl | Lookup | Open positions (StatusID=1) |
| TreeID | Trade.PositionTreeInfo | Lookup | Tree-level StopLoss, TakeProfit, IsTslEnabled |
| InstrumentID | Trade.Instrument | Lookup | SellCurrencyID |
| InstrumentID | Trade.InstrumentMetaData | Lookup | Symbol |
| CID | Customer.Customer | LEFT JOIN | AccountCurrencyID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by Portfolio API positions endpoint.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsByFilters (procedure)
|- Trade.PositionTbl (table) - open positions
|- Trade.PositionTreeInfo (table) - tree-level SL/TP/TSL
|- Trade.Instrument (table) - asset currency
|- Trade.InstrumentMetaData (table) - symbol
|- Customer.Customer (table) - account currency
|- dbo.IdIntList (UDT) - mirror and instrument filter TVPs
|- Trade.PositionIDsTbl (UDT) - position ID filter TVP
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by Portfolio API positions endpoint |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Architecture | Avoids OR EXISTS anti-pattern for filter combinations |
| StatusID=1 | Filter | Open positions only |
| ABS on units/lots | Normalization | Always positive regardless of direction |
| PartitionCol = PositionID%50 (position filter) | Partition routing | Used when @PositionIDs filter is active |
| ABS(TreeID%50) for PositionTreeInfo | Partition routing | Handles negative TreeIDs |
| sp_executesql | Safety | Parameterized dynamic SQL |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 All open positions for a customer

```sql
DECLARE @mirrors dbo.IdIntList
DECLARE @instruments dbo.IdIntList
DECLARE @positions Trade.PositionIDsTbl
EXEC Trade.GetPositionsByFilters
    @CID = 7234263,
    @MirrorIDs = @mirrors,
    @InstrumentIDs = @instruments,
    @PositionIDs = @positions
```

### 8.2 Filter to specific positions

```sql
DECLARE @mirrors dbo.IdIntList
DECLARE @instruments dbo.IdIntList
DECLARE @positions Trade.PositionIDsTbl
INSERT @positions VALUES (987654321), (987654322)
EXEC Trade.GetPositionsByFilters
    @CID = 7234263,
    @MirrorIDs = @mirrors,
    @InstrumentIDs = @instruments,
    @PositionIDs = @positions
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related API documented in Confluence "HLD - Portfolio Breakdowns" (TRAD space, page 13817511999).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsByFilters | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsByFilters.sql*
