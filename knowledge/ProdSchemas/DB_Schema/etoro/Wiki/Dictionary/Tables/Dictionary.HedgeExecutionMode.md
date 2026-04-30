# Dictionary.HedgeExecutionMode

> Lookup table defining the two hedge execution modes — HBC (Hedge Before Close) and CBH (Close Before Hedge) — that determine the sequencing of hedge operations relative to client position closes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | HedgeExecutionModeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeExecutionMode defines the two operational sequencing strategies for how eToro's hedge server coordinates hedge order execution with client position closures. When a client closes a position, the platform must also close (or adjust) the corresponding hedge position with the liquidity provider. The critical question is: should the hedge be closed first, or the client position?

This table exists because the sequencing of hedge vs. client operations has significant financial implications. In HBC (Hedge Before Close) mode, the hedge position with the liquidity provider is adjusted before the client's position is closed — reducing market exposure risk but potentially delaying the client experience. In CBH (Close Before Hedge) mode, the client's position is closed first and the hedge adjustment follows — providing faster client execution but temporarily creating unhedged exposure.

The HedgeExecutionModeID is referenced in the order execution reporting system and hedge latency reports. Procedures like Trade.GetOrdersForExecutionReportDrillDown and Hedge.SSRS_Latency_Report join to this table to display the execution mode used for each trade.

---

## 2. Business Logic

### 2.1 Hedge Execution Sequencing

**What**: The two modes determine whether hedge adjustments happen before or after client position operations.

**Columns/Parameters Involved**: `HedgeExecutionModeID`, `Name`

**Rules**:
- **HBC (1)** — Hedge Before Close: The hedge server sends the order to the liquidity provider first, waits for confirmation, then closes the client's position. Minimizes unhedged exposure but adds latency to the client experience.
- **CBH (2)** — Close Before Hedge: The client's position is closed immediately, then the hedge adjustment is sent to the liquidity provider. Provides faster client execution but creates a brief window of unhedged market exposure.
- The choice between HBC and CBH depends on instrument volatility, liquidity provider speed, and risk appetite configuration.

**Diagram**:
```
HBC (Hedge Before Close):          CBH (Close Before Hedge):
  Client closes position              Client closes position
         │                                    │
         ▼                                    ▼
  Send hedge to LP first            Close client position first
         │                                    │
         ▼                                    ▼
  LP confirms hedge close            Client gets confirmation
         │                                    │
         ▼                                    ▼
  Close client position              Send hedge to LP
         │                                    │
         ▼                                    ▼
  Client gets confirmation           LP confirms hedge close

Risk: Lower (hedged first)         Risk: Higher (briefly unhedged)
Speed: Slower for client           Speed: Faster for client
```

---

## 3. Data Overview

| HedgeExecutionModeID | Name | Meaning |
|---|---|---|
| 1 | HBC | Hedge Before Close — the hedge position with the liquidity provider is adjusted first, then the client's position is closed. Used when minimizing unhedged exposure is more important than client-facing latency. |
| 2 | CBH | Close Before Hedge — the client's position is closed immediately, then the hedge is adjusted with the liquidity provider. Used when fast client execution is prioritized over brief unhedged exposure windows. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeExecutionModeID | int | NO | - | VERIFIED | Primary key identifying the hedge execution mode. 1=HBC (Hedge Before Close — hedge LP first, then close client), 2=CBH (Close Before Hedge — close client first, then hedge LP). Used in execution reporting and latency analysis. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Short code for the execution mode. "HBC" = Hedge Before Close, "CBH" = Close Before Hedge. Displayed in SSRS latency reports and execution drill-down screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrdersForExecutionReportDrillDown | HedgeExecutionModeID | Lookup | Joins to resolve execution mode for order execution reporting |
| Trade.GetOrdersForExecutionReportDrillDownTest | HedgeExecutionModeID | Lookup | Test variant of the execution report drill-down |
| Hedge.SSRS_Latency_Report | HedgeExecutionModeID | Lookup | Resolves execution mode in hedge latency SSRS reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrdersForExecutionReportDrillDown | Stored Procedure | Reads — joins to resolve execution mode name |
| Trade.GetOrdersForExecutionReportDrillDownTest | Stored Procedure | Reads — test variant of execution report |
| Hedge.SSRS_Latency_Report | Stored Procedure | Reads — hedge latency SSRS report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeExecutionMode | CLUSTERED PK | HedgeExecutionModeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeExecutionMode | PRIMARY KEY | Unique hedge execution mode identifier |

---

## 8. Sample Queries

### 8.1 List all hedge execution modes
```sql
SELECT  HedgeExecutionModeID,
        Name
FROM    [Dictionary].[HedgeExecutionMode] WITH (NOLOCK)
ORDER BY HedgeExecutionModeID;
```

### 8.2 Join execution mode to order report data
```sql
SELECT  o.OrderID,
        o.InstrumentID,
        hem.Name AS ExecutionMode
FROM    [Trade].[OrdersForExecution] o WITH (NOLOCK)
JOIN    [Dictionary].[HedgeExecutionMode] hem WITH (NOLOCK)
        ON o.HedgeExecutionModeID = hem.HedgeExecutionModeID
ORDER BY o.OrderID;
```

### 8.3 Compare latency by execution mode
```sql
SELECT  hem.Name AS ExecutionMode,
        COUNT(*) AS OrderCount,
        AVG(o.LatencyMs) AS AvgLatencyMs
FROM    [Trade].[OrdersForExecution] o WITH (NOLOCK)
JOIN    [Dictionary].[HedgeExecutionMode] hem WITH (NOLOCK)
        ON o.HedgeExecutionModeID = hem.HedgeExecutionModeID
GROUP BY hem.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeExecutionMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeExecutionMode.sql*
