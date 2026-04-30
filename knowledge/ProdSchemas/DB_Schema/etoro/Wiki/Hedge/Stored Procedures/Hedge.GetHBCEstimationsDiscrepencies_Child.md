# Hedge.GetHBCEstimationsDiscrepencies_Child

> Child variant of the HBC discrepancy check: accepts caller-supplied time window parameters instead of reading from Maintenance.Feature, uses Trade.GetPositionData (not Slim), and writes the cursor advance back to the primary replica via OPENQUERY to a linked server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LastTime, @TimeRangeSeconds, @MaxTime - caller-supplied time window (IN, not OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHBCEstimationsDiscrepencies_Child is the "child" worker variant of the HBC discrepancy reconciliation system. Where the parent procedure (GetHBCEstimationsDiscrepencies) reads the time window from Maintenance.Feature internally and returns @MaxTime as an OUTPUT, this _Child variant receives the window parameters from the caller. The parent (or the HedgeAlertService orchestrator) reads the Feature config, passes it as arguments, and calls this procedure to perform the actual check.

The key operational difference is cursor advancement: instead of the caller updating the Feature table after receiving @MaxTime, this procedure writes the @MaxTime cursor back to the primary replica database via OPENQUERY to [AO-REAL-DB]. This pattern was introduced in 2021 (by Shany) to handle a scenario where the query runs on a secondary replica (read-only) but the Feature update must go to the primary. The commented-out line (`UPDATE [AZR-N-REAL-DB-3_SS]...`) shows the pre-2021 approach was a direct update.

The procedure uses `Trade.GetPositionData` (rather than the Slim variant) for the position join, which includes the full position dataset with potentially more columns but the same InitExecutionID/EndExecutionID linkage.

---

## 2. Business Logic

### 2.1 Caller-Supplied Time Window (vs Parent's Self-Read)

**What**: The window parameters are passed IN rather than read from Maintenance.Feature.

**Columns/Parameters Involved**: `@LastTime`, `@TimeRangeSeconds`, `@MaxTime`

**Rules**:
- @LastTime: start of window (= Maintenance.Feature FeatureID 43 value, read by the orchestrator).
- @TimeRangeSeconds: window width in seconds (= Maintenance.Feature FeatureID 42 value).
- @MaxTime: window end (= DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()), calculated by orchestrator before calling).
- Unlike the parent, @MaxTime here is an IN parameter (not OUTPUT) - the orchestrator calculated it before the call.
- The same filter logic applies: `exe.EndTime >= @LastTime AND exe.EndTime < @MaxTime`.

### 2.2 Cursor Advancement via OPENQUERY (Primary Replica Write)

**What**: After producing discrepancy results, this procedure advances the cursor on the primary replica using OPENQUERY.

**Rules**:
- At the end: `UPDATE Openquery([AO-REAL-DB], 'SELECT Value FROM [etoro].Maintenance.Feature where FeatureID = 43') SET [Value] = @MaxTime`
- [AO-REAL-DB] is a linked server pointing to the primary replica (Always On primary).
- This pattern runs when the procedure executes on a secondary replica (read-only) - it cannot write locally.
- The commented-out original: `UPDATE [AZR-N-REAL-DB-3_SS].[etoro].Maintenance.Feature SET Value = @MaxTime where FeatureID = 43` (direct write, pre-2021).
- Note: No temp table indexes on #executions (unlike parent) - a minor performance difference on large result sets.

### 2.3 Trade.GetPositionData vs Trade.GetPositionDataSlim

**What**: This variant uses the full position view, not the Slim variant used by the parent.

**Rules**:
- Trade.GetPositionData: includes all position columns (may be heavier).
- Trade.GetPositionDataSlim: lighter view with subset of columns, used by the parent.
- Both expose InitExecutionID, EndExecutionID, HedgeServerID, IsBuy, LotCountDecimal, OpenOccurred, CloseOccurred, IsOpened, CID - the columns needed for this check.
- The behavioral difference is negligible for this procedure's output; the full view is used here for historical reasons (pre-Slim).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastTime | datetime | NO | - | CODE-BACKED | Start of the analysis window. Caller must supply this (read from Maintenance.Feature FeatureID 43 before calling). Equivalent to @LastTime in the parent, but passed IN rather than read internally. |
| 2 | @TimeRangeSeconds | int | NO | - | CODE-BACKED | Duration of the lookback window in seconds. Caller must supply this (read from Maintenance.Feature FeatureID 42 before calling). Used in the WHERE clause via the pre-calculated @MaxTime. |
| 3 | @MaxTime | datetime | NO | - | CODE-BACKED | End of the analysis window. Caller calculates this as DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()) before calling. IN parameter (not OUTPUT) - unlike the parent's OUTPUT variant. Also written back to primary replica Feature FeatureID 43 via OPENQUERY at end. |

