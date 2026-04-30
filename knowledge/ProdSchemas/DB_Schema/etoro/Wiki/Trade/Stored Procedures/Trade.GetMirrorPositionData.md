# Trade.GetMirrorPositionData

> Returns open copy-trade position data for a specific mirror, with Amount converted to cents (x100), used by mirror management to get a compact position snapshot for rebalancing or synchronisation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - filters to one mirror's open copy positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorPositionData` returns a compact snapshot of all open copy-trade positions (`ParentPositionID > 0`) belonging to a specific mirror. It reads from the `Trade.Position` view (which already filters to `StatusID = 1`, open positions only) and returns key identifiers and financial metrics for each position. The `Amount` column is multiplied by 100 to convert from dollars to cents, matching the unit system expected by the mirror management consumer.

This procedure exists to support mirror-level operations such as portfolio rebalancing, mirror state calculation, and synchronisation with the leader's portfolio. By filtering to copy positions (`ParentPositionID > 0`), it excludes the leader's own root position from the result.

Data flows: Called by mirror management services. Returns one row per open copier position in the mirror. The compact output (8 columns) is optimised for high-frequency mirror state reads.

---

## 2. Business Logic

### 2.1 Amount Unit Conversion

**What**: Amount is returned in cents (dollars x100) rather than dollars.

**Columns/Parameters Involved**: `Amount`

**Rules**:
- The `Trade.Position` view exposes `Amount` in dollars (same as `Trade.PositionTbl.Amount`).
- This procedure multiplies by 100: `pos.Amount * 100 as Amount`.
- Consumer expects cents. This is an application-level unit conversion performed in the SP.

### 2.2 Copy Position Filter

**What**: Only copier positions are returned, not the leader's root position.

**Columns/Parameters Involved**: `ParentPositionID`, `MirrorID`

**Rules**:
- `ParentPositionID > 0`: Copy-trade child positions only. The leader's root position has `ParentPositionID = 0`.
- `MirrorID = @MirrorID`: Scoped to a single mirror's positions.
- `StatusID = 1` (open) is enforced by the `Trade.Position` view itself.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier to scope the query. All returned positions have MirrorID = this value. Corresponds to Trade.Mirror.MirrorID. |

**Output columns** (result set - from Trade.Position view):

| # | Column | Description |
|---|--------|-------------|
| 1 | PositionID | Unique position identifier. Copier position ID. |
| 2 | InstrumentID | The traded instrument ID. Links to Trade.Instrument. |
| 3 | AmountInUnitsDecimal | Position size in instrument units (e.g., shares, barrels). |
| 4 | InitForexRate | Opening forex conversion rate when the position was opened. |
| 5 | IsBuy | Direction: 1=Buy/Long, 0=Sell/Short. |
| 6 | MirrorID | The mirror ID (same as @MirrorID parameter). Included for consumer convenience. |
| 7 | Amount | Position size in CENTS (Trade.PositionTbl.Amount * 100). Application unit conversion performed in this SP. |
| 8 | IsDiscounted | Flag indicating if this position is discounted. From Trade.Position view (computed from PositionTreeInfo). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Lookup | Filters positions to those belonging to this mirror. |
| (via view) | Trade.Position | Primary read | View that provides the open position data (joins PositionTbl + PositionTreeInfo, filters StatusID=1). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorPositionData (procedure)
└── Trade.Position (view)
      ├── Trade.PositionTbl (table)
      └── Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Primary source - SELECT with ParentPositionID > 0 AND MirrorID = @MirrorID filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get mirror position snapshot

```sql
EXEC Trade.GetMirrorPositionData @MirrorID = 12345;
```

### 8.2 Verify Amount unit conversion (dollars vs cents)

```sql
SELECT
    p.PositionID,
    p.Amount AS AmountDollars,
    p.Amount * 100 AS AmountCents
FROM Trade.Position p WITH (NOLOCK)
WHERE p.MirrorID = 12345
  AND p.ParentPositionID > 0;
```

### 8.3 Get open copy positions for a mirror by instrument

```sql
SELECT pos.InstrumentID, COUNT(*) AS PositionCount, SUM(pos.Amount) AS TotalAmountDollars
FROM Trade.Position pos WITH (NOLOCK)
WHERE pos.MirrorID = 12345
  AND pos.ParentPositionID > 0
GROUP BY pos.InstrumentID
ORDER BY TotalAmountDollars DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorPositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorPositionData.sql*
