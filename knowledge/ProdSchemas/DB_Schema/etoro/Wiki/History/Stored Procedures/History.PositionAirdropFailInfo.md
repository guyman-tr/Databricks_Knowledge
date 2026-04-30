# History.PositionAirdropFailInfo

> Thin airdrop-specific wrapper around History.PositionFailInfo that records a position failure AND updates the airdrop execution log (Trade.PositionAirdropLog Result=0) for the associated airdrop event. The procedure adds a single extra parameter @AirdropID to the standard PositionFailInfo interface.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID + @AirdropID - the failed position and the airdrop event it was associated with |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionAirdropFailInfo` extends the standard position failure recording path for crypto airdrop scenarios. An "airdrop" in eToro's context is an automated position operation (typically opening or closing a position) performed as part of a crypto token distribution event. When such an operation fails, two things must happen:

1. **Standard position failure recording**: The failure is logged via `History.PositionFailInfo` (which enqueues an async ActionID=5 XML record via Trade.InsertAsyncRecord for insertion into History.PositionFail)
2. **Airdrop execution log update**: The `Trade.PositionAirdropLog` record for `@AirdropID` is updated with `Result=0` (failure), the `FailReason`, and `ExecutionOccurred=GETUTCDATE()`

The procedure has an identical parameter set to `History.PositionFailInfo` except:
- Adds `@AirdropID INT` (links to the airdrop event)
- Omits `@ErrorCode INT` (not passed to PositionFailInfo or used internally)

All other parameters are passed through directly to `History.PositionFailInfo` without transformation.

History note: PositionID changed to BIGINT on 2021-11-17 (per DDL comment "Bonnie - Change positionID to bigint").

---

## 2. Business Logic

### 2.1 Delegation to History.PositionFailInfo

**What**: All standard position failure recording is delegated entirely to History.PositionFailInfo.

**Columns/Parameters Involved**: All 54 shared parameters

**Rules**:
- Complete pass-through: every parameter is forwarded using named parameter syntax
- @ErrorCode is NOT included in either the parameter list or the EXEC call (absent from this procedure's interface vs PositionFailInfo which has @ErrorCode)
- History.PositionFailInfo handles: OrigParentPositionID resolution from Trade.PositionTbl (with partition elimination) or History.Position_Active fallback; XML payload construction; Trade.InsertAsyncRecord ActionID=5 enqueue; RAISERROR 60000 on failure

### 2.2 Airdrop Execution Log Update

**What**: Sets the airdrop operation result to failure (Result=0) and records the failure details.

**Columns/Parameters Involved**: `@AirdropID`, `@FailReason`, `Trade.PositionAirdropLog`

**Rules**:
- `UPDATE Trade.PositionAirdropLog SET Result=0, FailReason=@FailReason, ExecutionOccurred=GETUTCDATE() WHERE AirdropID=@AirdropID`
- Result=0 indicates failure (success would be Result=1 in the underlying log)
- ExecutionOccurred=GETUTCDATE() records when the failure was processed
- Trade.PositionAirdropLog is documented as a UNION ALL view; this UPDATE likely targets the underlying base table via a trigger or direct table reference
- No error handling around the UPDATE - if the UPDATE fails, the exception propagates

**Pipeline**:
```
Airdrop operation fails
    |
    EXEC History.PositionAirdropFailInfo(@PositionID, ..., @AirdropID)
         |
         +-- EXEC History.PositionFailInfo (position failure async queue)
         |         |
         |         +-- Trade.InsertAsyncRecord (ActionID=5)
         |               |
         |               Internal.AsyncExecuter -> History.PostPositionFail -> History.PositionFailLocal
         |
         +-- UPDATE Trade.PositionAirdropLog SET Result=0 WHERE AirdropID=@AirdropID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position ID that failed. BIGINT since 2021-11-17. Forwarded to History.PositionFailInfo. |
