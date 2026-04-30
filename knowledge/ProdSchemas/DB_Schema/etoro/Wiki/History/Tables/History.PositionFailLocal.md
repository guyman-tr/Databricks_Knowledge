# History.PositionFailLocal

> Forensic log of failed trading position operations - captures a complete snapshot of all position parameters at the moment a trade operation (open, close, edit, etc.) encountered a failure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionFailID (BIGINT IDENTITY, clustered PK with FailOccurred) |
| **Partition** | Yes - PS_EndMonth scheme on FailOccurred |
| **Indexes** | 1 (1 clustered) |

---

## 1. Business Meaning

`History.PositionFailLocal` records a full position-state snapshot every time a trading operation fails. When a position open, close, edit, or other operation encounters an error - whether from a rejected provider request, a validation failure, a missing price feed, or an internal system error - the system logs all position parameters here alongside the failure reason. The result is a complete forensic record: exactly what the system attempted, at what rates, for which customer and instrument, and why it failed.

This table is the primary investigation tool for failed trade operations. Operations teams and developers query it to diagnose production issues, characterize failure patterns by type and instrument, identify systematic failures (e.g., a provider consistently rejecting requests above a certain leverage), and assist in partial recovery scenarios. Without it, failed operations would disappear with no audit trail, making post-mortems impossible.

Data is written exclusively via the `History.PositionFailWrite` synonym (which resolves to this table), typically by `History.PostPositionFail` (called asynchronously from the trade engine via XML payload) or directly by Trade schema procedures. The table is partitioned by `FailOccurred` using the `PS_EndMonth` scheme for month-boundary partition management. The table is currently empty in this environment (prod activity only), but in production carries the complete history of all position failures.

---

## 2. Business Logic

### 2.1 Position Snapshot at Failure Time

**What**: The table captures all position parameters AS THEY WERE when the failure occurred, not as they ended up.

**Columns/Parameters Involved**: `InitForexRate`, `LimitRate`, `StopRate`, `Amount`, `AmountInUnitsDecimal`, `IsBuy`, `InitDateTime`, `EndForexRate`, `RequestedEndForexRate`

**Rules**:
- All rate/amount columns reflect the state at the time the operation was attempted
- `RequestedEndForexRate` captures what close rate was requested vs `EndForexRate` which is what was achieved (or NULL if failed before execution)
- `*UnAdjusted` variants (InitForexRateUnAdjusted, LimitRateUnAdjusted, etc.) capture the pre-adjustment rates before any price adjustment was applied, enabling comparison of raw vs adjusted values

**Diagram**:
```
Trade Engine attempts operation
    -> Failure occurs
    -> Snapshot all position parameters
    -> Insert into History.PositionFailWrite (= PositionFailLocal)
       with FailTypeID + FailReason + FailOccurred
```

### 2.2 Fail Type Classification

**What**: Each failure is classified by what operation was being attempted when it failed.

**Columns/Parameters Involved**: `FailTypeID`, `FailCategory`, `ErrorCode`, `FailReason`

**Rules**:
- `FailTypeID` (FK to Dictionary.FailType) identifies the operation type that failed
- `FailReason` is a free-text description (varchar MAX) of what went wrong
- `ErrorCode` is a numeric error code (application-defined, not SQL error number)
- `FailCategory` provides a higher-level grouping of the failure (int, lookup not discovered)

**FailTypeID values (Dictionary.FailType)**:
```
1  = Request To Open       (open request rejected before execution)
2  = Request To Close      (close request rejected)
3  = Open                  (open operation failed mid-execution)
4  = Close                 (close operation failed mid-execution)
5  = Edit                  (edit stop-loss/take-profit failed)
6  = External Error        (error from external system/provider)
7  = Internal Error        (internal system failure)
8  = MM object disconnected from its parent
9  = MM Max StopLoss       (mirror max stop-loss exceeded)
10 = Min Position Amount   (below minimum size)
11 = Mirror edit StopLoss insufficient funds
12 = Max position amount in units
13 = Max Take Profit reached
14 = PositionRedeemCancelFail
15 = PositionRedeemPendingFail
16 = PositionRedeemCloseFail
17 = Detach                (detach from mirror failed)
```

