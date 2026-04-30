# Dictionary.GameType

> Lookup table defining 14 specific trading game/activity types — from legacy social games (Horse Race, Slot, Poker) to the current eToro Trading mode — each classified under a parent sub-type category.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GameTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK + GameSubTypeID NC) |

---

## 1. Business Meaning

Dictionary.GameType defines the specific trading game variants available on eToro. Each game type represents a distinct trading activity format — from legacy social games (Horse Race, Car Race, Poker, Slot) to the current standard trading mode ("eToro Trading"). This is the most granular level of the game classification hierarchy, with each type linked to a parent sub-type via Dictionary.GameSubType.

This table is fundamental to the eToro history and position tracking system. Every closed position in History.ForexResult is tagged with a GameTypeID, and many history views and stored procedures use GameTypeID to filter and display trades. The Internal.GetGameTypeList function provides a list of game types for views like History.GetClosedPositions. Championship.Championship also references GameTypeID to define the game format for trading competitions.

While most legacy game types are no longer offered to customers, GameTypeID 34 ("eToro Trading") is the dominant production value used for all modern trades.

---

## 2. Business Logic

### 2.1 Game Type Hierarchy

**What**: Each game type belongs to a parent sub-type, forming a two-level classification system.

**Columns/Parameters Involved**: `GameTypeID`, `GameSubTypeID`, `Name`

**Rules**:
- GameTypeID is NOT sequential — IDs jump (0, 1, 2, 3, 4, 11, 21, 31, 32, 33, 34, 41, 51, 52) with gaps between families
- Multiple game types can share the same sub-type (e.g., Horse Race, Car Race, Forex Marathon all under Race sub-type)
- GameTypeID 34 ("eToro Trading") is the current production value for all standard instrument trades
- GameTypeID 0 ("NULL") is the unclassified fallback under sub-type None

### 2.2 Legacy vs Current Types

**What**: The game type system reflects eToro's evolution from gamified trading to serious investing.

**Columns/Parameters Involved**: `GameTypeID`, `Name`

**Rules**:
- **Legacy games (1-33, 41, 51)**: Historical formats no longer offered — racing predictions, slot-style random trading, poker-style multiplayer, globe visualization
- **Current production (34)**: "eToro Trading" — standard instrument trading (stocks, crypto, forex, indices, commodities)
- **Forex Charts (52)**: Standard chart-based trading, the precursor to eToro Trading
- History tables preserve all game types to maintain accurate historical records

---

## 3. Data Overview

