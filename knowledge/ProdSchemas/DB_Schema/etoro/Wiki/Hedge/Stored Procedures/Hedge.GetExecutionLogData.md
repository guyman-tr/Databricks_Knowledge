# Hedge.GetExecutionLogData

> Aggregates partial fills for a specific EMS order within a time window, returning total executed units and volume-weighted average execution rate for order reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @EMSOrderID - the EMS order being reconciled |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetExecutionLogData answers a single operational question: "For this EMS order, how many units were filled and at what average price?" It queries Hedge.ExecutionLog filtering for partial fill rows (OrderState=3) within a time window, then computes two aggregates: total executed units and the volume-weighted average execution rate (VWAP) across all fills.

The procedure exists because EMS orders in eToro's hedge system are typically filled in multiple partial tranches (OrderState=3 rows), not as a single atomic fill. Each tranche has its own ExecutionRate and Units. To determine the true blended cost of an order, all tranches must be combined using a volume-weighted average. Without this procedure, consumers would need to perform the aggregation themselves and risk inconsistent filtering logic.

The EMS (Execution Management System) calls this procedure after an order completes to reconcile the DB-side fill record against the expected order. The @FromDate/@ToDate window scopes the query to the order's execution timeframe. A 5-second trailing buffer (`DATEADD(SECOND, -5, @ToDate)`) is applied internally to guard against race conditions where concurrent inserts could slip in after the caller considers the window closed.

---

## 2. Business Logic

### 2.1 Partial Fill Aggregation (VWAP)

**What**: Computes volume-weighted average execution rate across all partial fills for the order.

**Columns/Parameters Involved**: `@EMSOrderID`, `OrderState`, `Units`, `ExecutionRate`, `LogTime`

**Rules**:
- Only rows where `OrderState = 3` (Partial) are included. OrderState=4 (Fill) rows are excluded - the partial fill rows carry the actual fill quantities and rates.
- The weighted average formula: `SUM(Units * ExecutionRate) / SUM(Units)` returns NULL when SUM(Units) = 0 (no fills in window) to avoid division by zero.
- `TotalExecutedUnits` = SUM of all partial fill Units in the window for this EMSOrderID.
- `WeightedAverageExecutionRate` = VWAP across all partial fills (NULL if no fills).

**Diagram**:
```
Order "35564138_1":
  Fill 1: 3 units @ 1.0820  ->  3 * 1.0820 = 3.2460
  Fill 2: 2 units @ 1.0825  ->  2 * 1.0825 = 2.1650
  Fill 3: 1 unit  @ 1.0830  ->  1 * 1.0830 = 1.0830
  -----------------------------------------------
  TotalExecutedUnits = 6
  WeightedAvgRate    = (3.2460 + 2.1650 + 1.0830) / 6 = 1.0823
```

### 2.2 5-Second Trailing Buffer

**What**: The @ToDate parameter is silently adjusted inward by 5 seconds before being applied.

**Columns/Parameters Involved**: `@ToDate`, `LogTime`

**Rules**:
- Effective upper bound: `@adjustedToDate = DATEADD(SECOND, -5, @ToDate)`
- This prevents reading rows inserted by concurrent processes that are still writing for the same order at the moment the caller closes the window.
- Callers must account for this: if they pass @ToDate = GETUTCDATE(), rows from the last 5 seconds of the window are intentionally excluded.
- See Hedge.ExecutionLog Section 2.4 for context on the partial fill aggregation pattern.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EMSOrderID | NVARCHAR(50) | NO | - | CODE-BACKED | The EMS order identifier to aggregate. Format: "{ExternalID}_{sequence}" (e.g., "35564138_1"). Matched against Hedge.ExecutionLog.EMSOrderID. Must be an exact string match (case-sensitive due to COLLATE Latin1_General_BIN pattern used elsewhere in this schema). |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the time window for fill lookup. Applied as LogTime >= @FromDate. Should be set to the order's submission time or the start of the expected execution window. |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the time window for fill lookup. Internally adjusted to DATEADD(SECOND, -5, @ToDate) before use. Callers should pass the expected completion time; the 5-second buffer is applied automatically. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | TotalExecutedUnits | decimal | YES | - | CODE-BACKED | Sum of all Units from partial fill rows (OrderState=3) for this EMSOrderID in the time window. Represents total quantity executed across all tranches. NULL is not expected (will be 0 if no fills match). |
| 5 | WeightedAverageExecutionRate | decimal | YES | - | CODE-BACKED | Volume-weighted average execution price across all partial fills: SUM(Units * ExecutionRate) / SUM(Units). NULL when no fills exist in the window (SUM(Units) = 0 guard). Used by EMS to measure blended fill cost vs. the pre-execution target rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @EMSOrderID filter | Hedge.ExecutionLog | Lookup / Read | Filters ExecutionLog rows by EMSOrderID (EMS path orders where OrderID=-1). |
| @FromDate/@ToDate | Hedge.ExecutionLog.LogTime | Lookup / Read | Time window scoping the partial fill rows to aggregate. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EMS application layer | - | Caller | Called by the Execution Management System after order completion to reconcile DB fill records. Not called by any other SQL procedures in the Hedge schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetExecutionLogData (procedure)
└── Hedge.ExecutionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLog | Table | SELECT with NOLOCK. Filters by EMSOrderID, LogTime range, OrderState=3. Aggregates Units and ExecutionRate. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EMS system (external) | Application | Calls this procedure to retrieve aggregated partial fill data for order reconciliation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get fill summary for a specific EMS order

```sql
EXEC Hedge.GetExecutionLogData
    @EMSOrderID = '35564138_1',
    @FromDate   = '2026-03-19 00:00:00',
    @ToDate     = '2026-03-19 01:00:00';
```

### 8.2 Verify manually against ExecutionLog (what the proc computes)

```sql
SELECT  SUM(Units)                                               AS TotalExecutedUnits,
        CASE
            WHEN SUM(Units) > 0
            THEN SUM(Units * ExecutionRate) / SUM(Units)
            ELSE NULL
        END                                                      AS WeightedAverageExecutionRate
FROM    Hedge.ExecutionLog WITH (NOLOCK)
WHERE   LogTime BETWEEN '2026-03-19 00:00:00'
                    AND DATEADD(SECOND, -5, '2026-03-19 01:00:00')
        AND EMSOrderID  = '35564138_1'
        AND OrderState  = 3
GROUP BY EMSOrderID;
```

### 8.3 Inspect all partial fill tranches for an EMS order to understand the VWAP build-up

```sql
SELECT  LogTime,
        Units,
        ExecutionRate,
        Units * ExecutionRate                    AS WeightedContribution,
        SUM(Units) OVER (ORDER BY LogTime)       AS RunningUnits
FROM    Hedge.ExecutionLog WITH (NOLOCK)
WHERE   EMSOrderID  = '35564138_1'
        AND OrderState  = 3
ORDER BY LogTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetExecutionLogData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetExecutionLogData.sql*