### 2.3 Adjusted vs Unadjusted Rate Tracking

**What**: The table stores both adjusted and unadjusted versions of key rates/amounts to track what adjustments were applied.

**Columns/Parameters Involved**: `InitForexRate` + `InitForexRateUnAdjusted`, `LimitRate` + `LimitRateUnAdjusted`, `StopRate` + `StopRateUnAdjusted`, `AmountInUnitsDecimal` + `AmountInUnitsDecimalUnAdjusted`, `LotCountDecimal` + `LotCountDecimalUnAdjusted`, `EndForexRate` + `EndForexRateUnAdjusted`

**Rules**:
- `*UnAdjusted` columns capture raw values before price/amount adjustment was applied
- Difference between adjusted and unadjusted reveals the magnitude of applied adjustment
- NULL in `*UnAdjusted` means no adjustment was applied (or predates this feature)

### 2.4 Write via Synonym

**What**: Writes go through a synonym for abstraction between writer processes and the physical table.

**Columns/Parameters Involved**: (all columns)

**Rules**:
- `History.PositionFailWrite` is a synonym for `History.PositionFailLocal`
- Writer processes (`History.PostPositionFail`, Trade procedures) INSERT into `History.PositionFailWrite`
- This allows the physical table to be replaced or rerouted without changing writer code
- `AdditionalParam` (sql_variant) defaults to `'DB_Direct'` when NULL, indicating direct DB insertion (not via service)

---

## 3. Data Overview

Table is empty in current environment (production activity only). Representative pattern based on schema design and writer procedure `History.PostPositionFail`:

| PositionFailID | PositionID | FailTypeID | CID | InstrumentID | IsBuy | FailOccurred | FailReason | ErrorCode |
|---|---|---|---|---|---|---|---|---|
| 10001 | 987654321 | 3 | 5000123 | 50 | 1 | 2025-03-15 14:23:01 | Provider rejected: price moved 0.5% during execution | 1042 |
| 10002 | 0 | 1 | 5000456 | 7 | 0 | 2025-03-15 14:23:05 | Insufficient margin for leverage requested | 2001 |

