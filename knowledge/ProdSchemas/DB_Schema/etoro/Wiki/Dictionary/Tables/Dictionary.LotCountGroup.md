# Dictionary.LotCountGroup

> Maps lot count groups to eToro Club player levels, enabling tier-based position sizing rules across the platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LotCountGroupID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.LotCountGroup defines tier-based groupings for lot count (position size) configurations. Each group corresponds to an eToro Club player level (Bronze, Silver, Gold, Platinum, Test), allowing the platform to offer different position sizing options based on a customer's membership tier.

Without this table, the system could not differentiate position sizing rules by player level. Higher-tier customers (Gold, Platinum) may access different lot count ranges or trading conditions than entry-level (Bronze) customers. This is a core component of the eToro Club tiering system.

Rows are managed via BackOffice.SetLotCountGroupID procedure. The group is assigned to customers and referenced by trading procedures to determine available lot counts for each tier. The PlayerLevelID column links to Dictionary.PlayerLevel, establishing the tier hierarchy.

---

## 2. Business Logic

### 2.1 Player Level to Lot Count Group Mapping

**What**: Each lot count group maps to a specific eToro Club tier, controlling position sizing by membership level.

**Columns/Parameters Involved**: `LotCountGroupID`, `LotCountGroupName`, `PlayerLevelID`

**Rules**:
- Group Bronze (0) → PlayerLevel 1 (lowest tier)
- Group Silver (1) → PlayerLevel 5
- Group Gold (2) → PlayerLevel 3
- Group Platinum (3) → PlayerLevel 2
- Group Test (4) → PlayerLevel 4 (internal testing)
- The PlayerLevelID ordering does not match the group ordering — the mapping is explicit, not positional

**Diagram**:
```
LotCountGroup     PlayerLevel     Tier
─────────────     ───────────     ────
0 (Bronze)    →   1           →   Entry-level customers
1 (Silver)    →   5           →   Mid-tier customers
2 (Gold)      →   3           →   High-value customers
3 (Platinum)  →   2           →   Top-tier customers
4 (Test)      →   4           →   Internal QA/testing
```

---

## 3. Data Overview

| LotCountGroupID | LotCountGroupName | PlayerLevelID | Meaning |
|---|---|---|---|
| 0 | Group Bronze | 1 | Entry-level eToro Club tier — default lot count configuration for new or low-equity customers |
| 1 | Group Silver | 5 | Mid-tier customers who have reached Silver status get expanded position sizing options |
| 2 | Group Gold | 3 | High-value Gold tier customers with premium lot count availability |
| 3 | Group Platinum | 2 | Top-tier Platinum customers with the widest position sizing options |
| 4 | Group Test | 4 | Internal testing group used by QA to validate lot count rules without affecting real customers |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LotCountGroupID | int | NO | - | CODE-BACKED | Unique identifier for the lot count group tier. Values 0–4 map to Bronze/Silver/Gold/Platinum/Test. Referenced by BackOffice.SetLotCountGroupID and customer tier assignment logic. |
| 2 | LotCountGroupName | varchar(50) | YES | - | VERIFIED | Human-readable tier name: "Group Bronze", "Group Silver", "Group Gold", "Group Platinum", "Group Test". Used in BackOffice displays and reporting. |
| 3 | PlayerLevelID | int | YES | - | CODE-BACKED | FK to Dictionary.PlayerLevel. Maps this lot count group to an eToro Club membership tier. Values: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 4=Test. See [Player Level](Dictionary.PlayerLevel.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | Links lot count group to eToro Club membership tier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetLotCountGroupID | @LotCountGroupID | Implicit | Admin procedure to assign customers to lot count groups |
| Customer.SetPlayerLevelNoLot | LotCountGroupID | Implicit | Sets player level without changing lot count group |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetLotCountGroupID | Stored Procedure | Assigns customers to lot count groups |
| Customer.SetPlayerLevelNoLot | Stored Procedure | References lot count group during player level changes |
| BackOffice.GetPlayerLevel | Stored Procedure | Reads lot count group for player level display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DLCG | CLUSTERED PK | LotCountGroupID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all lot count groups with player level names
```sql
SELECT  lcg.LotCountGroupID,
        lcg.LotCountGroupName,
        lcg.PlayerLevelID,
        pl.Name AS PlayerLevelName
FROM    [Dictionary].[LotCountGroup] lcg WITH (NOLOCK)
LEFT JOIN [Dictionary].[PlayerLevel] pl WITH (NOLOCK)
        ON lcg.PlayerLevelID = pl.PlayerLevelID
ORDER BY lcg.LotCountGroupID;
```

### 8.2 Find which group a specific player level belongs to
```sql
SELECT  *
FROM    [Dictionary].[LotCountGroup] WITH (NOLOCK)
WHERE   PlayerLevelID = 3;
```

### 8.3 Count customers per lot count group
```sql
SELECT  lcg.LotCountGroupName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[LotCountGroup] lcg WITH (NOLOCK)
        ON cs.LotCountGroupID = lcg.LotCountGroupID
GROUP BY lcg.LotCountGroupName
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LotCountGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.LotCountGroup.sql*
