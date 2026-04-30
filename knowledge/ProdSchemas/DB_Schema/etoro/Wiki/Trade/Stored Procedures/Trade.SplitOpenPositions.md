# Trade.SplitOpenPositions

> Orchestrates stock split adjustments for all open positions of an instrument by identifying affected positions, distributing work across 10 parallel SQL Agent jobs, handling US customer precision, managing demo tree synchronization, and retrying failures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (identifies the split event from History.SplitRatio) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SplitOpenPositions is the main orchestrator for adjusting all open positions when a stock split occurs. Unlike Trade.OpenOrdersSplit (which adjusts pending orders) and Trade.CloseOrdersSplit (which adjusts historical closed orders), this procedure handles live open positions in Trade.PositionTbl - the most complex and sensitive part of the split process.

The procedure:
1. Identifies all affected positions (opened before the split date, not yet processed)
2. Determines US customer status for special rounding rules (US regulations require different precision)
3. Distributes positions across 10 parallel SQL Agent jobs for high throughput
4. Waits for all jobs to complete, retries failures
5. For demo environments: additionally synchronizes tree info from real server
6. Logs errors, sends alerts for unrecoverable failures, and marks the split as completed

The parallelization is achieved via NtilePositionID (position modulo 10), with each SQL Agent job processing one partition. This is a long-running process with WAITFOR DELAY polling.

---

## 2. Business Logic

### 2.1 Position Identification and Preparation

**What**: Identifies all positions affected by the split and prepares work distribution.

**Columns/Parameters Involved**: `@SplitID`, `InstrumentID`, `MinDate`, `AmountRatio`, `PriceRatio`

**Rules**:
- Reads split ratios from History.SplitRatio (uses full-precision ratios when available)
- Validates split exists and IsCompletedOpenPositions=0
- Selects positions from Trade.Position where InitDateTime < MinDate AND InstrumentID matches
- Excludes already-processed positions (LEFT JOIN History.PositionSplit)
- Assigns NtilePositionID = PositionPartitionCol % 10 + 1 for parallel distribution
- Determines IsUsCustomer via Trade.IsUsUser function for each CID

### 2.2 US Customer Precision Handling

**What**: Computes rounding adjustments for US customers who require 5-decimal precision.

**Columns/Parameters Involved**: `IsUsCustomer`, `AmountInUnitsDecimal`, `AmountRatio`

**Rules**:
- US customer positions use @UsUnitsPrecision = 0.00001 (5 decimals)
- Compares per-position rounding ("eToroCalc") vs aggregate rounding ("ApexCalc")
- Distributes remainder units across positions to match APEX settlement system

### 2.3 Parallel Job Execution

**What**: Launches 10 SQL Agent jobs in parallel to process positions.

**Columns/Parameters Involved**: `@IsReal`, `Trade.PositionToSplitByJob`

**Rules**:
- Real environment: "etoro - Split Positions 1" through "10"
- Demo environment: "tradonomi - Split Positions 1" through "10"
- Polls every 30 seconds via WAITFOR DELAY until all PositionWasSplit != 0
- Retry phase: reassigns failed positions (PositionWasSplit=-1) to NtilePositionID=11

### 2.4 Demo Tree Synchronization

**What**: For demo environments, synchronizes PositionTreeInfo from real server.

**Columns/Parameters Involved**: `@IsReal`, `TreeID`, `dbo.RealPositionTreeInfo`

**Rules**:
- Only runs when @IsReal=0 (demo)
- Reads tree info (LimitRate, StopRate, NextThresHold, SLManualVer) from dbo.RealPositionTreeInfo
- Distributes across 3 parallel jobs: "tradonomi - Split DemoTreeToSplitFromReal 1-3"
- Same retry pattern as position splits

### 2.5 Completion and Error Handling

**What**: Marks split as completed, logs errors, sends alerts.

**Columns/Parameters Involved**: `@SplitID`, `History.SplitRatio.IsCompletedOpenPositions`

