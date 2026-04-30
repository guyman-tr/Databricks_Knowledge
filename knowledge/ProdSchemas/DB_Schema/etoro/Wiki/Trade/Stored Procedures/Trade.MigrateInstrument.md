# Trade.MigrateInstrument

> One-time DBA migration tool that transitions a stock instrument's existing positions into the regular trading system: sets copy-trade tree IDs, inserts PositionTreeInfo rows, aligns UnitMargin, and configures lot count limits to enable SL/TP support.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - the instrument to migrate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MigrateInstrument is a one-time DBA tool for transitioning stock instruments from a legacy trading system (without SL/TP) to the regular eToro trading system (with full SL/TP and copy-trade tree support). The inline comment is explicit: "This procedure should only be used when we transfer stocks to work with the regular trading system and let them have SL and TP. It shouldn't be used in any of our applications."

The procedure performs six steps: (1) detects Real vs Demo environment via Maintenance.Feature, (2) assigns TreeID and RootHedgeServerID to root positions (ParentPositionID=0), (3) recursively propagates TreeID and RootHedgeServerID down the copy-trade tree using a CTE, (4) aligns UnitMargin from Trade.ProviderToInstrument, (5) inserts missing Trade.PositionTreeInfo rows with default SL/TP values, (6) sets up lot count limits (MaxUnits) and enables the instrument.

This procedure exists because legacy stock instruments were originally traded without the position tree infrastructure that powers copy-trading, SL/TP, and tree-based close operations. Migration populates the missing infrastructure rows so the standard trading engine can treat these positions as regular ones.

---

## 2. Business Logic

### 2.1 Real vs Demo Environment Detection

**What**: Checks Maintenance.Feature (FeatureID=22) to determine whether to use positive or negative TreeIDs.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`

**Rules**:
- FeatureID=22, Value=1 -> @IsReal=1 (Real environment): TreeID = PositionID * 1 (positive).
- FeatureID=22, Value!=1 -> @IsReal=-1 (Demo environment): TreeID = PositionID * -1 (negative, per comment: "In demo environment the treeID for any copied position is a negative number (zero minus the Parent Position ID)").
- This sign convention ensures Real and Demo TreeIDs never collide.

**Diagram**:
```
Maintenance.Feature (FeatureID=22, Value)
    |-- Value=1  -> @IsReal=1  -> TreeID = PositionID (positive)
    |-- Value!=1 -> @IsReal=-1 -> TreeID = -PositionID (negative)
```

### 2.2 Copy-Trade Tree ID Assignment

**What**: Two-phase UPDATE sets TreeID and RootHedgeServerID for all positions of the migrated instrument.

**Columns/Parameters Involved**: `Trade.PositionTbl.TreeID`, `Trade.PositionTbl.RootHedgeServerID`, `Trade.PositionTbl.ParentPositionID`

**Rules**:
- Phase 1 (root positions): WHERE ParentPositionID IS NULL OR = 0 -> TreeID = PositionID * @IsReal, RootHedgeServerID = HedgeServerID, ParentPositionID = 0.
- Phase 2 (child positions): recursive CTE (Roots) traverses the tree, propagating TreeID (root's PositionID) and ParentHedgeServerID (root's HedgeServerID) to all descendants. Only updates Lvl > 1 rows (children, not roots already updated in Phase 1).
- After migration, all positions in a copy-trade tree share the same TreeID (the root's PositionID).

**Diagram**:
```
Root position (ParentPositionID=0):
  TreeID = PositionID * IsReal
  RootHedgeServerID = HedgeServerID

Children (ParentPositionID != 0):
  TreeID = ancestor root's PositionID * IsReal
  RootHedgeServerID = ancestor root's HedgeServerID
