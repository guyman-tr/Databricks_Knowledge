# Dictionary.GameSubType

> Lookup table defining the 11 trading game/activity sub-type categories — from legacy social games (Race, Slot, Poker) to the current eToro Trading mode — used to group related game types.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GameSubTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK + unique Name index) |

---

## 1. Business Meaning

Dictionary.GameSubType defines the broad categories of trading game formats available on the eToro platform. This is a legacy classification from eToro's early era as a gamified trading platform, when the system offered social trading as games — horse races, slots, poker, and globe trader challenges alongside actual forex trading. Over time, the platform evolved into a serious investment platform, and "eToro Trading" (ID 10) became the dominant sub-type.

This table exists as the parent classification for Dictionary.GameType, forming a two-level hierarchy: SubType → Type. While most legacy game sub-types (Race, Slot, Poker) are no longer active on the platform, the classification persists in the database schema because historical trading records (History.ForexResult) reference these game types, and the GameType FK chain passes through this table.

GameSubTypeID is referenced by Dictionary.GameType (FK), Game.ForexGame, and indirectly by all history tables that track trade results and position data.

---

## 2. Business Logic

### 2.1 Game Category Hierarchy

**What**: Sub-types are broad categories that group specific game types into families.

**Columns/Parameters Involved**: `GameSubTypeID`, `Name`

**Rules**:
- **None (0)**: Default/unclassified — fallback when no sub-type applies
- **Legacy social games (1-9)**: Historical game formats from eToro's gamified era — Race (horse/car/forex marathon), Slot, Poker, Globe Trader, Trade Box, Rope Game, VS USD, IB Trade, Forex Charts
- **eToro Trading (10)**: Current production mode — standard instrument trading on the eToro platform
- Dictionary.GameType entries reference GameSubTypeID to classify each specific game variant under its parent category

**Diagram**:
```
Dictionary.GameSubType (broad category)
└── Dictionary.GameType (specific variant)
    Examples:
    ├── Race (1) ──► Horse Race (1), Car Race (2), Forex Marathon (3)
    ├── Slot (2) ──► Slot (11)
    ├── Poker (3) ──► Poker (21)
    └── eToro Trading (10) ──► eToro Trading (34)
```

---

## 3. Data Overview

| GameSubTypeID | Name | Meaning |
|---|---|---|
| 0 | None | Default fallback category for unclassified activities. Used when a trading record doesn't map to a specific game format. |
| 1 | Race | Legacy racing game category — customers competed by predicting instrument price movements in a horse race, car race, or forex marathon visual format. Multiple GameType variants existed under this sub-type. |
| 10 | eToro Trading | The current standard trading mode. All modern instrument trading (stocks, crypto, forex, indices) on the eToro platform falls under this sub-type. This is the only sub-type actively used in production today. |
| 4 | Globe Trader | Legacy social trading game where customers traded on a global map visualization. One of eToro's early innovative UX concepts for making trading accessible and engaging. |
| 9 | Forex Charts | Standard chart-based forex trading mode. Predecessor to the current eToro Trading sub-type, focused specifically on forex chart analysis and trading. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GameSubTypeID | int | NO | - | VERIFIED | Primary key identifying the game sub-type category. 0=None, 1=Race, 2=Slot, 3=Poker, 4=Globe Trader, 5=Trade Box, 6=Rope Game, 7=VS USD, 8=IB Trade, 9=Forex Charts, 10=eToro Trading. Referenced by Dictionary.GameType via FK to group game variants into categories. |
| 2 | Name | char(50) | NO | - | VERIFIED | Unique human-readable label for the sub-type category. Fixed-width char(50). Used in reporting, history views, and BackOffice for classifying trading activities. Enforced unique via DGST_NAME index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.GameType | GameSubTypeID | FK | Each game type is classified under a sub-type category |
| Game.ForexGame | GameSubTypeID | Implicit Lookup | Game sessions reference their sub-type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GameType | Table | FK to GameSubTypeID — groups game variants into categories |
| Game.ForexGame | Table | References GameSubTypeID for game session classification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DGST | CLUSTERED PK | GameSubTypeID ASC | - | - | Active |
| DGST_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DGST | PRIMARY KEY | Unique sub-type identifier |
| DGST_NAME | UNIQUE INDEX | Each sub-type has a unique name |

---

## 8. Sample Queries

### 8.1 List all game sub-types
```sql
SELECT  GameSubTypeID,
        RTRIM(Name)     AS SubTypeName
FROM    [Dictionary].[GameSubType] WITH (NOLOCK)
ORDER BY GameSubTypeID;
```

### 8.2 Show game type hierarchy (sub-type → type)
```sql
SELECT  gst.GameSubTypeID,
        RTRIM(gst.Name) AS SubTypeName,
        gt.GameTypeID,
        RTRIM(gt.Name)   AS GameTypeName
FROM    [Dictionary].[GameSubType] gst WITH (NOLOCK)
JOIN    [Dictionary].[GameType] gt WITH (NOLOCK)
        ON gst.GameSubTypeID = gt.GameSubTypeID
ORDER BY gst.GameSubTypeID, gt.GameTypeID;
```

### 8.3 Find the current production sub-type
```sql
SELECT  GameSubTypeID,
        RTRIM(Name)     AS SubTypeName
FROM    [Dictionary].[GameSubType] WITH (NOLOCK)
WHERE   GameSubTypeID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GameSubType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.GameSubType.sql*
