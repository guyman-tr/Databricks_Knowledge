# Trade.GetMirrorStocksPositionsIDs

> Returns open copy-trade position IDs and instrument IDs for a mirror where the instrument is DISABLED in ProviderToInstrument (Enabled=0), used to identify positions in suspended/disabled instruments that need special handling. Despite its name, returns all disabled-instrument positions, not only stocks.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - filters to one mirror's disabled-instrument positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorStocksPositionsIDs` retrieves open copy-trade positions belonging to a mirror where the instrument has been disabled in `Trade.ProviderToInstrument` (`Enabled = 0`). These are positions in instruments that have been suspended, withdrawn, or otherwise marked as unavailable for new trading.

**Important naming caveat**: The procedure name "StocksPositionsIDs" is a legacy name. A code comment explains: "This procedure get IDs of positions regardless if those are stocks or not. At first it used to get only stocks, but now it gets all IDs for positions that with instrument that has 0 in Enabled column for there instruments." The original stock filter (`InstrumentID > 1000`) has been commented out and replaced with the `ProviderToInstrument.Enabled = 0` filter.

This procedure is the **complement** of `Trade.GetMirrorNonStocksPositions`, which returns positions where `Enabled = 1`. Together they partition a mirror's open positions: this procedure finds the disabled-instrument ones, the other finds the enabled-instrument ones.

Data flows: Called alongside `GetMirrorNonStocksPositions` during mirror operations to identify which positions are in disabled instruments. These positions may require special handling (e.g., forced closure) before mirror operations can proceed.

---

## 2. Business Logic

### 2.1 Disabled Instrument Filter

**What**: Returns only positions in instruments that are no longer active/enabled for the provider.

**Columns/Parameters Involved**: `PTI.Enabled`, `MirrorID`, `ParentPositionID`, `StatusID`

**Rules**:
- `PTI.Enabled = 0`: Instrument is disabled for this provider. These are instruments that have been suspended or removed from trading.
- `ParentPositionID > 0`: Copy-trade child positions only. Root/manual positions excluded.
- `MirrorID > 0`: Safety guard against MirrorID=0 (non-copy positions).
- `StatusID = 1`: Open positions only. Code comment confirms: "StatusID = 1 Indicates whether the position is still open."
- Change history matches `GetMirrorNonStocksPositions`: FB 24690 (2015 stock check redesign) and FB 52337 (2018 async close + status condition).

### 2.2 Complement to GetMirrorNonStocksPositions

**What**: This procedure + GetMirrorNonStocksPositions = complete set of a mirror's open copy positions.

**Columns/Parameters Involved**: `PTI.Enabled`

**Rules**:
- GetMirrorStocksPositionsIDs: `PTI.Enabled = 0` (disabled instruments)
- GetMirrorNonStocksPositions: `PTI.Enabled = 1` (enabled instruments)
- Union of both = all open copy positions in the mirror.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier. Filters to open copy positions in this mirror where the instrument is disabled. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | PositionID | Trade.PositionTbl | The position identifier. Used by caller to process or close the disabled-instrument position. |
| 2 | InstrumentID | Trade.PositionTbl | The instrument that is disabled (PTI.Enabled=0 for this InstrumentID + ProviderID combination). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.PositionTbl | Primary read | Source of open copy positions for the mirror. |
| InstrumentID + ProviderID | Trade.ProviderToInstrument | JOIN | Filter on Enabled=0 to find disabled-instrument positions. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorStocksPositionsIDs (procedure)
├── Trade.PositionTbl (table)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Primary source - open copy positions for the mirror |
| Trade.ProviderToInstrument | Table | INNER JOIN on InstrumentID - filters WHERE Enabled=0 |

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

### 8.1 Get disabled-instrument positions for a mirror

```sql
EXEC Trade.GetMirrorStocksPositionsIDs @MirrorID = 12345;
```

### 8.2 Verify disabled instrument positions directly

```sql
SELECT TPOS.PositionID, TPOS.InstrumentID, PTI.Enabled
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON TPOS.InstrumentID = PTI.InstrumentID
WHERE TPOS.MirrorID = 12345
  AND TPOS.MirrorID > 0
  AND TPOS.ParentPositionID > 0
  AND TPOS.StatusID = 1
  AND PTI.Enabled = 0;
```

### 8.3 Get full mirror position split by instrument status

```sql
-- Enabled instruments
SELECT 'Enabled' AS InstrumentStatus, COUNT(*) AS PositionCount
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK) ON TPOS.InstrumentID = PTI.InstrumentID AND TPOS.ProviderID = PTI.ProviderID
WHERE TPOS.MirrorID = 12345 AND TPOS.ParentPositionID > 0 AND TPOS.StatusID = 1 AND PTI.Enabled = 1
UNION ALL
-- Disabled instruments
SELECT 'Disabled' AS InstrumentStatus, COUNT(*) AS PositionCount
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK) ON TPOS.InstrumentID = PTI.InstrumentID
WHERE TPOS.MirrorID = 12345 AND TPOS.ParentPositionID > 0 AND TPOS.StatusID = 1 AND PTI.Enabled = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorStocksPositionsIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorStocksPositionsIDs.sql*
