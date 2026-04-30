# BackOffice.GetPlayerStatusReasonMapping

> Returns the complete mapping of PlayerStatus -> PlayerStatusReason -> PlayerStatusSubReason, enabling UI dropdowns to enforce valid reason/sub-reason combinations when setting a customer's account status.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - returns full mapping) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the configuration table for the three-level account status classification hierarchy: Player Status -> Status Reason -> Status Sub-Reason. It answers "which reasons are valid for each status, and which sub-reasons are valid for each reason?" - allowing BackOffice UI components to dynamically populate cascading dropdowns with only valid combinations.

When a BackOffice agent changes a customer's account status (e.g., Blocking, Closing, Suspending), the UI uses this mapping to restrict which reasons and sub-reasons can be selected, ensuring consistent and valid status data entry.

**Created**: 2019-02-18 by Geri Reshef (Jira RD-1752, 2227, Ops0451 - "Ops0451: reorg of PlayerStatus, reasons and sub-reasons").

**Permission**: No active EXECUTE grants found. Accessed via ad-hoc queries or legacy BackOffice application.

---

## 2. Business Logic

### 2.1 Status-Reason-SubReason Hierarchy

**What**: Joins the two mapping tables to produce a flat row per (status, reason, sub-reason) combination.

**Columns/Parameters Involved**: BackOffice.PlayerStatusToReason, BackOffice.PlayerStatusReasonToSubReason

**Rules**:
- `FROM BackOffice.PlayerStatusToReason psr`: Base table maps each PlayerStatus to its allowed Reasons. One row per (PlayerStatusID, PlayerStatusReasonID) pair.
- `LEFT JOIN BackOffice.PlayerStatusReasonToSubReason psrs ON psrs.PlayerStatusReasonID = psr.PlayerStatusReasonID`: Adds sub-reasons. LEFT JOIN preserves reasons that have no sub-reasons (sub-reason selection is optional for those).
- The result is a flattened join: one row per (PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID) triple. Reasons without sub-reasons appear with NULL PlayerStatusSubReasonID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | INT | NO | - | CODE-BACKED | The account status (e.g., Active, Blocked, Closed). References Dictionary.PlayerStatus.PlayerStatusID. |
| 2 | PlayerStatusReasonID | INT | NO | - | CODE-BACKED | The reason for setting this status (e.g., "Fraud", "AML", "Customer Request"). References Dictionary.PlayerStatusReasons.PlayerStatusReasonID. |
| 3 | PlayerStatusSubReasonID | INT | YES | NULL | CODE-BACKED | Optional sub-reason further classifying the reason (e.g., "Chargeback Fraud", "Identity Fraud"). NULL when a reason has no sub-reasons. References Dictionary.PlayerStatusSubReasons.PlayerStatusSubReasonID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerStatusID, PlayerStatusReasonID | BackOffice.PlayerStatusToReason | Read (FROM) | Defines which reasons are valid for each player status |
| PlayerStatusSubReasonID | BackOffice.PlayerStatusReasonToSubReason | Read (LEFT JOIN) | Defines which sub-reasons are valid for each reason |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPlayerStatusReasonMapping (procedure)
+-- BackOffice.PlayerStatusToReason (table)
+-- BackOffice.PlayerStatusReasonToSubReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.PlayerStatusToReason | Table | FROM clause; PlayerStatusID-to-PlayerStatusReasonID mapping |
| BackOffice.PlayerStatusReasonToSubReason | Table | LEFT JOIN; PlayerStatusReasonID-to-PlayerStatusSubReasonID mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameters | Design | Returns complete mapping; callers filter in application layer |
| LEFT JOIN | Nullable sub-reasons | Reasons without sub-reasons produce NULL PlayerStatusSubReasonID rows |
| No NOLOCK | Locking | Reference configuration tables; typically small and infrequently written |

---

## 8. Sample Queries

### 8.1 Get the full mapping

```sql
EXEC BackOffice.GetPlayerStatusReasonMapping
```

### 8.2 Get reasons for a specific status

```sql
SELECT psr.PlayerStatusID, ps.Name AS StatusName,
       psr.PlayerStatusReasonID, pr.Name AS ReasonName
FROM BackOffice.PlayerStatusToReason psr WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = psr.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons pr WITH (NOLOCK) ON pr.PlayerStatusReasonID = psr.PlayerStatusReasonID
WHERE psr.PlayerStatusID = 3  -- e.g., Blocked
ORDER BY pr.Name;
```

### 8.3 Get sub-reasons for a specific reason

```sql
SELECT psrs.PlayerStatusReasonID, pr.Name AS ReasonName,
       psrs.PlayerStatusSubReasonID, psr.Name AS SubReasonName
FROM BackOffice.PlayerStatusReasonToSubReason psrs WITH (NOLOCK)
JOIN Dictionary.PlayerStatusReasons pr WITH (NOLOCK) ON pr.PlayerStatusReasonID = psrs.PlayerStatusReasonID
JOIN Dictionary.PlayerStatusSubReasons psr WITH (NOLOCK) ON psr.PlayerStatusSubReasonID = psrs.PlayerStatusSubReasonID
ORDER BY pr.Name, psr.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPlayerStatusReasonMapping | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPlayerStatusReasonMapping.sql*
