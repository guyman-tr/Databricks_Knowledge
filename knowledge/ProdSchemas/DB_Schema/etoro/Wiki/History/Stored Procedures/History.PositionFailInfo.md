# History.PositionFailInfo

> Async position fail recorder - collects the full state snapshot of a failed position operation, builds an XML payload with ActionID=5, and enqueues it via Trade.InsertAsyncRecord for asynchronous insertion into the History.PositionFail table by a background processor.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID + @FailTypeID + @CID - identifies which position failed, the failure type, and the customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionFailInfo` captures the failure of a trading operation (open or close attempt) at the point of failure. When the trading engine detects that a position cannot be opened or closed (due to insufficient margin, market conditions, validation failure, etc.), it calls this procedure to record the full position state at the time of failure.

The procedure does NOT directly write to any History table. Instead, it builds a comprehensive XML payload and enqueues it via `Trade.InsertAsyncRecord` (ActionID=5) for asynchronous processing. The background job picks up this record and inserts it into `History.PositionFail` (via the synonym). This asynchronous approach prevents failure recording from blocking the trading path - the failure is logged without adding latency to the main transaction.

Data flow: (1) Lookup OrigParentPositionID and UnAdjusted rate fields from Trade.PositionTbl (using partition elimination on PositionID%50); (2) if not found in Trade.PositionTbl, try History.Position_Active; (3) if still null, default @OrigParentPositionID = @ParentPositionID; (4) build XML payload with ActionID=5 and all position state fields (Amount and NetProfit divided by 100 - converting cents to standard units for XML); (5) EXEC Trade.InsertAsyncRecord @CID, 5, @Params1, 0, 0, 0 to enqueue; (6) RETURN 0. On any error: RAISERROR 60000 and RETURN 60000.

History note: Long evolution - added ClientVersion (2013, FB 14550), async processing path (2013, FB 16683), SessionID and ClosePositionActionTypeID (2014), OrderType (2015), History.Position_Active instead of view (2018, FB 50211), ClientRequestGuid (2018, FB 51172), async close condition (2018, FB 52337), ClientViewRate params (2018, FB 53286), partition elimination (2021-03-07), PositionID to BIGINT (2021-11-17).

---

## 2. Business Logic

### 2.1 OrigParentPositionID Resolution

**What**: The OrigParentPositionID (original parent at open time, before any detachments) must be resolved from the active position tables since it's not always passed by the caller.

**Columns/Parameters Involved**: `@OrigParentPositionID`, `@PositionID`, `@ParentPositionID`

**Rules**:
- First try Trade.PositionTbl with partition elimination: WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50 (@@ROWCOUNT=0 if not found)
- If not found in Trade.PositionTbl: try History.Position_Active WHERE PositionID=@PositionID
- If still NULL (position not found anywhere): SET @OrigParentPositionID = @ParentPositionID (fallback)
- Also reads AmountInUnitsDecimalUnAdjusted, InitForexRateUnAdjusted, LimitRateUnAdjusted, StopRateUnAdjusted from whichever table succeeds

### 2.2 Async Fail Record Enqueueing (ActionID=5)

**What**: All parameters are serialized to XML and inserted into the Trade async queue for background processing into History.PositionFail.

**Columns/Parameters Involved**: All parameters, `@Params` (XML), `Trade.InsertAsyncRecord`

**Rules**:
- ActionID=5 in the XML payload identifies this as a PositionFail async record
- Amount conversion: @Amount / 100 in XML (input is in cents, XML stores in dollar units)
- NetProfit conversion: @NetProfit / 100 in XML (input is in cents, XML stores in dollar units)
- Comment in DDL: "@NetProfit -- IN CENTS" - confirms input unit
- FaileOccurred (note: typo in original code - "FaileOccurred" not "FailerOccurred") is set to GETUTCDATE() in the XML - captures when the failure was recorded
- EXEC Trade.InsertAsyncRecord @CID, 5, @Params1, 0, 0, 0 - enqueues for async background processing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | The position ID of the failed operation. Changed to BIGINT on 2021-11-17. Used as the primary identifier in the XML payload and for lookup in Trade.PositionTbl. |
| 2 | @FailTypeID | INT | NO | - | VERIFIED | Type of failure that occurred. References Dictionary.FailType lookup. Included in the XML payload for categorization by the async processor. |
| 3 | @CID | INT | NO | - | VERIFIED | Customer ID. Used as the primary routing key for Trade.InsertAsyncRecord and included in XML payload. |
| 4 | @ForexResultID | BIGINT | NO | - | VERIFIED | The ForexResult (game context) ID for the failed operation. |
| 5 | @CurrencyID | INT | NO | - | VERIFIED | Account currency ID. |
| 6 | @ProviderID | INT | NO | - | VERIFIED | Market data provider / trading platform ID. |
| 7 | @GameServerID | INT | NO | - | VERIFIED | Game server that processed the operation. |
| 8 | @InstrumentID | INT | NO | - | VERIFIED | Financial instrument (stock, currency pair, crypto, etc.) for the failed position. |
| 9 | @HedgeID | INT | NO | - | VERIFIED | Hedge order ID associated with the position attempt. |
| 10 | @Leverage | INT | NO | - | VERIFIED | Leverage applied to the position. |
| 11 | @Amount | MONEY | NO | - | CODE-BACKED | Invested amount IN CENTS (as noted in DDL comment for @NetProfit). Divided by 100 in XML payload to convert to dollar units. |
| 12 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | VERIFIED | Position size in instrument units. |
| 13 | @UnitMargin | INT | NO | - | VERIFIED | Margin per unit required for this position. |
| 14 | @LotCountDecimal | DECIMAL(16,6) | NO | - | VERIFIED | Position size in lots. |
| 15 | @NetProfit | MONEY | NO | - | CODE-BACKED | Net profit at time of failure, IN CENTS (per DDL comment "IN CENTS"). Divided by 100 in XML payload to convert to dollar units. For open failures, this is typically 0. |
| 16 | @InitForexRate | dtPrice | NO | - | VERIFIED | Opening exchange rate for the position attempt. |
| 17 | @InitDateTime | DATETIME | NO | - | VERIFIED | DateTime of the open request. |
| 18 | @LimitRate | dtPrice | NO | - | VERIFIED | Take profit rate set for the position. |
| 19 | @StopRate | dtPrice | NO | - | VERIFIED | Stop loss rate set for the position. |
| 20 | @IsBuy | BIT | NO | - | VERIFIED | 1 = Buy (Long) direction, 0 = Sell (Short). |
| 21 | @CloseOnEndOfWeek | BIT | NO | - | VERIFIED | Whether position would auto-close at end of trading week. |
| 22 | @Commission | MONEY | NO | - | VERIFIED | Spread/commission amount for the position. |
| 23 | @CommissionOnClose | MONEY | NO | - | VERIFIED | Commission charged on close (deferred commission). |
| 24 | @SpreadedCommission | INT | NO | - | VERIFIED | Spreaded commission in points/pips. |
| 25 | @EndForexRate | dtPrice | NO | - | VERIFIED | Closing exchange rate (at time of close attempt; 0 for open failures). |
| 26 | @RequestedEndForexRate | dtPrice | NO | - | VERIFIED | Rate requested by client for close; may differ from market rate. |
| 27 | @EndDateTime | DATETIME | NO | - | VERIFIED | DateTime of the close request (for close failures; InitDateTime for open failures). |
| 28 | @AdditionalParam | SQL_VARIANT | NO | - | NAME-INFERRED | Additional context parameter; SQL_VARIANT allows any type. Typically NULL for most failure scenarios. |
| 29 | @RequestOpenOccurred | DATETIME | NO | - | VERIFIED | UTC timestamp when the open request was received. |
| 30 | @RequestCloseOccurred | DATETIME | NO | - | VERIFIED | UTC timestamp when the close request was received (NULL for open failures). |
| 31 | @OpenOccurred | DATETIME | NO | - | VERIFIED | UTC timestamp when position actually opened (NULL for open failures). |
| 32 | @FailReason | VARCHAR(MAX) | NO | - | VERIFIED | Human-readable or system-provided reason for the failure. Stored in the XML for human-readable diagnostics. |
| 33 | @InitForexPriceRateID | BIGINT | NO | - | VERIFIED | Rate ID for the opening exchange rate snapshot. |
| 34 | @EndForexPriceRateID | BIGINT | NO | - | VERIFIED | Rate ID for the closing exchange rate snapshot. |
| 35 | @OrderPriceRateID | BIGINT | NO | - | VERIFIED | Rate ID for the order price rate. |
| 36 | @OrderPriceRate | dtPrice | NO | - | VERIFIED | Order price rate. |
| 37 | @OrderID | INT | YES | NULL | VERIFIED | Order ID associated with the position attempt. NULL if no specific order. |
| 38 | @ParentPositionID | BIGINT | YES | 0 | VERIFIED | Parent position ID for copy/mirror positions. 0 = not a copy position. |
| 39 | @OrigParentPositionID | BIGINT | YES | NULL | CODE-BACKED | Original parent position ID. Resolved by the procedure from Trade.PositionTbl or History.Position_Active if NULL on input. Falls back to @ParentPositionID. |
| 40 | @LastOpPriceRate | dtPrice | YES | 0 | VERIFIED | Price rate at time of last operation on this position. |
| 41 | @LastOpPriceRateID | BIGINT | YES | 0 | VERIFIED | Rate ID for last operation price rate. |
| 42 | @LastOpConversionRate | dtPrice | YES | 0 | VERIFIED | Currency conversion rate at last operation. |
| 43 | @LastOpConversionRateID | BIGINT | YES | 0 | VERIFIED | Rate ID for last operation conversion rate. |
| 44 | @MirrorID | INT | YES | 0 | VERIFIED | Mirror relationship ID. 0 = not mirrored. |
| 45 | @IsOpenOpen | BIT | YES | 0 | CODE-BACKED | Whether this was an "open open" (pre-market / pending open) position attempt. |
| 46 | @SessionID | BIGINT | YES | 0 | VERIFIED | Trading session ID for the failed operation. |
| 47 | @ClosePositionActionTypeID | INT | YES | NULL | VERIFIED | Type of close action attempted (manual, SL, TP, etc.). NULL for open failures. |
| 48 | @OrderType | INT | YES | NULL | VERIFIED | Order type (market, limit, etc.) for the failed operation. |
| 49 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | VERIFIED | Client request GUID for idempotency. Added FB 51172. |
| 50 | @ClientViewRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID visible to the client in the UI. Added FB 53286. |
| 51 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate displayed to client in UI at time of failure. |
| 52 | @ClientRateForCalcID | BIGINT | YES | NULL | CODE-BACKED | Rate ID used for client-side calculations. |
| 53 | @ClientRateForCalc | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate used for client-side calculations. |
| 54 | @HedgeServerID | BIGINT | YES | NULL | VERIFIED | Hedge server ID that processed the order. |
| 55 | @ExecutionID | BIGINT | YES | NULL | VERIFIED | Execution ID from the execution engine (if applicable). |
| 56 | @ErrorCode | INT | YES | NULL | VERIFIED | System error code returned by the execution engine at the point of failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionTbl | Lookup | SELECT OrigParentPositionID and UnAdjusted rates WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50 (partition elimination) |
| @PositionID | History.Position_Active | Lookup | Fallback lookup for OrigParentPositionID and UnAdjusted rates if not found in Trade.PositionTbl |
| @CID + ActionID=5 + XML | Trade.InsertAsyncRecord | Procedure call | Enqueues the XML payload for async processing by the background PositionFail insertion job |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionAirdropFailInfo | (body) | Calls (EXEC) | Calls this procedure to record airdrop-specific position fail events |
| Trading engine (application) | - | External caller | Primary caller for all standard position open/close failure scenarios |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFailInfo (procedure)
+-- Trade.PositionTbl (table, cross-schema)
+-- History.Position_Active (table)
+-- Trade.InsertAsyncRecord (procedure, cross-schema)
      (enqueues ActionID=5 for async insertion into History.PositionFail via synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table (cross-schema) | Lookup for OrigParentPositionID and UnAdjusted rate fields using partition elimination |
| History.Position_Active | Table | Fallback lookup for same fields when position not in Trade.PositionTbl |
| Trade.InsertAsyncRecord | Procedure (cross-schema) | Enqueues the position fail XML record for asynchronous processing |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionAirdropFailInfo | Procedure | Calls History.PositionFailInfo to record airdrop fail events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Amount/NetProfit unit conversion | Implementation | @Amount and @NetProfit inputs are in CENTS; divided by 100 in XML to store in dollar units |
| PartitionCol = @PositionID%50 | Optimization | Partition elimination for Trade.PositionTbl lookup - avoids full-table scan across 50 partitions |
| No direct History write | Design | This procedure never writes to any History.* table directly; all writes are async via Trade.InsertAsyncRecord + background processor |
| Error 60000 | RAISERROR | Any exception raises error 60000 and returns the same code to caller |

---

## 8. Sample Queries

### 8.1 Check recent fail records for a position (via async processing result)

```sql
SELECT pf.PositionID, pf.FailTypeID, pf.CID, pf.FailReason, pf.FailOccurred,
       ft.Name AS FailTypeName
FROM History.PositionFail pf WITH (NOLOCK)
LEFT JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.ID = pf.FailTypeID
WHERE pf.PositionID = 123456789
ORDER BY pf.FailOccurred DESC
```

### 8.2 Check fail volume by fail type in the last day

```sql
SELECT pf.FailTypeID, COUNT(*) AS FailCount
FROM History.PositionFail pf WITH (NOLOCK)
WHERE pf.FailOccurred >= DATEADD(day, -1, GETUTCDATE())
GROUP BY pf.FailTypeID
ORDER BY FailCount DESC
```

### 8.3 Check pending async fail records not yet processed

```sql
SELECT COUNT(*) AS PendingFailRecords
FROM Trade.AsyncRecord WITH (NOLOCK)
WHERE ActionID = 5
  AND Status = 0  -- pending
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 25 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFailInfo | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PositionFailInfo.sql*
