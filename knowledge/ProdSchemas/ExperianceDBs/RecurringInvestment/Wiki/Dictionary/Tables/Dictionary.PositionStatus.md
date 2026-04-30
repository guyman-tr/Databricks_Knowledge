# Dictionary.PositionStatus

> Lookup table tracking the outcome of position creation after a trading order is filled in a recurring investment cycle.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table tracks the outcome of position creation after a trading order is filled (or not) in a recurring investment cycle. After the Order Execution Job places an order via the Trading API, the resulting position status is captured here. This covers the final step of the recurring investment pipeline: was the user's money actually invested?

Without this table, the system could not distinguish between successful position opens, failures, in-progress states, and the various "no position" outcomes where the order was cancelled or expired before execution.

The PositionStatus is written to PlanInstances by the position confirmation flow. Combined with PositionFailErrorCode (from the Trading API's TradingOpenPositionErrorCodes enum), it provides complete position outcome tracking.

---

## 2. Business Logic

### 2.1 Position Outcome Classification

**What**: Six-state model covering all possible outcomes after an order is placed.

**Columns/Parameters Involved**: `ID`, `PositionStatus`

**Rules**:
- Success (1): Position opened - investment completed for this cycle
- Failed (2): Position open failed - see PositionFailErrorCode for specific Trading API error
- InProgress (3): Position being processed - not yet final
- Unknown (4): Status cannot be determined - data gap or system issue
- NoPositionOrderCanceledByUser (6): No position because user cancelled the order (PlanEventCode 508)
- NoPositionOrderExpiredOrCanceledByEtoro (7): No position because order expired or eToro cancelled it (PlanEventCode 509)

**Diagram**:
```
Order Filled/Placed
    |
    +-- Position opens --> Success (1)
    |
    +-- Position fails --> Failed (2) [+ PositionFailErrorCode]
    |
    +-- Still processing --> InProgress (3)
    |
    +-- Data unavailable --> Unknown (4)
    |
    +-- User cancelled order --> NoPositionOrderCanceledByUser (6)
    |
    +-- Order expired/eToro cancelled --> NoPositionOrderExpiredOrCanceledByEtoro (7)
```

---

## 3. Data Overview

| ID | PositionStatus | Meaning |
|----|----------------|---------|
| 1 | Success | Position was successfully opened after order fill. The user's recurring investment executed completely - money was deposited, order was placed, and the position is now live. |
| 2 | Failed | Position opening failed despite an order being placed. The specific error from Trading API is captured in PositionFailErrorCode (TradingOpenPositionErrorCodes enum). May trigger PlanEventCode 600. |
| 3 | InProgress | Position is being created/processed and has not reached a terminal state yet. The system is waiting for confirmation from the Trading API. |
| 4 | Unknown | Position status cannot be determined due to a data gap or system issue. May trigger PlanEventCode 601 (MissingPositionData) or 602 (deadline passed). |
| 6 | NoPositionOrderCanceledByUser | No position was opened because the user cancelled the order before it could execute. The deposit was made but the investment did not occur. Maps to PlanEventCode 508. |
| 7 | NoPositionOrderExpiredOrCanceledByEtoro | No position was opened because the order expired (market closed, time limit) or was cancelled by eToro system rules. Maps to PlanEventCode 509. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the position status. 1=Success, 2=Failed, 3=InProgress, 4=Unknown, 6=NoPositionOrderCanceledByUser, 7=NoPositionOrderExpiredOrCanceledByEtoro. Gap at ID=5 suggests a deprecated status. See [Position Status](../../_glossary.md#position-status). |
| 2 | PositionStatus | varchar(50) | NO | - | VERIFIED | Human-readable label describing the position creation outcome. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | PositionStatus | Implicit Lookup | Tracks the position creation outcome for each plan instance |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | PositionStatus column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionStatus | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all position statuses
```sql
SELECT ID, PositionStatus
FROM [Dictionary].[PositionStatus] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find instances with position failures
```sql
SELECT pi.InstanceID, pi.PlanID, ps.PositionStatus, pi.PositionFailErrorCode,
       pi.PositionExecutionDate
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[PositionStatus] ps WITH (NOLOCK) ON pi.PositionStatus = ps.ID
WHERE pi.PositionStatus IN (2, 6, 7)
```

### 8.3 Count instances by position outcome
```sql
SELECT ps.ID, ps.PositionStatus, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[PositionStatus] ps WITH (NOLOCK) ON pi.PositionStatus = ps.ID
GROUP BY ps.ID, ps.PositionStatus
ORDER BY ps.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | PositionStatus based on Dictionary table; PositionFailErrorCode from TradingOpenPositionErrorCodes enum |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Position opening is the final step in the Order Execution Job flow |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PositionStatus | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.PositionStatus.sql*
