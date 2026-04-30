# Trade.GetGuruOpenPositionsWithCustomerData

> Returns all copyable open positions for a guru/leader along with the customer's RealizedEquity in a two-result-set call.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (primary result set), CID (parameter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves two pieces of information for a given CID in a single database call: (1) all of the customer's open guru/leader positions that are currently eligible for copy-trading, and (2) the customer's RealizedEquity from Customer.Customer. Together these enable the CopyTrader system to evaluate the leader's portfolio state and equity for new copier onboarding.

The procedure wraps Trade.GetGuruOpenPositions (a view that filters out positions mid-close, mid-redeem, or in terminal execution states) and supplements it with RealizedEquity. It also applies ISNULL fallbacks on several operational rate columns (LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID) to ensure non-null defaults for positions that may not have had a post-open rate update yet.

Data flow: caller passes @CID. Result set 1 returns all columns from Trade.GetGuruOpenPositions for that CID (with ISNULL wrappers on four columns). Result set 2 returns RealizedEquity from Customer.Customer. A synonym `dbo.RealGetGuruOpenPositionsWithCustomerData` exists for cross-database access.

---

## 2. Business Logic

### 2.1 ISNULL Fallbacks on Operational Rate Columns

**What**: Ensures rate-related columns never return NULL, providing safe defaults for downstream calculations.

**Columns/Parameters Involved**: `LastOpPriceRate`, `LastOpPriceRateID`, `LastOpConversionRate`, `LastOpConversionRateID`

**Rules**:
- `LastOpPriceRate` defaults to 0 when NULL (no post-open price update yet)
- `LastOpPriceRateID` defaults to 0 when NULL
- `LastOpConversionRate` defaults to 1 when NULL (identity conversion rate - no currency conversion needed). Changed from previous logic per Elad's fix (2021-10-10)
- `LastOpConversionRateID` defaults to 0 when NULL

**Diagram**:
```
Result Set 1: Trade.GetGuruOpenPositions WHERE CID = @CID
  + ISNULL wrappers on 4 rate columns

Result Set 2: Customer.Customer.RealizedEquity WHERE CID = @CID
```

### 2.2 Two Result Sets

**What**: Returns position data and customer equity as separate result sets in a single call.

**Columns/Parameters Involved**: `@CID`, all position columns, `RealizedEquity`

**Rules**:
- Result set 1: copyable open positions from Trade.GetGuruOpenPositions
- Result set 2: single-value RealizedEquity from Customer.Customer
- Both filtered by the same @CID for consistency

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID of the guru/leader whose copyable positions and equity are requested. |

