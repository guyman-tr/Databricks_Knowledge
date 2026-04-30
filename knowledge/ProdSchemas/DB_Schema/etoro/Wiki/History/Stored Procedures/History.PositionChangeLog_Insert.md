# History.PositionChangeLog_Insert

> Thin transactional INSERT wrapper for History.PositionChangeLog_Active_BIGINT - records every position lifecycle event (open, stop loss edit, take profit edit, TSL toggle, partial close, redeem, close) with before/after snapshots of all modified fields. The single writer for the position change audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID + @ChangeTypeID + @Occurred - identifies which position changed, what type of change, and when |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionChangeLog_Insert` is the **sole writer** for `History.PositionChangeLog_Active_BIGINT`, the partitioned position change audit log that records every lifecycle event for every open position. Each call creates one audit row capturing the before and after state of every relevant position field.

The trading engine (application layer) calls this procedure for all 14 change types: when a position is opened (ChangeTypeID=0), when a customer edits stop loss or take profit (1, 2), when TSL is toggled (7), when a partial close occurs (11, 12), when a position is closed (6), and for redeem workflow transitions (8, 9, 10) among others. The procedure is designed to be a simple, reliable gateway - it wraps the INSERT in a transaction, returns detailed error information via @ErrOut on failure, and handles nested transaction scenarios correctly in CATCH.

Data flow: Caller assembles all before/after values for the change type being recorded -> EXEC PositionChangeLog_Insert with all parameters -> INSERT into History.PositionChangeLog_Active_BIGINT within a transaction -> RETURN 0 on success or error number on failure, with @ErrOut populated with error details.

History note: PositionID parameter changed from INT to BIGINT on 2021-11-17 (Bonnie, comment in DDL). Additional optional parameters added 2018-12-18 (ClientViewRateID, ClientViewRate, ClientRateForCalcID, ClientRateForCalc) per FB 53286.

---

## 2. Business Logic

### 2.1 Change Type State Machine

**What**: @ChangeTypeID determines which type of position lifecycle event is being recorded, and therefore which before/after field pairs carry meaningful data.

**Columns/Parameters Involved**: `@ChangeTypeID`, all @Previous* and current value parameters

**Rules** (from Dictionary.PCL_ChangeType):

| @ChangeTypeID | Event | Key Parameters Changed |
|--------------|-------|----------------------|
| 0 | Open Position | All fields - initial snapshot at position open |
| 1 | Edit Stop Loss | @PreviousStopRate / @StopRate |
| 2 | Edit Take Profit | @PreviousLimitRate / @LimitRate |
| 3 | Edit Over Weekend | @PreviousCloseOnEndOfWeek / @CloseOnEndOfWeek |
| 4 | EOW Fee change | @PreviousEndOfWeekFee / @EndOfWeekFee |
| 5 | Detach from Mirror | ParentPositionID set to NULL (mirror detach) |
| 6 | Close Position | Final snapshot - all values at close |
| 7 | Enable/Disable TSL | @IsTslEnabled toggled |
| 8 | PositionRedeemCancel | @RedeemStatus -> 0 |
| 9 | PositionRedeemPending | @RedeemStatus -> pending state |
| 10 | PositionRedeemClose | @RedeemStatus -> closed |
| 11 | Partial close | @PreviousAmountInUnits / @AmountInUnits / @AmountChanged |
| 12 | Edit due to partial close | Parent position amount adjusted |
| 13 | Edit Is Settled | @PreviousIsSettled / @IsSettled |
| 14 | Data Fix | Correction after data reconciliation |

### 2.2 Error Handling and Output

**What**: On failure, detailed error information is returned via the @ErrOut OUTPUT parameter and the error number is returned as the RETURN value.

**Columns/Parameters Involved**: `@ErrOut` (OUTPUT)

**Rules**:
- @ErrOut is initialized to '' on entry
- On success: @ErrOut remains '', RETURN 0
- On failure (CATCH): @ErrOut = 'ERROR_NUMBER: {n} ERROR_LINE: {n} ERROR_MESSAGE: {msg}'
- RAISERROR(@ErrOut, 16, 1) - re-raises with severity 16 (error)
- RETURN ERROR_NUMBER() - returns the error number to caller
- Transaction handling: IF @@TRANCOUNT=1 ROLLBACK, IF @@TRANCOUNT>1 COMMIT (handles nested transaction rollback correctly - preserves outer transaction state)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | Position identifier for which the change is being recorded. Changed to BIGINT on 2021-11-17. FK to History.PositionChangeLog_Active_BIGINT.PositionID. |
| 2 | @PreviousCloseOnEndOfWeek | BIT | NO | - | VERIFIED | Previous value of CloseOnEndOfWeek before this change. Set for ChangeTypeID=3 (Edit Over Weekend). |
| 3 | @CloseOnEndOfWeek | BIT | NO | - | VERIFIED | New value of CloseOnEndOfWeek after this change. Indicates whether position closes automatically at end of trading week. |
| 4 | @PreviousEndOfWeekFee | MONEY | NO | - | VERIFIED | Previous overnight/end-of-week fee amount before change. Set for ChangeTypeID=4. |
| 5 | @EndOfWeekFee | MONEY | NO | - | VERIFIED | New end-of-week fee amount. |
| 6 | @PreviousAmount | MONEY | NO | - | VERIFIED | Invested amount before this change. Set for partial close (ChangeTypeID=11,12) and open/close snapshots. |
| 7 | @AmountChanged | MONEY | NO | - | VERIFIED | Delta amount applied by this change (positive = increase, negative = decrease). 0 for non-amount changes. Stored as AmountChanged in PositionChangeLog_Active_BIGINT. |
| 8 | @PreviousLimitRate | dtPrice | NO | - | VERIFIED | Previous take profit rate before this change. 0 = no take profit set. Set for ChangeTypeID=2 (Edit Take Profit). |
| 9 | @LimitRate | dtPrice | NO | - | VERIFIED | New take profit rate after this change. |
| 10 | @PreviousStopRate | dtPrice | NO | - | VERIFIED | Previous stop loss rate before this change. Set for ChangeTypeID=1 (Edit Stop Loss) and 7 (TSL). |
| 11 | @StopRate | dtPrice | NO | - | VERIFIED | New stop loss rate after this change. |
| 12 | @Occurred | DATETIME | NO | - | VERIFIED | UTC timestamp when the change occurred. Used as the partition key in PositionChangeLog_Active_BIGINT (partition scheme on Occurred). |
| 13 | @ParentPositionID | BIGINT | NO | - | VERIFIED | Parent position ID (for copy/mirror positions). Set to NULL for ChangeTypeID=5 (Detach from Mirror). 0 = not a copy position. |
| 14 | @OrigParentPositionID | BIGINT | NO | - | VERIFIED | Original parent position ID at the time of opening (does not change when mirror is detached). Used to trace copy lineage even after detachment. |
| 15 | @LastOpPriceRate | dtPrice | NO | - | VERIFIED | Price rate at the time of the last operation on this position. Used for PnL recalculation and audit. |
| 16 | @LastOpPriceRateID | BIGINT | NO | - | VERIFIED | Rate ID corresponding to @LastOpPriceRate. Links to the rate snapshot table for the last operation. |
| 17 | @LastOpConversionRate | dtPrice | NO | - | VERIFIED | Currency conversion rate at the time of the last operation. Used for converting PnL between instrument and account currencies. |
| 18 | @LastOpConversionRateID | BIGINT | NO | - | VERIFIED | Rate ID for the last operation conversion rate. |
| 19 | @MirrorID | INT | NO | - | VERIFIED | Mirror relationship ID. 0/NULL = not a mirrored position. >0 = mirror trade linked to this MirrorID. Used in Section 5 of PositionChangeLog_Active_BIGINT index. |
| 20 | @ClientVersion | VARCHAR(20) | NO | - | VERIFIED | Version of the trading client application that triggered this change. Used for debugging and version-specific behavior analysis. |
| 21 | @CID | INT | NO | - | VERIFIED | Customer ID who owns the position. Stored in PositionChangeLog_Active_BIGINT.CID; used in CLUSTERED index (CID + Occurred) for per-customer queries. |
| 22 | @ChangeTypeID | TINYINT | NO | - | VERIFIED | Type of position change event. 0-14 as documented in Section 2.1. Determines which before/after fields carry meaningful data. |
| 23 | @NewAmount | dtPrice | NO | - | VERIFIED | New invested amount after the change (for amount-changing events like partial close). |
| 24 | @ErrOut | NVARCHAR(4000) | YES | '' OUTPUT | CODE-BACKED | OUTPUT parameter: empty string on success; 'ERROR_NUMBER: {n} ERROR_LINE: {n} ERROR_MESSAGE: {msg}' on failure. Populated in the CATCH block before RAISERROR. |
| 25 | @MirrorRealizedEquity | MONEY | YES | 0 | NAME-INFERRED | Realized equity of the mirror relationship at time of change. Defaults to 0. |
| 26 | @AccountRealizedEquity | MONEY | YES | 0 | NAME-INFERRED | Realized equity of the customer's account at time of change. Defaults to 0. |
| 27 | @PrevTreeID | BIGINT | YES | 0 | VERIFIED | Previous copy-trade tree ID before this change. Used with @TreeID to track tree reassignments. |
| 28 | @TreeID | BIGINT | YES | 0 | VERIFIED | Current copy-trade tree ID. Links this position to a CopyTrader tree hierarchy. |
| 29 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for the operation. Optional audit link to the active session that triggered this change. |
| 30 | @IsTslEnabled | TINYINT | YES | NULL | VERIFIED | TSL (Trailing Stop Loss) enabled flag: 1=enabled, 0=disabled, NULL=not applicable. Key field for ChangeTypeID=7 (Enable/Disable TSL). |
| 31 | @RedeemStatus | INT | YES | 0 | VERIFIED | Redeem (stock delivery) workflow status. Default 0 = not in redeem. Key field for ChangeTypeID=8/9/10. ISNULL(@RedeemStatus,0) applied on INSERT. |
| 32 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-side request GUID for idempotency tracking. Allows the application to detect duplicate requests. |
| 33 | @PreviousIsSettled | BIT | YES | NULL | VERIFIED | Previous IsSettled value. Key field for ChangeTypeID=13 (Edit Is Settled). 1=real stock, 0=CFD. |
| 34 | @IsSettled | BIT | YES | NULL | VERIFIED | New IsSettled value after change. |
| 35 | @PreviousAmountInUnits | DECIMAL(16,6) | YES | NULL | VERIFIED | Previous position size in instrument units. Set for ChangeTypeID=11 (Partial close). |
| 36 | @AmountInUnits | DECIMAL(16,6) | YES | NULL | VERIFIED | New position size in instrument units after change. |
| 37 | @PreviousUnitsBaseValueCents | INT | YES | NULL | NAME-INFERRED | Previous base value of units in cents. Used for real stock value tracking. |
| 38 | @UnitsBaseValueCents | INT | YES | NULL | NAME-INFERRED | New base value of units in cents after change. |
| 39 | @ClientViewRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID for the rate shown to the client in the UI at time of change. Added FB 53286. |
| 40 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate displayed to the client in the trading UI at time of change. Added FB 53286. |
| 41 | @ClientRateForCalcID | BIGINT | YES | NULL | CODE-BACKED | Rate ID used for client-side calculations at time of change. Added FB 53286. |
| 42 | @ClientRateForCalc | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate value used for client-side calculations. Added FB 53286. |
| 43 | @ExecutedWithoutSettings | BIT | YES | 0 | NAME-INFERRED | Flag indicating the operation was executed without the normal settings validation path. Default 0. |
| 44 | @PreviousSettlementTypeID | TINYINT | YES | NULL | VERIFIED | Previous settlement type (1=Real, 2=CFD, etc.) before change. |
| 45 | @SettlementTypeID | TINYINT | YES | NULL | VERIFIED | New settlement type after change. |
| 46 | @IsNoStopLoss | BIT | YES | NULL | VERIFIED | Whether the position has "No Stop Loss" protection active after this change. |
| 47 | @IsNoTakeProfit | BIT | YES | NULL | VERIFIED | Whether the position has "No Take Profit" active after this change. |
| 48 | @PreviousIsNoStopLoss | BIT | YES | NULL | VERIFIED | Previous IsNoStopLoss state before this change. |
| 49 | @PreviousIsNoTakeProfit | BIT | YES | NULL | VERIFIED | Previous IsNoTakeProfit state before this change. |
| 50 | @PreviousLotCountDecimal | DECIMAL(16,6) | YES | NULL | VERIFIED | Previous lot count (position size in lots) before this change. |
| 51 | @LotCountDecimal | DECIMAL(16,6) | YES | NULL | VERIFIED | New lot count after this change. |
| 52 | @SnapshotTimestamp | DATETIME | YES | NULL | CODE-BACKED | Optional timestamp for rate snapshot used in this change. May differ from @Occurred if rates are sourced from a specific historical snapshot. |
| 53 | @PriceType | INT | YES | NULL | NAME-INFERRED | Price type classification for the rate used. NULL = default price type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All parameters | History.PositionChangeLog_Active_BIGINT | WRITER (INSERT) | Single exclusive writer - inserts one audit row per call capturing the position change event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PostDetachMirrorPosition | (body) | Calls (EXEC) | Calls this procedure to record ChangeTypeID=5 (Detach from Mirror) events |
| History.PostPositionOpen | (body) | Calls (EXEC) | Calls this procedure to record ChangeTypeID=0 (Open Position) events |
| Trading engine (application) | - | External caller | Primary caller for all ChangeTypeID values via application-layer position operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionChangeLog_Insert (procedure)
+-- History.PositionChangeLog_Active_BIGINT (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Active_BIGINT | Table | INSERT target - the single table this procedure writes to |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PostDetachMirrorPosition | Procedure | Calls this to insert ChangeTypeID=5 (mirror detach) audit row |
| History.PostPositionOpen | Procedure | Calls this to insert ChangeTypeID=0 (position open) audit row |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition key | Business rule | @Occurred is the partition key; writing with @Occurred outside the active partition range will fail |
| ISNULL(@RedeemStatus, 0) | Default handling | NULL @RedeemStatus is coerced to 0 on INSERT |
| @@TRANCOUNT handling | Implementation | CATCH block: if @@TRANCOUNT=1 ROLLBACK (top-level failure), if >1 COMMIT (nested - preserves outer transaction) |

---

## 8. Sample Queries

### 8.1 Check recent position change events for a position

```sql
SELECT PositionChangeID, PositionID, CID, ChangeTypeID, Occurred,
       PreviousStopRate, StopRate, PreviousLimitRate, LimitRate,
       AmountChanged, IsTslEnabled
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE PositionID = 123456789
ORDER BY Occurred DESC
```

### 8.2 Check all change types for a customer in the last week

```sql
SELECT ChangeTypeID, COUNT(*) AS EventCount
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE CID = 12345678
  AND Occurred >= DATEADD(day, -7, GETUTCDATE())
GROUP BY ChangeTypeID
ORDER BY EventCount DESC
```

### 8.3 Find stop loss edit events with before/after rates

```sql
SELECT TOP 10 PositionID, CID, Occurred,
       PreviousStopRate, StopRate,
       CASE WHEN StopRate > PreviousStopRate THEN 'Tightened' ELSE 'Widened' END AS Direction
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE CID = 12345678
  AND ChangeTypeID = 1
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 28 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionChangeLog_Insert | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PositionChangeLog_Insert.sql*