```

### 2.3 PositionTreeInfo Bootstrap

**What**: Inserts a PositionTreeInfo row for each unique TreeID discovered, with default SL/TP values.

**Columns/Parameters Involved**: `Trade.PositionTreeInfo.TreeID`, `Trade.PositionTreeInfo.StopRate`, `Trade.PositionTreeInfo.LimitRate`, `Trade.PositionTreeInfo.CloseOnEndOfWeek`

**Rules**:
- Inserts DISTINCT TreeIDs from Trade.PositionTbl WHERE InstrumentID = @InstrumentID.
- Default values: StopRate=0.01, LimitRate=0, CloseOnEndOfWeek=0.
- TreeID in the insert is multiplied by @IsReal (same sign convention as Phase 1).
- Only inserts; no check for existing rows - callers must ensure no duplicates.

### 2.4 Lot Count and Instrument Configuration

**What**: Ensures @MaxUnits exists as a valid lot count option and updates the instrument's provider configuration.

**Columns/Parameters Involved**: `@MaxUnits`, `@Enabled`, `Dictionary.LotCount`, `Trade.ProviderInstrumentToLotCount`, `Trade.ProviderToInstrument`

**Rules**:
- If @MaxUnits not in Dictionary.LotCount: INSERT new row (LotCountID = Value = @MaxUnits).
- DELETE existing ProviderInstrumentToLotCount for this instrument + LotCountID = @MaxUnits (prevents unique constraint violations on re-run).
- INSERT ProviderInstrumentToLotCount for each LotCountGroup (ProviderID=1, IsDefault=0, Percentage=0).
- UPDATE Trade.ProviderToInstrument: Enabled = @Enabled, MaxPositionUnits = @MaxUnits.
- Also aligns UnitMargin: UPDATE PositionTbl.UnitMargin from ProviderToInstrument.UnitMargin for all positions of this instrument.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | ID of the stock instrument to migrate. All positions in Trade.PositionTbl with this InstrumentID are updated. All ProviderToInstrument and ProviderInstrumentToLotCount rows for this instrument are reconfigured. |
| 2 | @MaxUnits | INTEGER | NO | - | CODE-BACKED | Maximum number of units allowed per position for this instrument after migration. Inserted into Dictionary.LotCount if not present. Set as MaxPositionUnits in Trade.ProviderToInstrument. Used as LotCountID in Trade.ProviderInstrumentToLotCount. |
| 3 | @Enabled | BIT | NO | - | CODE-BACKED | Whether to enable the instrument for trading after migration. Written to Trade.ProviderToInstrument.Enabled. 1 = instrument is tradeable; 0 = disabled (migration without enabling). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=22 | Maintenance.Feature | Read | Detects Real vs Demo environment for TreeID sign convention |
| @InstrumentID | Trade.PositionTbl | Read/Write | Updates TreeID, RootHedgeServerID, ParentPositionID, UnitMargin for all matching positions |
| TreeID | Trade.PositionTreeInfo | Write | Inserts default SL/TP tree rows for all unique TreeIDs of this instrument |
| @InstrumentID | Trade.ProviderToInstrument | Read/Write | Reads UnitMargin for positions; updates Enabled and MaxPositionUnits |
| @MaxUnits | Dictionary.LotCount | Read/Write | Ensures MaxUnits value exists as a valid lot count |
| @InstrumentID, @MaxUnits | Trade.ProviderInstrumentToLotCount | Write | Deletes conflicting row, then inserts max units mapping per LotCountGroup |
| LotCountGroupID | Dictionary.LotCountGroup | Read | Source of all LotCountGroupIDs for the ProviderInstrumentToLotCount insert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No callers found) | - | - | DBA-only procedure called manually; no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MigrateInstrument (procedure)
├── Maintenance.Feature (table)
├── Trade.PositionTbl (table)
├── Trade.PositionTreeInfo (table)
├── Trade.ProviderToInstrument (table)
├── Dictionary.LotCount (table)
├── Trade.ProviderInstrumentToLotCount (table)
└── Dictionary.LotCountGroup (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECTed for FeatureID=22 to determine Real vs Demo (TreeID sign) |
| Trade.PositionTbl | Table | UPDATEd for TreeID/RootHedgeServerID/ParentPositionID/UnitMargin; SELECTed in CTE for tree traversal |
| Trade.PositionTreeInfo | Table | INSERTed with default StopRate/LimitRate/CloseOnEndOfWeek per TreeID |
| Trade.ProviderToInstrument | Table | SELECTed for UnitMargin; UPDATEd with Enabled and MaxPositionUnits |
| Dictionary.LotCount | Table | Checked for @MaxUnits existence; INSERTed if missing |
| Trade.ProviderInstrumentToLotCount | Table | Existing row DELETEd to avoid unique constraint, then INSERTed with new max units config |
| Dictionary.LotCountGroup | Table | SELECTed to find all LotCountGroupIDs for the ProviderInstrumentToLotCount insert |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | One-time migration tool; no consumers. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses WITH RECOMPILE to avoid suboptimal cached plans when called for different instruments (varying data distribution per instrument).

### 7.2 Constraints

N/A for stored procedure. Note: contains a commented-out `INSERT INTO Stocks.InstrumentBlackList(InstrumentID)` - this step was apparently removed from the migration workflow. No explicit transaction wrapping - all DML runs outside a transaction; partial failure leaves data in an intermediate state.

---

## 8. Sample Queries

### 8.1 Check positions that would be updated (before running migration)

```sql
SELECT PositionID, InstrumentID, ParentPositionID, TreeID, RootHedgeServerID, HedgeServerID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE InstrumentID = <InstrumentID>
ORDER BY ParentPositionID, PositionID;
```

### 8.2 Verify TreeID assignment after migration

```sql
SELECT PT.PositionID, PT.TreeID, PT.ParentPositionID, PT.RootHedgeServerID,
       PTI.StopRate, PTI.LimitRate
FROM Trade.PositionTbl AS PT WITH (NOLOCK)
LEFT JOIN Trade.PositionTreeInfo AS PTI WITH (NOLOCK) ON PTI.TreeID = PT.TreeID
WHERE PT.InstrumentID = <InstrumentID>
ORDER BY PT.TreeID, PT.PositionID;
```

### 8.3 Check provider configuration for the instrument after migration

```sql
SELECT PTI.InstrumentID, PTI.Enabled, PTI.MaxPositionUnits, PTI.UnitMargin
FROM Trade.ProviderToInstrument AS PTI WITH (NOLOCK)
WHERE PTI.InstrumentID = <InstrumentID>;

SELECT PILC.ProviderID, PILC.InstrumentID, PILC.LotCountGroupID,
       PILC.LotCountID, PILC.IsDefault
FROM Trade.ProviderInstrumentToLotCount AS PILC WITH (NOLOCK)
WHERE PILC.InstrumentID = <InstrumentID>;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MigrateInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MigrateInstrument.sql*