| GameTypeID | Name | SubTypeName | Meaning |
|---|---|---|---|
| 34 | eToro Trading | eToro Trading | The current standard trading mode. All modern trades (stocks, crypto, forex, ETFs, indices, commodities) on the eToro platform use this game type. This is the only actively used type for new positions. |
| 1 | Horse Race | Race | Legacy social game where customers predicted which of several instruments would gain the most value, visualized as a horse race. Customers wagered on their prediction. No longer available. |
| 21 | Poker | Poker | Legacy multiplayer trading game with poker-style mechanics. Customers competed in trading rounds with poker-themed UI. Part of eToro's early gamification approach. |
| 31 | Globe Trader | Globe Trader | Legacy social trading game with a global map visualization. Customers selected instruments from different regions on an interactive globe. Part of eToro's innovative early UX. |
| 4 | Dollar Trend | VS USD | Legacy game type focused on predicting USD movement against other currencies. Simple directional bet on the dollar's strength. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GameTypeID | int | NO | - | VERIFIED | Primary key identifying the specific game/trading type. Key values: 0=NULL (fallback), 34=eToro Trading (current production). Legacy: 1=Horse Race, 2=Car Race, 3=Forex Marathon, 4=Dollar Trend, 11=Slot, 21=Poker, 31=Globe Trader, 32=IB Trades, 33=Trade Box, 41=Race Pro, 51/52=Forex Charts. Referenced by History.ForexResult, Championship.Championship, and multiple history views/procedures. |
| 2 | GameSubTypeID | int | NO | - | VERIFIED | FK to Dictionary.GameSubType classifying this game type under a parent category. 0=None, 1=Race, 2=Slot, 3=Poker, 4=Globe Trader, 5=Trade Box, 6=Rope Game, 7=VS USD, 8=IB Trade, 9=Forex Charts, 10=eToro Trading. Groups related game variants together. |
| 3 | Name | char(50) | NO | - | VERIFIED | Human-readable label for the game type. Fixed-width char(50). Used in history views, closed position reports, and BackOffice for display. Describes the specific trading activity format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GameSubTypeID | Dictionary.GameSubType | FK | Classifies this game type under a parent sub-type category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ForexResult | GameTypeID | Implicit Lookup | Every closed trade is tagged with its game type |
| Championship.Championship | GameTypeID | Implicit Lookup | Competitions reference their game format |
| History.GetClosedPositions | GameTypeID | JOIN | Closed position view filters/displays by game type |
| History.GetTradingFlatViewClosedPositionsPerPageNew | GameTypeID | Read | Flat view of closed positions includes game type |
| History.PR_GetPosition_For_HistoryWS | GameTypeID | Read | History web service procedure uses game type |
| History.GetClosedPositionsPerPageByParentCID | GameTypeID | Read | Parent CID position history includes game type |
| Internal.GetGameTypeList | GameTypeID | Read | Returns game type list for view consumption |
| BackOffice.GetFirstGameInfoPerCustomer | GameTypeID | JOIN | First game info per customer view |
| Dictionary.GetGameType | GameTypeID | Read | View exposes game types |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object depends on Dictionary.GameSubType (FK).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GameSubType | Table | FK — parent sub-type classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Table | Tags each closed trade with GameTypeID |
| Championship.Championship | Table | Defines game format for competitions |
| History.GetClosedPositions | View | Filters/displays closed positions by game type |
| Internal.GetGameTypeList | Function | Provides game type list for view consumption |
| BackOffice.GetFirstGameInfoPerCustomer | View | First game info per customer |
| Dictionary.GetGameType | View | Exposes game types for external consumption |
| History.GetTradingFlatViewClosedPositionsPerPageNew | Stored Procedure | Closed position reports |
| History.PR_GetPosition_For_HistoryWS | Stored Procedure | History web service |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DGMT | CLUSTERED PK | GameTypeID ASC | - | - | Active |
| DGMT_SUBTYPE | NONCLUSTERED | GameSubTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DGMT | PRIMARY KEY | Unique game type identifier |
| FK_DGST_DGMT | FOREIGN KEY | GameSubTypeID → Dictionary.GameSubType.GameSubTypeID |

---

## 8. Sample Queries

### 8.1 List all game types with their sub-type
```sql
SELECT  gt.GameTypeID,
        RTRIM(gt.Name)      AS GameTypeName,
        gt.GameSubTypeID,
        RTRIM(gst.Name)     AS SubTypeName
FROM    [Dictionary].[GameType] gt WITH (NOLOCK)
JOIN    [Dictionary].[GameSubType] gst WITH (NOLOCK)
        ON gt.GameSubTypeID = gst.GameSubTypeID
ORDER BY gt.GameTypeID;
```

### 8.2 Find the current production game type
```sql
SELECT  GameTypeID,
        RTRIM(Name) AS GameTypeName
FROM    [Dictionary].[GameType] WITH (NOLOCK)
WHERE   GameTypeID = 34;
```

### 8.3 Count closed trades by game type
```sql
SELECT  RTRIM(gt.Name)  AS GameType,
        COUNT(*)        AS TradeCount
FROM    [History].[ForexResult] hr WITH (NOLOCK)
JOIN    [Dictionary].[GameType] gt WITH (NOLOCK)
        ON hr.GameTypeID = gt.GameTypeID
GROUP BY RTRIM(gt.Name)
ORDER BY TradeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GameType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.GameType.sql*