*Note: Table is empty in this environment. Rows above are illustrative of the failure log pattern.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionFailID | bigint IDENTITY(1,1) | NO | auto | CODE-BACKED | Auto-incrementing surrogate PK. Part of the clustered composite key (PositionFailID, FailOccurred). Uniquely identifies each failure event. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | ID of the position involved in the failed operation. NULL when the failure occurred before a PositionID was assigned (e.g., during a pre-open request that was rejected). Implicit FK to Trade.PositionTbl and History equivalents. |
| 3 | FailTypeID | int | NO | - | VERIFIED | Type of operation that failed. FK to Dictionary.FailType: 1=Request To Open, 2=Request To Close, 3=Open, 4=Close, 5=Edit, 6=External Error, 7=Internal Error, 8=MM object disconnected, 9=MM Max StopLoss, 10=Min Position Amount, 11=Mirror edit SL insufficient funds, 12=Max position amount in units, 13=Max Take Profit reached, 14=PositionRedeemCancelFail, 15=PositionRedeemPendingFail, 16=PositionRedeemCloseFail, 17=Detach. |
| 4 | CID | int | YES | - | NAME-INFERRED | Customer account ID of the position owner. Implicit FK to customer table. |
| 5 | ForexResultID | bigint | YES | - | NAME-INFERRED | ID of the forex result/pricing event associated with this operation. References the price engine result set. |
| 6 | CurrencyID | int | YES | - | NAME-INFERRED | Currency denomination of the position's account. Implicit FK to Dictionary.Currency. |
| 7 | ProviderID | int | YES | - | NAME-INFERRED | Liquidity provider or market maker assigned to this position. Implicit FK to provider lookup. |
| 8 | GameServerID | int | YES | - | NAME-INFERRED | ID of the trading engine game server that processed this operation. |
| 9 | InstrumentID | int | YES | - | NAME-INFERRED | Financial instrument being traded (stock, currency pair, crypto, commodity). Implicit FK to instrument lookup. |
| 10 | HedgeID | int | YES | - | NAME-INFERRED | ID of the associated hedge order in the hedge engine, if this position was hedged. NULL for non-hedged positions. |
| 11 | HedgeServerID | int | YES | - | NAME-INFERRED | ID of the hedge server handling the hedge side of this position. Added 2019-10-22. |
| 12 | OrderID | int | YES | - | NAME-INFERRED | ID of the pending order associated with this position operation, if triggered by an order. |
| 13 | Leverage | int | YES | - | NAME-INFERRED | Leverage multiplier applied to this position (e.g., 2=2x, 10=10x). |
| 14 | Amount | money | YES | - | CODE-BACKED | Position size in the account's base currency (stored in cents). The notional investment amount. |
| 15 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size expressed in instrument units with 6 decimal places. For stocks: number of shares. For forex: lot size. Used alongside AmountInUnitsDecimalUnAdjusted. |
| 16 | UnitMargin | int | YES | - | NAME-INFERRED | Margin requirement per unit as an integer value. |
| 17 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Number of lots for this position with 6 decimal precision. Related to AmountInUnitsDecimal scaled by lot size. |
| 18 | NetProfit | money | YES | - | CODE-BACKED | Unrealized or realized P&L at time of failure, in cents (per comment in History.PostPositionFail: "IN CENTS"). |
| 19 | InitForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Opening price rate of the position (dbo.dtPrice UDT). The rate at which the position was opened or was being opened. |
| 20 | InitDateTime | datetime | YES | - | CODE-BACKED | Timestamp when the position was opened or when the open was initiated. |
| 21 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate set on this position (dbo.dtPrice UDT). NULL if no take-profit was set. |
| 22 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate set on this position (dbo.dtPrice UDT). NULL if no stop-loss was set. |
| 23 | IsBuy | bit | YES | - | CODE-BACKED | Trade direction: 1=Buy (Long), 0=Sell (Short). |
| 24 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Whether this position was configured to automatically close at end of trading week: 1=Yes, 0=No. |
| 25 | EndOfWeekFee | money | YES | - | NAME-INFERRED | End-of-week overnight fee charged for holding the position over the weekend, in money units. |
| 26 | Commission | money | YES | - | CODE-BACKED | Opening commission charged for this position, in money units. |
| 27 | CommissionOnClose | money | YES | - | CODE-BACKED | Commission to be charged on close of this position, in money units. |
| 28 | SpreadedCommission | int | YES | - | NAME-INFERRED | Spread-based commission component as an integer value. |
| 29 | EndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Actual closing price rate achieved (or attempted) at time of failure (dbo.dtPrice UDT). NULL if failure occurred before any close rate was established. |
| 30 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The close rate requested by the client or system before execution. May differ from EndForexRate due to slippage or rejection (dbo.dtPrice UDT). |
| 31 | EndDateTime | datetime | YES | - | CODE-BACKED | Timestamp of the close or attempted close at time of failure. NULL for open failures. |
| 32 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Free-form additional context parameter. Defaults to 'DB_Direct' when NULL (meaning the insert came directly from DB rather than a service). sql_variant type allows any scalar value. |
| 33 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the open request was received by the system (before execution began). Enables measurement of request-to-execution latency. |
| 34 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the close request was received by the system. NULL for open failures. |
| 35 | OpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the position actually opened successfully (before the failure occurred on a subsequent operation). NULL if failure occurred during open itself. |
| 36 | FailReason | varchar(max) | YES | - | CODE-BACKED | Free-text description of why the operation failed. Written by the trade engine or service layer. Contains error messages, validation failure reasons, or provider rejection messages. |
| 37 | FailOccurred | datetime2(7) | NO | getdate() | CODE-BACKED | Timestamp when the failure was recorded. Partition key for PS_EndMonth partitioning. NOT NULL with DEFAULT getdate(). Note: getdate() not getutcdate() - uses server local time. Part of the composite clustered PK. |
| 38 | TradeRange | int | YES | - | NAME-INFERRED | Trade range or price range tolerance configured at time of the operation. |
| 39 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | ID referencing the price feed rate record used as the opening rate. NOT NULL - required for audit. Links to the price rate history for traceability. |
| 40 | OrderPriceRateID | bigint | NO | - | CODE-BACKED | ID of the price rate record used for the order's execution price. NOT NULL. |
| 41 | EndForexPriceRateID | bigint | NO | - | CODE-BACKED | ID of the price rate record used for the closing rate. NOT NULL - even if close failed, a rate ID is captured. |
| 42 | OrderPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | The actual order execution price at which the operation was attempted (dbo.dtPrice UDT). NOT NULL. |
| 43 | ParentPositionID | bigint | YES | 1 | CODE-BACKED | ID of the parent (copy-from) position in a CopyTrader hierarchy. Default 1 indicates no parent (1 is the sentinel value for "no parent/standalone position"). |
| 44 | OrigParentPositionID | bigint | YES | 1 | CODE-BACKED | Original parent position ID before any detach operations. Allows tracking the original copy relationship even after detachment. Default 1 = no parent. |
| 45 | LastOpPriceRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Price rate of the most recent successful operation prior to this failure (dbo.dtPrice UDT). Default 0. Enables comparison of current vs last known good rate. |
| 46 | LastOpPriceRateID | bigint | YES | 0 | CODE-BACKED | ID of the price record for LastOpPriceRate. Default 0. |
| 47 | LastOpConversionRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Currency conversion rate from the most recent operation, used for PnL calculation in account currency (dbo.dtPrice UDT). Default 0. |
| 48 | LastOpConversionRateID | bigint | YES | 0 | CODE-BACKED | ID of the conversion rate record for LastOpConversionRate. Default 0. |
| 49 | MirrorID | int | YES | 0 | CODE-BACKED | ID of the CopyTrader mirror (portfolio copy) this position belongs to. Default 0 = not in a mirror/copy relationship. |
| 50 | StocksOrderID | int | YES | - | NAME-INFERRED | Order ID for the underlying stock exchange order, used for real stock (non-CFD) positions. NULL for CFD positions. |
| 51 | IsOpenOpen | bit | YES | - | CODE-BACKED | Indicates whether the position was in an "open-open" state (a specific intermediate state during the open flow). Passed from the trading engine XML payload. |
| 52 | ClientVersion | varchar(20) | YES | - | NAME-INFERRED | Version string of the client application that initiated this operation. Note: ClientVersion is COMMENTED OUT in the History.PostPositionFail INSERT statement - this column may not be populated by that path. |
| 53 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Raw AmountInUnitsDecimal before any adjustment was applied. Enables comparison of requested vs adjusted unit count. NULL if no adjustment. |
| 54 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Raw LotCountDecimal before adjustment. Paired with LotCountDecimal to show lot-level adjustment impact. |
| 55 | InitForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Raw opening rate before price adjustment (dbo.dtPrice UDT). Captures the pre-adjustment price for audit of applied adjustments. |
| 56 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Raw take-profit rate before adjustment (dbo.dtPrice UDT). NULL if no take-profit set or no adjustment applied. |
| 57 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Raw stop-loss rate before adjustment (dbo.dtPrice UDT). NULL if no stop-loss set or no adjustment applied. |
| 58 | EndForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Raw closing rate before adjustment (dbo.dtPrice UDT). Enables comparison of adjusted vs unadjusted close rate. |
| 59 | ClosePositionActionTypeID | bigint | YES | - | VERIFIED | Reason/trigger for the close attempt. FK to Dictionary.ClosePositionActionType (PK column is ID): 0=Customer, 1=Stop Loss, 2=End of Week, 3=Stop Loss via trade server, 4=Return to Market, 5=Take Profit, 6=Take Profit via trade server, 7=Contract Rollover, 8=BackOffice User, 9=Hierarchical Close, 10=Hierarchical close by recovery, 11=Join Demo Challenge, 12=Close All, 13=Copy Stop Loss, 14=Mirror position manual close, 15=Manual Liquidation, 16=BSL, 17=Manual Unregister, 18=BackOffice Unregister, 19=Redeem, 20=Operational position adjustment, 21=Orphaned position, 22=Transferred Out, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. NULL for non-close failures. |
| 60 | OrderType | int | YES | - | NAME-INFERRED | Type of order (market order, limit order, etc.) if this failure was triggered by an order. NULL for non-order operations. |
| 61 | ExitOrderID | int | YES | - | NAME-INFERRED | ID of the exit/close order that triggered this failure, if applicable. |
| 62 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Trailing Stop Loss enabled flag at time of failure: 0=disabled, non-zero=enabled. NOT NULL with DEFAULT 0. |
| 63 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Unique GUID sent by the client application for this request. Enables idempotency checking and request tracing across systems. Added 2018-05-01 (FB:51172). |
| 64 | ReopenForPositionID | bigint | YES | - | NAME-INFERRED | If this failure occurred during a reopen operation, this is the PositionID being reopened. NULL for non-reopen scenarios. |
| 65 | ClientViewRateID | bigint | YES | - | CODE-BACKED | ID of the price rate displayed to the client in the UI at the time of the request. Added 2018-12-18 (FB 53286). |
| 66 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Price rate shown to the client in the UI at the time of the request. Used to detect discrepancies between client-visible price and execution price. Added 2018-12-18 (FB 53286). |
| 67 | ClientRateForCalcID | bigint | YES | - | CODE-BACKED | ID of the rate used for client-side calculations (e.g., PnL preview). Added 2018-12-18 (FB 53286). |
| 68 | ClientRateForCalc | decimal(16,6) | YES | - | CODE-BACKED | Rate used by the client for pre-submission calculations. May differ from execution rate, enabling client-rate vs server-rate auditing. Added 2018-12-18 (FB 53286). |
| 69 | ExecutionID | bigint | YES | - | CODE-BACKED | ID of the execution event in the execution engine. Added 2019-10-22 alongside HedgeServerID. |
| 70 | ErrorCode | int | YES | - | CODE-BACKED | Numeric application error code for this failure. Application-defined (not SQL error number). Useful for programmatic failure classification. |
| 71 | FailCategory | int | YES | - | NAME-INFERRED | Higher-level category grouping the failure (e.g., infrastructure, business logic, provider rejection). Exact values not resolved from available code. |
| 72 | ExitOrderType | int | YES | - | NAME-INFERRED | Type of exit order that triggered this close failure. Distinct from OrderType - specifically for exit/close side orders. |
| 73 | SessionID | bigint | YES | - | CODE-BACKED | Session ID of the trading session in which this operation occurred. Added to enable session-level failure analysis. |
| 74 | SnapshotTimestamp | datetime | YES | - | NAME-INFERRED | Timestamp of a state snapshot taken around the time of failure. May capture system state at a slightly different moment than FailOccurred. |
| 75 | PriceType | int | YES | - | NAME-INFERRED | Type of price used for this operation (e.g., bid, ask, mid). Exact values not resolved from available code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FailTypeID | Dictionary.FailType | Implicit FK | Classification of the operation type that failed |
| CID | Customer table | Implicit | Customer who owns the position |
| InstrumentID | Instrument lookup | Implicit | Financial instrument being traded |
| CurrencyID | Dictionary.Currency | Implicit | Account denomination currency |
| ClosePositionActionTypeID | Dictionary.ClosePositionActionType | Implicit FK | What triggered the close attempt (NULL for non-close failures) |
| PositionID | Trade.PositionTbl / History.ClosedPositions equivalents | Implicit | The position involved in the failure |
| InitForexPriceRateID / OrderPriceRateID / EndForexPriceRateID | Price rate history | Implicit | Traceable price records at time of failure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionFailWrite | (synonym) | Synonym | Alias used by all writer processes - resolves to this table |
| History.PostPositionFail | INSERT via PositionFailWrite | WRITER | Primary write path - inserts failure records via XML payload |
| History.PositionFailInfo | SELECT | READER | Retrieves failure info by PositionID/FailTypeID |
| History.AdminPositionFailInfo | SELECT | READER | Admin view of failure records |
| History.PositionAirdropFailInfo | SELECT | READER | Airdrop-specific failure queries |
| History.PositionFailInfo_Get | SELECT | READER | Get failure records by ID |
| dbo.SSRS_FailedPosition | SELECT | READER | SSRS report for failed positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFailLocal (table)
(leaf - no code-level dependencies)
```

This object has no code-level dependencies. All relationships are implicit FK lookups or application-layer references.

---

### 6.1 Objects This Depends On

No dependencies. (No explicit FK constraints. No computed columns referencing other objects.)

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFailWrite | Synonym | Alias that resolves to this table - all writers use this synonym |
| History.PostPositionFail | Stored Procedure | WRITER - primary insert path via XML params |
| History.PositionFailInfo | Stored Procedure | READER - retrieves failure records |
| History.AdminPositionFailInfo | Stored Procedure | READER - admin failure queries |
| History.PositionAirdropFailInfo | Stored Procedure | READER - airdrop failure queries |
| History.PositionFailInfo_Get | Stored Procedure | READER - get by ID |
| History.InsertFailPositionToAzure | Stored Procedure | READER/WRITER - Azure sync |
| dbo.SSRS_FailedPosition | Stored Procedure | READER - SSRS reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradePositionTbl_BIGINT | CLUSTERED PK | PositionFailID ASC, FailOccurred ASC | - | - | Active |

*FILLFACTOR=90, DATA_COMPRESSION=PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY=ON. Partitioned on PS_EndMonth(FailOccurred).*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PositionFail_FailOccurred | DEFAULT | `getdate()` on FailOccurred - auto-sets failure timestamp to current local time |
| DF_PositionFail_ParentPositionID | DEFAULT | `1` on ParentPositionID - sentinel value indicating no copy-trade parent |
| DF_PositionFail_OrigParentPositionID | DEFAULT | `1` on OrigParentPositionID - sentinel value indicating no original parent |
| DF_PositionFail_LastOpPriceRate | DEFAULT | `0` on LastOpPriceRate |
| DF_PositionFail_LastOpPriceRateID | DEFAULT | `0` on LastOpPriceRateID |
| DF_PositionFail_LastOpConversionRate | DEFAULT | `0` on LastOpConversionRate |
| DF_PositionFail_LastOpConversionRateID | DEFAULT | `0` on LastOpConversionRateID |
| DF_PositionFail_MirrorID | DEFAULT | `0` on MirrorID - 0 means not in a mirror |
| DF_PositionFail_IsTslEnabled | DEFAULT | `0` on IsTslEnabled - default: TSL disabled |

---

## 8. Sample Queries

### 8.1 Get all failures for a specific position

```sql
SELECT
    pfl.PositionFailID,
    pfl.PositionID,
    ft.Name AS FailTypeName,
    pfl.FailReason,
    pfl.ErrorCode,
    pfl.FailOccurred,
    pfl.IsBuy,
    pfl.InitForexRate,
    pfl.EndForexRate
