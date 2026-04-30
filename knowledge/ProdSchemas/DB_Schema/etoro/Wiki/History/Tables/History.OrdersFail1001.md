# History.OrdersFail1001

> Legacy local partition of the failed-orders audit log, capturing complete order state snapshots for orders that could not be executed on trading node 1001.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrdersFailID (INT, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.OrdersFail1001 is a legacy local-shard table that stores complete snapshots of orders that failed to execute - capturing the full order state at the moment of failure including rates, amounts, leverage, and the failure reason. The "1001" suffix identifies this as the local table for trading node/server 1001 in a multi-server deployment architecture.

This table exists because the eToro trading platform originally used a sharded approach where each trading node wrote failed orders to its own local History table (e.g., History.OrdersFail1001, History.OrdersFail1002, etc.). These tables enabled per-node failure analysis and troubleshooting without cross-server queries. A synonym History.OrdersFail now points to DB_Logs.History.OrdersFail as the consolidated destination, making this local table inactive.

The table currently has 0 rows in the live database. Active failed-order logging goes through Trade.OrdersFailAdd -> History.OrdersFail (synonym -> DB_Logs.History.OrdersFail). This table is retained in the SSDT schema for reference and potential recovery/migration purposes.

---

## 2. Business Logic

### 2.1 Failed Order Capture - Full Snapshot Pattern

**What**: Unlike the change logs (OrdersEntryChangeLog, OrdersExitChangeLog) that log lifecycle events, this table captures the COMPLETE order state at the moment of failure.

**Columns/Parameters Involved**: `OrderID`, `FailReason`, `FailOccurred`, `ErrorCode`, `RateFrom`, `RateTo`

**Rules**:
- One row per failed order - the snapshot is taken at the time Trade.OrdersFailAdd was called.
- FailReason contains the full error message/description from the trading engine.
- ErrorCode is the numeric error identifier (e.g., 1001 may relate to the node identifier or a specific error class).
- RateFrom and RateTo capture the bid/ask rates at the moment the order failed - critical for investigating slippage and rate-related failures.
- The PK name "PK_OrdersFail" (without the 1001 suffix) indicates this structure predates the sharding suffix - the original table was simply "OrdersFail" before the node numbering was added.

### 2.2 Multi-Server Shard Architecture (Historical)

**What**: Each trading server node maintained its own local failed-order log before data consolidation.

**Columns/Parameters Involved**: `OrdersFailID`, `LoginID`

**Rules**:
- The "1001" in the table name identifies the trading server/node that originally wrote to this table.
- LoginID references the trading server session/login that attempted the order - key for identifying which server processed the failing order.
- Active writes now go to DB_Logs.History.OrdersFail via the History.OrdersFail synonym, replacing this sharded pattern.

---

## 3. Data Overview

Table currently has 0 rows in the live database. No sample data available - table is legacy/inactive.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrdersFailID | int | NO | - | CODE-BACKED | Surrogate primary key. Unique identifier for each failed-order record. No business meaning beyond row identity. |
| 2 | OrderID | int | NO | - | CODE-BACKED | The order identifier that failed. Corresponds to the OrderID from the originating order request. -1 when the order had no ID at the time of failure (failure before order assignment). |
| 3 | CID | int | YES | - | CODE-BACKED | Customer identifier who placed the failed order. |
| 4 | CurrencyID | int | YES | - | CODE-BACKED | Account currency at the time of the order attempt. Implicit FK to Dictionary.Currency. |
| 5 | ProviderID | int | YES | - | CODE-BACKED | Liquidity provider that was targeted for the order. Implicit FK to provider lookup tables. |
| 6 | OrderTypeID | int | YES | - | CODE-BACKED | Type of the order that failed (market, limit, etc.). Implicit FK to Dictionary.OrderType or similar. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument the order was for. Implicit FK to Dictionary/Trade instrument tables. |
| 8 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier applied to the failed order. |
| 9 | Amount | money | YES | - | CODE-BACKED | Order notional amount in the account's currency at the time of the attempt. |
| 10 | Units | int | YES | - | CODE-BACKED | Legacy integer unit count for the order. Predates AmountInUnitsDecimal (decimal precision). |
| 11 | UnitMargin | int | YES | - | CODE-BACKED | Margin requirement per unit at the time of the order attempt. |
| 12 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size expressed in lots (liquidity provider unit). Decimal precision for fractional lots. |
| 13 | RateFrom | dbo.dtPrice | YES | - | CODE-BACKED | Bid/offer rate captured at the moment of the order attempt (decimal(16,8)). Used to investigate rate-related rejection causes. |
| 14 | RateTo | dbo.dtPrice | YES | - | CODE-BACKED | Target/limit rate for the order (decimal(16,8)). For market orders, this is the execution rate requested. |
| 15 | IsBuy | bit | YES | - | CODE-BACKED | Trade direction: 1=Buy (long), 0=Sell (short). |
| 16 | ForexResultID | bigint | YES | - | CODE-BACKED | Result identifier from the forex/execution engine. Default -1 when not applicable. Links to execution result records for detailed failure analysis. |
| 17 | GameID | int | YES | - | CODE-BACKED | Virtual trading game identifier when the order was from a practice/demo account (0 for live accounts). |
| 18 | SpreadID | int | YES | - | CODE-BACKED | Spread configuration active at the time of the order. Identifies which pricing spread was applied. |
| 19 | LoginID | int | YES | - | CODE-BACKED | Trading server session/login ID that processed this order. Identifies which server session handled the failing order. |
| 20 | IsOverWeekend | bit | YES | - | CODE-BACKED | Whether the order was placed over a weekend (1=yes). Relevant for overnight fee and settlement calculation. |
| 21 | StopLosAmount | int | YES | - | CODE-BACKED | Stop-loss amount in cents at the time of the order. |
| 22 | TakeProfitAmount | int | YES | - | CODE-BACKED | Take-profit amount in cents at the time of the order. |
| 23 | MarketSpreadPips | int | YES | - | CODE-BACKED | Market spread in pips at the moment of failure. Captures market conditions at failure time. |
| 24 | MarketSpreadCents | int | YES | - | CODE-BACKED | Market spread in cents at the moment of failure. Complement to MarketSpreadPips. |
| 25 | StopLosRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate level in decimal(16,8) at the time of the order attempt. |
| 26 | TakeProfitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate level in decimal(16,8) at the time of the order attempt. |
| 27 | OpenOccurredTime | datetime | YES | - | CODE-BACKED | UTC timestamp when the order was originally submitted (before the failure). |
| 28 | FailReason | varchar(max) | YES | - | CODE-BACKED | Free-text error description from the trading engine. Contains the full exception message or business rule violation reason. |
| 29 | FailOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the failure was recorded. |
| 30 | TradeRange | int | YES | - | CODE-BACKED | Acceptable rate range (in pips/points) the customer specified for order execution. Orders failing outside this range produce rate-range rejection failures. |
| 31 | ParentOrderID | int | YES | - | CODE-BACKED | For derived orders (e.g., copy-trade orders): the parent order that spawned this failed order. Default 1 when not a child order. |
| 32 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client application version at time of failure. Populated by joining Customer.Login.ClientVersion at INSERT time. Useful for diagnosing version-specific failures. |
| 33 | PendingClosePositionID | bigint | YES | - | CODE-BACKED | For close orders: the PositionID that was pending closure when this order failed. Links the failed close attempt to the specific open position. |
| 34 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether Trailing Stop Loss was enabled for this order. 0=disabled (default), 1=enabled. |
| 35 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size in instrument units with decimal precision. Added 2017 (FB 47233) to supersede the legacy integer Units column for unit-based instruments. |
| 36 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-supplied idempotency key from the original request. Enables deduplication and correlation with client-side logs. Added 2018 (FB 51445). |
| 37 | ErrorCode | int | YES | - | CODE-BACKED | Numeric error code from the trading engine. Complements the free-text FailReason with a machine-readable failure identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer who placed the failed order. |
| InstrumentID | Dictionary/Trade instrument | Implicit | Trading instrument the order was for. |
| CurrencyID | Dictionary.Currency | Implicit | Account currency at order time. |
| RateFrom, RateTo, StopLosRate, TakeProfitRate | dbo.dtPrice | UDT | Uses the dbo.dtPrice user-defined type (decimal(16,8)) for all price/rate fields. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.OrdersFail (synonym) | - | Synonym | History.OrdersFail is a synonym for DB_Logs.History.OrdersFail - the active consolidated table. This local table is the inactive legacy predecessor. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersFail1001 (table)
└── dbo.dtPrice (UDT) - used for RateFrom, RateTo, StopLosRate, TakeProfitRate columns
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Used as the column type for RateFrom, RateTo, StopLosRate, TakeProfitRate (decimal(16,8)) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersFailAdd | Stored Procedure | WRITER - historically wrote failed orders here; now writes to History.OrdersFail synonym -> DB_Logs |
| BackOffice.GetCustomerClosedOrders | Stored Procedure | READER - references OrdersFail pattern for historical closed order data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OrdersFail | CLUSTERED PK | OrdersFailID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OrdersFail | PRIMARY KEY | Unique per failed-order record |
| DF_HistoryOrdersFail_IsTslEnabled | DEFAULT | IsTslEnabled defaults to 0 (disabled) |

---

## 8. Sample Queries

### 8.1 Get all failed orders for a customer (when table has data)

```sql
SELECT OrdersFailID, OrderID, InstrumentID, Amount, FailReason, FailOccurred, ErrorCode
FROM History.OrdersFail1001 WITH (NOLOCK)
WHERE CID = @CID
ORDER BY FailOccurred DESC;
```

### 8.2 Find failures by error code

```sql
SELECT ErrorCode, COUNT(*) AS FailCount, MIN(FailOccurred) AS FirstSeen, MAX(FailOccurred) AS LastSeen
FROM History.OrdersFail1001 WITH (NOLOCK)
WHERE ErrorCode IS NOT NULL
GROUP BY ErrorCode
ORDER BY FailCount DESC;
```

### 8.3 Compare rate at failure vs stop-loss / take-profit levels

```sql
SELECT OrdersFailID, OrderID, InstrumentID, RateFrom, RateTo, StopLosRate, TakeProfitRate,
       FailReason, FailOccurred
FROM History.OrdersFail1001 WITH (NOLOCK)
ORDER BY FailOccurred DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 37 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersFail1001 | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersFail1001.sql*
