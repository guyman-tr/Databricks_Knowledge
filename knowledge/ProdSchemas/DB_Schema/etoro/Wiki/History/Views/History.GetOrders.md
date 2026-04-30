# History.GetOrders

> Read-only passthrough view over History.Orders exposing the core 29 columns of the closed pending orders archive - providing a NOLOCK-enabled access path to historical order records without the newer extended attributes added in later releases.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | OrderID (int, from History.Orders) |
| **Partition** | N/A (view - base table is unpartitioned) |
| **Indexes** | N/A (view - History.Orders clustered PK on OrderID used) |

---

## 1. Business Meaning

`History.GetOrders` is a thin SELECT view over `History.Orders WITH(NOLOCK)` that exposes the 29 original core columns of the closed pending orders archive. It provides access to all pending orders that have been removed from the live `Trade.Orders` table - whether cancelled by the client, filled and converted to a position, or server-removed.

The view was created to give consumers a stable, named access path to order history without requiring them to reference the base table directly. The `WITH(NOLOCK)` hint in the view definition means all consumers of the view benefit from read-uncommitted isolation, important for high-concurrency reporting on the order archive.

The view omits 12 newer columns that were added to `History.Orders` in later feature releases (FB 47233, FB 53719): `TradeRange`, `LastOpPriceRate`, `LastOpPriceRateID`, `LastOpConversionRate`, `LastOpConversionRateID`, `IsTslEnabled`, `AmountInUnitsDecimal`, `IsDiscounted`, `IsSettled`, `SettlementTypeID`, `IsNoStopLoss`, `IsNoTakeProfit`. Consumers needing those columns should query `History.Orders` directly.

---

## 2. Business Logic

### 2.1 Core Column Selection (Original Schema)

**What**: The view was designed to expose the original set of columns that existed before extended attributes were added, providing a stable contract for older consumers.

**Columns/Parameters Involved**: All 29 exposed columns (see Section 4)

**Rules**:
- Exposes columns 1-29 of the original History.Orders schema (pre-FB-47233/53719)
- Omits extended attributes: TSL flag, decimal amount/units, settlement fields, stop-loss/take-profit explicit flags, rate capture fields, TradeRange
- Adding WITH(NOLOCK) at the view level means the isolation hint is always applied - consumers get read-uncommitted by default
- The base table History.Orders itself records all closures atomically (INSERT into History.Orders + DELETE from Trade.Orders in a single transaction), so NOLOCK on this archive table is low-risk

### 2.2 Archive-on-Close Pattern (inherited from History.Orders)

**What**: All rows in this view came from the live `Trade.Orders` table when an order was closed.

**Columns/Parameters Involved**: `ActionTypeID`, `OpenOccurred`, `CloseOcurred`

**Rules**:
- ActionTypeID 1 (ClientRemove): client cancelled the order - dominant, ~90% of records
- ActionTypeID 2 (ConvertedToPosition): order was filled, converted to a live position in Trade.PositionTbl
- ActionTypeID 5 (ConvertedToOrderForOpen): order converted to pre-execution state change
- `OpenOccurred` = original order placement time (copied from Trade.Orders.OccurredTime)
- `CloseOcurred` = time of archival, set to GETDATE() by Trade.OrdersClose (note: "CloseOcurred" typo is in the base table DDL and is preserved here)

---

## 3. Data Overview

| OrderID | CID | InstrumentID | ActionTypeID | IsBuy | Amount | RateFrom | RateTo | OpenOccurred | CloseOcurred | Meaning |
|---------|-----|-------------|-------------|-------|--------|----------|--------|-------------|-------------|---------|
| 24360007 | 14866508 | 1144 | 1 (ClientRemove) | Buy | 12463 | 124.63 | 125.38 | 2026-03-17 21:02:33 | 2026-03-17 21:02:49 | Buy order on instrument 1144 placed and cancelled 16 seconds later by the client. Rate moved from 124.63 to 125.38 during the order's lifetime. |
| 24338008 | 14952814 | 1144 | 1 (ClientRemove) | Buy | 15000 | 124.63 | 125.38 | 2026-03-17 21:02:33 | 2026-03-17 21:02:52 | A larger $15,000 buy order on the same instrument, also client-cancelled within 20 seconds - same rate snapshot. |
| 24338007 | 14952810 | 1144 | 1 (ClientRemove) | Sell | 12463 | 124.63 | 125.38 | 2026-03-17 21:02:33 | 2026-03-17 21:02:49 | Sell-side order on instrument 1144 also cancelled. Three orders placed at the same second (21:02:33) suggests a coordinated test or UI interaction sequence. |

