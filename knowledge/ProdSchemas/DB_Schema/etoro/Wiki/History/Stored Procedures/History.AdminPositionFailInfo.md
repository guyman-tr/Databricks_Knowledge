# History.AdminPositionFailInfo

> Admin-path wrapper for recording a failed admin-initiated position operation: marks the admin operation as failed in Trade.AdminPositionLog, then delegates full position failure logging to History.PositionFailInfo.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AdminPositionID (input) - identifies the admin operation to mark as failed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AdminPositionFailInfo` is the failure-reporting path for position operations that were initiated by an admin through the back-office admin position system (`Trade.AdminPositionLog`). When a back-office user manually opens, closes, or edits a position and that operation fails, this procedure is called instead of the standard `History.PositionFailInfo`.

The procedure exists because admin-initiated position failures need two things to happen atomically: the admin operation record in `Trade.AdminPositionLog` must be marked as failed (State=4) with the error details, AND the standard position failure record must be written to `History.PositionFailLocal` via `History.PositionFailInfo`. Without this procedure, admin failures would either miss the admin operation status update or require duplicate logic in calling code.

The calling flow is: an admin triggers a position operation -> the operation fails -> the trade engine calls `History.AdminPositionFailInfo` with all position parameters plus `@AdminPositionID` -> this procedure marks the admin operation as failed and then delegates to `History.PositionFailInfo` to write the full failure audit record.

---

## 2. Business Logic

### 2.1 Two-Phase Failure Recording

**What**: Every admin position failure must be recorded in two tables: Trade.AdminPositionLog (admin operation status) and History.PositionFailLocal (full position failure audit).

**Columns/Parameters Involved**: `@AdminPositionID`, `@FailReason`, `@ErrorCode`

**Rules**:
- Step 1: UPDATE Trade.AdminPositionLog SET State=4 (Failed), FailReason=@FailReason, ErrorCode=@ErrorCode, ExecutionOccurred=GETUTCDATE() WHERE AdminPositionID=@AdminPositionID
- Step 2: EXEC History.PositionFailInfo with all position parameters (delegates the full failure audit record write)
- @ErrorCode is captured in Trade.AdminPositionLog but is NOT forwarded to History.PositionFailInfo (PositionFailInfo has its own error code handling)
- GETUTCDATE() used for ExecutionOccurred (UTC) vs getdate() used by PositionFailLocal partition key

**Diagram**:
```
Admin operation fails
    |
    v
History.AdminPositionFailInfo(@AdminPositionID, @FailReason, @ErrorCode, ...position params...)
    |
    +-> UPDATE Trade.AdminPositionLog
    |       SET State=4 (Failed)
    |           FailReason=@FailReason
    |           ErrorCode=@ErrorCode
    |           ExecutionOccurred=GETUTCDATE()
    |       WHERE AdminPositionID=@AdminPositionID
    |
    +-> EXEC History.PositionFailInfo
            (all 62 position params forwarded, @ErrorCode excluded)
            -> INSERT into History.PositionFailLocal (via PositionFailWrite synonym)
