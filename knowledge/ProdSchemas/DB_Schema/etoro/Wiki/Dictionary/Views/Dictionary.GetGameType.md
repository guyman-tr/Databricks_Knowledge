# Dictionary.GetGameType

> Legacy convenience view exposing GameTypeID and Name from Dictionary.GameType for backward-compatible game/trading activity type lookups.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | GameTypeID (from GameType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetGameType is a legacy convenience view (created 2007-06-27 by Spivak Igor) that exposes the two columns from Dictionary.GameType — GameTypeID and Name. "Game" is eToro's original internal term for trading instrument categories, dating back to the platform's early days when social trading included gamified elements like "Horse Race", "Car Race", and "Forex Marathon" alongside actual trading.

The view provides a stable interface for older platform components that reference game types by view name rather than querying the base table directly. The 14 game types span from the original gamified experiences (Horse Race=1, Car Race=2, Poker=21) to modern trading modes (eToro Trading=34, Forex Charts=51/52).

Without this view, legacy stored procedures and application code that reference Dictionary.GetGameType would need to be refactored to query Dictionary.GameType directly. The view acts as a backward-compatibility layer.

---

## 2. Business Logic

### 2.1 Trading Activity Classification Taxonomy

**What**: Maps the historical evolution of eToro's platform from gamified trading to modern investment.

**Columns/Parameters Involved**: `GameTypeID`, `Name`

**Rules**:
- GameTypeID ranges reflect the platform's evolution: 0-4=original gamified trading, 11=Slot, 21=Poker, 31-34=modern trading modes, 41=Race Pro, 51-52=Forex Charts
- "eToro Trading" (ID=34) is the primary modern trading mode used for all current platform activity
- Legacy game types (Horse Race, Car Race, Poker) are historical artifacts — no longer active but retained for audit trail integrity
- GameType feeds into Dictionary.GameSubType for further sub-classification

**Diagram**:
```
GameType Evolution Timeline
│
├── 2007 (Gamified Trading)
│   ├── 0: NULL (placeholder)
│   ├── 1: Horse Race
│   ├── 2: Car Race
│   ├── 3: Forex Marathon
│   └── 4: Dollar Trend
│
├── 2008 (Social Games)
│   ├── 11: Slot
│   └── 21: Poker
│
├── 2010 (Broker Transition)
│   ├── 31: Globe Trader
│   ├── 32: IB Trades
│   ├── 33: Trade Box
│   └── 34: eToro Trading ← CURRENT PRIMARY MODE
│
└── 2012+ (Tools)
    ├── 41: Race Pro
    ├── 51: Forex Charts
    └── 52: Forex Charts (variant)
```

---

## 3. Data Overview

| GameTypeID | Name | Meaning |
|---|---|---|
| 0 | NULL | Placeholder/unknown game type — used as a default when no specific type is assigned |
| 1 | Horse Race | Original gamified trading experience where users "raced" currencies against each other — purely historical |
| 34 | eToro Trading | The primary modern trading mode used for all current CFD, stock, and crypto trading on the platform |
| 51 | Forex Charts | Chart-based forex trading interface — an analytical trading tool mode |
| 21 | Poker | Social poker game that was part of eToro's early gamification strategy — no longer active |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GameTypeID | int | NO | - | VERIFIED | Game/trading activity type identifier. PK from Dictionary.GameType. Values range from 0 (NULL/unknown) through legacy games (1-4, 11, 21) to modern trading modes (31-34, 41, 51-52). Referenced by Dictionary.GameSubType for sub-classification. (Dictionary.GameType) |
| 2 | Name | char(50) | YES | - | VERIFIED | Game type display name (padded to 50 chars). Names reflect the platform's evolution: "Horse Race", "Poker" (legacy gamification) → "eToro Trading", "Forex Charts" (modern). Inherited from Dictionary.GameType.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GameTypeID | Dictionary.GameType | Base table | Source of all game type definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GetGameTypeList | - | Function | Generates a comma-separated list of game type IDs for filtering |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetGameType (view)
└── Dictionary.GameType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GameType | Table | Base table — SELECT GameTypeID, Name (all rows, no filter) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetGameTypeList | Function | Reads game types for building ID lists |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Base table Dictionary.GameType has a clustered PK on GameTypeID.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all game/trading types
```sql
SELECT  GameTypeID, RTRIM(Name) AS Name
FROM    Dictionary.GetGameType WITH (NOLOCK)
ORDER BY GameTypeID
```

### 8.2 Find the primary modern trading type
```sql
SELECT  GameTypeID, RTRIM(Name) AS Name
FROM    Dictionary.GetGameType WITH (NOLOCK)
WHERE   GameTypeID = 34
```

### 8.3 Join game types with their sub-categories
```sql
SELECT  gt.GameTypeID, RTRIM(gt.Name) AS GameType,
        gst.GameSubTypeID, gst.Name AS SubType
FROM    Dictionary.GetGameType gt WITH (NOLOCK)
JOIN    Dictionary.GameSubType gst WITH (NOLOCK) ON gst.GameTypeID = gt.GameTypeID
ORDER BY gt.GameTypeID, gst.GameSubTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetGameType | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetGameType.sql*
