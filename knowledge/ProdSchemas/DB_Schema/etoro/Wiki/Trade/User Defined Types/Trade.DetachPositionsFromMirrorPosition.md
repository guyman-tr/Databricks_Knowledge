# Trade.DetachPositionsFromMirrorPosition

> Memory-optimized TVP carrying position-level data for the mirror detach operation - individual position details for each position being detached, while DetachPositionsFromMirror carries the mirror relationship data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | TreeID (bigint) |
| **Partition** | N/A |
| **Indexes** | 1 nonclustered hash (TreeID) |

---

## 1. Business Meaning

Trade.DetachPositionsFromMirrorPosition is a memory-optimized table-valued parameter (TVP) that carries position-level data for copy-trade detach operations. While Trade.DetachPositionsFromMirror carries the mirror relationship state (CID, ParentCID, financial snapshots, flags), this type carries the individual position details: position identity (PositionID, OrigParentPositionID), trading details (InstrumentID, IsBuy, Leverage), tree hierarchy (TreeID, MirrorID), and settlement info (IsSettled, SettlementTypeID).

The type exists because detach procedures need both mirror-level and position-level data. Trade.DetachPositionsFromMirror consumes this TVP alongside the mirror relationship TVP to process each position being detached. IsSettled is the legacy real-stock flag (1=real stock, 0=CFD); SettlementTypeID is the newer multi-value replacement. IsComputeForHedge determines whether the position is included in hedge exposure calculations. The hash index on TreeID with bucket count 1 optimizes tree-level operations.

---

## 2. Business Logic

### 2.1 Position Detach Identity and Hierarchy

**What**: Each row represents one position being detached, with identity, tree placement, and settlement type.

**Columns/Parameters Involved**: `PositionID`, `OrigParentPositionID`, `TreeID`, `MirrorID`, `IsSettled`, `SettlementTypeID`, `IsComputeForHedge`

**Rules**:
- PositionID identifies the copier's position being detached
- OrigParentPositionID points to the leader's source position
- TreeID and MirrorID place the position in the copy-trade tree
- IsSettled (legacy) or SettlementTypeID (new) determines real stock vs CFD
- IsComputeForHedge controls hedge exposure inclusion

**Diagram**:
```
TreeID (hash index)
  |
  +-> PositionID, OrigParentPositionID (identity)
  |
  +-> MirrorID, CID, InstrumentID (relationship + instrument)
  |
  +-> IsBuy, Leverage (trading params)
  |
  +-> IsSettled, SettlementTypeID (settlement type)
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID of the copier whose position is being detached. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Instrument (asset) identifier. Determines what was traded. |
| 3 | PositionID | bigint | YES | - | CODE-BACKED | Copier's position identifier. Primary key for the position being detached. |
| 4 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Leader's original position ID that this position was copied from. Source of the copy relationship. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | Mirror relationship identifier. Links to mirror-level detach data. |
| 6 | IsComputeForHedge | smallint | YES | - | CODE-BACKED | Whether the position is included in hedge exposure calculations. 1=include, 0=exclude. Affects hedging and risk aggregation. |
| 7 | HedgeServerID | int | YES | - | CODE-BACKED | Server ID for hedge routing. Used when position participates in hedge calculations. |
| 8 | TreeID | bigint | YES | - | CODE-BACKED | Position tree identifier. Hash index on this column optimizes tree-level lookups during detach. |
| 9 | IsBuy | bit | YES | - | CODE-BACKED | Direction: 1=buy (long), 0=sell (short). Preserved through detach. |
| 10 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier (e.g., 5 for 5x). Trading parameter preserved at detach. |
| 11 | IsSettled | bit | YES | - | CODE-BACKED | Legacy flag for settlement type: 1=real stock (customer owns actual shares), 0=CFD (contract for difference). Predates SettlementTypeID; when SettlementTypeID is NULL, IsSettled is used. |
| 12 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Newer multi-value settlement type. Replaces IsSettled for finer-grained classification. Real stock vs CFD and variants. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerTbl | Implicit | Copier customer |
| InstrumentID | Trade.InstrumentTbl | Implicit | Instrument lookup |
| PositionID | Trade.PositionTbl | Implicit | Copier position |
| OrigParentPositionID | Trade.PositionTbl | Implicit | Leader position |
| MirrorID | Trade.MirrorTbl | Implicit | Mirror relationship |
| SettlementTypeID | Dictionary lookup | Implicit | Settlement type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DetachPositionsFromMirror | TVP parameter | Parameter (TVP) | Passes position-level data to detach procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DetachPositionsFromMirror | Stored Procedure | READONLY parameter for position-level detach data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX | Nonclustered HASH | TreeID | - | - | Active |

BUCKET_COUNT = 1, optimized for single-tree detach operations.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Populate DetachPositionsFromMirrorPosition from open mirror positions

```sql
DECLARE @PositionData Trade.DetachPositionsFromMirrorPosition;
INSERT INTO @PositionData (CID, InstrumentID, PositionID, OrigParentPositionID, MirrorID, IsComputeForHedge, HedgeServerID, TreeID, IsBuy, Leverage, IsSettled, SettlementTypeID)
SELECT  p.CID, p.InstrumentID, p.PositionID, p.OrigParentPositionID, p.MirrorID, p.IsComputeForHedge, p.HedgeServerID, p.TreeID, p.IsBuy, p.Leverage, p.IsSettled, ISNULL(p.SettlementTypeID, CAST(p.IsSettled AS tinyint))
FROM    Trade.PositionTbl p WITH (NOLOCK)
WHERE   p.MirrorID = @MirrorID AND p.IsOpen = 1;

EXEC Trade.DetachPositionsFromMirror @MirrorData = @MirrorData, @PositionData = @PositionData;
```

### 8.2 Build position TVP for detach with hedge computation flag

```sql
DECLARE @Positions Trade.DetachPositionsFromMirrorPosition;
INSERT INTO @Positions (CID, InstrumentID, PositionID, OrigParentPositionID, MirrorID, TreeID, IsBuy, Leverage, IsSettled, SettlementTypeID, IsComputeForHedge)
SELECT  p.CID, p.InstrumentID, p.PositionID, p.OrigParentPositionID, p.MirrorID, p.TreeID, p.IsBuy, p.Leverage, p.IsSettled, p.SettlementTypeID, ISNULL(p.IsComputeForHedge, 1)
FROM    Trade.PositionTbl p WITH (NOLOCK)
JOIN    Trade.MirrorTbl m WITH (NOLOCK) ON m.MirrorID = p.MirrorID
WHERE   m.CID = @CID AND m.ParentCID = @ParentCID AND p.IsOpen = 1;

EXEC Trade.DetachPositionsFromMirror @MirrorData = @MirrorData, @PositionData = @Positions;
```

### 8.3 Single position detach payload

```sql
DECLARE @Pos Trade.DetachPositionsFromMirrorPosition;
INSERT INTO @Pos (CID, InstrumentID, PositionID, OrigParentPositionID, MirrorID, TreeID, IsBuy, Leverage, IsSettled, SettlementTypeID)
VALUES (@CID, @InstrumentID, @PositionID, @OrigParentPositionID, @MirrorID, @TreeID, @IsBuy, @Leverage, @IsSettled, @SettlementTypeID);
EXEC Trade.DetachPositionsFromMirror @MirrorData = @MirrorData, @PositionData = @Pos;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachPositionsFromMirrorPosition | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DetachPositionsFromMirrorPosition.sql*
