# History.HedgeFailInfo

> Records a hedge operation failure in History.HedgeFail and cleans up the associated pending request from Trade.HedgeRequest - the primary writer for hedge failure audit logging.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeID - the failed hedge operation identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.HedgeFailInfo` is the primary writer procedure for hedge operation failures. When eToro's hedging engine fails to open, close, or process a hedge request with a liquidity provider, this procedure is called to: (1) permanently record the full context of the failure in `History.HedgeFail` for audit and investigation, and (2) clean up the pending hedge request from `Trade.HedgeRequest` so it no longer appears as an open/outstanding operation.

The procedure was enhanced over time (comment notes: "add ReasonTag column", "add HedgeFail column") and handles 25 parameters capturing the complete state snapshot of the failed hedge at the moment of failure - the instrument, provider, amounts, rates, timing, and structured/free-text failure reason.

The hedging engine (an external application, not in SSDT) calls this procedure after a FIX protocol operation fails. The transaction guarantees atomicity: either both the INSERT into HedgeFail and the DELETE from HedgeRequest succeed together, or neither applies. Error handling uses `Internal.CallRaiseError` for structured error propagation.

---

## 2. Business Logic

### 2.1 Atomic Failure Record + Request Cleanup

**What**: Inserts the failure record and removes the pending request in a single transaction.

**Columns/Parameters Involved**: All parameters, `Trade.HedgeRequest.RequestType`

**Rules**:
- BEGIN TRANSACTION / COMMIT TRANSACTION ensures atomicity
- INSERT INTO History.HedgeFail captures the full failed trade context
- DELETE FROM Trade.HedgeRequest WHERE HedgeID = @HedgeID AND RequestType = 1 removes the open hedge request (RequestType = 1 = open/pending request)
- On any error: ROLLBACK if exactly 1 open transaction; COMMIT if nested (@@TRANCOUNT > 1); error propagated via Internal.CallRaiseError

### 2.2 Cents-to-Units Conversion

**What**: NetProfit and Commission are passed in cents but stored in money units (dollars).

**Columns/Parameters Involved**: `@NetProfit`, `@Commission`

**Rules**:
- @NetProfit is passed IN CENTS (per code comment) -> stored as @NetProfit / 100
- @Commission is passed IN CENTS -> stored as @Commission / 100
- All other MONEY parameters (@Amount) are passed directly without conversion

### 2.3 LiquidityAccountID Server-Side Resolution

**What**: LiquidityAccountID is looked up from HedgeServerID rather than passed as a parameter.

**Columns/Parameters Involved**: `@HedgeServerID`, `@LiquidityAccountID`

**Rules**:
- SELECT LiquidityAccountID FROM Hedge.HedgeServerToLiquidityAccount WHERE HedgeServerID = @HedgeServerID
- This resolves the liquidity account associated with the hedge server at the time of the failure
- LiquidityAccountID is then stored in History.HedgeFail for audit purposes

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | VERIFIED | Unique identifier of the hedge operation that failed. Used as the INSERT value for History.HedgeFail.HedgeID and as the WHERE key for the DELETE from Trade.HedgeRequest. Links the failure record back to the originating hedge request. |
| 2 | @FailTypeID | INTEGER | NO | - | VERIFIED | Classifies the stage at which the hedge operation failed. FK to Dictionary.FailType (17 types): 1=Request To Open, 2=Request To Close, 3=Open, 4=Close, 5=Edit, 6=External Error. Determines which phase of the hedge lifecycle failed. |
| 3 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | The currency denomination of the hedge position. FK to Dictionary.Currency. Stored in History.HedgeFail.CurrencyID. |
| 4 | @ProviderID | INTEGER | NO | - | CODE-BACKED | The liquidity provider involved in the failed hedge. FK to Trade or Dictionary provider table. Stored in History.HedgeFail.ProviderID. |
| 5 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The trading instrument for which the hedge failed. FK to Trade.Instrument. Stored in History.HedgeFail.InstrumentID. |
| 6 | @HedgeServerID | INTEGER | NO | - | VERIFIED | The hedge server that processed the failed operation. Used to resolve LiquidityAccountID via Hedge.HedgeServerToLiquidityAccount. Stored in History.HedgeFail.HedgeServerID. |
| 7 | @Leverage | INTEGER | NO | - | CODE-BACKED | The leverage multiplier applied to the hedge position at time of failure. Stored in History.HedgeFail.Leverage. |
| 8 | @Amount | MONEY | NO | - | CODE-BACKED | The position amount in USD. Passed and stored directly (not in cents). Stored in History.HedgeFail.Amount. |
| 9 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in units (shares/contracts/coins). Stored in History.HedgeFail.AmountInUnitsDecimal. |
| 10 | @LotCountDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in lots. Stored in History.HedgeFail.LotCountDecimal. |
| 11 | @NetProfit | MONEY | NO | - | VERIFIED | Net profit/loss IN CENTS (per code comment). Stored as @NetProfit / 100 (converted to dollars). Represents the P&L at the time of the failed close/edit attempt. |
| 12 | @Commission | MONEY | NO | - | VERIFIED | Commission amount IN CENTS. Stored as @Commission / 100 (converted to dollars). |
| 13 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | The opening rate of the hedge position. dtPrice is a custom SQL type for price values. Stored in History.HedgeFail.InitForexRate. |
| 14 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the hedge position was initially opened. Stored in History.HedgeFail.InitDateTime. |
| 15 | @LimitRate | dtPrice | NO | - | CODE-BACKED | The take-profit rate set on the hedge position at time of failure. dtPrice custom type. Stored in History.HedgeFail.LimitRate. |
| 16 | @StopRate | dtPrice | NO | - | CODE-BACKED | The stop-loss rate set on the hedge position at time of failure. dtPrice custom type. Stored in History.HedgeFail.StopRate. |
| 17 | @IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy (long), 0 = Sell (short). Stored in History.HedgeFail.IsBuy. |
| 18 | @EndForexRate | dtPrice | YES | - | CODE-BACKED | The closing rate at the time of the failed close attempt. May be NULL if the failure occurred before a closing rate was established. dtPrice custom type. |
| 19 | @RequestedEndForexRate | dtPrice | YES | - | CODE-BACKED | The requested closing rate (limit/stop target) at the time of failure. dtPrice custom type. |
| 20 | @EndDateTime | DATETIME | YES | - | CODE-BACKED | Timestamp of the requested/attempted close. May be NULL for open-stage failures. |
| 21 | @RequestOpenOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the original open request was submitted. Captured for timing audit. |
| 22 | @RequestCloseOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the close request was submitted. NULL for open-stage failures. |
| 23 | @OpenOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the hedge position was actually opened with the liquidity provider. NULL if the failure occurred before the open was confirmed. |
| 24 | @FailText | VARCHAR(MAX) | YES | - | VERIFIED | Free-text description of the failure reason. Stored in History.HedgeFail.FailReason. May be a system-generated message ("Cannot find corresponding request") or an error returned by the liquidity provider via FIX protocol. |
| 25 | @FailReasonID | INT | NO | - | VERIFIED | Structured failure reason code. FK to Dictionary.HedgePositionFailReason (24 codes): 0=Unknown error, 1=Market closed, 2=Slippage breached, 3=Liquidity breached, 4=Insufficient margin, etc. Provides machine-readable failure categorization complementing the free-text FailReason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Hedge.HedgeServerToLiquidityAccount | Reads (lookup) | SELECT LiquidityAccountID for the given HedgeServerID |
| (body) | History.HedgeFail | Writes (INSERT) | Primary writer - inserts one failure record per call |
| @HedgeID | Trade.HedgeRequest | Modifies (DELETE) | Removes the pending open request (RequestType=1) after recording the failure |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository. Called by the external hedging engine application after FIX protocol failures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeFailInfo (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table - lookup)
├── History.HedgeFail (table - INSERT target)
└── Trade.HedgeRequest (table - DELETE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | SELECT - resolves LiquidityAccountID from @HedgeServerID |
| History.HedgeFail | Table | INSERT - records the full hedge failure context |
| Trade.HedgeRequest | Table | DELETE - removes the pending open request after failure is recorded |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository. Called by the external hedging engine.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Transaction behavior**:
- Explicit BEGIN TRANSACTION / COMMIT TRANSACTION wraps INSERT + DELETE
- On error: ROLLBACK if @@TRANCOUNT = 1; COMMIT if @@TRANCOUNT > 1 (nested transaction)
- EXEC Internal.CallRaiseError propagates structured errors
- RETURN 0 on success; RETURN @error_num on catch; RETURN -1 on unexpected exit

---

## 8. Sample Queries

### 8.1 Check failure count by FailTypeID

```sql
SELECT FailTypeID, COUNT(*) AS FailCount
FROM History.HedgeFail WITH (NOLOCK)
GROUP BY FailTypeID
ORDER BY FailCount DESC
```

### 8.2 Find recent hedge failures with reason text

```sql
SELECT TOP 20
    HedgeID,
    FailTypeID,
    FailReasonID,
    FailReason,
    FailOccurred,
    InstrumentID
FROM History.HedgeFail WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.3 Check if any open hedge requests exist for a given HedgeID

```sql
SELECT HedgeID, RequestType, CreatedDate
FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = 12345
  AND RequestType = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.HedgeFailInfo | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.HedgeFailInfo.sql*
