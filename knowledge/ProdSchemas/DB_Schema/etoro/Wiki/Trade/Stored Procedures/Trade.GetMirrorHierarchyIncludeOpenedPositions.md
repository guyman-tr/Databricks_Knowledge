# Trade.GetMirrorHierarchyIncludeOpenedPositions

> Recursively walks the CopyTrader mirror hierarchy to find ALL copiers who should receive a copied position, INCLUDING those who already have one opened from this parent position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MirrorID, CID, ParentCID, Level, IsFundCopy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorHierarchyIncludeOpenedPositions is a CopyTrader hierarchy walker used during position modification operations (e.g., updating stop-loss, take-profit, or partial close propagation). Unlike its counterpart `Trade.GetMirrorHierarchyExcludeOpenedPositions` which is used during position open, this procedure returns ALL copiers in the hierarchy regardless of whether they already have a derived position, because the operation needs to reach every copier that may hold a copy of the position.

The procedure accepts the parent CID and position date directly as parameters (rather than deriving them from the position like the Exclude variant), and walks the mirror hierarchy recursively using a CTE. It filters on active mirrors, pause-copy status, and occurrence date. Multi-level recursion is gated by the FeatureID=22 flag.

If the hierarchy walk returns no copiers but followers exist, a diagnostic log entry is written to History.LogErrorGeneral.

---

## 2. Business Logic

### 2.1 Recursive Hierarchy Walk

**What**: Traverses the CopyTrader mirror hierarchy from a trader down through all levels of copiers, returning ALL copiers regardless of existing derived positions.

**Columns/Parameters Involved**: `@ParentCID`, `@PositionID`, `@PositionInitDateTime`, `@UseHierarchy`, `Trade.Mirror`, `Customer.Customer`

**Rules**:
- Anchor: All active mirrors where ParentCID = @ParentCID, Occurred <= @PositionInitDateTime, PauseCopy = 0
- Recursion: Each copier's copiers (Trade.Mirror joined on ParentCID = previous level CID)
- Recursion gated by: @UseHierarchy=1, IsActive=1, PauseCopy=0, FeatureID=22 enabled
- Returns financial data: TotalCash, MirrorRealizedEquity, customer RealizedEquity (for downstream amount calculations)
- IsFundCopy: Flagged via dbo.RealFund if ParentCID is a fund account
- Ordered by Level, ParentCID to ensure parent-first processing

### 2.2 Key Difference from Exclude Variant

**What**: Does NOT check Trade.GetPositionData for existing positions. Returns all copiers unconditionally (after active/pause/date filters).

**Why**: Used for operations that need to propagate to all existing copies (modifications, closures), not just new position creation.

### 2.3 Diagnostic Logging

**What**: Logs to History.LogErrorGeneral when no copiers are found despite active followers existing.

**Rules**:
- Only logs if @@ROWCOUNT = 0 AND active non-paused followers exist
- Captures CID, PositionID, UseHierarchy, PositionDate, MinPosAmount as XML
- Message: "User has fallowers but only his position was opened"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @ParentCID | int | IN | NULL | CODE-BACKED | The trader CID whose copier hierarchy to walk. Passed by Trade.GetMirrorHierarchy after looking up the position owner. |
| 2 | @PositionID | bigint | IN | - | CODE-BACKED | The parent position ID. Used only for diagnostic logging (not for position lookups in this variant). |
| 3 | @PositionInitDateTime | datetime | IN | NULL | CODE-BACKED | The position's open date. Mirrors that started copying after this date are excluded (Occurred <= this value). |
| 4 | @UseHierarchy | int | IN | 1 | CODE-BACKED | 1=walk multi-level hierarchy, 0=only direct copiers (Level 0). |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | The mirror relationship ID. |
| 2 | CID | int | NO | CODE-BACKED | The copier's customer ID. |
| 3 | ParentCID | int | YES | CODE-BACKED | The trader this copier is copying (immediate parent in hierarchy). |
| 4 | Level | int | NO | CODE-BACKED | Hierarchy depth: 0=direct copier, 1=copier's copier, etc. |
| 5 | TotalCash | money | YES | CODE-BACKED | Copier's total cash from Customer.Customer (for downstream amount calculations). |
| 6 | Amount | money | YES | CODE-BACKED | The mirror's allocated amount from Trade.Mirror. |
| 7 | MirrorRealizedEquity | money | YES | CODE-BACKED | Mirror-level realized equity from Trade.Mirror. |
| 8 | RealizedEquity | money | YES | CODE-BACKED | Customer-level realized equity from Customer.Customer. |
| 9 | IsFundCopy | int | NO | CODE-BACKED | 1 if the ParentCID is a fund account (from dbo.RealFund), 0 otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Recursive hierarchy traversal |
| INNER JOIN | Customer.Customer | SELECT (READER) | Copier financial data (TotalCash, RealizedEquity) |
| FROM | Maintenance.Feature | SELECT (READER) | FeatureID=100 (min position amount), FeatureID=22 (hierarchy enabled) |
| LEFT JOIN | dbo.RealFund | SELECT (READER) | Fund account detection |
| INSERT | History.LogErrorGeneral | INSERT (WRITER) | Diagnostic logging when no copiers found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorHierarchy | EXEC | Stored Procedure | Called when @IncludeAlreadyOpenedPositions=1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorHierarchyIncludeOpenedPositions (procedure)
+-- Trade.Mirror (table)
+-- Customer.Customer (table)
+-- Maintenance.Feature (table)
+-- dbo.RealFund (table)
+-- History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Recursive hierarchy walk |
| Customer.Customer | Table | Copier financial info |
| Maintenance.Feature | Table | Feature flags (100, 22) |
| dbo.RealFund | Table | Fund account detection |
| History.LogErrorGeneral | Table | Diagnostic logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorHierarchy | Stored Procedure | Calls this for include mode |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Recursive CTE with FeatureID=22 gate. Uses NOLOCK hints throughout. Returns financial columns (TotalCash, Amount, RealizedEquity) that the Exclude variant does not, supporting downstream amount calculations.

---

## 8. Sample Queries

### 8.1 Get full hierarchy including already-opened positions

```sql
EXEC Trade.GetMirrorHierarchyIncludeOpenedPositions
    @ParentCID = 11111,
    @PositionID = 1234567890,
    @PositionInitDateTime = '2026-03-01 12:00:00',
    @UseHierarchy = 1;
```

### 8.2 Direct copiers only

```sql
EXEC Trade.GetMirrorHierarchyIncludeOpenedPositions
    @ParentCID = 11111,
    @PositionID = 1234567890,
    @PositionInitDateTime = '2026-03-01 12:00:00',
    @UseHierarchy = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorHierarchyIncludeOpenedPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorHierarchyIncludeOpenedPositions.sql*