```

### 2.2 Admin Operation State Machine

**What**: The State column in Trade.AdminPositionLog tracks admin operation lifecycle.

**Columns/Parameters Involved**: `@AdminPositionID` (links to Trade.AdminPositionLog.AdminPositionID)

**Rules**:
- State=4 means "Failed" - this proc sets that state when the position operation fails
- ExecutionOccurred is set to GETUTCDATE() when the failure is recorded
- @FailReason and @ErrorCode are written to the admin log for back-office visibility

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | - | - | CODE-BACKED | ID of the position involved in the failed admin operation. Forwarded to History.PositionFailInfo. NULL if failure occurred before a PositionID was assigned. |
| 2 | @FailTypeID | INTEGER | - | - | CODE-BACKED | Type of operation that failed. FK to Dictionary.FailType. Forwarded to History.PositionFailInfo. |
| 3 | @CID | INTEGER | - | - | CODE-BACKED | Customer account ID of the position owner. Forwarded to History.PositionFailInfo. |
| 4 | @ForexResultID | BIGINT | - | - | CODE-BACKED | ID of the forex result/pricing event. Forwarded to History.PositionFailInfo. |
| 5 | @CurrencyID | INTEGER | - | - | CODE-BACKED | Currency denomination of the position's account. Forwarded to History.PositionFailInfo. |
| 6 | @ProviderID | INTEGER | - | - | CODE-BACKED | Liquidity provider or market maker ID. Forwarded to History.PositionFailInfo. |
| 7 | @GameServerID | INTEGER | - | - | CODE-BACKED | Trading engine game server ID. Forwarded to History.PositionFailInfo. |
| 8 | @InstrumentID | INTEGER | - | - | CODE-BACKED | Financial instrument being traded. Forwarded to History.PositionFailInfo. |
| 9 | @HedgeID | INTEGER | - | - | CODE-BACKED | Associated hedge order ID. Forwarded to History.PositionFailInfo. |
| 10 | @Leverage | INTEGER | - | - | CODE-BACKED | Leverage multiplier applied to the position. Forwarded to History.PositionFailInfo. |
| 11 | @Amount | MONEY | - | - | CODE-BACKED | Position size in account base currency (cents). Forwarded to History.PositionFailInfo. |
| 12 | @AmountInUnitsDecimal | DECIMAL(16,6) | - | - | CODE-BACKED | Position size in instrument units. Forwarded to History.PositionFailInfo. |
| 13 | @UnitMargin | INTEGER | - | - | CODE-BACKED | Margin requirement per unit. Forwarded to History.PositionFailInfo. |
| 14 | @LotCountDecimal | DECIMAL(16,6) | - | - | CODE-BACKED | Number of lots with decimal precision. Forwarded to History.PositionFailInfo. |
| 15 | @NetProfit | MONEY | - | - | CODE-BACKED | Unrealized/realized P&L at time of failure, in cents. Forwarded to History.PositionFailInfo. |
| 16 | @InitForexRate | dtPrice | - | - | CODE-BACKED | Opening price rate (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 17 | @InitDateTime | DATETIME | - | - | CODE-BACKED | Timestamp when the position was opened. Forwarded to History.PositionFailInfo. |
| 18 | @LimitRate | dtPrice | - | - | CODE-BACKED | Take-profit rate (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 19 | @StopRate | dtPrice | - | - | CODE-BACKED | Stop-loss rate (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 20 | @IsBuy | BIT | - | - | CODE-BACKED | Trade direction: 1=Buy (Long), 0=Sell (Short). Forwarded to History.PositionFailInfo. |
| 21 | @CloseOnEndOfWeek | BIT | - | - | CODE-BACKED | Whether position auto-closes at end of trading week. Forwarded to History.PositionFailInfo. |
| 22 | @Commission | MONEY | - | - | CODE-BACKED | Opening commission charged. Forwarded to History.PositionFailInfo. |
| 23 | @CommissionOnClose | MONEY | - | - | CODE-BACKED | Commission to be charged on close. Forwarded to History.PositionFailInfo. |
| 24 | @SpreadedCommission | INTEGER | - | - | CODE-BACKED | Spread-based commission component. Forwarded to History.PositionFailInfo. |
| 25 | @EndForexRate | dtPrice | - | - | CODE-BACKED | Actual closing price rate at time of failure (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 26 | @RequestedEndForexRate | dtPrice | - | - | CODE-BACKED | Requested close rate before execution (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 27 | @EndDateTime | DATETIME | - | - | CODE-BACKED | Timestamp of the close or attempted close. Forwarded to History.PositionFailInfo. |
| 28 | @AdditionalParam | SQL_VARIANT | - | - | CODE-BACKED | Free-form context. Defaults to 'DB_Direct' when NULL. Forwarded to History.PositionFailInfo. |
| 29 | @RequestOpenOccurred | DATETIME | - | - | CODE-BACKED | Timestamp when open request was received. Forwarded to History.PositionFailInfo. |
| 30 | @RequestCloseOccurred | DATETIME | - | - | CODE-BACKED | Timestamp when close request was received. Forwarded to History.PositionFailInfo. |
| 31 | @OpenOccurred | DATETIME | - | - | CODE-BACKED | Timestamp when position actually opened. Forwarded to History.PositionFailInfo. |
| 32 | @FailReason | VARCHAR(MAX) | - | - | CODE-BACKED | Free-text description of why the operation failed. Written to BOTH Trade.AdminPositionLog.FailReason AND forwarded to History.PositionFailInfo. |
| 33 | @ErrorCode | INT | - | - | CODE-BACKED | Numeric application error code. Written to Trade.AdminPositionLog.ErrorCode. NOT forwarded to History.PositionFailInfo. |
| 34 | @InitForexPriceRateID | BIGINT | - | - | CODE-BACKED | ID of the price feed rate record used for the opening rate. Forwarded to History.PositionFailInfo. |
| 35 | @EndForexPriceRateID | BIGINT | - | - | CODE-BACKED | ID of the price rate used for the closing rate. Forwarded to History.PositionFailInfo. |
| 36 | @OrderPriceRateID | BIGINT | - | - | CODE-BACKED | ID of the price rate used for order execution. Forwarded to History.PositionFailInfo. |
| 37 | @OrderPriceRate | dtPrice | - | - | CODE-BACKED | Actual order execution price (dbo.dtPrice UDT). Forwarded to History.PositionFailInfo. |
| 38 | @OrderID | INTEGER | - | NULL | CODE-BACKED | ID of the pending order, if triggered by an order. Optional, defaults NULL. Forwarded to History.PositionFailInfo. |
| 39 | @ParentPositionID | bigint | - | 0 | CODE-BACKED | Parent position ID in CopyTrader hierarchy. Default 0 (History.PositionFailInfo uses default 1 = no parent). Forwarded to History.PositionFailInfo. |
| 40 | @OrigParentPositionID | bigint | - | NULL | CODE-BACKED | Original parent position before detach. Optional. Forwarded to History.PositionFailInfo. |
| 41 | @LastOpPriceRate | dtPrice | - | 0 | CODE-BACKED | Price rate of the most recent successful operation (dbo.dtPrice UDT). Default 0. Forwarded. |
| 42 | @LastOpPriceRateID | BIGINT | - | 0 | CODE-BACKED | ID for LastOpPriceRate. Default 0. Forwarded to History.PositionFailInfo. |
| 43 | @LastOpConversionRate | dtPrice | - | 0 | CODE-BACKED | Conversion rate from the most recent operation (dbo.dtPrice UDT). Default 0. Forwarded. |
| 44 | @LastOpConversionRateID | BIGINT | - | 0 | CODE-BACKED | ID for LastOpConversionRate. Default 0. Forwarded to History.PositionFailInfo. |
| 45 | @MirrorID | INT | - | 0 | CODE-BACKED | CopyTrader mirror ID. Default 0 = not in a mirror. Forwarded to History.PositionFailInfo. |
| 46 | @IsOpenOpen | BIT | - | 0 | CODE-BACKED | Whether position was in "open-open" intermediate state. Default 0. Forwarded. |
| 47 | @SessionID | INT | - | 0 | CODE-BACKED | Trading session ID. Default 0. Forwarded to History.PositionFailInfo. |
| 48 | @ClosePositionActionTypeID | int | - | NULL | CODE-BACKED | What triggered the close attempt. FK to Dictionary.ClosePositionActionType. Default NULL. Forwarded. |
| 49 | @OrderType | int | - | NULL | CODE-BACKED | Type of order that triggered the failure (market, limit, etc.). Default NULL. Forwarded. |
| 50 | @ClientRequestGuid | UNIQUEIDENTIFIER | - | NULL | CODE-BACKED | Client request GUID for idempotency tracking. Default NULL. Forwarded to History.PositionFailInfo. |
| 51 | @ClientViewRateID | BIGINT | - | NULL | CODE-BACKED | ID of the price rate displayed to client in UI. Default NULL. Forwarded. |
| 52 | @ClientViewRate | DECIMAL(16,6) | - | NULL | CODE-BACKED | Price rate shown to client in UI at time of request. Default NULL. Forwarded. |
| 53 | @ClientRateForCalcID | BIGINT | - | NULL | CODE-BACKED | ID of the rate used for client-side calculations. Default NULL. Forwarded. |
| 54 | @ClientRateForCalc | DECIMAL(16,6) | - | NULL | CODE-BACKED | Rate used by client for pre-submission calculations. Default NULL. Forwarded. |
| 55 | @HedgeServerID | BIGINT | - | NULL | CODE-BACKED | ID of the hedge server. Default NULL. Forwarded to History.PositionFailInfo. |
| 56 | @ExecutionID | BIGINT | - | NULL | CODE-BACKED | ID of the execution event in the execution engine. Default NULL. Forwarded. |
| 57 | @AdminPositionID | INT | - | - | CODE-BACKED | ID of the admin position operation in Trade.AdminPositionLog. Used to UPDATE the admin record's State to 4 (Failed). NOT forwarded to History.PositionFailInfo. This is the key differentiator from the standard History.PositionFailInfo path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AdminPositionID | Trade.AdminPositionLog | FK | Updates the admin operation record to State=4 (Failed) |
| (all position params) | History.PositionFailInfo | EXEC | Delegates the full position failure write to the standard procedure |
| (via PositionFailInfo) | History.PositionFailLocal | Indirect Write | Failure record ultimately written to this table via PositionFailWrite synonym |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade engine / back-office system | @AdminPositionID | CALLER | Called when an admin-initiated position operation fails |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AdminPositionFailInfo (procedure)
+-- Trade.AdminPositionLog (table) [UPDATE - mark State=4 Failed]
+-- History.PositionFailInfo (procedure) [EXEC - delegates failure logging]
      +-- History.PositionFailWrite (synonym) [INSERT]
            +-- History.PositionFailLocal (table) [physical target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | UPDATED: marks State=4 (Failed), sets FailReason, ErrorCode, ExecutionOccurred for the admin operation record |
| History.PositionFailInfo | Stored Procedure | EXEC: delegates full position failure audit logging with all 56 position parameters |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade engine / back-office caller | Application | CALLER - invokes when an admin position operation fails |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Find recent admin position failures in Trade.AdminPositionLog

```sql
SELECT TOP 20
    apl.AdminPositionID,
    apl.State,
    apl.FailReason,
    apl.ErrorCode,
    apl.ExecutionOccurred,
    apl.CID
FROM Trade.AdminPositionLog apl WITH (NOLOCK)
WHERE apl.State = 4  -- Failed
  AND apl.ExecutionOccurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY apl.ExecutionOccurred DESC
```

### 8.2 Join admin position failures with position fail audit records

```sql
SELECT
    apl.AdminPositionID,
    apl.State,
    apl.ErrorCode AS AdminErrorCode,
    apl.FailReason AS AdminFailReason,
    pfl.PositionFailID,
    pfl.FailTypeID,
    pfl.FailReason AS PosFailReason,
    pfl.FailOccurred,
    pfl.InstrumentID
FROM Trade.AdminPositionLog apl WITH (NOLOCK)
JOIN History.PositionFailLocal pfl WITH (NOLOCK)
    ON pfl.CID = apl.CID
WHERE apl.State = 4
ORDER BY pfl.FailOccurred DESC
```

### 8.3 Count admin failures by error code

```sql
SELECT
    apl.ErrorCode,
    COUNT(*) AS FailCount,
    MIN(apl.ExecutionOccurred) AS FirstSeen,
    MAX(apl.ExecutionOccurred) AS LastSeen
FROM Trade.AdminPositionLog apl WITH (NOLOCK)
WHERE apl.State = 4
GROUP BY apl.ErrorCode
ORDER BY FailCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 57 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (PositionFailInfo, Trade.AdminPositionLog) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AdminPositionFailInfo | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AdminPositionFailInfo.sql*