### Result Set 1 - Guru Open Positions

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner (same as @CID). |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. PK of Trade.PositionTbl. |
| 4 | ForexResultID | INT | - | - | CODE-BACKED | Forex result identifier linked to this position. |
| 5 | Currency | VARCHAR | - | - | CODE-BACKED | Currency code of the position. |
| 6 | ProviderID | INT | - | - | CODE-BACKED | Provider (broker/liquidity source) for this instrument. |
| 7 | InstrumentID | INT | - | - | CODE-BACKED | Financial instrument being traded. FK to Trade.Instrument. |
| 8 | PositionHedgeServerID | INT | - | - | CODE-BACKED | Hedge server that executed this position. FK to Trade.HedgeServer. |
| 9 | Leverage | INT | - | - | CODE-BACKED | Leverage multiplier for the position. 1 = no leverage (real stocks). |
| 10 | ForexBuy | DECIMAL | - | - | CODE-BACKED | Buy (ask) forex rate at position context. |
| 11 | ForexSell | DECIMAL | - | - | CODE-BACKED | Sell (bid) forex rate at position context. |
| 12 | InitForexRate | DECIMAL | - | - | CODE-BACKED | Initial forex conversion rate at position open. |
| 13 | EndForexRate | DECIMAL | - | - | CODE-BACKED | End forex conversion rate (populated on close). |
| 14 | InitDateTime | DATETIME | - | - | CODE-BACKED | Timestamp when the position was opened. |
| 15 | NetProfit | DECIMAL | - | - | CODE-BACKED | Net profit/loss of the position in account currency. |
| 16 | StopRate | DECIMAL | - | - | CODE-BACKED | Stop-loss rate. NULL if no SL set. |
| 17 | LimitRate | DECIMAL | - | - | CODE-BACKED | Take-profit rate. NULL if no TP set. |
| 18 | Amount | DECIMAL | - | - | CODE-BACKED | Position amount in account currency (cents). |
| 19 | AmountInUnitsDecimal | DECIMAL | - | - | CODE-BACKED | Position amount expressed in instrument units. |
| 20 | Commission | DECIMAL | - | - | CODE-BACKED | Commission charged for this position. |
| 21 | IsBuy | BIT | - | - | CODE-BACKED | Direction: 1 = Buy/Long, 0 = Sell/Short. |
| 22 | Units | INT | - | - | CODE-BACKED | Number of lots/units in this position. |
| 23 | LotCountDecimal | DECIMAL | - | - | CODE-BACKED | Decimal lot count for fractional share positions. |
| 24 | UnitMargin | DECIMAL | - | - | CODE-BACKED | Margin per unit for this position. |
| 25 | AdditionalParam | VARCHAR | - | - | CODE-BACKED | Extended parameters stored as key-value pairs. |
| 26 | OrderID | BIGINT | - | - | CODE-BACKED | Associated order ID. |
| 27 | TradeRange | DECIMAL | - | - | CODE-BACKED | Trade range (market range) tolerance for this position. |
| 28 | InitForexPriceRateID | INT | - | - | CODE-BACKED | Rate ID for the initial forex price. |
| 29 | ParentPositionID | BIGINT | - | - | CODE-BACKED | Parent position ID in copy-trade hierarchy. 0 = original (leader) position. |
| 30 | LastOpPriceRate | DECIMAL | NO | 0 | CODE-BACKED | Last operational price rate. ISNULL wrapped to 0 when no post-open update exists. |
| 31 | LastOpPriceRateID | INT | NO | 0 | CODE-BACKED | Rate ID for last operational price. ISNULL wrapped to 0. |
| 32 | LastOpConversionRate | DECIMAL | NO | 1 | CODE-BACKED | Last operational conversion rate. ISNULL wrapped to 1 (identity rate). |
| 33 | LastOpConversionRateID | INT | NO | 0 | CODE-BACKED | Rate ID for last operational conversion. ISNULL wrapped to 0. |
| 34 | InstrumentPrecision | INT | - | - | CODE-BACKED | Decimal precision for this instrument's rates. |
| 35 | MirrorID | BIGINT | - | - | CODE-BACKED | Mirror/copy relationship ID. 0 = not a copy position. |
| 36 | PositionRatio | DECIMAL | - | - | CODE-BACKED | Copy ratio relative to the leader position. |
| 37 | DirectAggLotCount | DECIMAL | - | - | CODE-BACKED | Direct aggregated lot count. |
| 38 | InitialAmountCents | BIGINT | - | - | CODE-BACKED | Initial investment amount in cents. |
| 39 | RootHedgeServerID | INT | - | - | CODE-BACKED | Hedge server at the root of the copy tree. |
| 40 | TreeID | INT | - | - | CODE-BACKED | Copy-trade tree identifier. Groups leader + all copier positions. |
| 41 | IsTslEnabled | BIT | - | - | CODE-BACKED | Whether Trailing Stop Loss is active on this position. |
| 42 | UnitsBaseValueCents | BIGINT | - | - | CODE-BACKED | Base value of units in cents. |
| 43 | IsSettled | BIT | - | - | CODE-BACKED | Legacy settlement flag: 1 = real stock position, 0 = CFD. Predates SettlementTypeID. |
| 44 | SettlementTypeID | TINYINT | - | - | CODE-BACKED | Settlement classification: 0=CFD, 1=Real, 2=TRS, 5=MarginTrade. See [Settlement Type](../../_glossary.md#settlement-type). |
| 45 | IsRootSettled | BIT | - | - | CODE-BACKED | Whether the root position in the copy tree is a real stock position. |
| 46 | IsOpened | BIT | - | - | CODE-BACKED | Whether the position has fully completed the open execution flow. |
| 47 | IsDiscounted | BIT | - | - | CODE-BACKED | Whether the position has a discounted fee/spread. |
| 48 | RootSettlementTypeID | TINYINT | - | - | CODE-BACKED | Settlement type of the root position in the copy tree. |

### Result Set 2 - Customer Equity

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 49 | RealizedEquity | DECIMAL | - | - | CODE-BACKED | Customer's realized equity from Customer.Customer. Represents the cash value of the account after realized gains/losses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetGuruOpenPositions | FROM (view) | Source of copyable guru open positions with exclusion filters |
| @CID | Customer.Customer | FROM (WHERE) | Source of RealizedEquity for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RealGetGuruOpenPositionsWithCustomerData | SYNONYM | Alias | Cross-database synonym for this procedure |
| LinkedSrvRO | GRANT EXECUTE | Permission | Read-only linked server access |
| LinkedSrvRO_WE_DB | GRANT EXECUTE | Permission | WE database linked server read-only access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetGuruOpenPositionsWithCustomerData (procedure)
+-- Trade.GetGuruOpenPositions (view)
|     +-- Trade.GetOpenPositionDataForGuro (view)
|     +-- Trade.OrdersExit (table)
|     +-- Trade.DelayedOrderForClose (table)
|     +-- Trade.CloseExecutionPlan (table)
|     +-- Trade.OrderForClose (table)
|     +-- Dictionary.OrderForExecutionStatus (table)
+-- Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetGuruOpenPositions | View | FROM - source of all copyable guru open positions |
| Customer.Customer | Table | FROM - source of RealizedEquity |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealGetGuruOpenPositionsWithCustomerData | Synonym | Points to this procedure for cross-database access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a leader

```sql
EXEC Trade.GetGuruOpenPositionsWithCustomerData @CID = 12345;
```

### 8.2 Query the underlying view directly

```sql
SELECT  *
FROM    Trade.GetGuruOpenPositions WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.3 Combined position and equity query

```sql
SELECT  gop.PositionID,
        gop.InstrumentID,
        gop.IsBuy,
        gop.Amount,
        gop.Leverage,
        gop.SettlementTypeID,
        c.RealizedEquity
FROM    Trade.GetGuruOpenPositions gop WITH (NOLOCK)
JOIN    Customer.Customer c WITH (NOLOCK)
        ON c.CID = gop.CID
WHERE   gop.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 48 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetGuruOpenPositionsWithCustomerData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetGuruOpenPositionsWithCustomerData.sql*
