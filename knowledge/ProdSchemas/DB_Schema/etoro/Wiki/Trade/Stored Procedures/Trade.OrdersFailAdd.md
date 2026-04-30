# Trade.OrdersFailAdd

> Records a failed position-open attempt to History.OrdersFail, enriching the record with the customer's current client version from Customer.Login.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID OUTPUT (defaults to -1 if NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersFailAdd is the explicit failure-logging companion to Trade.OrdersAdd. While Trade.OrdersAdd writes to its own CATCH block to log failures, other procedures in the order entry pipeline (Trade.OrderEntryOpen, Trade.OrderExitClose, Trade.OrderExitEdit, Trade.OrderExitOpen) call Trade.OrdersFailAdd directly to record position-open failures in History.OrdersFail.

The procedure captures the full order context at the time of failure, the fail reason string (VARCHAR(MAX)), and the customer's ClientVersion from Customer.Login - which is valuable for diagnosing client-specific issues (old app versions, browser quirks, etc.).

@RateFrom and @RateTo are rounded to 4 decimal places before insertion, normalizing precision regardless of how the caller computed them.

---

## 2. Business Logic

### 2.1 OrderID Null Handling

**What**: Normalizes a NULL @OrderID to -1.

**Columns/Parameters Involved**: `@OrderID OUTPUT`

**Rules**:
- IF @OrderID IS NULL: SET @OrderID = -1.
- -1 is the sentinel for "order was never created" - matches the pattern used in Trade.OrdersAdd's CATCH block (ISNULL(@OrderID,-1)).

### 2.2 ClientVersion Lookup and Failure Record Insert

**What**: Fetches the client version and writes the failure record.

**Columns/Parameters Involved**: `Customer.Login.ClientVersion`, `History.OrdersFail`

**Rules**:
- SELECT ClientVersion FROM Customer.Login NOLOCK WHERE CID=@CID.
- INSERT INTO History.OrdersFail with all order parameters + @FailReason + @ClientVersion + @ErrorCode.
- @RateFrom and @RateTo rounded to 4 decimal places via ROUND().
- OpenOccurredTime and FailOccurred both set to GETDATE().
- RETURN @@ERROR (0 on success).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | YES | - | CODE-BACKED | OUTPUT: the OrderID of the failed order. Set to -1 if NULL (order was never assigned an ID). Written to History.OrdersFail.OrderID. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to look up ClientVersion. Written to History.OrdersFail.CID. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Order currency. Written to History.OrdersFail.CurrencyID. |
| 4 | @ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider. Written to History.OrdersFail.ProviderID. |
| 5 | @OrderTypeID | INT | NO | - | CODE-BACKED | Order type. Written to History.OrdersFail.OrderTypeID. |
| 6 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument. Written to History.OrdersFail.InstrumentID. |
| 7 | @Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. Written to History.OrdersFail.Leverage. |
| 8 | @Amount | INT | NO | - | CODE-BACKED | Order amount. Written to History.OrdersFail.Amount. |
| 9 | @Units | INT | NO | - | CODE-BACKED | Order units. Written to History.OrdersFail.Units. |
| 10 | @UnitMargin | INT | NO | - | CODE-BACKED | Margin per unit. Written to History.OrdersFail.UnitMargin. |
| 11 | @LotCountDecimal | decimal(16,6) | NO | - | CODE-BACKED | Lot count. Written to History.OrdersFail.LotCountDecimal. |
| 12 | @RateFrom | dtPrice | NO | - | CODE-BACKED | Rate range lower bound. Rounded to 4dp before INSERT. Written to History.OrdersFail.RateFrom. |
| 13 | @RateTo | dtPrice | NO | - | CODE-BACKED | Rate range upper bound. Rounded to 4dp before INSERT. Written to History.OrdersFail.RateTo. |
| 14 | @IsBuy | BIT | NO | - | CODE-BACKED | Buy/Sell direction. Written to History.OrdersFail.IsBuy. |
| 15 | @ForexResultID | INT | YES | -1 | CODE-BACKED | ForexResult reference. Defaults to -1. |
| 16 | @GameID | INT | YES | 0 | CODE-BACKED | Game/demo account ID. |
| 17 | @SpreadID | INT | YES | 0 | CODE-BACKED | Spread configuration ID. |
| 18 | @LoginID | INT | YES | 0 | CODE-BACKED | Login session ID. |
| 19 | @IsOverWeekend | BIT | YES | 1 | CODE-BACKED | Weekend hold flag. |
| 20 | @StopLosAmount | INT | YES | 0 | CODE-BACKED | SL amount. |
| 21 | @TakeProfitAmount | INT | YES | 0 | CODE-BACKED | TP amount. |
| 22 | @MarketSpreadPips | INT | YES | 0 | CODE-BACKED | Market spread in pips. |
| 23 | @MarketSpreadCents | INT | YES | 0 | CODE-BACKED | Market spread in cents. |
| 24 | @StopLosRate | dtPrice | NO | - | CODE-BACKED | SL rate. Written to History.OrdersFail.StopLosRate. |
| 25 | @TakeProfitRate | dtPrice | NO | - | CODE-BACKED | TP rate. Written to History.OrdersFail.TakeProfitRate. |
| 26 | @TradeRange | INT | NO | - | CODE-BACKED | Slippage tolerance. |
| 27 | @ParentOrderID | INT | YES | 1 | CODE-BACKED | Parent order reference. |
| 28 | @FailReason | VARCHAR(MAX) | YES | 'unknown error' | CODE-BACKED | Description of why the order failed. Written to History.OrdersFail.FailReason. |
| 29 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | Trailing SL flag. Added FB-34563. |
| 30 | @AmountInUnitsDecimal | decimal(16,6) | YES | NULL | CODE-BACKED | Decimal units precision. Added FB-47233. |
| 31 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client deduplication GUID. Added FB-51445. |
| 32 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Numeric error code for the failure. Written to History.OrdersFail.ErrorCode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Login | Read NOLOCK | Retrieves ClientVersion for the failure record |
| @OrderID + all params | History.OrdersFail | Write | Main INSERT: failure audit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderEntryOpen | - | EXEC | Logs open entry failures |
| Trade.OrderEntryClose | - | EXEC | Logs close entry failures using this proc for order context |
| Trade.OrderExitClose | - | EXEC | Logs exit close failures |
| Trade.OrderExitEdit | - | EXEC | Logs order edit failures |
| Trade.OrderExitOpen | - | EXEC | Logs open exit failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersFailAdd (procedure)
├── Customer.Login (table)
└── History.OrdersFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | NOLOCK SELECT for ClientVersion |
| History.OrdersFail | Table | INSERTed with failed order record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderEntryOpen | Procedure | Calls on order open failure |
| Trade.OrderEntryClose | Procedure | Calls on order close failure (order context) |
| Trade.OrderExitClose | Procedure | Calls on exit close failure |
| Trade.OrderExitEdit | Procedure | Calls on order edit failure |
| Trade.OrderExitOpen | Procedure | Calls on exit open failure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction. RETURN @@ERROR (0 on success). No TRY/CATCH - errors propagate to caller.

---

## 8. Sample Queries

### 8.1 View recent failed order attempts

```sql
SELECT OrderID, CID, InstrumentID, IsBuy, Amount, FailReason, FailOccurred, ClientVersion, ErrorCode
FROM History.OrdersFail WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY FailOccurred DESC;
```

### 8.2 Find most common failure reasons

```sql
SELECT LEFT(FailReason, 100) AS FailReasonPrefix, COUNT(*) AS Count
FROM History.OrdersFail WITH (NOLOCK)
WHERE FailOccurred >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY LEFT(FailReason, 100)
ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 SP callers (OrderEntry/OrderExit family) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrdersFailAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersFailAdd.sql*