---

## 4. Elements

All columns are inherited unchanged from `History.Orders`. See `History.Orders.md` for full business context on each column.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Pending order identifier. Not IDENTITY - allocated by Internal.GetOrderID sequence. Preserved from Trade.Orders on archival. PK of the base table. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID of the order owner. FK (implicit) to Customer.Customer. |
| 3 | CurrencyID | int | YES | - | CODE-BACKED | Account currency denomination. FK (implicit) to Dictionary.Currency. |
| 4 | ProviderID | int | YES | - | CODE-BACKED | Liquidity provider routing rates for this order. FK (implicit) to Trade.Provider. |
| 5 | OrderTypeID | int | YES | - | NAME-INFERRED | Order subtype. Observed values: 0 (83%, standard), 15 (15%, likely market order), 4, 5, 6, 7. No FK constraint. |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument for the order. FK (implicit) to Trade.Instrument. |
| 7 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. All recent rows = 1 (no leverage, consistent with Free Stocks rollout). |
| 8 | Amount | money | YES | - | CODE-BACKED | Order size in account currency (USD). Must be > 0 (validated in Trade.OrdersAdd). |
| 9 | Units | int | YES | - | CODE-BACKED | Number of instrument units in the order. |
| 10 | UnitMargin | int | YES | - | NAME-INFERRED | Margin required per unit in cents. System-calculated at order placement. |
| 11 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size in lots (fractional precision). Added in FB 47233 for decimal lot handling. |
| 12 | RateFrom | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate at order placement (the trigger/limit rate). Uses dbo.dtPrice UDT. Live data: 124.63 for recent orders on instrument 1144. |
| 13 | RateTo | dbo.dtPrice | YES | - | CODE-BACKED | Market rate at order close time. Uses dbo.dtPrice UDT. Compared to RateFrom for execution quality analysis. Live data: 125.38 for most recent closed orders. |
| 14 | IsBuy | bit | YES | - | CODE-BACKED | Order direction: 1=Buy (long), 0=Sell (short). |
| 15 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy game session link. Hardcoded to -1 in Trade.OrdersAdd (per code comment: "ForexResultID is not being used anymore"). All modern orders have -1. |
| 16 | GameID | int | YES | - | NAME-INFERRED | Legacy game/contest identifier. 0 or NULL for all modern orders. Non-zero historically for eToro game platform (2009-2014). |
| 17 | SpreadID | int | YES | - | NAME-INFERRED | Spread configuration ID applied at order placement. 0 for most rows. |
| 18 | LoginID | int | YES | - | NAME-INFERRED | Trading account login ID (distinct from CID). 0 for most rows. |
| 19 | IsOverWeekend | bit | YES | - | CODE-BACKED | Whether the order was open over a weekend, triggering weekend financing charges. |
| 20 | StopLosAmount | int | YES | - | CODE-BACKED | Stop-loss threshold in account currency units. Note: column name typo "StopLos" is from the base table DDL. 0 = no stop-loss amount. |
| 21 | TakeProfitAmount | int | YES | - | CODE-BACKED | Take-profit threshold in account currency units. 0 = no take-profit amount. |
| 22 | MarketSpreadPips | int | YES | - | NAME-INFERRED | Market spread at order placement in pips. Used for spread cost calculation. 0 for most rows. |
| 23 | MarketSpreadCents | int | YES | - | NAME-INFERRED | Market spread at order placement in cents. Alternative to pips for non-pip instruments. 0 for most rows. |
| 24 | StopLosRate | dbo.dtPrice | YES | - | CODE-BACKED | Rate at which the stop-loss triggers. Uses dbo.dtPrice UDT. NULL/0 if no stop-loss rate set. |
| 25 | TakeProfitRate | dbo.dtPrice | YES | - | CODE-BACKED | Rate at which the take-profit triggers. Uses dbo.dtPrice UDT. NULL/0 if no take-profit rate set. |
| 26 | OpenOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the order was originally placed. Copied from Trade.Orders.OccurredTime at archival. |
| 27 | CloseOcurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the order was archived. Set to GETDATE() by Trade.OrdersClose. Note: "CloseOcurred" typo (missing 's') is in the base table DDL and is preserved here. |
| 28 | ActionTypeID | int | YES | - | CODE-BACKED | Why the order was archived. FK WITH CHECK to Dictionary.OrdersActionType: 1=ClientRemove (90%), 2=ConvertedToPosition (2%), 5=ConvertedToOrderForOpen (7%). (Inherited from History.Orders) |
| 29 | ParentOrderID | int | YES | - | CODE-BACKED | For copy-trading: parent order in the REAL environment this order was following. 0 = no parent (all current live data). Non-zero triggers detach logic in demo environments. |

