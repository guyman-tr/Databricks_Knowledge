# Trade.OrdersMarketFailAdd

> Records a failed market-order execution attempt to History.OrdersMarketFail, capturing the full position context including copy-trade mirror linkage, SL/TP percentages, and the action type that was attempted.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID + @CID + @ActionTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersMarketFailAdd is the market-order failure logger, the counterpart to Trade.OrdersFailAdd for the market-order execution path. While Trade.OrdersFailAdd targets traditional limit-order opens (Trade.Orders), this procedure records failures in the market-order and position-action execution context (History.OrdersMarketFail).

It captures context specific to the eToro position model: PositionID (the existing position being acted upon for close/edit actions), ParentPositionID and MirrorID (copy-trade tree linkage), SL/TP as percentages (not rates), InitialMirrorAmountInCents (mirror state at time of action), MirrorCloseActionType, and OrderExitOpenActionType (what the exit attempted to do).

Called by Trade.OrderEntryClose, Trade.OrderExitClose, Trade.OrderExitEdit, and Trade.OrderExitOpen.

---

## 2. Business Logic

### 2.1 Market Failure Record Insert

**What**: Simple direct INSERT into History.OrdersMarketFail with all provided parameters.

**Columns/Parameters Involved**: All @* parameters -> `History.OrdersMarketFail` columns

**Rules**:
- INSERT INTO History.OrdersMarketFail with all parameters.
- No NULL normalization (unlike OrdersFailAdd which sets @OrderID=-1 if NULL).
- No ClientVersion lookup (unlike OrdersFailAdd - market fail records don't include client version).
- TRY/CATCH with bare THROW - errors propagate to caller unchanged.
- ActionTypeID comment indicates "OrderExitClose" as the primary use case.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The order ID of the failed market action. Written to History.OrdersMarketFail.OrderID. |
| 2 | @FailReason | varchar(max) | NO | - | CODE-BACKED | Description of the failure. Written to History.OrdersMarketFail.FailReason. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Written to History.OrdersMarketFail.CID. |
| 4 | @ActionTypeID | INT | NO | - | CODE-BACKED | Type of action that failed (e.g., OrderExitClose). Written to History.OrdersMarketFail.ActionTypeID. |
| 5 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | The position the action was applied to (BIGINT; changed from INT in 2021-11-16). Written to History.OrdersMarketFail.PositionID. |
| 6 | @OrdersType | INT | YES | NULL | CODE-BACKED | Order type context. Written to History.OrdersMarketFail.OrdersType. |
| 7 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session ID from calling context. Written to History.OrdersMarketFail.SessionID. |
| 8 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Instrument of the position. Written to History.OrdersMarketFail.InstrumentID. |
| 9 | @Leverage | INT | YES | NULL | CODE-BACKED | Leverage of the position. Written to History.OrdersMarketFail.Leverage. |
| 10 | @Amount | MONEY | YES | NULL | CODE-BACKED | Position amount in dollars. Written to History.OrdersMarketFail.Amount. |
| 11 | @IsBuy | BIT | YES | NULL | CODE-BACKED | Buy/sell direction. Written to History.OrdersMarketFail.IsBuy. |
| 12 | @StopLosPercentage | money | YES | NULL | CODE-BACKED | Stop Loss as a percentage of position value. Written to History.OrdersMarketFail.StopLosPercentage. |
| 13 | @TakeProfitPercentage | money | YES | NULL | CODE-BACKED | Take Profit as a percentage of position value. Written to History.OrdersMarketFail.TakeProfitPercentage. |
| 14 | @ParentPositionID | BIGINT | YES | NULL | CODE-BACKED | Parent position in the copy-trade tree. Written to History.OrdersMarketFail.ParentPositionID. |
| 15 | @MirrorID | INT | YES | NULL | CODE-BACKED | Copy-trade mirror ID this position belongs to. Written to History.OrdersMarketFail.MirrorID. |
| 16 | @InitialMirrorAmountInCents | money | YES | NULL | CODE-BACKED | The mirror's amount in cents at the time of the action. Written to History.OrdersMarketFail.InitialMirrorAmountInCents. |
| 17 | @MirrorCloseActionType | int | YES | NULL | CODE-BACKED | How the mirror close was initiated. Written to History.OrdersMarketFail.MirrorCloseActionType. |
| 18 | @OrderExitOpenActionType | int | YES | 0 | CODE-BACKED | Exit open action type (what was being attempted on exit). Written to History.OrdersMarketFail.OrderExitOpenActionType. |
| 19 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | Trailing SL flag. Added FB-34563. Written to History.OrdersMarketFail.IsTslEnabled. |
| 20 | @AmountInUnitsDecimal | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Decimal precision units. Added FB-47233. Written to History.OrdersMarketFail.AmountInUnitsDecimal. |
| 21 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client GUID for deduplication. Added FB-51445. Written to History.OrdersMarketFail.ClientRequestGuid. |
| 22 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Numeric error code for the failure. Written to History.OrdersMarketFail.ErrorCode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.OrdersMarketFail | Write | Single INSERT with failure record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderEntryClose | - | EXEC | Logs entry close failures |
| Trade.OrderExitClose | - | EXEC | Logs exit close failures |
| Trade.OrderExitEdit | - | EXEC | Logs order edit failures |
| Trade.OrderExitOpen | - | EXEC | Logs exit open failures |
| Trade.OrderEntryOpen | - | EXEC | Logs entry open failures for market orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersMarketFailAdd (procedure)
└── History.OrdersMarketFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersMarketFail | Table | INSERTed with failed market order record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderEntryClose | Procedure | Calls on market order close entry failure |
| Trade.OrderExitClose | Procedure | Calls on market order close exit failure |
| Trade.OrderExitEdit | Procedure | Calls on order edit failure |
| Trade.OrderExitOpen | Procedure | Calls on market order open exit failure |
| Trade.OrderEntryOpen | Procedure | Calls on market order open entry failure |
| Trade.OrderEntryClose | Procedure | (also calls Trade.OrdersFailAdd for order-level failures) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. TRY/CATCH with bare THROW. No transaction. No return value.

---

## 8. Sample Queries

### 8.1 Recent market order failures for a customer

```sql
SELECT OrderID, CID, ActionTypeID, PositionID, InstrumentID, FailReason,
       ErrorCode, Occurred, ClientRequestGuid
FROM History.OrdersMarketFail WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY Occurred DESC;
```

### 8.2 Failures by action type (last 24 hours)

```sql
SELECT ActionTypeID, COUNT(*) AS FailCount,
       LEFT(FailReason, 80) AS CommonReason
FROM History.OrdersMarketFail WITH (NOLOCK)
WHERE Occurred >= DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY ActionTypeID, LEFT(FailReason, 80)
ORDER BY FailCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 SP callers (OrderEntry/OrderExit family) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrdersMarketFailAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersMarketFailAdd.sql*