FROM History.PositionFailLocal pfl WITH (NOLOCK)
LEFT JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = pfl.FailTypeID
WHERE pfl.PositionID = @PositionID
ORDER BY pfl.FailOccurred ASC
```

### 8.2 Summarize recent failures by type (last 30 days)

```sql
SELECT
    ft.Name AS FailTypeName,
    pfl.ErrorCode,
    COUNT(*) AS FailureCount,
    MIN(pfl.FailOccurred) AS FirstSeen,
    MAX(pfl.FailOccurred) AS LastSeen
FROM History.PositionFailLocal pfl WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = pfl.FailTypeID
WHERE pfl.FailOccurred >= DATEADD(DAY, -30, GETDATE())
GROUP BY ft.Name, pfl.ErrorCode
ORDER BY FailureCount DESC
```

### 8.3 Failed close operations with close action context

```sql
SELECT
    pfl.PositionFailID,
    pfl.PositionID,
    pfl.CID,
    pfl.InstrumentID,
    cat.ClosePositionActionName,
    pfl.RequestedEndForexRate,
    pfl.EndForexRate,
    pfl.FailReason,
    pfl.FailOccurred
FROM History.PositionFailLocal pfl WITH (NOLOCK)
JOIN Dictionary.ClosePositionActionType cat WITH (NOLOCK)
    ON cat.ID = pfl.ClosePositionActionTypeID
WHERE pfl.FailTypeID IN (2, 4)  -- Request To Close or Close failures
  AND pfl.FailOccurred >= DATEADD(DAY, -7, GETDATE())
ORDER BY pfl.FailOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 8.3/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 10 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (PostPositionFail, PositionFailInfo) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFailLocal | Type: Table | Source: etoro/etoro/History/Tables/History.PositionFailLocal.sql*
