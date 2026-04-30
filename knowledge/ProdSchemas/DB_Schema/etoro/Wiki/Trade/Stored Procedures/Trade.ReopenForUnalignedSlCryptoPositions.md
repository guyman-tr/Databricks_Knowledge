# Trade.ReopenForUnalignedSlCryptoPositions

> Automated recovery job that identifies crypto positions closed by stop-loss at near-total loss (99%+ loss) due to misaligned SL configuration, groups them by the instrument-precision-based minimum stop rate, and creates reopen operations with a corrected stop rate equal to the minimum representable price for each instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters (scheduled job) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenForUnalignedSlCryptoPositions is a compensation recovery job designed to correct a class of historical data quality issue: crypto positions that were prematurely closed by their stop-loss because the stop-loss rate was not properly aligned to the minimum representable price for the instrument. When a crypto price approaches near-zero (e.g., 0.0000001), a misaligned SL at 0 or a slightly higher value could trigger a stop-loss close even though the position still had value. This procedure finds such affected positions and creates reopen operations with a corrected RequestedStopRate equal to 1 / 10^Precision (the smallest non-zero price the instrument can represent).

The procedure groups positions by the calculated NewStopRate (different instruments have different Precision values), creates one ReopenOperation per distinct stop rate, inserts all positions for that rate into Trade.PositionToReopen, validates them (removing ineligible positions), and sends an approval request email. The reopen operation is created with CompensateOnStopLossDelta=1 to compensate customers for the PnL difference caused by the misaligned SL.

This procedure exists to address a systemic issue with crypto position stop-loss precision that affected customers who had long positions (ActionType=1) at x1 leverage (Leverage=1) on crypto instruments that closed within the last 15 days with a near-total loss.

Data flow: No parameters - intended for scheduled job execution. Sources History.PositionSlim for closed positions. Excludes: internal accounts (PlayerLevelID=4), LabelID=30 accounts, Israeli customers (CountryID=250). Scoped to 12 specific crypto instrument IDs (100000-100023). Hardcoded lower bound: OpenOccurred >= 2017-04-01.

---

## 2. Business Logic

### 2.1 Position Eligibility Filter

**What**: Identifies crypto positions that qualify for SL-correction-based reopening.

**Columns/Parameters Involved**: `PositionID`, `CID`, `InstrumentID`, `Leverage`, `ActionType`, `IsSettled`, `CloseOccurred`, `NetProfit`, `Amount`, `ReopenForPositionID`

