# Hedge.GetHedgeEstimationsDiscrepencies

> EMS (Execution Management System) variant of the hedge discrepancy check: reconciles EMS filled orders against customer position unit amounts, using a 1-hour safety cap and reading from SynHedgeEMSOrders (not HBCExecutionLog).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxTime OUTPUT - upper bound of analysis window (returned to caller) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeEstimationsDiscrepencies is the EMS counterpart to the HBC discrepancy family. Where GetHBCEstimationsDiscrepencies checks HBC lot executions against customer lot counts, this procedure checks **EMS order executions** against customer **unit amounts** (AmountInUnitsDecimal). It detects cases where the total customer position units linked to an EMS order do not match the order's RequestedAmountInUnits.

The key structural difference is the execution source: instead of Hedge.HBCExecutionLog, this procedure reads from `[dbo].[SynHedgeEMSOrders]` - a synonym pointing to the EMS orders table. EMS orders use a "Filled" string OrderStatus rather than a numeric OrderState. The comparison is in units (not lots), reflected by `IsAmountInLots = 0` hardcoded in the output.

A safety guard prevents runaway queries: if @LastTime (from Maintenance.Feature FeatureID 43) is more than 1 hour old, it is capped at `DATEADD(HOUR, -1, GETUTCDATE())`. This protects against the scenario where the monitoring process stops for an extended period and then restarts with a very large time range, causing a timeout.

Called by HedgeAlertService; no SQL procedure callers within the Hedge schema.

---

## 2. Business Logic

### 2.1 1-Hour Safety Cap on @LastTime

**What**: If the stored cursor is stale (> 1 hour old), the window start is reset to 1 hour ago.

**Columns/Parameters Involved**: `@LastTime`, Maintenance.Feature FeatureID 43

**Rules**:
- @LastTime read from Maintenance.Feature FeatureID 43 (same as HBC variants).
- Guard: `IF @LastTime < DATEADD(HOUR, -1, GETUTCDATE()) SET @LastTime = DATEADD(HOUR, -1, GETUTCDATE())`
- This cap does NOT exist in the HBC variants - unique to the EMS discrepancy check.
- Purpose: "Prevents a situation where the monitoring process didn't run, and we end up with a large time range that could cause a timeout" (DDL comment).
- The caller still receives the @MaxTime output (= NOW - @TimeRangeSeconds) unchanged, but the effective query window is capped.

### 2.2 Units vs Lots Reconciliation

**What**: This procedure reconciles in units (AmountInUnitsDecimal), not lots (LotCountDecimal) as the HBC variants do.

**Columns/Parameters Involved**: `ExecutionAmount` (=RequestedAmountInUnits), `SumAmountDecimal` (=SUM(AmountInUnitsDecimal)), `IsAmountInLots`

**Rules**:
- EMS orders store their amount as `RequestedAmountInUnits` (in eToro units, not lots).
- Customer positions contribute `AmountInUnitsDecimal` per position.
- `IsAmountInLots = 0` is hardcoded in the SELECT (always units, never lots for this variant).
- Discrepancy: `ExecutionAmount <> SumAmountDecimal` (units mismatch).
- The Description string adapts: when IsAmountInLots=0, it shows "ExecutionAmountInUnits" and "SumAmountUnitsDecimal".

### 2.3 Three-Stage Temp Table Pipeline

**What**: The procedure builds results through three temp tables: positions, EMS orders, then matches.

**Rules**:
- Stage 1: `#PositionsExecutionIDs` - all recently opened/closed positions for real customers (PlayerLevelID <> 4), filtered by time window. NC indexes on InitExecutionID, EndExecutionID, HedgeServerID.
- Stage 2: `#EMSOrders` - EMS orders in the time window. NC indexes on ExecutionID, OrderStatus, HedgeServerID.
- Stage 3: `#PositionMatches` - UNION of InitExecutionID matches + EndExecutionID matches, filtered to `OrderStatus = 'Filled'` only. OPTION(RECOMPILE).
- Final: `#executions` - aggregated with SUM(AmountInUnitsDecimal) per ExecutionID. NC indexes on ExecutionAmount and SumAmountDecimal.

### 2.4 EMS Order Identification

**What**: EMS orders use string-based status and are sourced from SynHedgeEMSOrders (synonym).

