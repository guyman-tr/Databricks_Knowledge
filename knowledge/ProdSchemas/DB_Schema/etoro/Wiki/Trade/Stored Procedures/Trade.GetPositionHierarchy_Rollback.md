# Trade.GetPositionHierarchy_Rollback

> Older rollback variant of GetPositionHierarchy - uses Trade.GetPositionData view instead of PositionTbl directly, adds NumOfDemoCopiers and HasCopyPlusInDemo columns, and checks Maintenance.Feature FeatureID=22 inline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - parent position to traverse from |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionHierarchy_Rollback` is the older (rollback) version of `Trade.GetPositionHierarchy`. It uses the `Trade.GetPositionData` view as its data source instead of querying `Trade.PositionTbl` directly. It adds two extra columns not present in the current version: `NumOfDemoCopiers` (count of demo accounts copying the position) and `HasCopyPlusInDemo` (flag for CopyPlus demo positions). Includes ORDER BY Level, ParentPositionID.

**WHY:** This rollback version was preserved as a safety net when GetPositionHierarchy was re-engineered (2020-07-14) to use PositionTbl directly. The "_Rollback" suffix indicates it was the previous version kept for quick rollback if the new version had issues.

**HOW:** Recursive CTE `PositionHiararchy` (note typo in CTE name) seeds with Level=0 from Trade.GetPositionData WHERE ParentPositionID=@PositionID. Recursive step adds Level+1 WHERE @UseHierarchy=1 AND IsOpened=1 AND EXISTS(Feature 22=1). Final SELECT joins to Trade.DemoCopiedCIDs (NumOfDemoCopiers) and Trade.DemoCopiedPositions (HasCopyPlusInDemo).

---

## 2. Business Logic

### 2.1 GetPositionData View as Source

**What:** Uses Trade.GetPositionData (a unified live+history view) instead of PositionTbl.

**Rules:**
- Trade.GetPositionData returns columns already aliased (IsOpened, Currency, PositionHedgeServerID, etc.)
- `WHERE IsOpened = 1` in recursive step (not StatusID=1)
- No explicit partition routing needed (view handles it internally)

### 2.2 Feature Flag as Inline Subquery

**What:** Recursion enabled by EXISTS subquery on Maintenance.Feature, not a variable.

**Rules:**
- `AND EXISTS (SELECT * FROM Maintenance.Feature WHERE FeatureID = 22 AND CAST(Value AS INT) = 1)`
- Called per recursive iteration (vs. pre-loaded variable in current version)
- Slight performance difference from current GetPositionHierarchy approach

### 2.3 Demo Copier Enrichment

**What:** Adds demo copier metrics to each position row.

**Columns/Parameters Involved:** `NumOfDemoCopiers`, `HasCopyPlusInDemo`

**Rules:**
- `LEFT JOIN Trade.DemoCopiedCIDs TDCC ON PH.CID = TDCC.CID` -> `ISNULL(TDCC.NumOfDemoCopiers, 0)`
- `LEFT JOIN Trade.DemoCopiedPositions TDCP ON PH.PositionID = TDCP.PositionID` -> `CASE WHEN TDCP.PositionID > 0 THEN 1 ELSE 0 END AS HasCopyPlusInDemo`
- These columns are absent from the current GetPositionHierarchy version

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Parent position to traverse. |
| 2 | @UseHierarchy | INT | YES | 1 | CODE-BACKED | 1=recurse; 0=Level 0 only. |
| 3 | Level | INT | NO | - | CODE-BACKED | Depth in copy tree. 0=direct children. |
| 4 | (all GetPositionData columns) | VARIOUS | - | - | CODE-BACKED | Same columns as Trade.GetPositionData. Includes CID, PositionID, ParentPositionID, IsOpened, Currency, IsBuy, etc. (identical to GetPositionHierarchy minus IsMirrorActive, plus different source). |
| 5 | NumOfDemoCopiers | INT | NO | 0 | CODE-BACKED | Number of demo accounts copying this position. From Trade.DemoCopiedCIDs. |
| 6 | HasCopyPlusInDemo | BIT | NO | 0 | CODE-BACKED | 1 if there is a CopyPlus demo position for this position. From Trade.DemoCopiedPositions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.GetPositionData | Recursive CTE | Unified live+history position view |
| CID | Trade.DemoCopiedCIDs | LEFT JOIN | Demo copier count per customer |
| PositionID | Trade.DemoCopiedPositions | LEFT JOIN | CopyPlus demo detection |
| FeatureID=22 | Maintenance.Feature | EXISTS subquery | IsReal recursion gate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Rollback version - preserved for emergency fallback.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionHierarchy_Rollback (procedure)
|- Trade.GetPositionData (view) - unified live+history position data
|- Trade.DemoCopiedCIDs (table) - demo copier counts
|- Trade.DemoCopiedPositions (table) - CopyPlus demo positions
|- Maintenance.Feature (table) - IsReal feature flag
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Rollback version of GetPositionHierarchy |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsOpened = 1 in recursion | Filter | Open positions only (vs StatusID=1 in current version) |
| EXISTS Feature 22 = 1 | Recursion gate | Inline check vs pre-loaded variable in current version |
| ORDER BY Level, ParentPositionID | Output | Removed from current version for performance |
| CTE named "PositionHiararchy" | Note | Typo in CTE name (hiararchy vs hierarchy) |

---

## 8. Sample Queries

### 8.1 Get copy hierarchy (rollback version)

```sql
EXEC Trade.GetPositionHierarchy_Rollback @PositionID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionHierarchy_Rollback | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionHierarchy_Rollback.sql*
