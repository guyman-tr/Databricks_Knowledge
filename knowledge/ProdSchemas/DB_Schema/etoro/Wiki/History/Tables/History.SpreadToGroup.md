# History.SpreadToGroup

> Trigger-managed application history table for Trade.SpreadToGroup, recording all past assignments of specific spreads to spread groups - the junction table history showing which spreads belonged to which groups and for how long.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | SpreadToGroupVersionID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (CLUSTERED PK on SpreadToGroupVersionID; NONCLUSTERED on SpreadGroupID+SpreadID; NONCLUSTERED on SpreadID) |

---

## 1. Business Meaning

This table is the **trigger-managed application history table** for `Trade.SpreadToGroup`. History is maintained by triggers on `Trade.SpreadToGroup`:
- `SpreadToGroupInsert` trigger (INSERT): inserts a new row with ValidFrom=GETDATE(), ValidTo='3000-01-01'
- `SpreadToGroupDelete` trigger (DELETE): closes the active row (ValidTo=GETDATE())

**Note**: There is NO UPDATE trigger - spread-to-group assignments are atomic: they are either added (INSERT) or removed (DELETE), never modified in place.

`Trade.SpreadToGroup` is the **junction table** linking spread groups to individual spreads (many-to-many). Each row says "spread X belongs to group Y." A spread group aggregates multiple spreads (one per provider-instrument combination) and can be assigned to customers or introducing brokers to give them custom pricing. When a spread is added to a group, a history row is written; when removed, the row's ValidTo is set to the current date.

The table has **14,100 rows** spanning March 2009 through April 2014. It has not been actively written to since 2014, consistent with History.Spread and History.SpreadGroup - the custom spread group feature is a legacy system. Most active records (ValidTo='3000-01-01') represent the frozen final state.

14 distinct SpreadGroups and 11,669 distinct Spreads appear across the history.

---

## 2. Business Logic

### 2.1 Spread Assignment History

**What**: Records when each spread was added to or removed from a spread group.

**Columns/Parameters Involved**: `SpreadGroupID`, `SpreadID`, `ValidFrom`, `ValidTo`

**Rules**:
- `ValidTo='3000-01-01'` = this assignment is currently active (spread still in the group)
- `ValidTo < '3000-01-01'` = this assignment ended (spread was removed from the group)
- INSERT to Trade.SpreadToGroup -> new history row with ValidFrom=NOW, ValidTo='3000-01-01'
- DELETE from Trade.SpreadToGroup -> active row closed with ValidTo=NOW
- No UPDATE trigger: spread-to-group assignments cannot be modified, only added or removed
- Source FKs: SpreadGroupID -> Trade.SpreadGroup, SpreadID -> Trade.Spread

### 2.2 Spread Group Composition

**What**: A spread group is composed of multiple spreads, allowing a complete custom pricing overlay.

**Columns/Parameters Involved**: `SpreadGroupID`, `SpreadID`

**Rules**:
- One SpreadID can belong to multiple SpreadGroups (observed: SpreadID 1342 in groups 1, 2, 3, 7 simultaneously)
- One SpreadGroup contains many SpreadIDs (one per provider-instrument pair)
- The combination of spreads in a group defines the complete pricing override for a customer or IB assigned to that group

---

## 3. Data Overview

| SpreadToGroupVersionID | SpreadGroupID | SpreadID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 3086 | 3 | 1342 | 2014-04-08 09:32 | 3000-01-01 (active) | SpreadID 1342 added to group 3 |
| 3085 | 2 | 1342 | 2014-04-08 09:32 | 3000-01-01 (active) | Same SpreadID 1342 also in group 2 |
| 3084 | 7 | 1342 | 2014-04-08 09:32 | 3000-01-01 (active) | And in group 7 simultaneously |

Total: 14,100 rows | 14 distinct groups | 11,669 distinct spreads | Mar 2009 - Apr 2014 (last change)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadToGroupVersionID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key for history rows. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each spread-to-group assignment event. |
| 2 | SpreadGroupID | int | NO | - | VERIFIED | The spread group this spread was assigned to. FK to Trade.SpreadGroup (enforced on source). Indexed with SpreadID. |
| 3 | SpreadID | int | NO | - | VERIFIED | The individual spread (provider-instrument bid/ask adjustment) assigned to the group. FK to Trade.Spread (enforced on source). Multiple SpreadToGroupVersionIDs can share the same SpreadID if the spread belongs to multiple groups. |
| 4 | ValidFrom | datetime | NO | - | CODE-BACKED | UTC timestamp when this spread was added to the spread group. Set to GETDATE() by the SpreadToGroupInsert trigger. |
| 5 | ValidTo | datetime | NO | - | CODE-BACKED | UTC timestamp when this spread was removed from the group. Sentinel '3000-01-01' = currently assigned. Set to GETDATE() by SpreadToGroupDelete trigger when the spread is removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadGroupID | Trade.SpreadToGroup | Trigger History | Each row is a past assignment state recorded when spreads were added to groups. |
| SpreadGroupID | Trade.SpreadGroup (via source FK) | Implicit FK | The group that contains this spread. See History.SpreadGroup for group metadata. |
| SpreadID | Trade.Spread (via source FK) | Implicit FK | The spread being assigned. See History.Spread for spread details. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SpreadToGroup | SpreadToGroupInsert / SpreadToGroupDelete triggers | Trigger Writer | All INSERT/DELETE operations on Trade.SpreadToGroup are reflected here. |

---

## 6. Dependencies

No dependencies. Application-managed trigger history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HS2G | CLUSTERED PK | SpreadToGroupVersionID ASC | - | - | Active |
| HS2G_LINK | NONCLUSTERED | SpreadGroupID ASC, SpreadID ASC | - | - | Active |
| HS2G_SPREAD | NONCLUSTERED | SpreadID ASC | - | - | Active |

Note: All indexes on [HISTORY] filegroup with FILLFACTOR=90.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HS2G | PRIMARY KEY | Uniqueness on SpreadToGroupVersionID. CLUSTERED. FILLFACTOR=90. NOT FOR REPLICATION. |

---

## 8. Sample Queries

### 8.1 Get all currently active spread-to-group assignments
```sql
SELECT SpreadGroupID, SpreadID, ValidFrom
FROM [History].[SpreadToGroup] WITH (NOLOCK)
WHERE ValidTo = '30000101'
ORDER BY SpreadGroupID, SpreadID
```

### 8.2 Get all spreads ever in a specific group
```sql
SELECT SpreadToGroupVersionID, SpreadID, ValidFrom, ValidTo
FROM [History].[SpreadToGroup] WITH (NOLOCK)
WHERE SpreadGroupID = @SpreadGroupID
ORDER BY ValidFrom ASC
```

### 8.3 Find which groups a spread belonged to at a point in time
```sql
SELECT SpreadGroupID, ValidFrom, ValidTo
FROM [History].[SpreadToGroup] WITH (NOLOCK)
WHERE SpreadID = @SpreadID
  AND ValidFrom <= @PointInTime
  AND ValidTo > @PointInTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (trigger-driven) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SpreadToGroup | Type: Table | Source: etoro/etoro/History/Tables/History.SpreadToGroup.sql*
