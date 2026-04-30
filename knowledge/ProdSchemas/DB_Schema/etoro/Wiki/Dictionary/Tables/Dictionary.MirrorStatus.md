# Dictionary.MirrorStatus

> Lookup table defining the 4 states of a CopyTrading (mirror) relationship lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MirrorStatus defines the operational states of a CopyTrading relationship between a copying user and a copied trader. The status controls whether new positions are automatically replicated and whether the relationship is in an active, paused, or closing state.

This table is essential to CopyTrading lifecycle management. When a user starts copying, the relationship enters InAlignment (3) while the copier's portfolio is synced to match the leader. Once aligned, it moves to Active (0). Users can Pause (1) copying temporarily, and PendingClose (2) indicates the system is unwinding all mirrored positions.

MirrorStatus is stored in copy relationship records and checked by every copy-trade execution to determine whether to replicate the leader's action.

---

## 2. Business Logic

### 2.1 Copy Relationship Lifecycle

**What**: State machine governing the CopyTrading relationship.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- New copy → starts at InAlignment (3) while portfolio syncs
- Sync complete → transitions to Active (0)
- User pauses → Pause (1), existing positions remain, no new copies
- User stops copying → PendingClose (2), all mirrored positions being closed
- All positions closed → relationship record archived

**Diagram**:
```
[Start Copying] ──► [3: InAlignment] ──► [0: Active] ◄──► [1: Pause]
                                              │
                                         [Stop Copy]
                                              │
                                              ▼
                                        [2: PendingClose] ──► [Archived]
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Active | Copy relationship is live — every trade the leader makes is automatically replicated proportionally in the copier's account. The steady-state for functioning copy relationships. |
| 1 | Pause | Temporarily suspended — existing mirrored positions remain open but no new leader trades are copied. The copier chose to pause, possibly to review performance. Resuming returns to Active. |
| 2 | PendingClose | Termination in progress — the system is actively closing all mirrored positions. Triggered when the copier stops copying or a redeem is processed. Once all positions close, the relationship record is archived. |
| 3 | InAlignment | Initial synchronization — the system is opening positions to match the leader's current portfolio. Happens when first starting to copy or when resuming from a desynchronized state. Temporary state before transitioning to Active. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the copy relationship state. 0=Active (live replication), 1=Pause (suspended, positions retained), 2=PendingClose (unwinding), 3=InAlignment (syncing portfolio). See [Mirror Status](_glossary.md#mirror-status). (Dictionary.MirrorStatus) |
| 2 | Name | varchar(40) | NO | - | CODE-BACKED | Human-readable state label. Used in back-office displays, API responses, and copy relationship management UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade mirror tables | StatusID | Implicit Lookup | Current state of each copy relationship |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade mirror tables | Table | Stores StatusID for each copy relationship |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorStatus_ID | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorStatus_ID | PRIMARY KEY | Unique mirror status identifier |

---

## 8. Sample Queries

### 8.1 List all mirror statuses
```sql
SELECT ID, Name FROM [Dictionary].[MirrorStatus] WITH (NOLOCK) ORDER BY ID;
```

### 8.2 Count copy relationships by status
```sql
SELECT ms.Name, COUNT(*) AS RelationshipCount
FROM [Trade].[Mirror] m WITH (NOLOCK)
JOIN [Dictionary].[MirrorStatus] ms WITH (NOLOCK) ON m.StatusID = ms.ID
GROUP BY ms.Name ORDER BY RelationshipCount DESC;
```

### 8.3 Find all relationships currently aligning
```sql
SELECT m.CID, m.ParentCID, m.StartDate, ms.Name AS Status
FROM [Trade].[Mirror] m WITH (NOLOCK)
JOIN [Dictionary].[MirrorStatus] ms WITH (NOLOCK) ON m.StatusID = ms.ID
WHERE m.StatusID = 3 ORDER BY m.StartDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.MirrorStatus.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorStatus.sql*