**Rules**:
- Marks IsCompletedOpenPositions=1 in History.SplitRatio
- Logs failed positions to History.PositionSplitError
- Logs failed trees to History.TreeSplitError (demo only)
- Calls Trade.AlertSplitPositionEndedWithError for position failures
- Calls Trade.AlertSplitTreeEndedWithErrorDemo for tree failures (demo)
- Truncates staging tables after completion
- RAISERROR if any failures remain

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | Identifier of the split event in History.SplitRatio. Must reference an incomplete split (IsCompletedOpenPositions=0). |
| 2 | @BatchSize | INT | YES | 2000 | CODE-BACKED | Batch size parameter (declared but used by the SQL Agent job procedures, not directly in this orchestrator). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID | History.SplitRatio | READ + UPDATE | Reads split ratios; marks IsCompletedOpenPositions=1 |
| InstrumentID | Trade.ProviderToInstrument | READ | Reads OnePip for precision calculations |
| InstrumentID | Trade.Position | READ | Identifies all affected open positions |
| @SplitID | History.PositionSplit | READ | Excludes already-processed positions |
| CID | Trade.IsUsUser | Function call | Determines US customer status for precision |
| - | Trade.PositionToSplitByJob | TRUNCATE + INSERT + READ | Staging table for parallel job distribution |
| - | Trade.UsUnitsToAddByPositionToSplitByJob | TRUNCATE + INSERT | US customer rounding adjustments |
| - | Trade.DemoTreeToSplitFromReal | TRUNCATE + INSERT + READ | Staging for demo tree synchronization |
| - | Trade.DebugSplitwithError | TRUNCATE | Debug/error tracking |
| - | dbo.RealPositionTreeInfo | READ | Tree info from real server (demo) |
| - | History.PositionSplitError | INSERT | Error log for failed position splits |
| - | History.TreeSplitError | INSERT | Error log for failed tree splits (demo) |
| @SplitID | Trade.AlertSplitPositionEndedWithError | EXEC | Sends alerts for position split failures |
| @SplitID | Trade.AlertSplitTreeEndedWithErrorDemo | EXEC | Sends alerts for tree split failures (demo) |
| FeatureID=22 | Maintenance.Feature | READ | Determines real vs demo environment |
| - | msdb.dbo.sp_start_job | EXEC | Launches SQL Agent jobs for parallel processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActivateSplit_Inner | (upstream) | EXEC | Called as part of the split activation pipeline |
| Stock split pipeline | External | Orchestrates open position splits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SplitOpenPositions (procedure - orchestrator)
+-- History.SplitRatio (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.Position (view)
+-- History.PositionSplit (table)
+-- Trade.IsUsUser (function)
+-- Trade.PositionToSplitByJob (table - staging)
+-- Trade.UsUnitsToAddByPositionToSplitByJob (table - staging)
+-- Trade.DemoTreeToSplitFromReal (table - staging, demo only)
+-- Trade.DebugSplitwithError (table - debug)
+-- dbo.RealPositionTreeInfo (table/view - demo only)
+-- History.PositionSplitError (table)
+-- History.TreeSplitError (table - demo only)
+-- Trade.AlertSplitPositionEndedWithError (procedure)
+-- Trade.AlertSplitTreeEndedWithErrorDemo (procedure - demo only)
+-- Maintenance.Feature (table)
+-- SQL Agent Jobs: "etoro/tradonomi - Split Positions 1-10"
+-- SQL Agent Jobs: "tradonomi - Split DemoTreeToSplitFromReal 1-3" (demo)
+-- SQL Agent Jobs: "etoro/tradonomi - Split Positions with Errors" (retry)
+-- SQL Agent Jobs: "tradonomi - Split DemoTreeToSplitFromReal with Errors" (retry, demo)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | READ (split ratios) + UPDATE (mark completed) |
| Trade.ProviderToInstrument | Table | READ (OnePip for precision) |
| Trade.Position | View | READ (identify affected positions) |
| History.PositionSplit | Table | READ (exclude already-processed) |
| Trade.IsUsUser | Function | CROSS APPLY (determine US customer status) |
| Trade.PositionToSplitByJob | Table | Staging for parallel job work distribution |
| Trade.UsUnitsToAddByPositionToSplitByJob | Table | US rounding adjustments |
| Trade.DemoTreeToSplitFromReal | Table | Demo tree sync staging |
| dbo.RealPositionTreeInfo | Table/View | READ (tree info from real server) |
| History.PositionSplitError | Table | INSERT (error logging) |
| History.TreeSplitError | Table | INSERT (error logging, demo) |
| Trade.AlertSplitPositionEndedWithError | Procedure | EXEC (alert on failures) |
| Trade.AlertSplitTreeEndedWithErrorDemo | Procedure | EXEC (alert on demo failures) |
| Maintenance.Feature | Table | READ (FeatureID=22: real vs demo) |
| msdb.dbo.sp_start_job | System procedure | EXEC (launches SQL Agent jobs) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Split activation pipeline | Procedure chain | EXEC - open position split step |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 10 parallel SQL Agent jobs | Performance | Distributes work via NtilePositionID modulo 10 |
| WAITFOR DELAY '00:00:30' | Polling | Checks job completion every 30 seconds |
| Retry mechanism | Resilience | Failed positions (PositionWasSplit=-1) re-queued to NtilePositionID=11 |
| Full-precision ratios | Accuracy | Uses DECIMAL(38,19) for PriceRatio and AmountRatio |
| US precision: 5 decimals | Regulation | US customers use 0.00001 precision, matching APEX settlement |
| OPTION(RECOMPILE) | Performance | Position identification query recompiled for parameter sniffing mitigation |
| PositionWasSplit states | Status tracking | 0=not processed, 1=success, -1=failure, -2=retry failure |
| TRY/CATCH with THROW | Error handling | Re-throws to caller |

---

## 8. Sample Queries

### 8.1 Check pending open position splits

```sql
SELECT ID, InstrumentID, IsCompletedOpenPositions, MinDate
FROM   History.SplitRatio WITH (NOLOCK)
WHERE  IsCompletedOpenPositions = 0;
```

### 8.2 Monitor split job progress

```sql
SELECT NtilePositionID,
       COUNT(*) AS Total,
       SUM(IIF(PositionWasSplit = 1, 1, 0)) AS Completed,
       SUM(IIF(PositionWasSplit = 0, 1, 0)) AS Pending,
       SUM(IIF(PositionWasSplit = -1, 1, 0)) AS Failed
FROM   Trade.PositionToSplitByJob WITH (NOLOCK)
GROUP BY NtilePositionID
ORDER BY NtilePositionID;
```

### 8.3 Check split errors

```sql
SELECT PositionID, SplitID, InsertDate, ErrorMessage
FROM   History.PositionSplitError WITH (NOLOCK)
WHERE  SplitID = 42
ORDER BY InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (AlertSplitPositionEndedWithError, AlertSplitTreeEndedWithErrorDemo) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SplitOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SplitOpenPositions.sql*