| 2 | @FailTypeID | INT | NO | - | CODE-BACKED | Failure type ID (FK to Dictionary.FailType). Forwarded to PositionFailInfo. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Forwarded to PositionFailInfo and used for async queue routing. |
| 4 | @ForexResultID | BIGINT | NO | - | CODE-BACKED | Game/trading context ID. Forwarded. |
| 5 | @CurrencyID | INT | NO | - | CODE-BACKED | Account currency ID. Forwarded. |
| 6 | @ProviderID | INT | NO | - | CODE-BACKED | Market data provider ID. Forwarded. |
| 7 | @GameServerID | INT | NO | - | CODE-BACKED | Game server ID. Forwarded. |
| 8 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID (crypto instrument for airdrop events). Forwarded. |
| 9 | @HedgeID | INT | NO | - | CODE-BACKED | Hedge order ID. Forwarded. |
| 10 | @Leverage | INT | NO | - | CODE-BACKED | Leverage. Forwarded. |
| 11 | @Amount | MONEY | NO | - | CODE-BACKED | Invested amount IN CENTS (per PositionFailInfo convention; divided by 100 in XML). Forwarded. |
| 12 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units. Forwarded. |
| 13 | @UnitMargin | INT | NO | - | CODE-BACKED | Margin per unit. Forwarded. |
| 14 | @LotCountDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in lots. Forwarded. |
| 15 | @NetProfit | MONEY | NO | - | CODE-BACKED | Net profit IN CENTS (per DDL comment). Forwarded; divided by 100 in XML. |
| 16 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | Opening exchange rate. Forwarded. |
| 17 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | Open request datetime. Forwarded. |
| 18 | @LimitRate | dtPrice | NO | - | CODE-BACKED | Take profit rate. Forwarded. |
| 19 | @StopRate | dtPrice | NO | - | CODE-BACKED | Stop loss rate. Forwarded. |
| 20 | @IsBuy | BIT | NO | - | CODE-BACKED | 1=Buy/Long, 0=Sell/Short. Forwarded. |
| 21 | @CloseOnEndOfWeek | BIT | NO | - | CODE-BACKED | Auto-close at weekend flag. Forwarded. |
| 22 | @Commission | MONEY | NO | - | CODE-BACKED | Spread/commission amount. Forwarded. |
| 23 | @CommissionOnClose | MONEY | NO | - | CODE-BACKED | Deferred commission on close. Forwarded. |
| 24 | @SpreadedCommission | INT | NO | - | CODE-BACKED | Spreaded commission in points. Forwarded. |
| 25 | @EndForexRate | dtPrice | NO | - | CODE-BACKED | Closing exchange rate. Forwarded. |
| 26 | @RequestedEndForexRate | dtPrice | NO | - | CODE-BACKED | Client-requested close rate. Forwarded. |
| 27 | @EndDateTime | DATETIME | NO | - | CODE-BACKED | Close attempt datetime. Forwarded. |
| 28 | @AdditionalParam | SQL_VARIANT | NO | - | CODE-BACKED | Additional context. Forwarded. |
| 29 | @RequestOpenOccurred | DATETIME | NO | - | CODE-BACKED | Open request timestamp. Forwarded. |
| 30 | @RequestCloseOccurred | DATETIME | NO | - | CODE-BACKED | Close request timestamp. Forwarded. |
| 31 | @OpenOccurred | DATETIME | NO | - | CODE-BACKED | Actual open timestamp. Forwarded. |
| 32 | @FailReason | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable failure reason. Forwarded to PositionFailInfo AND used directly in Trade.PositionAirdropLog UPDATE. |
| 33 | @InitForexPriceRateID | BIGINT | NO | - | CODE-BACKED | Rate ID for opening rate. Forwarded. |
| 34 | @EndForexPriceRateID | BIGINT | NO | - | CODE-BACKED | Rate ID for closing rate. Forwarded. |
| 35 | @OrderPriceRateID | BIGINT | NO | - | CODE-BACKED | Order price rate ID. Forwarded. |
| 36 | @OrderPriceRate | dtPrice | NO | - | CODE-BACKED | Order price rate. Forwarded. |
| 37 | @OrderID | INT | YES | NULL | CODE-BACKED | Order ID. Forwarded. |
| 38 | @ParentPositionID | BIGINT | YES | 0 | CODE-BACKED | Parent copy position ID. Forwarded. |
| 39 | @OrigParentPositionID | BIGINT | YES | NULL | CODE-BACKED | Original parent position ID. Forwarded to PositionFailInfo which resolves it if NULL. |
| 40 | @LastOpPriceRate | dtPrice | YES | 0 | CODE-BACKED | Last operation price rate. Forwarded. |
| 41 | @LastOpPriceRateID | BIGINT | YES | 0 | CODE-BACKED | Rate ID for last operation. Forwarded. |
| 42 | @LastOpConversionRate | dtPrice | YES | 0 | CODE-BACKED | Last operation conversion rate. Forwarded. |
| 43 | @LastOpConversionRateID | BIGINT | YES | 0 | CODE-BACKED | Rate ID for last conversion. Forwarded. |
| 44 | @MirrorID | INT | YES | 0 | CODE-BACKED | Mirror relationship ID. Forwarded. |
| 45 | @IsOpenOpen | BIT | YES | 0 | CODE-BACKED | Pre-market open flag. Forwarded. |
| 46 | @SessionID | INT | YES | 0 | CODE-BACKED | Trading session ID. Forwarded. Note: declared as INT (vs BIGINT in PositionFailInfo). |
| 47 | @ClosePositionActionTypeID | INT | YES | NULL | CODE-BACKED | Close action type. Forwarded. |
| 48 | @OrderType | INT | YES | NULL | CODE-BACKED | Order type. Forwarded. |
| 49 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client idempotency GUID. Forwarded. |
| 50 | @ClientViewRateID | BIGINT | YES | NULL | CODE-BACKED | Client-visible rate ID. Forwarded. |
| 51 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Client-visible rate. Forwarded. |
| 52 | @ClientRateForCalcID | BIGINT | YES | NULL | CODE-BACKED | Client calculation rate ID. Forwarded. |
| 53 | @ClientRateForCalc | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Client calculation rate. Forwarded. |
| 54 | @HedgeServerID | BIGINT | YES | NULL | CODE-BACKED | Hedge server ID. Forwarded. |
| 55 | @ExecutionID | BIGINT | YES | NULL | CODE-BACKED | Execution ID. Forwarded. |
| 56 | @AirdropID | INT | NO | - | CODE-BACKED | **Airdrop-specific addition.** ID of the airdrop event in Trade.PositionAirdropLog. Used to mark the airdrop as failed (Result=0). Not present in base History.PositionFailInfo. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All 54 position params | History.PositionFailInfo | Calls (EXEC) | Full pass-through delegation for standard position failure recording (async enqueue path) |
| @AirdropID, @FailReason | Trade.PositionAirdropLog | UPDATE | Sets Result=0, FailReason, ExecutionOccurred for the airdrop event |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by the airdrop/crypto operations engine.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionAirdropFailInfo (procedure)
+-- History.PositionFailInfo (procedure)
|     +-- Trade.PositionTbl (table, cross-schema, partition elimination)
|     +-- History.Position_Active (table)
|     +-- Trade.InsertAsyncRecord (procedure, ActionID=5)
+-- Trade.PositionAirdropLog (view/table - UPDATE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFailInfo | Procedure | Called with all 54 standard position failure parameters for async failure recording |
| Trade.PositionAirdropLog | View (or underlying table) | UPDATE target: sets Result=0, FailReason=@FailReason, ExecutionOccurred=GETUTCDATE() WHERE AirdropID=@AirdropID |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @ErrorCode omitted | Interface difference | PositionAirdropFailInfo has no @ErrorCode parameter; History.PositionFailInfo has @ErrorCode as the 56th parameter - airdrop failures do not track error codes |
| @SessionID as INT | Type note | @SessionID is INT here but BIGINT in History.PositionFailInfo; implicit conversion applies on EXEC |
| Trade.PositionAirdropLog UPDATE | Implementation note | PositionAirdropLog is documented as a UNION ALL view; this UPDATE likely succeeds via an INSTEAD OF trigger or targets the underlying base table directly |
| Result=0 for failure | Business rule | Airdrop operation failure is encoded as Result=0 (vs Result=1 for success in the State->Result mapping in the view definition) |
| PositionID BIGINT | Change history | Changed from INT to BIGINT on 2021-11-17 per inline comment |

---

## 8. Sample Queries

### 8.1 Check airdrop failures for a customer

```sql
SELECT pal.AirdropID, pal.Result, pal.FailReason, pal.ExecutionOccurred,
       pf.PositionID, pf.FailTypeID, pf.FailOccurred
FROM Trade.PositionAirdropLog pal WITH (NOLOCK)
LEFT JOIN History.PositionFail pf WITH (NOLOCK) ON pf.PositionID = pal.PositionID
WHERE pal.CID = 12345678
  AND pal.Result = 0  -- failures
ORDER BY pal.ExecutionOccurred DESC
```

### 8.2 Check airdrop execution outcomes

```sql
SELECT Result,
       COUNT(*) AS Count,
       MIN(ExecutionOccurred) AS FirstOccurred,
       MAX(ExecutionOccurred) AS LastOccurred
FROM Trade.PositionAirdropLog WITH (NOLOCK)
WHERE ExecutionOccurred >= DATEADD(day, -7, GETUTCDATE())
GROUP BY Result
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 56 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionAirdropFailInfo | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PositionAirdropFailInfo.sql*
