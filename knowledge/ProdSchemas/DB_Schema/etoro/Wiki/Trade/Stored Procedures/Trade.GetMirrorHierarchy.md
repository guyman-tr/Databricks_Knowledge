# Trade.GetMirrorHierarchy

> Entry-point dispatcher for the CopyTrader mirror hierarchy walk — routes to Include or Exclude variant based on whether already-opened positions should be included.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorHierarchy is the public entry point for the CopyTrader hierarchy traversal system. When a trader opens, modifies, or closes a position, the system calls this procedure to find all copiers (and their copiers, recursively) who need to receive a propagated operation.

This procedure:
1. Looks up the position owner (CID) and open date from `RealOpenPositions`
2. Routes to one of two specialized hierarchy walkers based on the `@IncludeAlreadyOpenedPositions` flag:
   - **Include mode** (`Trade.GetMirrorHierarchyIncludeOpenedPositions`): Returns ALL copiers — used for modifications/closures that must reach every existing copy
   - **Exclude mode** (`Trade.GetMirrorHierarchyExcludeOpenedPositions`): Returns only copiers who DON'T already have a derived position — used for new position opens to avoid duplicates

This dispatcher pattern keeps the business logic clean: callers only need to know about one procedure and one flag.

---

## 2. Business Logic

### 2.1 Position Owner Lookup

**What**: Derives the ParentCID and position open datetime from the position ID.

**Columns/Parameters Involved**: `@PositionID`, `RealOpenPositions`

**Rules**:
- SELECT @InitDateTime = Occurred, @ParentCID = CID FROM RealOpenPositions WHERE PositionID = @PositionID
- These values are passed to the Include variant; the Exclude variant derives them internally

### 2.2 Routing Decision

**What**: Dispatches to the appropriate hierarchy walker.

**Columns/Parameters Involved**: `@IncludeAlreadyOpenedPositions`

**Rules**:
- @IncludeAlreadyOpenedPositions = 1 → EXEC Trade.GetMirrorHierarchyIncludeOpenedPositions @ParentCID, @PositionID, @InitDateTime, @UseHierarchy
- @IncludeAlreadyOpenedPositions = 0 → EXEC Trade.GetMirrorHierarchyExcludeOpenedPositions @PositionID, @UseHierarchy, @ExcludeInsufficientMirrorFunds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @PositionID | bigint | IN | - | CODE-BACKED | The position ID to find copier hierarchy for. Used to look up the position owner and open date. |
| 2 | @IncludeAlreadyOpenedPositions | int | IN | 1 | CODE-BACKED | 1=Include mode (all copiers, for modifications). 0=Exclude mode (only copiers without existing derived position, for new opens). |
| 3 | @UseHierarchy | int | IN | 1 | CODE-BACKED | 1=walk multi-level hierarchy, 0=direct copiers only. Passed through to child procedures. |
| 4 | @ExcludeInsufficientMirrorFunds | int | IN | 0 | CODE-BACKED | Only used in Exclude mode. When 1, excludes copiers with insufficient mirror funds. |

### 4.2 Result Set

Result set is returned by the dispatched child procedure. See:
- [Trade.GetMirrorHierarchyIncludeOpenedPositions](Trade.GetMirrorHierarchyIncludeOpenedPositions.md) — returns MirrorID, CID, ParentCID, Level, TotalCash, Amount, MirrorRealizedEquity, RealizedEquity, IsFundCopy
- [Trade.GetMirrorHierarchyExcludeOpenedPositions](Trade.GetMirrorHierarchyExcludeOpenedPositions.md) — returns MirrorID, CID, ParentCID, Level, IsFundCopy

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | RealOpenPositions | SELECT (READER) | Position owner and datetime lookup |
| EXEC | Trade.GetMirrorHierarchyIncludeOpenedPositions | Stored Procedure | Include mode hierarchy walker |
| EXEC | Trade.GetMirrorHierarchyExcludeOpenedPositions | Stored Procedure | Exclude mode hierarchy walker |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application Layer | EXEC | Application | Called by trading services for position propagation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorHierarchy (procedure - dispatcher)
+-- RealOpenPositions (synonym/view)
+-- Trade.GetMirrorHierarchyIncludeOpenedPositions (procedure)
|   +-- Trade.Mirror, Customer.Customer, Maintenance.Feature, dbo.RealFund, History.LogErrorGeneral
+-- Trade.GetMirrorHierarchyExcludeOpenedPositions (procedure)
    +-- Trade.Mirror, RealOpenPositions, Trade.GetPositionData, Customer.Customer,
        Maintenance.Feature, dbo.RealFund, History.LogErrorGeneral
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealOpenPositions | Synonym/View | Position owner lookup |
| Trade.GetMirrorHierarchyIncludeOpenedPositions | Stored Procedure | Include mode delegation |
| Trade.GetMirrorHierarchyExcludeOpenedPositions | Stored Procedure | Exclude mode delegation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application Layer | Service | Position propagation in CopyTrader |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Thin dispatcher with no direct business logic — all hierarchy logic is in the child procedures
- @IncludeAlreadyOpenedPositions defaults to 1 (include mode), meaning modifications are the expected common case
- Position lookup uses RealOpenPositions which filters for active open positions only

---

## 8. Sample Queries

### 8.1 Get hierarchy for position modification (include all copiers)

```sql
EXEC Trade.GetMirrorHierarchy
    @PositionID = 1234567890,
    @IncludeAlreadyOpenedPositions = 1,
    @UseHierarchy = 1;
```

### 8.2 Get hierarchy for new position open (exclude already-opened)

```sql
EXEC Trade.GetMirrorHierarchy
    @PositionID = 1234567890,
    @IncludeAlreadyOpenedPositions = 0,
    @UseHierarchy = 1,
    @ExcludeInsufficientMirrorFunds = 1;
```

### 8.3 Direct copiers only (no multi-level)

```sql
EXEC Trade.GetMirrorHierarchy
    @PositionID = 1234567890,
    @IncludeAlreadyOpenedPositions = 1,
    @UseHierarchy = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Dependencies inherited: Trade.GetMirrorHierarchyIncludeOpenedPositions.md, Trade.GetMirrorHierarchyExcludeOpenedPositions.md*
*Object: Trade.GetMirrorHierarchy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorHierarchy.sql*
