# Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest

> Test/debug variant of GetOrderMatchingItemsByInstrumentID_OmeTrees - identical logic, returns position tree data for a batch of instruments. Likely a development artifact left in production.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates #PositionHeaders with NONCLUSTERED INDEX IX on (TreeID, RootHedgeServerID) |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_OmeTreesTest` is a byte-for-byte duplicate of `GetOrderMatchingItemsByInstrumentID_OmeTrees`. Both procedures have identical DDL. The "Test" suffix indicates this was created for testing or development purposes and left in production.

**WHY:** Likely created to test changes to the OmeTrees logic without impacting the production procedure. The test variant may have been used by a developer to validate behavior before promoting changes to the main SP.

**HOW:** Identical to `GetOrderMatchingItemsByInstrumentID_OmeTrees`. See that procedure's documentation for full details.

---

## 2. Business Logic

### 2.1 Identical to OmeTrees

**What:** All logic is the same as `Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees`:
- Feature flag FeatureID=22 (@IsReal multiplier)
- Tree head filter: (PositionID * @IsReal) = TreeID AND StatusID=1
- #PositionHeaders temp table with NONCLUSTERED INDEX
- Final DISTINCT SELECT with windowed SUM for AmountInUnitsDecimal (IsComputeForHedge=1)

See [Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees](Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees.md) for complete business logic documentation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Identical to OmeTrees parameter. |

**Output columns:** Identical to `Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees`. See that document for full column descriptions.

| # | Element | Source | Description |
|---|---------|--------|-------------|
| 1 | InstrumentID | TVP join | Instrument ID |
| 2 | PositionID | Trade.PositionTbl | Tree head position ID |
| 3 | CID | Trade.PositionTbl | Customer ID |
| 4 | InitDateTime | Trade.PositionTbl | Position open time |
| 5 | StopRate | Trade.PositionTbl | Current stop-loss rate |
| 6 | LimitRate | Trade.PositionTbl | Current take-profit rate |
| 7 | IsBuy | Trade.PositionTbl | Direction flag |
| 8 | RootHedgeServerID | Trade.PositionTbl | Root hedge server |
| 9 | TreeID | Trade.PositionTreeInfo | Copy-trade tree ID |
| 10 | IsTslEnabled | Trade.PositionTreeInfo | Trailing SL flag |
| 11 | StopLossVersion | Trade.PositionTreeInfo | SL manual version counter |
| 12 | TrailingStopLossThreshold | Trade.PositionTreeInfo | Next TSL threshold |
| 13 | StopLossVersionTimestamp | Trade.PositionTreeInfo | SL version timestamp |
| 14 | AmountInUnitsDecimal | Windowed SUM | Total hedgeable units per tree-server |
| 15 | Leverage | Trade.PositionTbl | Position leverage |
| 16 | IsNoStopLoss | Trade.PositionTreeInfo | No-SL flag |
| 17 | IsNoTakeProfit | Trade.PositionTreeInfo | No-TP flag |
| 18 | IsSettled | Trade.PositionTbl | Legacy settlement flag |
| 19 | CountryID | Customer.CustomerStatic | Customer country |
| 20 | OrderID | Trade.PositionTbl | Opening order ID |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees` - identical logic and table references.

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| treeInfo.TreeID = TPOS.TreeID | Trade.PositionTreeInfo | JOIN | Tree configuration |
| INNER JOIN | Trade.PositionTbl | JOIN | Open positions |
| INNER JOIN | Customer.CustomerStatic | JOIN | Customer country |
| INNER JOIN | Trade.Position | VIEW JOIN | Hedge amount aggregation |
| FeatureID=22 | Maintenance.Feature | Lookup | Tree ID convention flag |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest (procedure)
|- Trade.InstrumentIDsTbl (user defined type)
|- Trade.PositionTreeInfo (table)
|- Trade.PositionTbl (table)
|- Customer.CustomerStatic (table)
|- Trade.Position (view)
|- Maintenance.Feature (table)
(Identical dependency chain to OmeTrees)
```

### 6.1 Objects This Depends On

Identical to `Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees`. See that document for full dependency list.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Test/development variant - may not be actively called |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Identical temp table index structure to OmeTrees)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Query hint | Same as OmeTrees - prevents suboptimal plan caching |
| Duplicate of OmeTrees | Note | Both procedures have identical code - this Test variant appears to be a development artifact |

---

## 8. Sample Queries

### 8.1 Execute (same as OmeTrees)

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2)

EXEC Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest
    @instrumentsTable = @instruments
```

### 8.2 Compare output with OmeTrees to verify equivalence

```sql
-- Both should return identical results for the same instrument set
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1)

-- Run both and compare row counts / values:
EXEC Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees @instrumentsTable = @instruments
EXEC Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest @instrumentsTable = @instruments
```

### 8.3 Check if actively used vs OmeTrees

```sql
-- Check Maintenance.Feature for context
SELECT FeatureID, Value FROM Maintenance.Feature WITH (NOLOCK) WHERE FeatureID = 22
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest.sql*