**Output Columns** (returned resultset - identical to parent GetHBCEstimationsDiscrepencies):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | NotificationTime | datetime | NO | - | CODE-BACKED | EndTime of the discrepant HBC execution. Inherited from parent. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server of the discrepant execution. Inherited from parent. |
| 6 | InstrumentID | int | NO | - | CODE-BACKED | The instrument with the lot mismatch. Inherited from parent. |
| 7 | AmountInLots | decimal | YES | - | CODE-BACKED | SumLotDecimal - ExecutionAmountInLots. The lot gap (positive = under-hedged, negative = over-hedged). Inherited from parent. |
| 8 | IsBuy | bit | NO | - | CODE-BACKED | Direction of customer positions (PositionIsBuy). Inherited from parent. |
| 9 | IsOpen | bit | NO | - | CODE-BACKED | 1=opening hedge, 0=closing hedge (derived from direction match). Inherited from parent. |
| 10 | Description | varchar | NO | - | CODE-BACKED | Diagnostic string with ExecutionID, ExecutionAmountInLots, SumLotDecimal, IsOpen. Inherited from parent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID join | Hedge.HBCExecutionLog | Lookup / Read | Same as parent - source of execution amounts. |
| InitExecutionID/EndExecutionID join | Trade.GetPositionData | Cross-schema Lookup | Uses full position view (not Slim variant). |
| CID join | Customer.Customer | Cross-schema Lookup | Filters PlayerLevelID=4 (internal accounts). |
| OPENQUERY write | Maintenance.Feature (via [AO-REAL-DB]) | Cross-server Write | Advances cursor FeatureID 43 on primary replica after processing. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @LastTime, @TimeRangeSeconds, @MaxTime | Caller | Orchestrator calls this variant when running on secondary replica; provides window params. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHBCEstimationsDiscrepencies_Child (procedure)
├── Hedge.HBCExecutionLog (table)
├── Trade.GetPositionData (view) [cross-schema - full position view]
├── Customer.Customer (table) [cross-schema]
└── Maintenance.Feature (table) [via OPENQUERY - write back to [AO-REAL-DB] primary]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCExecutionLog | Table | Same join as parent. IsSuccess=1, time window filter. |
| Trade.GetPositionData | View | Cross-schema: full position view (vs GetPositionDataSlim in parent). Same columns used. |
| Customer.Customer | Table | Cross-schema: PlayerLevelID <> 4 filter. |
| Maintenance.Feature (linked server) | Table | Write-only via OPENQUERY to [AO-REAL-DB]: advances FeatureID 43 cursor to @MaxTime. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Calls this _Child variant for secondary-replica execution with pre-computed window params. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Runtime temp table**: `#executions` - created per call. No NC indexes (unlike parent - a minor performance difference).

**Change history** (from DDL comments):
- 2015-07-07 (Adi, FB:26726): Modified WHERE clause for Trade.GetPositionData; added IsOpened column criteria; cast 1 as BIT.
- 2021-03-02 (Shany): Removed CTE, switched to #Table for performance. Changed cursor write to use OPENQUERY on secondary replica (instead of direct linked server update).

---

## 8. Sample Queries

### 8.1 Execute the child check with manual window params

```sql
DECLARE @LastTime DATETIME = '2026-03-19 00:00:00';
DECLARE @TimeRangeSeconds INT = 30;
DECLARE @MaxTime DATETIME = DATEADD(second, -@TimeRangeSeconds, GETUTCDATE());

EXEC Hedge.GetHBCEstimationsDiscrepencies_Child
    @LastTime        = @LastTime,
    @TimeRangeSeconds = @TimeRangeSeconds,
    @MaxTime         = @MaxTime;
```

### 8.2 Read the current cursor position (before calling)

```sql
SELECT FeatureID,
       CASE FeatureID WHEN 42 THEN 'TimeRangeSeconds' WHEN 43 THEN 'LastTime' END AS FeatureName,
       Value
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID IN (42, 43);
```

### 8.3 Compare output to parent variant (should match for same time window)

```sql
-- Parent: reads its own window from Maintenance.Feature, outputs @MaxTime
DECLARE @MaxTimeParent DATETIME;
EXEC Hedge.GetHBCEstimationsDiscrepencies @MaxTime = @MaxTimeParent OUTPUT;
SELECT @MaxTimeParent AS ParentWindowEnd;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC reconciliation via GetHBCEstimationsDiscrepencies family; _Child variant handles secondary-replica execution scenario. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 parent analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHBCEstimationsDiscrepencies_Child | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHBCEstimationsDiscrepencies_Child.sql*
