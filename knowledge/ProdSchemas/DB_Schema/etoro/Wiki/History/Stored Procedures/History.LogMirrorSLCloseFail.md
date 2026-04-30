# History.LogMirrorSLCloseFail

> Sole writer for Mirror Stop Loss failure events - inserts a single audit row into History.MirrorSLCloseFail when the MSL engine fails to force-close a copy-trade relationship, capturing the error message and the account state at time of failure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - the copy relationship that the MSL engine failed to close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogMirrorSLCloseFail` is the failure-side counterpart to `History.LogMirrorSLClose`. When eToro's MSL (Mirror Stop Loss) engine attempts to force-close a copy relationship because the portfolio value fell below the stop-loss threshold and that close attempt fails (due to a database error, business rule violation, or race condition), this procedure is called to record the failure permanently. It inserts a single row into `History.MirrorSLCloseFail` with the full context: the financial snapshot at the moment of the failure, the error message, and the market rates and position IDs that were involved.

Together, `History.LogMirrorSLClose` (success writer) and `History.LogMirrorSLCloseFail` (failure writer) form a complete success/failure audit trail for every MSL enforcement event. A row in this table means the copy relationship was NOT successfully closed by the MSL engine at that moment - the positions may still be open and the copier's losses may be continuing. The MSL engine may retry after a failure, in which case a failure row here may be followed by a success row in `History.MirrorSLCloseLog` for the same MirrorID.

Failures are rare in this system. The test environment has 0 rows in History.MirrorSLCloseFail, while the success table has ~28,000 rows.

---

## 2. Business Logic

### 2.1 MSL Failure Error Capture

**What**: When the MSL close attempt fails, the full error context plus the account state snapshot are captured for post-mortem investigation.

**Columns/Parameters Involved**: `@ErrorOccurred`, `@ErrorMessage`, `@MirrorID`, `@MirrorSL`, `@MirrorAmount`, `@InvestedAmount`, `@NetProfit`

**Rules**:
- A row here means the MSL close did NOT complete - the copy relationship may still be active and losses accumulating
- @ErrorMessage (varchar(max)) captures the full exception text from the MSL engine (e.g., "Deadlock victim during position close")
- @ErrorOccurred = UTC timestamp when the error was detected (supplied by caller; differs from @CloseOccurred in the success counterpart)
- Account snapshot columns (@MirrorSL, @MirrorAmount, @InvestedAmount, @NetProfit) capture the state at the moment of the failed attempt - these are identical in structure to the success procedure's parameters

### 2.2 Success/Failure Pair Pattern

**What**: Every MSL close attempt ends in exactly one of two tables: History.MirrorSLCloseLog (success) or History.MirrorSLCloseFail (failure). A MirrorID can appear in both tables if the MSL engine retried after a failure.

**Columns/Parameters Involved**: `@MirrorID`, `@CloseTrigger`

**Rules**:
- Same CloseTrigger enum as the success table: 0=scheduled check, 4, 1, 7 (defined in MSL engine application code)
- Same structural columns: @RatesList, @PositionIDs, @MirrorSL, @MirrorAmount, @InvestedAmount, @NetProfit, @CloseTrigger
- Difference from success proc: @ErrorOccurred + @ErrorMessage replace @CloseOccurred; these distinguish the two tables' semantics
- If a retry succeeds: the failure row here plus a success row in MirrorSLCloseLog both reference the same MirrorID
- StockOrdersAmount hardcoded to 0 (same as success procedure - not a parameter)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The copy-trade mirror relationship that the MSL engine attempted (and failed) to force-close. Maps to History.MirrorSLCloseFail.MirrorID. Primary correlation key for investigating why a specific copy was not stopped despite hitting the stop-loss level. |
| 2 | @MirrorSL | MONEY | NO | - | CODE-BACKED | The stop-loss threshold amount the portfolio had breached when this failed close was attempted. Same semantics as in History.LogMirrorSLClose - the floor value that should have been returned to the copier if the close had succeeded. |
| 3 | @MirrorAmount | MONEY | NO | - | CODE-BACKED | The total copy cash balance (not invested in positions) at time of the failed close attempt. Part of the MSLReturnedMoney formula for diagnostic comparison. |
| 4 | @InvestedAmount | MONEY | NO | - | CODE-BACKED | The amount deployed in open positions at time of the failed close attempt. Non-zero indicates positions that the MSL engine was trying to force-close when the error occurred. |
| 5 | @NetProfit | MONEY | NO | - | CODE-BACKED | Total net P&L (realized + unrealized) at time of the failed close. Typically negative for MSL events (losses triggered the stop). |
| 6 | @ErrorOccurred | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the MSL close error was detected by the MSL engine. Supplied by the caller. Distinguishes this parameter from @CloseOccurred in the success counterpart - in the failure case, the close did NOT complete at this time. |
| 7 | @ErrorMessage | VARCHAR(MAX) | NO | - | CODE-BACKED | The full error text from the MSL engine explaining why the close failed. Can be a database exception message (e.g., deadlock), a business rule violation, or an application-level error. Key diagnostic field for operations investigation. |
| 8 | @CloseTrigger | TINYINT | NO | - | CODE-BACKED | Identifies which MSL evaluation pathway detected the breach and triggered this close attempt. Same enum as History.LogMirrorSLClose: 0=scheduled check (dominant), 4, 1, 7 (defined in MSL engine application code). |
| 9 | @RatesList | VARCHAR(MAX) | YES | - | CODE-BACKED | Semicolon-delimited market rate snapshot at time of the failed close attempt. Can be used for post-failure analysis of what rates the MSL engine was working with when the error occurred. Validated by Trade.IsMSLRatesEqualsToEndForexRate. |
| 10 | @PositionIDs | VARCHAR(MAX) | YES | - | CODE-BACKED | Semicolon-delimited list of position IDs that were targeted for force-close by the failed MSL attempt. These positions may still be open after the failure. Used for investigation of which positions were involved. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.MirrorSLCloseFail | Writes (INSERT) | Sole writer - inserts one row per failed MSL close attempt |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MSL engine application | - | Caller | Called by the Mirror Stop Loss engine when a forced copy close fails; no callers found in the SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogMirrorSLCloseFail (procedure)
+-- History.MirrorSLCloseFail (table - MSL failure audit log)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MirrorSLCloseFail | Table | INSERT target - one row per failed MSL close attempt |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called exclusively by the MSL engine application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- No SET NOCOUNT ON - returns row count (1 on success)
- No explicit transaction - single-row INSERT; atomic by default
- No error handling (no TRY/CATCH) - failures propagate to the MSL engine caller
- No RETURN statement
- StockOrdersAmount hardcoded to literal 0 (not a parameter) - identical behavior to History.LogMirrorSLClose
- Structure is identical to History.LogMirrorSLClose except: @ErrorOccurred + @ErrorMessage replace @CloseOccurred; target table is MirrorSLCloseFail instead of MirrorSLCloseLog

---

## 8. Sample Queries

### 8.1 Log a failed MSL close attempt

```sql
EXEC History.LogMirrorSLCloseFail
    @MirrorID       = 1234567,
    @MirrorSL       = 2500.00,
    @MirrorAmount   = 1850.50,
    @InvestedAmount = 450.75,
    @NetProfit      = -1800.25,
    @ErrorOccurred  = '2024-06-01 10:30:00',
    @ErrorMessage   = 'Deadlock victim during position close batch',
    @CloseTrigger   = 0,
    @RatesList      = '1.08500;23450.00',
    @PositionIDs    = '2152662906;2152658629'
```

### 8.2 View recent MSL failures and check if they later succeeded

```sql
-- Find failures
SELECT
    mf.MirrorStopLossCloseFailID,
    mf.MirrorID,
    mf.ErrorOccurred,
    mf.ErrorMessage,
    mf.CloseTrigger
FROM History.MirrorSLCloseFail mf WITH (NOLOCK)
WHERE mf.ErrorOccurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY mf.ErrorOccurred DESC

-- Cross-reference: did the retry succeed?
SELECT
    ms.MirrorStopLossCloseID,
    ms.MirrorID,
    ms.CloseOccurred,
    ms.MirrorSL,
    ms.MirrorAmount + ms.InvestedAmount + ms.NetProfit AS ReturnedToCustomer
FROM History.MirrorSLCloseLog ms WITH (NOLOCK)
WHERE ms.MirrorID IN (
    SELECT MirrorID FROM History.MirrorSLCloseFail WITH (NOLOCK)
    WHERE ErrorOccurred >= DATEADD(DAY, -7, GETUTCDATE())
)
```

### 8.3 Compare failure rate against success rate by CloseTrigger

```sql
SELECT
    'Success' AS Outcome,
    CloseTrigger,
    COUNT(*) AS EventCount
FROM History.MirrorSLCloseLog WITH (NOLOCK)
GROUP BY CloseTrigger
UNION ALL
SELECT
    'Failure' AS Outcome,
    CloseTrigger,
    COUNT(*) AS EventCount
FROM History.MirrorSLCloseFail WITH (NOLOCK)
GROUP BY CloseTrigger
ORDER BY Outcome, EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogMirrorSLCloseFail | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogMirrorSLCloseFail.sql*
