# Dictionary.HedgeRecoveryState

> Lookup table defining five hedge recovery states — tracking the lifecycle of hedge position entries during the disaster recovery and reconciliation process between eToro's systems and liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (SMALLINT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeRecoveryState defines the possible states of hedge positions as they go through the recovery and reconciliation process. When the hedge server restarts or a communication failure occurs, each hedge position must be reconciled against the liquidity provider's records. The recovery process compares local records with LP records and classifies each position as: newly detected (Added), modified (Updated), no longer present (Removed), or found on the LP side without a local match (Detected).

This table exists because hedge recovery is one of the most risk-sensitive operations in the trading infrastructure. After a system failure, eToro must quickly determine which hedge positions are still active, which have changed, and which are missing. An incorrect recovery can leave positions unhedged, double-hedged, or orphaned at the LP, all of which create financial risk. Classifying recovery outcomes into discrete states enables systematic reconciliation and audit.

The ID column is referenced by the Hedge.RecoveryLog table, which records the state of every position discovered during each recovery scan.

---

## 2. Business Logic

### 2.1 Recovery State Lifecycle

**What**: Positions are classified during recovery as unchanged, new, modified, removed, or externally detected.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **None (0)**: Default/unset state before the recovery process classifies the position
- **Added (1)**: A new hedge position was discovered at the LP that was not in the local system. May indicate a position was opened just before the failure, or that a previous recovery missed it
- **Updated (2)**: An existing position was found but its details (quantity, price) differ from local records. Requires reconciliation to determine which version is correct
- **Removed (3)**: A position that existed in local records was not found at the LP. The LP may have closed it during the outage, or it may have been filled and removed
- **Detected (4)**: A position was detected at the LP during a scan. This is the initial classification before the system determines if it's Added, Updated, or expected

**Diagram**:
```
Recovery Process:
  ┌──────────────────────┐
  │  Recovery Scan Start │
  └──────────┬───────────┘
             │ Compare local vs LP
             ▼
  ┌──────────────────────┐
  │   Detected (4)       │ ← Initial classification for LP positions
  └──────────┬───────────┘
             │ classify
    ┌────────┼────────┐
    ▼        ▼        ▼
 Added(1) Updated(2) None(0)
 (new LP   (details   (matches
  position) changed)   local)

  Local-only positions → Removed(3)
  (exists locally, not found at LP)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | None | Default state — the position has not been classified by the recovery process, or it was found to match perfectly between local and LP records (no discrepancy). |
| 1 | Added | A new hedge position was discovered at the liquidity provider that did not exist in local records. Requires investigation to determine if it was opened during the outage or is an orphaned position. |
| 2 | Updated | An existing position was found at the LP but with different details (quantity, price, or state). The recovery system must reconcile the differences and determine which version is authoritative. |
| 3 | Removed | A position that existed in local records was not found at the LP. It may have been closed, filled, or cancelled at the LP during the outage. Local records need updating. |
| 4 | Detected | Initial classification for a position found at the LP during a scan. This is a transient state — the system will reclassify it as Added, Updated, or None once comparison with local records is complete. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | smallint | NO | - | VERIFIED | Primary key identifying the recovery state. 0=None (unclassified/matched), 1=Added (new LP position), 2=Updated (details changed), 3=Removed (not at LP), 4=Detected (initial scan state). Stored in Hedge.RecoveryLog. |
| 2 | Name | varchar(20) | NO | - | VERIFIED | Human-readable label for the recovery state. Displayed in recovery logs, reconciliation reports, and monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.RecoveryLog | RecoveryStateID | Implicit FK | Records the recovery classification of each position during reconciliation scans |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.RecoveryLog | Table | References recovery state for each position during reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeRecoveryState | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeRecoveryState | PRIMARY KEY | Unique recovery state identifier |

---

## 8. Sample Queries

### 8.1 List all recovery states
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[HedgeRecoveryState] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Join to recovery log
```sql
SELECT  rl.RecoveryLogID,
        rl.InstrumentID,
        rs.Name AS RecoveryState,
        rl.RecoveryDate
FROM    [Hedge].[RecoveryLog] rl WITH (NOLOCK)
JOIN    [Dictionary].[HedgeRecoveryState] rs WITH (NOLOCK)
        ON rl.RecoveryStateID = rs.ID
ORDER BY rl.RecoveryDate DESC;
```

### 8.3 Count positions by recovery state
```sql
SELECT  rs.Name AS RecoveryState,
        COUNT(*) AS PositionCount
FROM    [Hedge].[RecoveryLog] rl WITH (NOLOCK)
JOIN    [Dictionary].[HedgeRecoveryState] rs WITH (NOLOCK)
        ON rl.RecoveryStateID = rs.ID
GROUP BY rs.Name
ORDER BY PositionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeRecoveryState | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeRecoveryState.sql*
