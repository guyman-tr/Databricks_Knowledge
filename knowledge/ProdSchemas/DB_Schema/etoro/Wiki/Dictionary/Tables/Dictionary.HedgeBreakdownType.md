# Dictionary.HedgeBreakdownType

> Lookup table defining the six stages of the hedge execution pipeline — from customer order submission through trade status changes, exposure queries, provider order placement, provider execution, and execution confirmation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeBreakdownType defines the sequential stages of eToro's hedge execution pipeline. When a customer trade creates or changes exposure that needs to be hedged, the system follows a multi-step process: the customer places an order, the trade status changes, the hedge server calculates exposure, sends an order to the liquidity provider, the provider executes the trade, and confirmation is received. Each stage is logged independently to enable latency analysis and troubleshooting.

This table exists because hedge execution timing is critical for risk management. Delays at any stage can result in the broker carrying unhedged exposure, which creates financial risk. By breaking down the pipeline into discrete stages and logging timestamps for each, the operations team can identify bottlenecks — whether the delay is in the internal processing, the exposure calculation, or the external provider's execution.

ID is stored on History.HedgingBreakdownLog, which records timestamps for each hedge stage per trade event, enabling end-to-end latency analysis.

---

## 2. Business Logic

### 2.1 Hedge Pipeline Stages

**What**: The six stages represent the chronological steps in the hedge execution flow, from customer action to provider confirmation.

**Columns/Parameters Involved**: `ID`, `HedgeBreakdownName`

**Rules**:
- **Stage 1**: Customer sends an order — the trigger event that may require hedging
- **Stage 2**: Customer trade status change (opened/closed) — the trade is confirmed and the system now has exposure to hedge
- **Stage 3**: Hedge Server makes a Hedge Exposure Query — the hedge engine calculates the net exposure change and determines if a hedge order is needed
- **Stage 4**: Hedge Server sends the Provider an order — based on the exposure query, an offsetting order is sent to the liquidity provider
- **Stage 5**: Trade executed by the Provider — the liquidity provider fills the hedge order
- **Stage 6**: Confirmation arrives from the Provider — the hedge server receives and processes the fill confirmation

**Diagram**:
```
Hedge Execution Pipeline (chronological):

Customer Order (1)
    │
    ▼
Trade Status Change (2)
    │
    ▼
Hedge Exposure Query (3)    ← Hedge Server calculates net exposure
    │
    ▼
Order Sent to Provider (4)  ← Offsetting order transmitted
    │
    ▼
Provider Executes Trade (5) ← External execution
    │
    ▼
Confirmation Received (6)   ← Fill confirmation processed

Each stage is timestamped in History.HedgingBreakdownLog
for latency analysis: total = Σ(stage[n+1] - stage[n])
```

---

## 3. Data Overview

| ID | HedgeBreakdownName | Meaning |
|---|---|---|
| 1 | Customer sends an order | The initiating event — a customer submits a trade order that will require hedging. Timestamp marks when the customer's action enters the system. |
| 2 | Customer trade status change (opened/closed) | The trade is confirmed and the position status changes. This creates the actual exposure that needs to be hedged. Time between stages 1→2 represents internal trade processing latency. |
| 3 | Hedge Server makes an Hedge Exposure Query | The hedge engine calculates the net exposure change and determines whether a hedge order is needed and at what size. Time 2→3 represents the delay before the hedge server processes the event. |
| 4 | Hedge Server sends the Provider an order based on the Hedge Exposure Query result | Based on the exposure calculation, an offsetting order is transmitted to the liquidity provider. Time 3→4 represents hedge order generation and transmission latency. |
| 5 | Trade executed by the Provider | The liquidity provider fills the hedge order. Time 4→5 represents external execution latency — dependent on market conditions and provider speed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the hedge pipeline stage. 1=Customer order, 2=Trade status change, 3=Exposure query, 4=Order sent to provider, 5=Provider execution, 6=Confirmation received. Stored on History.HedgingBreakdownLog for per-event timing analysis. |
| 2 | HedgeBreakdownName | varchar(100) | NO | - | VERIFIED | Descriptive label for the pipeline stage. Explains what happens at each step in business terms. Used in hedge monitoring dashboards and latency analysis reports to label each timing point. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.HedgingBreakdownLog | HedgeBreakdownTypeID | Implicit Lookup | Each timing record references the pipeline stage it represents |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.HedgingBreakdownLog | Table | References ID to identify which pipeline stage a timing record belongs to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeBreakdownType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeBreakdownType | PRIMARY KEY | Unique pipeline stage identifier |

---

## 8. Sample Queries

### 8.1 List all hedge pipeline stages
```sql
SELECT  ID,
        HedgeBreakdownName
FROM    [Dictionary].[HedgeBreakdownType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Analyze average latency per pipeline stage
```sql
SELECT  bt.HedgeBreakdownName   AS Stage,
        AVG(DATEDIFF(MILLISECOND, hbl.StartTime, hbl.EndTime)) AS AvgLatencyMs
FROM    [History].[HedgingBreakdownLog] hbl WITH (NOLOCK)
JOIN    [Dictionary].[HedgeBreakdownType] bt WITH (NOLOCK)
        ON hbl.HedgeBreakdownTypeID = bt.ID
GROUP BY bt.ID, bt.HedgeBreakdownName
ORDER BY bt.ID;
```

### 8.3 Find slowest pipeline stages for a specific hedge event
```sql
SELECT  bt.HedgeBreakdownName   AS Stage,
        hbl.StartTime,
        hbl.EndTime,
        DATEDIFF(MILLISECOND, hbl.StartTime, hbl.EndTime) AS LatencyMs
FROM    [History].[HedgingBreakdownLog] hbl WITH (NOLOCK)
JOIN    [Dictionary].[HedgeBreakdownType] bt WITH (NOLOCK)
        ON hbl.HedgeBreakdownTypeID = bt.ID
WHERE   hbl.HedgeEventID = @HedgeEventID
ORDER BY bt.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeBreakdownType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeBreakdownType.sql*