**Rules**:
- Instrument scope (hardcoded): InstrumentID IN (100000, 100001, 100002, 100003, 100004, 100005, 100007, 100017, 100018, 100020, 100022, 100023). These are crypto instrument IDs.
- Time window: CloseOccurred > DATEADD(dd, -15, GETDATE()). Only positions closed within the last 15 days.
- Position characteristics: IsSettled=1 (fully settled), Leverage=1 (not leveraged), ActionType=1 (long position - BUY direction).
- Loss threshold: -dp.NetProfit > 0.99 * dp.Amount. The loss must be >= 99% of the invested amount (near-total loss).
- No existing reopen: ReopenForPositionID IS NULL (this wasn't already a reopened position), Trade.Position.ReopenForPositionID IS NULL (no live position already reopened from this one), History.PositionToReopen.ClosedPositionID IS NULL (not already queued for reopen).
- Customer exclusions: PlayerLevelID != 4 (not internal), LabelID != 30, CountryID != 250 (not Israeli customers).
- Hard lower limit: OpenOccurred >= '20170401' (positions opened before April 2017 excluded).

### 2.2 NewStopRate Calculation (Minimum Representable Price)

**What**: Calculates the corrected stop rate as the smallest non-zero price for each instrument based on its precision.

**Columns/Parameters Involved**: `NewStopRate`, `di.Precision`

**Rules**:
- NewStopRate = CAST(1 AS DECIMAL(16,8)) / POWER(10, di.Precision).
- Trade.ProviderToInstrument.Precision defines how many decimal places the instrument supports.
- Example: Precision=8 -> NewStopRate = 1/100000000 = 0.00000001 (1 satoshi for BTC-like instruments).
- This is the corrected stop-loss rate: the position should have been protected at this minimum price, not closed at a higher rate.
- Positions are grouped by NewStopRate because different instruments with the same Precision get the same ReopenOperation.

### 2.3 Reopen Operation Creation (One Per Distinct NewStopRate)

**What**: Creates one ReopenOperation per distinct NewStopRate, inserting all qualifying positions for that rate.

**Columns/Parameters Involved**: `@ReopenOperationID`, `@NewStopRate`

**Rules**:
- WHILE loop iterates over distinct NewStopRate values from #RatesToReOpen.
- For each rate: EXEC Trade.ReopenOperationAdd with UserName='ReopenForUnalignedSlCryptoPositions Job', ValidateUserBalance=0, RequestedStopRate=@NewStopRate, RequestedLimitRate=NULL, CompensateOnStopLossDelta=1, IsManual=0.
- INSERT INTO Trade.PositionToReopen all positions with that NewStopRate.
- EXEC Trade.ReopenOperationValidation to eliminate ineligible positions.
- EXEC Trade.ReopenOperationSendApprovalRequest to send the approval email.
- ValidateUserBalance=0: balance check skipped (this is a recovery operation, not a standard reopen).
- CompensateOnStopLossDelta=1: customers are compensated for the SL delta (difference between actual close rate and the minimum stop rate).
- IsManual=0: automated operation, not operator-initiated.

**Diagram**:
```
Trade.ReopenForUnalignedSlCryptoPositions()
    |
    v
SELECT qualifying crypto positions from History.PositionSlim
    (crypto InstrumentIDs, closed within 15 days, IsSettled=1, Leverage=1, ActionType=1)
    (loss >= 99% of Amount, no existing reopen)
    (exclude: internal, LabelID=30, Israel)
    |
    v
Calculate NewStopRate = 1/10^Precision per position
    |
    v
WHILE each distinct NewStopRate:
    |
    |- EXEC ReopenOperationAdd(StopRate=@NewStopRate, CompensateOnStopLossDelta=1, IsManual=0)
    |- INSERT Trade.PositionToReopen (positions with this NewStopRate)
    |- EXEC ReopenOperationValidation
    \- EXEC ReopenOperationSendApprovalRequest
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Procedure operates as an autonomous scheduled job.

**Temp tables created**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | #PositionsToReopenData | Temp Table | - | - | CODE-BACKED | Intermediate result: eligible positions with their PositionID, CID, and calculated NewStopRate. Dropped at session end. |
| 2 | #RatesToReOpen | Temp Table | - | - | CODE-BACKED | Distinct NewStopRate values with IDENTITY-based loop counter IDs. Used to drive the WHILE loop. Dropped at session end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.PositionSlim | Reader (SELECT) | Source of closed crypto positions. Reads PositionID, CID, InstrumentID, CloseOccurred, NetProfit, Amount, Leverage, ActionType, IsSettled, ReopenForPositionID, OpenOccurred. |
| CID | Customer.CustomerStatic | JOIN | Filters by PlayerLevelID (exclude internal=4), LabelID (exclude 30), CountryID (exclude Israel=250). |
| InstrumentID | Trade.ProviderToInstrument | JOIN | Reads Precision to calculate NewStopRate = 1/10^Precision. |
| PositionID | Trade.Position | LEFT JOIN | Checks for existing live reopen (ReopenForPositionID IS NULL guard). |
| ClosedPositionID | History.PositionToReopen | LEFT JOIN | Checks for already-queued reopen attempts (IS NULL guard). |
| (call) | Trade.ReopenOperationAdd | Callee | Creates one ReopenOperation per distinct NewStopRate. |
| (call) | Trade.ReopenOperationValidation | Callee | Validates each operation's positions after insertion. |
| (call) | Trade.ReopenOperationSendApprovalRequest | Callee | Sends approval request email for each operation. |
| ReopenOperationID | Trade.PositionToReopen | Writer (INSERT) | Inserts qualifying positions for each NewStopRate group. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Intended for scheduled SQL Agent job execution - not called by other procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenForUnalignedSlCryptoPositions (procedure)
├── History.PositionSlim (table)
├── Customer.CustomerStatic (table)
├── Trade.ProviderToInstrument (table)
├── Trade.Position (table)
├── History.PositionToReopen (table)
├── Trade.PositionToReopen (table)
├── Trade.ReopenOperationAdd (procedure)
│     └── Trade.ReopenOperation (table)
├── Trade.ReopenOperationValidation (procedure)
│     ├── Trade.ReopenOperation (table)
│     ├── Trade.PositionToReopen (table)
│     ├── History.Position (table)
│     └── History.PositionToReopen (table)
└── Trade.ReopenOperationSendApprovalRequest (procedure)
      ├── Trade.ReopenOperation (table)
      ├── Trade.PositionToReopen (table)
      └── msdb.dbo.sp_send_dbmail
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table | Source of closed position data for eligibility filtering. |
| Customer.CustomerStatic | Table | Customer exclusion filters (PlayerLevelID, LabelID, CountryID). |
| Trade.ProviderToInstrument | Table | Reads Precision for NewStopRate calculation. |
| Trade.Position | Table | Guard: checks for existing reopened position (ReopenForPositionID). |
| History.PositionToReopen | Table | Guard: checks for already-queued reopen. |
| Trade.PositionToReopen | Table | INSERT target for positions per reopen operation. |
| Trade.ReopenOperationAdd | Procedure | Creates the ReopenOperation record per distinct rate. |
| Trade.ReopenOperationValidation | Procedure | Validates and prunes invalid positions from the operation. |
| Trade.ReopenOperationSendApprovalRequest | Procedure | Sends approval email to operators. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent scheduled job | External job | Calls this procedure on a schedule to process crypto SL corrections. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: No explicit temp table indexes are created (unlike the ReportWrongDataInCustomerMoney family which creates CLUSTERED indexes on temp tables). For large crypto user bases this could be a performance concern.

### 7.2 Constraints

N/A for stored procedure.

**Hardcoded crypto instrument IDs**: 100000, 100001, 100002, 100003, 100004, 100005, 100007, 100017, 100018, 100020, 100022, 100023. InstrumentIDs 100006, 100008-100016, 100019, 100021 are intentionally excluded (possibly delisted or not affected by this SL issue). This list should be updated if new crypto instruments are added to the platform.

**DROP TABLE IF EXISTS at start**: `DROP TABLE IF EXISTS #PositionsToReopenData, #RatesToReOpen` - defensive cleanup in case a prior run failed mid-execution.

---

## 8. Sample Queries

### 8.1 Dry-run: Preview positions that would be processed

```sql
SELECT dp.PositionID, dp.CID, dp.InstrumentID,
    CAST(1 AS DECIMAL(16,8))/POWER(10, di.Precision) AS NewStopRate,
    dp.Amount, dp.NetProfit,
    -dp.NetProfit / dp.Amount * 100 AS LossPct
FROM History.PositionSlim dp WITH (NOLOCK)
JOIN Customer.CustomerStatic dc WITH (NOLOCK) ON dc.CID = dp.CID
JOIN Trade.ProviderToInstrument di WITH (NOLOCK) ON di.InstrumentID = dp.InstrumentID
LEFT JOIN Trade.Position tp WITH (NOLOCK) ON dp.CID = tp.CID AND dp.PositionID = tp.ReopenForPositionID
LEFT JOIN History.PositionToReopen rhp WITH (NOLOCK) ON dp.PositionID = rhp.ClosedPositionID
WHERE dc.PlayerLevelID <> 4
    AND dc.LabelID <> 30
    AND dc.CountryID <> 250
    AND dp.InstrumentID IN (100000,100001,100002,100003,100004,100005,100007,100017,100018,100020,100022,100023)
    AND dp.CloseOccurred > DATEADD(dd, -15, GETDATE())
    AND dp.IsSettled = 1
    AND dp.Leverage = 1
    AND dp.ActionType = 1
    AND -dp.NetProfit > 0.99 * dp.Amount
    AND dp.ReopenForPositionID IS NULL
    AND tp.PositionID IS NULL
    AND rhp.ClosedPositionID IS NULL
    AND dp.OpenOccurred >= '20170401'
ORDER BY dp.InstrumentID, dp.CloseOccurred;
```

### 8.2 Check distinct stop rates that would be created

```sql
SELECT CAST(1 AS DECIMAL(16,8))/POWER(10, di.Precision) AS NewStopRate, COUNT(*) AS PositionCount
FROM History.PositionSlim dp WITH (NOLOCK)
JOIN Trade.ProviderToInstrument di WITH (NOLOCK) ON di.InstrumentID = dp.InstrumentID
WHERE dp.InstrumentID IN (100000,100001,100002,100003,100004,100005,100007,100017,100018,100020,100022,100023)
    AND dp.CloseOccurred > DATEADD(dd, -15, GETDATE())
GROUP BY CAST(1 AS DECIMAL(16,8))/POWER(10, di.Precision);
```

### 8.3 View reopen operations created by this job

```sql
SELECT ReopenOperationID, Occurred, UserName, RequestedStopRate, ValidateUserBalance, IsExecuted
FROM Trade.ReopenOperation WITH (NOLOCK)
WHERE UserName = 'ReopenForUnalignedSlCryptoPositions Job'
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenForUnalignedSlCryptoPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenForUnalignedSlCryptoPositions.sql*
