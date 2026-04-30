# Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk

> DEBUG-ONLY diagnostic procedure that reconstructs the mirror hierarchy that would have been opened for a given parent position at the time the position was created, WITHOUT position amounts. Explicitly marked as not for real trading use.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID BIGINT, @UseHierarchy INT = 1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**THIS PROCEDURE IS FOR DEBUG ONLY.** The procedure's own header states: "IT CAN BE ACTIVATED WITH POSITIONS THAT WERE ALREADY OPEN AND IT WILL SHOW YOU THE TREE THAT WILL BE OPENED WITHOUT THE POSITION'S AMOUNT. IT WAS WRITTEN TO CHECK A BUG THAT WE HAD AND SHOULD NOT BE USED FOR REAL TRADING!!!!!!!"

The procedure reconstructs the CopyTrader mirror hierarchy as it existed at the time a specific position was opened. Given a PositionID, it looks up the open time and parent CID, then performs a recursive CTE to find all active mirrors that were connected to that leader (ParentCID) at the open time, subject to the minimum position amount and PauseCopy filters. This lets developers see which followers should have had positions opened without the actual monetary amounts involved.

The @UseHierarchy=1 recursive expansion also checks for Maintenance.Feature FeatureID=22 (the Real Positions feature flag) to control whether multi-level hierarchy is traversed.

Data flows: Look up OpenOccurred and CID from Trade.GetPositionDataSlim. Look up minimum position amount from Maintenance.Feature FeatureID=100. Recursive CTE on Trade.Mirror to build hierarchy as of @Date. Return MirrorID, CID, ParentCID, Level.

---

## 2. Business Logic

### 2.1 Point-in-Time Mirror Hierarchy

**What**: Reconstructs the mirror tree as it existed at the parent position's open time.

**Columns/Parameters Involved**: `@Date`, `@ParentCID`, `Trade.Mirror.Occurred`, `Trade.Mirror.IsActive`, `Trade.Mirror.PauseCopy`

**Rules**:
- @Date = position's OpenOccurred (from Trade.GetPositionDataSlim).
- @ParentCID = position's CID (the leader whose followers should be reconstructed).
- Anchor: IsActive=1 AND Occurred <= @Date (mirror existed before position open) AND Amount > @MinPosAmount AND PauseCopy=0.
- Recursive step: @UseHierarchy=1 AND IsActive=1 AND Occurred <= @Date AND Feature 22=1 AND Amount > @MinPosAmount AND PauseCopy=0.
- The Feature 22 check in the recursive step was the real-positions feature flag; this procedure predates the hardcoding of @IsReal=1 in GetPositionsTree.

### 2.2 Minimum Position Amount Filter

**What**: Filters out mirror relationships below a configured minimum investment threshold.

**Columns/Parameters Involved**: `@MinPosAmount`, `Maintenance.Feature.FeatureID=100`

**Rules**:
- @MinPosAmount = CONVERT(decimal(16,8), Value)/100 FROM Maintenance.Feature WHERE FeatureID=100.
- Divides by 100 (value stored in cents or basis points).
- Mirrors with Amount <= @MinPosAmount are excluded from the hierarchy.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The parent position to reconstruct the mirror hierarchy for. Changed from INT to BIGINT (2021-11-17). |
| 2 | @UseHierarchy | INT | YES | 1 | CODE-BACKED | 1=traverse multi-level mirror hierarchy recursively (subject to Feature 22 flag); 0=only direct mirrors of the parent CID. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | MirrorID | INT | NO | - | CODE-BACKED | CopyTrader mirror relationship ID. |
| 4 | CID | INT | NO | - | CODE-BACKED | Follower customer ID. |
| 5 | ParentCID | INT | NO | - | CODE-BACKED | Leader customer ID that this mirror follows. |
| 6 | Level | INT | NO | - | CODE-BACKED | Hierarchy depth. 0 = direct follower of the leader; N = N levels deep in the mirror chain. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.GetPositionDataSlim | Lookup | OpenOccurred and CID for the parent position |
| @MinPosAmount | Maintenance.Feature | Lookup | FeatureID=100 minimum mirror investment amount |
| MirrorID tree | Trade.Mirror | Recursive CTE | Mirror hierarchy as of position open time |
| @UseHierarchy=1 recursion | Maintenance.Feature | Conditional | FeatureID=22 controls multi-level traversal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Developers / DBAs | (manual invocation) | Debug only | Called manually to investigate mirror hierarchy bugs; never called by application code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk (procedure, DEBUG ONLY)
+-- Trade.GetPositionDataSlim (view) [OpenOccurred, CID lookup]
+-- Maintenance.Feature (table) [FeatureID=100 min amount, FeatureID=22 hierarchy flag]
+-- Trade.Mirror (table) [recursive CTE mirror hierarchy]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataSlim | View | OpenOccurred and CID lookup for the input position |
| Maintenance.Feature | Table | FeatureID=100 (min position amount), FeatureID=22 (hierarchy flag for recursive step) |
| Trade.Mirror | Table | Recursive CTE source for mirror hierarchy reconstruction |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | Debug-only; no production callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEBUG ONLY | Usage | Procedure header explicitly states NOT for real trading |
| Point-in-time filter | Logic | Trade.Mirror.Occurred <= @Date restricts hierarchy to mirrors active at position open time |
| Feature 22 guard | Recursion | Recursive step only traverses if Feature 22 = 1 |

---

## 8. Sample Queries

### 8.1 Check mirror hierarchy for a specific position (debug)

```sql
-- DEBUG ONLY - do not use in production
EXEC Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk
    @PositionID = 1234567890,
    @UseHierarchy = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk.sql*