**Rules**:
- `OrderStatus = 'Filled'` - string status (vs HBC's numeric `OrderState = 3/4`).
- `dbo.SynHedgeEMSOrders` is a synonym pointing to the EMS orders table. Not visible in Hedge schema DDL.
- Time filter: `StatusUpdateTime` (EMS order completion timestamp) vs HBC's `EndTime`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxTime | datetime | NO | - | CODE-BACKED | OUTPUT parameter. Set to DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()) from Maintenance.Feature FeatureID 42. Returned to caller to advance FeatureID 43 cursor. Same OUTPUT semantics as HBC parent. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | NotificationTime | datetime | NO | - | CODE-BACKED | StatusUpdateTime (completion time) of the discrepant EMS order. Alert timestamp. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server that executed the discrepant EMS order. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | The instrument with the unit mismatch. |
| 5 | DiffUnitAmount | decimal | YES | - | CODE-BACKED | SumAmountDecimal - ExecutionAmount (unit gap). Positive = customer positions have more units than the order executed. Negative = executed more units than customer sum. (Named DiffUnitAmount, unlike the lot-based AmountInLots in HBC variants.) |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | Customer position direction (PositionIsBuy). |
| 7 | IsAmountInLots | bit | NO | - | CODE-BACKED | Always 0 for this variant - amounts are in units, not lots. Hardcoded in the SELECT as `0 'IsAmountInLots'`. The Description string adapts based on this value. |
| 8 | IsOpen | bit | NO | - | CODE-BACKED | 1=opening hedge, 0=closing hedge. Derived: IIF(ExecutionIsBuy = PositionIsBuy, 1, 0). Inherited logic from HBC variants. |
| 9 | Description | varchar | NO | - | CODE-BACKED | Diagnostic string: "ExecutionID: {id} ExecutionAmountInUnits: {val} SumAmountUnitsDecimal: {val} IsOpen: {0/1}". Note: Description text adapts based on IsAmountInLots (0=units label vs 1=lots label). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID join | dbo.SynHedgeEMSOrders | Lookup / Read (synonym) | EMS orders filtered to StatusUpdateTime window and OrderStatus='Filled'. |
| InitExecutionID/EndExecutionID join | Trade.GetPositionDataSlim | Cross-schema Lookup | Customer position units grouped by execution; real customers only. |
| CID join | Customer.Customer | Cross-schema Lookup | PlayerLevelID <> 4 filter. |
| FeatureID 42, 43 | Maintenance.Feature | Configuration Read | Time window: FeatureID 42=TimeRangeSeconds, FeatureID 43=LastTime cursor. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @MaxTime OUTPUT | Caller | Scheduled monitoring service; advances cursor in Maintenance.Feature FeatureID 43 after processing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeEstimationsDiscrepencies (procedure)
├── dbo.SynHedgeEMSOrders (synonym -> EMS orders table)
├── Trade.GetPositionDataSlim (view) [cross-schema]
├── Customer.Customer (table) [cross-schema]
└── Maintenance.Feature (table) [config - FeatureID 42, 43]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SynHedgeEMSOrders | Synonym | Source of EMS orders: ExecutionID, RequestedAmountInUnits, StatusUpdateTime, IsBuy, HedgeServerID, OrderStatus. |
| Trade.GetPositionDataSlim | View | Cross-schema: AmountInUnitsDecimal, InitExecutionID, EndExecutionID, HedgeServerID, IsBuy, OpenOccurred, CloseOccurred, IsOpened, CID. |
| Customer.Customer | Table | Cross-schema: PlayerLevelID <> 4 filter (exclude internal accounts). |
| Maintenance.Feature | Table | Config: FeatureID 42 = TimeRangeSeconds, FeatureID 43 = @LastTime (with 1-hour cap). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Scheduled EMS discrepancy monitor. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Runtime temp tables** (4 stages):
- `#PositionsExecutionIDs`: NC indexes on InitExecutionID, EndExecutionID, HedgeServerID.
- `#EMSOrders`: NC indexes on ExecutionID, OrderStatus, HedgeServerID.
- `#PositionMatches`: Intermediate UNION result (no indexes).
- `#executions`: NC indexes on ExecutionAmount, SumAmountDecimal.

---

## 8. Sample Queries

### 8.1 Execute and capture window upper bound

```sql
DECLARE @MaxTime DATETIME;
EXEC Hedge.GetHedgeEstimationsDiscrepencies @MaxTime = @MaxTime OUTPUT;
SELECT @MaxTime AS WindowUpperBound;
```

### 8.2 Check current cursor state

```sql
SELECT FeatureID,
       CASE FeatureID WHEN 42 THEN 'TimeRangeSeconds' WHEN 43 THEN 'LastTime' END AS FeatureName,
       Value,
       CASE WHEN FeatureID = 43 AND CAST(Value AS datetime) < DATEADD(HOUR,-1,GETUTCDATE())
            THEN 'STALE (will be capped to -1hr)' ELSE 'OK' END AS CursorStatus
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID IN (42, 43);
```

### 8.3 Browse EMS orders directly (bypassing synonym)

```sql
SELECT TOP 100 ExecutionID, RequestedAmountInUnits, StatusUpdateTime, IsBuy, HedgeServerID, OrderStatus
FROM   dbo.SynHedgeEMSOrders WITH (NOLOCK)
WHERE  OrderStatus = 'Filled'
ORDER BY StatusUpdateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | EMS discrepancy monitoring is part of HedgeAlertService; EMS executions tracked separately from HBC. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeEstimationsDiscrepencies | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeEstimationsDiscrepencies.sql*
