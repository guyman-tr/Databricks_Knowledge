# Trade.GetMirrorHierarchyExcludeOpenedPositions

> Recursively walks the CopyTrader mirror hierarchy to find copiers who should receive a copied position, EXCLUDING those who already have a position opened from this parent position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MirrorID, CID, ParentCID, Level, IsFundCopy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorHierarchyExcludeOpenedPositions is a core CopyTrader procedure used during position open operations. When a trader opens a position, the system must propagate that position to all copiers (and their copiers, recursively). This procedure finds all eligible copiers who have NOT yet had a position opened for this parent position.

This procedure exists because the CopyTrader system supports multi-level hierarchies: Trader A is copied by B, who is copied by C. When A opens a position, B and C both need a copied position. This recursive CTE walks the hierarchy, checks whether each copier already has a derived position from this parent, and returns only those who don't (to avoid duplicate position creation).

If no eligible copiers are found but the trader has active followers, a diagnostic log entry is written to History.LogErrorGeneral for investigation.

---

## 2. Business Logic

### 2.1 Recursive Hierarchy Walk

**What**: Uses a recursive CTE to traverse the CopyTrader hierarchy from a trader down through all levels of copiers.

**Columns/Parameters Involved**: `@PositionID`, `@UseHierarchy`, `@ExcludeInsufficientMirrorFunds`, `Trade.Mirror`, `Trade.GetPositionData`

**Rules**:
- Anchor: All active mirrors where ParentCID = the position owner (Occurred <= position date)
- Recursion: Each copier's copiers (Trade.Mirror joined on ParentCID = previous level CID)
- Recursion gated by: @UseHierarchy=1, IsActive=1, FeatureID=22 enabled (hierarchy feature flag)
- ExistingPositionID: Checked via Trade.GetPositionData for OrigParentPositionID match. If found, copier already has this position
- Final WHERE: ExistingPositionID = 0 (exclude already-opened)
- IsFundCopy: Flagged via dbo.RealFund if ParentCID is a fund account

### 2.2 Diagnostic Logging

**What**: Logs to History.LogErrorGeneral when the hierarchy walk returns no results but followers exist.

**Rules**:
- Only logs if @@ROWCOUNT = 0 AND the trader has active followers
- Captures PositionID, CID, UseHierarchy, dates, and thresholds as XML
- Message: "User has followers but only his position was opened"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @PositionID | bigint | IN | - | CODE-BACKED | The parent position ID that was opened by the trader. Used to find the trader CID and check for existing derived positions. |
| 2 | @UseHierarchy | int | IN | 1 | CODE-BACKED | 1=walk multi-level hierarchy, 0=only direct copiers (Level 0). |
| 3 | @ExcludeInsufficientMirrorFunds | bit | IN | - | CODE-BACKED | When 1, excludes copiers whose mirror has insufficient funds. When 0, includes all regardless of funds. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | The mirror relationship to create a copied position under. |
| 2 | CID | int | NO | CODE-BACKED | The copier's customer ID who needs a new position. |
| 3 | ParentCID | int | YES | CODE-BACKED | The trader this copier is copying (immediate parent). |
| 4 | Level | int | NO | CODE-BACKED | Hierarchy depth: 0=direct copier, 1=copier's copier, etc. |
| 5 | IsFundCopy | int | NO | CODE-BACKED | 1 if the ParentCID is a fund account (from dbo.RealFund), 0 otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Recursive hierarchy traversal |
| FROM | RealOpenPositions (synonym) | SELECT (READER) | Gets position owner CID and date |
| FROM | Trade.GetPositionData | SELECT (READER) | Checks for existing derived positions |
| FROM | Customer.Customer | SELECT (READER) | Copier financial data (TotalCash, RealizedEquity) |
| FROM | Maintenance.Feature | SELECT (READER) | FeatureID=100 (min position amount), FeatureID=22 (hierarchy enabled) |
| LEFT JOIN | dbo.RealFund | SELECT (READER) | Fund account detection |
| INSERT | History.LogErrorGeneral | INSERT (WRITER) | Diagnostic logging when no copiers found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorHierarchy | EXEC | Stored Procedure | Called when @IncludeAlreadyOpenedPositions=0 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorHierarchyExcludeOpenedPositions (procedure)
+-- Trade.Mirror (table)
+-- RealOpenPositions (synonym/view)
+-- Trade.GetPositionData (view)
+-- Customer.Customer (table)
+-- Maintenance.Feature (table)
+-- dbo.RealFund (table)
+-- History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Recursive hierarchy walk |
| RealOpenPositions | Synonym/View | Position owner lookup |
| Trade.GetPositionData | View | Existing position check |
| Customer.Customer | Table | Copier financial info |
| Maintenance.Feature | Table | Feature flags (100, 22) |
| dbo.RealFund | Table | Fund account detection |
| History.LogErrorGeneral | Table | Diagnostic logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorHierarchy | Stored Procedure | Calls this for exclude mode |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Recursive CTE with FeatureID=22 gate for multi-level hierarchy.

---

## 8. Sample Queries

### 8.1 Get hierarchy excluding already-opened positions

```sql
EXEC Trade.GetMirrorHierarchyExcludeOpenedPositions
    @PositionID = 1234567890,
    @UseHierarchy = 1,
    @ExcludeInsufficientMirrorFunds = 0;
```

### 8.2 Direct copiers only (no recursion)

```sql
EXEC Trade.GetMirrorHierarchyExcludeOpenedPositions
    @PositionID = 1234567890,
    @UseHierarchy = 0,
    @ExcludeInsufficientMirrorFunds = 0;
```

### 8.3 Check active copiers of a trader

```sql
SELECT  MirrorID, CID, ParentCID, IsActive, Occurred
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 11111
        AND IsActive = 1
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorHierarchyExcludeOpenedPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorHierarchyExcludeOpenedPositions.sql*
