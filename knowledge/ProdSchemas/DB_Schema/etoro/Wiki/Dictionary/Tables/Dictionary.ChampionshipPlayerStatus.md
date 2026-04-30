# Dictionary.ChampionshipPlayerStatus

> Lookup table defining the 4 states of a player's participation in a trading championship — NULL (unset), Registration, Removed, and In Process.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ChampionshipPlayerStatusID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.ChampionshipPlayerStatus defines the lifecycle states for players participating in eToro's trading championships (competitive trading events where users compete for prizes based on trading performance). Each player in a championship transitions through these states as they register, participate, and potentially get removed.

The Championship module uses these statuses extensively. The `Championship.ChampionshipPlayer` table stores each player's current status. Procedures like `Championship.ChampionshipPlayerSetStatus` update player state, `Championship.ChampionshipPlayerAdd` sets initial registration status, `Championship.ChampionshipStart` advances players to active participation, and `Championship.ChampionshipEnd` finalizes states at championship completion. Views like `Championship.GetPlayer` and `Championship.GetChampionshipPlayer` expose player status for querying.

---

## 2. Business Logic

### 2.1 Player Lifecycle States

**What**: Four states tracking a player's journey through a trading championship.

**Columns/Parameters Involved**: `ChampionshipPlayerStatusID`, `Name`

**Rules**:
- **NULL (ID=0)**: Default/unset state. Placeholder value before a player's status is explicitly assigned.
- **Registration (ID=1)**: Player has registered for the championship but the event has not started yet. Player is in a pending queue waiting for the championship to begin.
- **Removed (ID=2)**: Player has been removed from the championship — either by admin action, disqualification, or voluntary withdrawal. Terminal state for that championship instance.
- **In process (ID=3)**: Player is actively competing in a running championship. Set when the championship starts via `Championship.ChampionshipStart`.

**Diagram**:
```
Championship Player Lifecycle
  NULL (0)
    │
    ▼
  Registration (1) ──────► Removed (2)
    │                         ▲
    ▼                         │
  In process (3) ────────────┘
```

---

## 3. Data Overview

| ChampionshipPlayerStatusID | Name | Meaning |
|---|---|---|
| 0 | NULL | Default placeholder state — player record exists but status has not been explicitly set. May indicate an incomplete registration or a data entry in progress. |
| 1 | Registration | Player has signed up for a championship that hasn't started yet — validated by `ChampionshipPlayerAdd` procedure. Player is queued and waiting for the event to begin. |
| 2 | Removed | Player was removed from the championship — could be admin disqualification, rule violation, or voluntary opt-out. Terminal state preventing further participation in that event. |
| 3 | In process | Player is actively competing in a live championship — set when `ChampionshipStart` runs. Player's trades are being tracked for ranking and prize eligibility. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipPlayerStatusID | int | NO | - | VERIFIED | Primary key identifying the player status. Values 0-3. Referenced by `Championship.ChampionshipPlayer` table and used in procedures `ChampionshipPlayerSetStatus`, `ChampionshipPlayerAdd`, `ChampionshipStart`, `ChampionshipEnd`. |
| 2 | Name | char(50) | NO | - | VERIFIED | Status label (e.g., 'Registration', 'Removed', 'In process'). Fixed-width char(50) — values are right-padded with spaces. Enforced unique via `DCPS_NAME` index. Used in views for display purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Championship.ChampionshipPlayer | ChampionshipPlayerStatusID | Implicit FK | Stores each player's current championship participation status |
| Championship.ChampionshipPlayerSetStatus | Parameter | Procedure | Updates a player's status in the championship |
| Championship.ChampionshipPlayerAdd | Status assignment | Procedure | Sets initial Registration status when a player joins |
| Championship.ChampionshipStart | Status update | Procedure | Advances players from Registration to In process |
| Championship.ChampionshipEnd | Status update | Procedure | Finalizes player states at championship conclusion |
| Championship.GetPlayer | Read | View | Exposes player status for querying |
| Championship.GetChampionshipPlayer | Read | View | Exposes player status with championship context |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Championship.ChampionshipPlayer | Table | Stores player status |
| Championship.ChampionshipPlayerSetStatus | Procedure | Updates player status |
| Championship.ChampionshipPlayerAdd | Procedure | Sets initial status on registration |
| Championship.ChampionshipStart | Procedure | Transitions players to active |
| Championship.ChampionshipEnd | Procedure | Finalizes player states |
| Championship.GetPlayer | View | Reads player status |
| Championship.GetChampionshipPlayer | View | Reads player status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCPS | CLUSTERED PK | ChampionshipPlayerStatusID ASC | - | - | Active |
| DCPS_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all championship player statuses
```sql
SELECT  ChampionshipPlayerStatusID,
        RTRIM(Name) AS Name
FROM    Dictionary.ChampionshipPlayerStatus WITH (NOLOCK)
ORDER BY ChampionshipPlayerStatusID;
```

### 8.2 Count players by status in a championship
```sql
SELECT  DCPS.ChampionshipPlayerStatusID,
        RTRIM(DCPS.Name) AS StatusName,
        COUNT(CP.CID) AS PlayerCount
FROM    Dictionary.ChampionshipPlayerStatus DCPS WITH (NOLOCK)
LEFT JOIN Championship.ChampionshipPlayer CP WITH (NOLOCK)
        ON CP.ChampionshipPlayerStatusID = DCPS.ChampionshipPlayerStatusID
GROUP BY DCPS.ChampionshipPlayerStatusID, DCPS.Name
ORDER BY DCPS.ChampionshipPlayerStatusID;
```

### 8.3 Find all active players (In process)
```sql
SELECT  CP.*
FROM    Championship.ChampionshipPlayer CP WITH (NOLOCK)
WHERE   CP.ChampionshipPlayerStatusID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChampionshipPlayerStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ChampionshipPlayerStatus.sql*
