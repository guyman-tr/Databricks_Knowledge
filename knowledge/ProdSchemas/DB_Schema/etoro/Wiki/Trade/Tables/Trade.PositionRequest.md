# Trade.PositionRequest

> Stores position open and close requests with provider, hedge server, and instrument details; links positions to liquidity providers and game servers before execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID, RequestType (composite PK) |
| **Partition** | No |
| **Indexes** | 3 (PK + 2 nonclustered) |

---

## 1. Business Meaning

**WHAT:** `PositionRequest` is a transient table that holds pending open and close requests for positions before they are executed by the trading engine. Each row represents either a request to open a new position (RequestType=1) or to close an existing one (RequestType=2). The table stores provider, game server, instrument, amount, rates, and other parameters needed for execution. Data is short-lived: open requests are consumed when positions are created; close requests are consumed when positions are closed.

**WHY:** The trading system decouples the request phase (user or system initiates) from the execution phase (provider/hedge server processes). This table acts as a queue, holding requests with all context (provider, instrument, rates, stop/limit) until the execution engine picks them up. It also supports linking positions to specific liquidity providers (ProviderID) and game servers (GameServerID).

**HOW:** `Trade.PositionOpenRequestAdd` inserts open requests (RequestType=1) with ProviderID, GameServerID, InstrumentID, Amount, Leverage, etc. `Trade.PositionCloseRequestAdd` inserts close requests (RequestType=2) with RequestedEndForexRate. If a duplicate close request exists, the prior one is moved to History.PositionFailWrite and replaced. Downstream jobs read and process these rows, then delete them upon completion.

---

## 2. Business Logic

### 2.1 Open Request (RequestType=1)

**What**: When a user or system requests to open a position, `PositionOpenRequestAdd` generates a new PositionID and inserts a row with RequestType=1. The row includes ProviderID, GameServerID, InstrumentID, Amount, AmountInUnitsDecimal, Leverage, IsBuy, and other parameters.

**Columns/Parameters Involved**: PositionID, RequestType=1, CID, CurrencyID, ProviderID, GameServerID, InstrumentID, OrderID, Leverage, Amount, AmountInUnitsDecimal, UnitMargin, LotCountDecimal, IsBuy, CloseOnEndOfWeek, AdditionalParam, TradeRange, ParentPositionID

**Rules**:
- RequestType=1 (open) or 2 (close) only; CHECK constraint enforces this
- PositionID for open requests is generated via Internal.GetPositionID_Bigint before insert
- OrderID must not already exist in Trade.Position or History.Position

### 2.2 Close Request (RequestType=2)

**What**: When a close is requested, `PositionCloseRequestAdd` inserts a row with RequestType=2. If a prior close request exists for the same PositionID, it is archived to History.PositionFailWrite first, then replaced.

**Columns/Parameters Involved**: PositionID, RequestType=2, RequestedEndForexRate, TradeRange, ParentPositionID

**Rules**:
- Only one active close request per PositionID; duplicates trigger archive-then-replace
- TradeRange and ParentPositionID are copied from Trade.Position for the given PositionID
- RequestedEndForexRate comes from the caller

### 2.3 Provider and Hedge Linkage

**What**: ProviderID and GameServerID link the request to liquidity providers and hedge/game servers. These are used by downstream execution to route the trade.

**Columns/Parameters Involved**: ProviderID, GameServerID

**Rules**:
- ProviderID references the liquidity provider
- GameServerID references the game/trading server handling the request

---

## 3. Data Overview

| PositionID | RequestType | CID | ProviderID | InstrumentID | Amount | Occurred | Meaning |
|------------|-------------|-----|------------|--------------|--------|----------|---------|
| (sample) | 1 | (sample) | (sample) | (sample) | (sample) | (sample) | Open request with provider/instrument |
| (sample) | 2 | (sample) | - | (sample) | - | (sample) | Close request |

