# Trade.GetPosition

> Legacy position view enriching open positions with hedge details (TradeID, AccountID, HedgedLotCount), customer real/demo flag, and provider instrument units, with monetary values converted to cents.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPosition is a **legacy position enrichment view** that combines open position data with hedge execution details and customer context. It joins Trade.Position with a UNION ALL of Trade.Hedge and History.Hedge (covering both active and historical hedges), Trade.ProviderToInstrument (for unit count), and Customer.Customer (for the IsReal account flag).

This view exists because the close execution flow needs to know not just the position details but also the hedge execution state (TradeID, AccountID from the provider, hedged lot count) to properly close the hedge alongside the position. The Customer.Customer join adds IsRealAccount to distinguish real vs demo accounts during close processing.

Monetary values are converted to cents (Amount * 100, NetProfit * 100, Commission * 100) for legacy system compatibility. The hedge UNION ALL ensures that even if a hedge has been partially closed to history, the view can still find the hedge record.

---

## 2. Business Logic

### 2.1 Hedge Data Enrichment

**What**: Combines active and historical hedge records to find the matching hedge for each position.

**Columns/Parameters Involved**: `HedgeID`, `HedgedLotCountDecimal`, `TradeID`, `AccountID`, `HedgeServerID` (from hedge)

**Rules**:
- LEFT OUTER JOIN to UNION ALL of Trade.Hedge + History.Hedge on HedgeID
- Returns the provider's TradeID, AccountID, HedgeServerID, and LotCountDecimal for the hedge
- If no hedge exists (HedgeID is NULL or no match), hedge columns are NULL

### 2.2 Cents Conversion

**What**: Converts monetary values from dollars to cents for legacy compatibility.

**Columns/Parameters Involved**: `Amount`, `NetProfit`, `Commission`

**Rules**:
- Amount = CAST(TPOS.Amount * 100 AS INTEGER) (position amount in cents)
- NetProfit = CAST(TPOS.NetProfit * 100 AS INTEGER) (PnL in cents)
- Commission = CAST(TPOS.Commission * 100 AS INTEGER) (commission in cents)

---

## 3. Data Overview

N/A - enrichment view. Data mirrors Trade.Position with added hedge and customer context.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. From Trade.Position. |
| 2 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result tracking. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Denomination currency. FK to Dictionary.Currency. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 6 | HedgeID | bigint | YES | - | CODE-BACKED | Hedge record ID from position. |
| 7 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server from position (aliased from HedgeServerID). |
| 8 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server from the hedge record (may differ from position's server). |
| 9 | Amount | int | YES | - | CODE-BACKED | Computed: CAST(Amount * 100 AS INTEGER). Position amount in cents. |
| 10 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units/shares. |
| 11 | NetProfit | int | YES | - | CODE-BACKED | Computed: CAST(NetProfit * 100 AS INTEGER). Unrealized PnL in cents. |
| 12 | InstrumentID | int | NO | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 13 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 15 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. |
| 16 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. |
| 17 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=buy/long, 0=sell/short. |
| 18 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Weekend close preference. |
| 19 | Commission | int | YES | - | CODE-BACKED | Computed: CAST(Commission * 100 AS INTEGER). Commission in cents. |
| 20 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position lot count. |
| 21 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance. |
| 22 | HedgedLotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from the hedge record. From Trade.Hedge or History.Hedge. |
| 23 | TradeID | varchar | YES | - | CODE-BACKED | External trade ID from the provider's hedge execution. |
| 24 | AccountID | varchar | YES | - | CODE-BACKED | External account ID on the provider. |
| 25 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. |
| 26 | Occurred | datetime | YES | - | CODE-BACKED | When position was executed. |
| 27 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. |
| 28 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. |
| 29 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | Order price rate snapshot. |
| 30 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Order price rate. |
| 31 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot. |
| 32 | MarketPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Market price rate. |
| 33 | Unit | decimal | YES | - | CODE-BACKED | Unit count from Trade.ProviderToInstrument. |
| 34 | IsRealAccount | bit | YES | - | CODE-BACKED | Whether customer has a real (non-demo) account. From Customer.Customer.IsReal. |
| 35 | OrderID | int | YES | 0 | CODE-BACKED | Computed: ISNULL(OrderID, 0). Originating order, defaulting to 0. |
| 36 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in hierarchy. |
| 37 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. |
| 38 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. |
| 39 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate snapshot. |
| 40 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 41 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last op conversion rate snapshot. |
| 42 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. 0=independent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | Trade.Position | FROM | Open position data |
| HedgeID | Trade.Hedge | LEFT JOIN (UNION ALL) | Active hedge records |
| HedgeID | History.Hedge | LEFT JOIN (UNION ALL) | Historical hedge records |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | Unit count |
| CID | Customer.Customer | Implicit JOIN | IsReal account flag |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPosition (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.Hedge (table)
+-- History.Hedge (x-schema table)
+-- Trade.ProviderToInstrument (table)
+-- Customer.Customer (x-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Base open position data |
| Trade.Hedge | Table | Active hedge lookup (UNION ALL) |
| History.Hedge | Table | Historical hedge lookup (UNION ALL) |
| Trade.ProviderToInstrument | Table | Unit count |
| Customer.Customer | Table | IsReal account flag |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Positions with their hedge details

```sql
SELECT PositionID, InstrumentID, LotCountDecimal, HedgedLotCountDecimal, TradeID, AccountID
FROM   Trade.GetPosition WITH (NOLOCK)
WHERE  HedgeID IS NOT NULL;
```

### 8.2 Real vs demo account positions

```sql
SELECT IsRealAccount, COUNT(*) AS PositionCount
FROM   Trade.GetPosition WITH (NOLOCK)
GROUP BY IsRealAccount;
```

### 8.3 Positions with amount in cents

```sql
SELECT PositionID, CID, InstrumentID, Amount AS AmountCents, NetProfit AS PnLCents, Commission AS CommissionCents
FROM   Trade.GetPosition WITH (NOLOCK)
WHERE  CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 42 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPosition | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPosition.sql*