**Omitted columns** (present in History.Orders but not exposed here): TradeRange, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID, IsTslEnabled, AmountInUnitsDecimal, IsDiscounted, IsSettled, SettlementTypeID, IsNoStopLoss, IsNoTakeProfit. Query History.Orders directly for these.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (entire view) | History.Orders | View dependency (WITH NOLOCK) | Direct SELECT wrapper - all 29 core columns with read-uncommitted isolation |
| ActionTypeID | Dictionary.OrdersActionType | Implicit (inherited) | Order close reason: 1=ClientRemove, 2=ConvertedToPosition, 5=ConvertedToOrderForOpen |
| InstrumentID | Trade.Instrument | Implicit (inherited) | The traded instrument |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the etoro SSDT repo directly reference History.GetOrders. Consumers likely access the underlying History.Orders table directly (which has 7 known SP consumers including Trade.OrdersClose, BackOffice.GetCustomerClosedOrders, History.OrdersEntry, History.OrdersExit).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetOrders (view)
└── History.Orders (table - 7,359 rows, 2010-present closed pending orders)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Orders | Table | Direct SELECT source with WITH(NOLOCK) - all 29 core columns |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. History.Orders has a single CLUSTERED PK on OrderID - queries filtering by OrderID will be efficient; range scans by date require full or partial table scan since there is no date index on the base table.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get recent cancelled orders for a customer

```sql
SELECT
    go.OrderID,
    go.InstrumentID,
    go.IsBuy,
    go.Amount,
    go.RateFrom,
    go.RateTo,
    go.OpenOccurred,
    go.CloseOcurred,
    DATEDIFF(SECOND, go.OpenOccurred, go.CloseOcurred) AS DurationSeconds
FROM History.GetOrders go WITH (NOLOCK)
WHERE go.CID = 14952810
  AND go.ActionTypeID = 1  -- ClientRemove
ORDER BY go.CloseOcurred DESC
```

### 8.2 Find orders that were filled (converted to a position)

```sql
-- ActionTypeID=2 means the order was filled and became a live position
SELECT
    go.OrderID,
    go.CID,
    go.InstrumentID,
    go.IsBuy,
    go.Amount,
    go.RateFrom,
    go.OpenOccurred,
    go.CloseOcurred
FROM History.GetOrders go WITH (NOLOCK)
WHERE go.ActionTypeID = 2  -- ConvertedToPosition
ORDER BY go.CloseOcurred DESC
```

### 8.3 Order activity summary by close reason

```sql
SELECT
    go.ActionTypeID,
    COUNT(*) AS OrderCount,
    SUM(go.Amount) AS TotalAmount,
    MIN(go.OpenOccurred) AS EarliestOrder,
    MAX(go.CloseOcurred) AS LatestClose
FROM History.GetOrders go WITH (NOLOCK)
GROUP BY go.ActionTypeID
ORDER BY OrderCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 8.6/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 9 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOrders | Type: View | Source: etoro/etoro/History/Views/History.GetOrders.sql*
