# History.LogMirrorSLClose

> Sole writer for Mirror Stop Loss success events - inserts a single audit row into History.MirrorSLCloseLog when the MSL engine successfully force-closes a copy-trade relationship at the stop-loss threshold.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - the copy relationship that was force-closed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogMirrorSLClose` is the MSL (Mirror Stop Loss) success audit writer. When eToro's MSL engine determines that a copier's portfolio value has fallen to or below the configured stop-loss threshold and successfully force-closes the copy relationship, this procedure is called to record the event permanently. It inserts a single row into `History.MirrorSLCloseLog` capturing the full financial snapshot of the close: the stop-loss threshold, the cash and invested amounts, the net P&L, the market rates used, and the IDs of all positions that were closed.

The procedure is the success counterpart to `History.LogMirrorSLCloseFail`, which is called when an MSL close attempt fails. Together, they provide a complete audit trail of every MSL engine decision - both the events that succeeded and those that failed.

The `StockOrdersAmount` column in the target table is always written as 0 (hardcoded), meaning the caller does not supply this value. This is a design decision in the MSL engine - real stock order amounts are tracked separately and not factored into the MSL close log.

---

## 2. Business Logic

### 2.1 MSL Financial Snapshot Persistence

**What**: The MSL engine computes the full financial state of the copy portfolio at the moment of the forced close and passes all components to this procedure for durable storage.

**Columns/Parameters Involved**: `@MirrorID`, `@MirrorSL`, `@MirrorAmount`, `@InvestedAmount`, `@NetProfit`, `@CloseOccurred`

**Rules**:
- @MirrorSL = the stop-loss threshold the portfolio reached (e.g., $2,500 means "stop copy if value drops below $2,500")
- @MirrorAmount = total copy allocation (cash held within the copy, not invested)
- @InvestedAmount = amount currently deployed in open positions at time of close
- @NetProfit = total realized + unrealized P&L at time of close (negative for MSL triggers - loss triggered the stop)
- @CloseOccurred = UTC timestamp when the forced close completed (supplied by caller, not auto-defaulted)
- Reconciliation identity: MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount should approximately equal MirrorSL (money returned to copier equals the stop-loss floor). Monitored by dbo.P_MSLMonitoring.

### 2.2 StockOrdersAmount Hardcoded to Zero

**What**: The target table column StockOrdersAmount is always written as 0 by this procedure - the caller does not pass this value.

**Columns/Parameters Involved**: `StockOrdersAmount` (INSERT target)

**Rules**:
- StockOrdersAmount is not a parameter of this procedure
- The INSERT always supplies literal 0 for this column
- The column exists in History.MirrorSLCloseLog with DEFAULT 0 and participates in the reconciliation formula used by dbo.P_MSLMonitoring
- Implication: real stock order amounts (if any exist at MSL close time) are NOT captured via this procedure and are excluded from the MSL reconciliation log

### 2.3 Position and Rate Context

**What**: The procedure captures two diagnostic context strings: the market rates at time of close and the list of position IDs that were force-closed.

**Columns/Parameters Involved**: `@RatesList`, `@PositionIDs`

**Rules**:
- @PositionIDs: semicolon-delimited list of all position IDs closed as part of this MSL event (e.g., "2152662906;2152658629;...") - enables full traceability of which positions were closed
- @RatesList: semicolon-delimited market rate snapshot at close - used by Trade.IsMSLRatesEqualsToEndForexRate and V2 to validate that the rates used in the MSL calculation match actual forex end rates
- Both are varchar(MAX) - large, diversified copy portfolios can generate very long strings
- Both can be NULL (passed as such if not available in the calling code path)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The copy-trade mirror relationship that was force-closed by the MSL engine. Maps to History.MirrorSLCloseLog.MirrorID (NONCLUSTERED indexed). References Trade.Mirror.MirrorID - no FK enforced. Primary key for customer dispute lookup ("why was my copy stopped?"). |
| 2 | @MirrorSL | MONEY | NO | - | CODE-BACKED | The stop-loss threshold amount (in account currency) that the portfolio fell to or below. This is the "floor" that triggered the MSL close. Stored as MirrorSL in History.MirrorSLCloseLog. Part of the reconciliation formula: MirrorAmount + InvestedAmount + NetProfit should approximately equal MirrorSL. |
| 3 | @MirrorAmount | MONEY | NO | - | CODE-BACKED | The total copy cash balance (not invested in positions) at time of close. Stored as MirrorAmount. Part of the MSLReturnedMoney formula used by dbo.P_MSLMonitoring. |
| 4 | @InvestedAmount | MONEY | NO | - | CODE-BACKED | The total amount deployed in open positions at time of the forced close. Stored as InvestedAmount. A non-zero value indicates positions were still open when MSL fired and had to be force-closed. |
| 5 | @NetProfit | MONEY | NO | - | CODE-BACKED | Total net P&L (realized + unrealized) of the copy portfolio at close time. Stored as NetProfit. For MSL-triggered closes, this is always negative (losses pushed the portfolio to the stop-loss level). The absolute value approximates the copier's total loss. |
| 6 | @CloseOccurred | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the MSL close was successfully completed. Supplied by the calling MSL engine application - not auto-defaulted. Used by dbo.P_MSLMonitoring (WHERE CloseOccurred > DATEADD(HOUR,-1,GETDATE())) for near-real-time reconciliation monitoring. |
| 7 | @CloseTrigger | TINYINT | NO | - | CODE-BACKED | Identifies which MSL evaluation pathway triggered this close. Enum defined in MSL engine application code. Known distribution from live data: 0=scheduled check (93%), 4=3.7%, 1=2.1%, 7=0.9%. Stored as CloseTrigger. |
| 8 | @RatesList | VARCHAR(MAX) | YES | - | CODE-BACKED | Semicolon-delimited market rate snapshot for each position in the copy at time of close. Validated by Trade.IsMSLRatesEqualsToEndForexRate and V2 to ensure close rates match actual forex end rates. NULL if rates were not available to the caller. |
| 9 | @PositionIDs | VARCHAR(MAX) | YES | - | CODE-BACKED | Semicolon-delimited list of all position IDs that were simultaneously force-closed as part of this MSL event. Enables full position-level traceability for a given MSL close. NULL if no positions were open. Can be very long for large, diversified copy portfolios. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.MirrorSLCloseLog | Writes (INSERT) | Sole writer - inserts one row per successful MSL close event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MSL engine application | - | Caller | Called by the Mirror Stop Loss engine after a successful forced copy close; no callers found in the SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogMirrorSLClose (procedure)
+-- History.MirrorSLCloseLog (table - MSL success audit log)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MirrorSLCloseLog | Table | INSERT target - one row per successful MSL close |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called exclusively by the MSL engine application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- No SET NOCOUNT ON - returns row count from the INSERT (1 on success)
- No explicit transaction - single-row INSERT; atomic by default
- No error handling (no TRY/CATCH) - any failure propagates to the calling MSL engine
- No RETURN statement - procedure exits silently after INSERT
- StockOrdersAmount hardcoded to literal 0 in the INSERT VALUES list; no corresponding parameter

---

## 8. Sample Queries

### 8.1 Log a successful MSL close event

```sql
EXEC History.LogMirrorSLClose
    @MirrorID       = 1234567,
    @MirrorSL       = 2500.00,
    @MirrorAmount   = 1850.50,
    @InvestedAmount = 450.75,
    @NetProfit      = -1800.25,
    @CloseOccurred  = '2024-06-01 10:30:00',
    @CloseTrigger   = 0,
    @RatesList      = '1.08500;23450.00;...',
    @PositionIDs    = '2152662906;2152658629;2152660379'
```

### 8.2 Verify the logged MSL close event

```sql
SELECT
    MirrorStopLossCloseID,
    MirrorID,
    MirrorSL,
    MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount AS ReturnedToCustomer,
    MirrorSL - (MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount) AS Discrepancy,
    CloseOccurred,
    CloseTrigger
FROM History.MirrorSLCloseLog WITH (NOLOCK)
WHERE MirrorID = 1234567
ORDER BY CloseOccurred DESC
```

### 8.3 Recent MSL close events within the last hour (as used by P_MSLMonitoring)

```sql
SELECT
    MirrorID,
    MirrorSL,
    MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount AS MSLReturnedMoney,
    ABS(MirrorSL - (MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount)) AS Discrepancy,
    CloseOccurred,
    CloseTrigger
FROM History.MirrorSLCloseLog WITH (NOLOCK)
WHERE CloseOccurred > DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogMirrorSLClose | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogMirrorSLClose.sql*