*Live data: table may be empty in dev/QA; production holds short-lived open/close request rows.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier. For open: generated before insert. For close: existing position to close. |
| 2 | RequestType | int | NO | - | VERIFIED | 1=Open, 2=Close. CHECK constraint enforces (1) or (2) only. |
| 3 | CID | int | YES | - | CODE-BACKED | Customer ID. References Customer.CustomerStatic. Populated for open requests. |
| 4 | CurrencyID | int | YES | - | CODE-BACKED | Currency for the position. |
| 5 | ProviderID | int | YES | - | CODE-BACKED | Liquidity provider. Populated for open requests. |
| 6 | GameServerID | int | YES | - | CODE-BACKED | Game/trading server. Populated for open requests. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument. |
| 8 | OrderID | int | YES | - | CODE-BACKED | Associated order if any. |
| 9 | HedgeID | int | YES | - | NAME-INFERRED | Hedge identifier for execution routing. |
| 10 | Leverage | int | YES | - | CODE-BACKED | Leverage for open requests. |
| 11 | Amount | money | YES | - | CODE-BACKED | Position amount in currency. |
| 12 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units. |
| 13 | UnitMargin | int | YES | - | CODE-BACKED | Unit margin. |
| 14 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count. |
| 15 | NetProfit | money | YES | - | NAME-INFERRED | Net profit (if applicable). |
| 16 | InitForexRate | dtPrice | YES | - | NAME-INFERRED | Initial forex rate at open. |
| 17 | InitDateTime | datetime | YES | - | NAME-INFERRED | Initial timestamp. |
| 18 | LimitRate | dtPrice | YES | - | CODE-BACKED | Take-profit rate. |
| 19 | StopRate | dtPrice | YES | - | CODE-BACKED | Stop-loss rate. |
| 20 | IsBuy | bit | YES | - | CODE-BACKED | 1=Buy, 0=Sell. |
| 21 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Whether to close at end of week. |
| 22 | Commission | money | YES | - | NAME-INFERRED | Commission amount. |
| 23 | SpreadedCommission | int | YES | - | NAME-INFERRED | Commission spread flag. |
| 24 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Additional parameters (parsed by Internal.ParseTradeAdditionalParam). |
| 25 | EndForexRate | dtPrice | YES | - | NAME-INFERRED | End forex rate at close. |
| 26 | RequestedEndForexRate | dtPrice | YES | - | CODE-BACKED | Requested close rate for close requests. |
| 27 | EndDateTime | datetime | YES | - | NAME-INFERRED | Close timestamp. |
| 28 | Occurred | datetime | NO | getdate() | CODE-BACKED | When the request was created. |
| 29 | TradeRange | int | YES | - | CODE-BACKED | Trade range identifier. Copied from Position for close requests. |
| 30 | ParentPositionID | bigint | YES | 1 | CODE-BACKED | Parent position in hierarchy. Default 1. |
| 31 | MirrorID | int | YES | 0 | CODE-BACKED | Mirror/copy relationship ID. Default 0. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit FK | Position being opened or closed |
| CID | Customer.CustomerStatic | Implicit FK | Customer |
| CurrencyID | Dictionary.Currency | Implicit FK | Currency lookup |
| ProviderID | (Provider table) | Implicit FK | Liquidity provider |
| InstrumentID | Dictionary.Instrument | Implicit FK | Instrument lookup |
| OrderID | Trade.OrderForOpen | Implicit FK | Associated order |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.PositionOpenRequestAdd | INSERT | WRITER | Inserts open requests |
| Trade.PositionCloseRequestAdd | INSERT/DELETE | WRITER | Inserts close requests; archives duplicates to History.PositionFailWrite |
| (execution jobs) | PositionID, RequestType | READER | Consume requests for execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionRequest (table)
<-- Trade.PositionOpenRequestAdd (WRITER)
<-- Trade.PositionCloseRequestAdd (WRITER)
<-- (Execution engine jobs - consume rows)
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|------------------|
| Trade.PositionTbl | Data (PositionID, TradeRange, ParentPositionID for close) |
| Internal.GetPositionID_Bigint | Open request PositionID generation |
| Internal.ParseTradeAdditionalParam | AdditionalParam parsing |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|------------------|
| History.PositionFailWrite | Archive target for duplicate close requests |
| Execution engine | Consumes rows for open/close |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Description |
|------------|------|-------------|-------------|
| PK_TPRQ | CLUSTERED PK | PositionID, RequestType | Primary key |
| TPRQ_CUSTOMER | NONCLUSTERED | CID | Customer lookup |
| TPRQ_INSTRUMENT | NONCLUSTERED | InstrumentID | Instrument lookup |

### 7.2 Constraints

| Constraint | Type | Description |
|------------|------|-------------|
| PK_TPRQ | PRIMARY KEY | (PositionID, RequestType) |
| TPRQ_OCCURRED | DEFAULT | getdate() for Occurred |
| DF_TradePositionRequest_ParentPositionID | DEFAULT | 1 for ParentPositionID |
| DF_TradePositionRequest_MirrorID | DEFAULT | 0 for MirrorID |
| TPRQ_REQUESTTYPE | CHECK | RequestType IN (1, 2) |

---

## 8. Sample Queries

```sql
-- Top 5 open requests by customer
SELECT TOP 5 PositionID, RequestType, CID, ProviderID, InstrumentID, Amount, Occurred
FROM   Trade.PositionRequest WITH (NOLOCK)
WHERE  RequestType = 1
ORDER  BY Occurred DESC;

-- Close requests for a position
SELECT PositionID, RequestType, RequestedEndForexRate, Occurred
FROM   Trade.PositionRequest WITH (NOLOCK)
WHERE  PositionID = @PositionID AND RequestType = 2;

-- Open requests by instrument
SELECT InstrumentID, COUNT(*) AS Cnt
FROM   Trade.PositionRequest WITH (NOLOCK)
WHERE  RequestType = 1
GROUP  BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.5/10 | Sources: DDL, PositionOpenRequestAdd, PositionCloseRequestAdd, CHECK constraint*
