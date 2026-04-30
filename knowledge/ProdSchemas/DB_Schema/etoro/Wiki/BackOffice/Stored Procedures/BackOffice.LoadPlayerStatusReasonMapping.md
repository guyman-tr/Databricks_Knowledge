# BackOffice.LoadPlayerStatusReasonMapping

> Returns the full three-level player status taxonomy: PlayerStatusID -> PlayerStatusReasonID -> PlayerStatusSubReasonID, used to populate the status-change reason dropdowns in the Back Office UI.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all PlayerStatusID/ReasonID/SubReasonID mappings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`LoadPlayerStatusReasonMapping` returns the complete reason/sub-reason taxonomy used when a Back Office manager changes a customer's player status. When a manager selects a new player status (e.g., "Active", "Blocked", "Dormant"), they must also select a reason and optionally a sub-reason for the change - this procedure provides the valid combinations.

The three-level hierarchy is:
1. **PlayerStatusID**: The status being set (e.g., Active=1, Blocked=2, etc.)
2. **PlayerStatusReasonID**: The reason for setting that status (e.g., for Blocked: "Fraud", "Compliance request", "Customer request")
3. **PlayerStatusSubReasonID**: Optional further granularity within a reason (e.g., for Fraud: "Card fraud", "Identity fraud")

The procedure returns all rows from `BackOffice.PlayerStatusToReason` (status-to-reason mappings) LEFT JOINed with `BackOffice.PlayerStatusReasonToSubReason` (reason-to-sub-reason mappings). The LEFT JOIN means reasons without sub-reasons are also returned (SubReasonID = NULL).

This data is loaded once when the Back Office UI initializes to build the cascading dropdown menus for player status changes.

---

## 2. Business Logic

### 2.1 Status-Reason-SubReason Tree Retrieval

**What**: Returns the complete three-level taxonomy for player status change reason classification.

**Columns/Parameters Involved**: `PlayerStatusID`, `PlayerStatusReasonID`, `PlayerStatusSubReasonID`

**Rules**:
- FROM `BackOffice.PlayerStatusToReason psr` (all status-to-reason pairs)
- LEFT JOIN `BackOffice.PlayerStatusReasonToSubReason psrs ON psrs.PlayerStatusReasonID = psr.PlayerStatusReasonID`
- LEFT JOIN: reasons with no sub-reasons return PlayerStatusSubReasonID = NULL
- No WHERE, no ORDER BY - returns all rows

**Diagram**:
```
PlayerStatusToReason
  PlayerStatusID | PlayerStatusReasonID
  1 (Active)     | 5 (Reactivation)
  2 (Blocked)    | 7 (Fraud)
  2 (Blocked)    | 8 (Compliance)
  ...
    LEFT JOIN PlayerStatusReasonToSubReason
      PlayerStatusReasonID | PlayerStatusSubReasonID
      7 (Fraud)            | 12 (Card fraud)
      7 (Fraud)            | 13 (Identity fraud)
      8 (Compliance)       | NULL (no sub-reasons)
    =
  Result:
  StatusID | ReasonID | SubReasonID
  1        | 5        | NULL
  2        | 7        | 12
  2        | 7        | 13
  2        | 8        | NULL
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | INT | NO | - | CODE-BACKED | The player status this reason applies to. FK to BackOffice.PlayerStatus (e.g., Active, Blocked, Dormant). |
| 2 | PlayerStatusReasonID | INT | NO | - | CODE-BACKED | The reason for changing to this status. FK to BackOffice.PlayerStatusReason. One status can have multiple valid reasons. |
| 3 | PlayerStatusSubReasonID | INT | YES | - | CODE-BACKED | Optional sub-reason for further granularity. NULL if no sub-reasons are defined for this reason. FK to BackOffice.PlayerStatusSubReason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerStatusID + PlayerStatusReasonID | BackOffice.PlayerStatusToReason | Lookup | All status-to-reason mappings |
| PlayerStatusReasonID + PlayerStatusSubReasonID | BackOffice.PlayerStatusReasonToSubReason | Lookup (LEFT JOIN) | All reason-to-sub-reason mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LoadPlayerStatusReasonMapping (procedure)
├── BackOffice.PlayerStatusToReason (table) [SELECT anchor]
└── BackOffice.PlayerStatusReasonToSubReason (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.PlayerStatusToReason | Table | FROM anchor - all status-to-reason pairs |
| BackOffice.PlayerStatusReasonToSubReason | Table | LEFT JOIN - adds sub-reason IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by BO UI on initialization to build status change reason dropdowns |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No SET NOCOUNT | Omission | Row counts sent to caller |
| LEFT JOIN | Design | Reasons without sub-reasons included with SubReasonID = NULL |
| No WITH (NOLOCK) | Design | Reads use default locking (reference data, rarely changes) |
| No ORDER BY | Design | Returns rows in natural table order |

---

## 8. Sample Queries

### 8.1 Get full reason mapping tree

```sql
EXEC [BackOffice].[LoadPlayerStatusReasonMapping];
-- Returns: PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID
-- SubReasonID is NULL for reasons with no sub-reasons
```

### 8.2 Find all reasons for a specific status

```sql
SELECT DISTINCT
    psr.PlayerStatusID,
    psr.PlayerStatusReasonID
FROM BackOffice.PlayerStatusToReason psr
WHERE psr.PlayerStatusID = 2  -- e.g., Blocked
ORDER BY psr.PlayerStatusReasonID;
```

### 8.3 Find all sub-reasons for a specific reason

```sql
SELECT PlayerStatusSubReasonID
FROM BackOffice.PlayerStatusReasonToSubReason
WHERE PlayerStatusReasonID = 7;  -- e.g., Fraud
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.LoadPlayerStatusReasonMapping | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LoadPlayerStatusReasonMapping.sql*
