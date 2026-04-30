# Trade.SI_GetPositionDataBy_CO

> System Integration query that returns trading position data for a specific customer filtered by open/closed status, reading from the Trade.GetPositionData view.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @IsOpened |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a System Integration (SI_) endpoint that returns a rich set of position data for a customer, filtered by whether positions are open or closed. The _CO suffix likely stands for "Customer + Open/closed". It reads from the `Trade.GetPositionData` view, which already unifies current open positions (Trade.PositionTbl) with historical closed positions.

Integration consumers use this procedure to retrieve position data for a specific customer in a given state (open or closed) without needing to know the underlying table structure. The column selection covers the key identifiers, financial rates, P&L, risk parameters, and execution metadata needed for most downstream integration use cases.

---

## 2. Business Logic

### 2.1 IsOpened State Filter

**What**: The @IsOpened parameter selects between current open positions and closed historical positions.

**Columns/Parameters Involved**: `@IsOpened`, `Trade.GetPositionData.IsOpened`

**Rules**:
- @IsOpened = 1 -> returns open positions (currently active in the portfolio)
- @IsOpened = 0 -> returns closed positions (historical)
- The filtering is pushed into the Trade.GetPositionData view which unifies both states

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID to filter positions by. Returns all positions (open or closed based on @IsOpened) belonging to this customer. |
| 2 | @IsOpened | int | NO | - | CODE-BACKED | Position state filter: 1 = open positions only, 0 = closed positions only. Filters on Trade.GetPositionData.IsOpened. |
| Output: CID | int | - | - | CODE-BACKED | Customer ID - same as @CID input. |
| Output: PositionID | bigint | - | - | CODE-BACKED | Unique position identifier. |
| Output: ForexResultID | - | - | - | CODE-BACKED | Forex result reference identifier. |
| Output: Currency | - | - | - | CODE-BACKED | Currency denomination of the position. |
| Output: ProviderID | - | - | - | CODE-BACKED | Liquidity provider ID for this position. |
| Output: InstrumentID | int | - | - | CODE-BACKED | Trading instrument (asset) identifier. FK to Trade.ProviderToInstrument. |
| Output: PositionHedgeServerID | - | - | - | CODE-BACKED | Hedge server routing identifier for this position. |
| Output: Leverage | int | - | - | CODE-BACKED | Leverage multiplier applied to this position (1 = no leverage / real stock). |
| Output: ForexBuy | - | - | - | CODE-BACKED | Buy-side forex rate component. |
| Output: ForexSell | - | - | - | CODE-BACKED | Sell-side forex rate component. |
| Output: InitForexRate | decimal | - | - | CODE-BACKED | Opening forex conversion rate (USD/instrument home currency at time of open). |
| Output: EndForexRate | decimal | - | - | CODE-BACKED | Closing forex conversion rate (set when position closes). |
| Output: InitDateTime | datetime | - | - | CODE-BACKED | Timestamp when the position was opened. |
| Output: NetProfit | money | - | - | CODE-BACKED | Net profit/loss of the position in USD. For open positions, current unrealized P&L. |
| Output: StopRate | decimal | - | - | CODE-BACKED | Stop-loss rate for this position. |
| Output: LimitRate | decimal | - | - | CODE-BACKED | Take-profit rate for this position. |
| Output: Amount | money | - | - | CODE-BACKED | Invested amount (USD) at position open. |
| Output: AmountInUnitsDecimal | decimal | - | - | CODE-BACKED | Number of units (shares/contracts) held in this position. |
| Output: Commission | money | - | - | CODE-BACKED | Commission charged at position open. |
| Output: SpreadedCommission | money | - | - | CODE-BACKED | Commission including spread component. |
| Output: IsBuy | bit | - | - | CODE-BACKED | Direction: 1 = Buy/Long position, 0 = Sell/Short position. |
| Output: CloseOnEndOfWeek | bit | - | - | CODE-BACKED | 1 = position auto-closes at end of trading week. |
| Output: EndOfWeekFee | money | - | - | CODE-BACKED | Fee charged for holding position over the weekend. |
| Output: Units | - | - | - | CODE-BACKED | Units held (legacy/alternative unit field). |
| Output: LotCountDecimal | decimal | - | - | CODE-BACKED | Current position size expressed in lots. |
| Output: UnitMargin | decimal | - | - | CODE-BACKED | Margin required per unit of this position. |
| Output: AdditionalParam | - | - | - | CODE-BACKED | Additional execution parameter. |
| Output: OrderID | bigint | - | - | CODE-BACKED | Order that opened this position. |
| Output: TradeRange | - | - | - | CODE-BACKED | Acceptable price range for order execution. |
| Output: InitForexPriceRateID | int | - | - | CODE-BACKED | Price rate record ID at open; 0 = HBC (host-based calculation), >0 = CBH (central brokerage hub). |
| Output: LastOpPriceRate | decimal | - | - | CODE-BACKED | Last operation price rate. |
| Output: LastOpPriceRateID | int | - | - | CODE-BACKED | ID of the last operation price rate record. |
| Output: LastOpConversionRate | decimal | - | - | CODE-BACKED | Last operation forex conversion rate. |
| Output: LastOpConversionRateID | int | - | - | CODE-BACKED | ID of the last operation conversion rate record. |
| Output: ParentPositionID | bigint | - | - | CODE-BACKED | Parent position ID for copy-trade child positions; 0 for standalone positions. |
| Output: InstrumentPrecision | int | - | - | CODE-BACKED | Decimal precision for this instrument's price display. |
| Output: MirrorID | int | - | - | CODE-BACKED | Copy-trade mirror ID for copy positions; 0 for manual positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, @IsOpened | Trade.GetPositionData | Reader | Reads from the position data view with NOLOCK, filtering by CID and IsOpened |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SI_GetPositionDataBy_CO (procedure)
└── Trade.GetPositionData (view) [SELECT with CID + IsOpened filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionData | View | Read with NOLOCK filtered by CID and IsOpened; provides unified open/closed position data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by external integration systems (SI_ prefix convention) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all open positions for a customer

```sql
EXEC Trade.SI_GetPositionDataBy_CO @CID = 12345, @IsOpened = 1;
```

### 8.2 Get all closed positions for a customer

```sql
EXEC Trade.SI_GetPositionDataBy_CO @CID = 12345, @IsOpened = 0;
```

### 8.3 Direct equivalent query for open positions

```sql
SELECT CID, PositionID, InstrumentID, IsBuy, Amount, AmountInUnitsDecimal, NetProfit, InitDateTime
FROM Trade.GetPositionData WITH (NOLOCK)
WHERE CID = 12345
AND IsOpened = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SI_GetPositionDataBy_CO | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SI_GetPositionDataBy_CO.sql*
