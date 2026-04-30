# Trade.GetOrphanedPositionsDataTest

> Test variant of the orphaned copy-trade position detection query - uses PositionTbl directly with a two-stage temp table approach and early-exit optimization.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @minutesSinceParentClose - controls the recency window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrphanedPositionsDataTest` is a test/development variant of `Trade.GetOrphanedPositionsData`. It produces the same orphaned copy-trade position detection output with two architectural differences: (1) queries Trade.PositionTbl directly instead of via the Trade.Position view, and (2) uses a two-stage approach with a temp table `#Position` and a clustered CID index for better join performance.

**WHY:** This variant exists to test an alternative query structure that avoids the Trade.Position view overhead. By querying PositionTbl directly with StatusID=1 and using a temp table, it may perform differently under load. The early-exit (`IF @@ROWCOUNT = 0 RETURN`) prevents unnecessary joins when no orphans exist.

**HOW:** Stage 1 builds `#Position` from PositionTbl (StatusID=1, ParentPositionID>0) joined to History.PositionSlim for parent close data, filtered to the time window. If empty, returns immediately. Stage 2 joins #Position to GetProviderToInstrument, BackOffice.Customer, CustomerStatic, and applies the three anti-join exclusions (OrdersExit, CloseExecutionPlan, DelayedOrderForClose).

**Note:** There is a potential bug in this version: `ParentCS.CountryID AS ParentCountryID` joins `ParentCS ON ParentCS.CID = S.CID` (using the CHILD's CID) rather than the parent's CID. In the production version (GetOrphanedPositionsData), this is `ParentCS.CID = H.CID` (the parent's CID). The test version may return the child's country as "ParentCountryID".

---

## 2. Business Logic

### 2.1 Orphan Detection Pattern (Same as Production)

**What:** Identical logic to GetOrphanedPositionsData.

**Rules:** See `Trade.GetOrphanedPositionsData` Section 2.1. All three anti-join conditions (OrdersExit, CloseExecutionPlan, DelayedOrderForClose) are present.

### 2.2 Early-Exit Optimization

**What:** If the first stage returns no rows, the SP exits immediately without performing the expensive joins.

**Rules:**
- After Stage 1 INSERT: `IF @@ROWCOUNT = 0 RETURN`
- This avoids joining GetProviderToInstrument, BackOffice.Customer, CustomerStatic when no orphans exist

### 2.3 PositionTbl Direct Query vs Trade.Position View

**What:** This version queries Trade.PositionTbl with explicit StatusID=1, bypassing the Trade.Position view.

**Rules:**
- `FROM Trade.PositionTbl S WITH (NOLOCK) ... WHERE S.StatusID = 1` - only open positions
- Production version uses `FROM Trade.Position S` which includes the StatusID filter implicitly

### 2.4 Two-Stage Query Structure

**What:** Intermediate `#Position` temp table with CID clustered index separates data collection from enrichment.

**Rules:**
- Stage 1: Collect PositionID, ParentPositionID, CloseTime, IsBuy, EndForexRate, FullCommissionOnClose, AmountInUnitsDecimal, LastOpConversionRate, InstrumentID, CID, IsSettled into #Position
- `CREATE CLUSTERED INDEX IX_Temp_Positions ON #Position (CID)` - for efficient CID-based joins in Stage 2
- Stage 2: Join #Position to enrichment tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @minutesSinceParentClose | INT | NO | - | CODE-BACKED | Minimum age (in minutes) of parent close before child is considered orphaned. Same semantics as GetOrphanedPositionsData. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Orphaned child position ID from Trade.PositionTbl (StatusID=1). |
| 3 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Leader's closed position ID (PositionTbl.ParentPositionID > 0). |
| 4 | ParentCloseTime | DATETIME | YES | - | CODE-BACKED | When the parent position closed (History.PositionSlim.CloseOccurred). |
| 5 | IsBuy | BIT | NO | - | CODE-BACKED | Direction of parent position: 1=Long, 0=Short. From History.PositionSlim.IsBuy. |
| 6 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Rate at which the parent closed. From History.PositionSlim.EndForexRate. |
| 7 | FullCommissionOnClose | DECIMAL | YES | - | CODE-BACKED | Commission from parent position close. From History.PositionSlim.FullCommissionOnClose. |
| 8 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Units of the parent position at close. From History.PositionSlim.AmountInUnitsDecimal. |
| 9 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Last conversion rate from parent. From History.PositionSlim.LastOpConversionRate. |
| 10 | Precision | INT | YES | - | CODE-BACKED | Instrument decimal precision from Trade.GetProviderToInstrument. |
| 11 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Instrument type from Trade.GetProviderToInstrument. |
| 12 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID from #Position (originally from PositionTbl.InstrumentID). |
| 13 | RegulationID | INT | YES | - | CODE-BACKED | ISNULL(DesignatedRegulationID, RegulationID) from BackOffice.Customer. |
| 14 | CountryID | INT | YES | - | CODE-BACKED | Child customer's country from Customer.CustomerStatic. |
| 15 | CID | INT | NO | - | CODE-BACKED | Child (copier) customer ID. |
| 16 | ParentIsSettled | BIT | YES | - | CODE-BACKED | IsSettled of the PARENT position from History.PositionSlim (stored as S.IsSettled in #Position). |
| 17 | ParentCountryID | INT | YES | - | CODE-BACKED | Country of ParentCS joined on S.CID (NOTE: potential bug - joins on child CID, not parent CID. May return child's country instead of parent's.) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Lookup | Live open positions (StatusID=1, ParentPositionID>0) |
| ParentPositionID | History.PositionSlim | Lookup | Closed parent position data |
| InstrumentID | Trade.GetProviderToInstrument | Lookup | Precision, InstrumentTypeID |
| CID | BackOffice.Customer | Lookup | RegulationID, DesignatedRegulationID |
| CID | Customer.CustomerStatic | Lookup | CountryID for child and parent (note: potential bug in parent join) |
| PositionID | Trade.OrdersExit | Anti-join | Exclude positions with existing exit orders |
| PositionID | Trade.CloseExecutionPlan | Anti-join | Exclude positions with close plans |
| PositionID | Trade.DelayedOrderForClose | Anti-join | Exclude positions with delayed closes |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Test version - not called by production systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrphanedPositionsDataTest (procedure)
|- Trade.PositionTbl (table) - direct (vs Trade.Position view in production)
|- History.PositionSlim (table) - closed parent positions
|- Trade.GetProviderToInstrument (view) - instrument metadata
|- BackOffice.Customer (table) - regulation IDs
|- Customer.CustomerStatic (table) - CountryID
|- Trade.OrdersExit (table) - anti-join
|- Trade.CloseExecutionPlan (table) - anti-join
|- Trade.DelayedOrderForClose (table) - anti-join
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Live open positions (StatusID=1, ParentPositionID>0) |
| History.PositionSlim | Table | Parent close data |
| Trade.GetProviderToInstrument | View | Precision, InstrumentTypeID |
| BackOffice.Customer | Table | RegulationID |
| Customer.CustomerStatic | Table | CountryID |
| Trade.OrdersExit | Table | Anti-join exclusion |
| Trade.CloseExecutionPlan | Table | Anti-join exclusion |
| Trade.DelayedOrderForClose | Table | Anti-join exclusion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Test version |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_Temp_Positions on #Position | CLUSTERED | CID | - | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 1 | Filter | Only open positions (explicit, vs implicit in Trade.Position view) |
| ParentPositionID > 0 | Filter | Only copy-trade child positions |
| @@ROWCOUNT = 0 early exit | Performance | Skips Stage 2 when no orphans exist |
| Triple anti-join | Filter | Excludes positions already in close pipeline |
| OPTION (RECOMPILE) | Performance | Applied to Stage 1 only |

---

## 8. Sample Queries

### 8.1 Find orphans with 30-minute minimum age

```sql
EXEC Trade.GetOrphanedPositionsDataTest @minutesSinceParentClose = 30
```

### 8.2 Compare results between test and production versions

```sql
-- Production version
EXEC Trade.GetOrphanedPositionsData @minutesSinceParentClose = 60
-- Test version
EXEC Trade.GetOrphanedPositionsDataTest @minutesSinceParentClose = 60
```

### 8.3 Standard operational call

```sql
EXEC Trade.GetOrphanedPositionsDataTest @minutesSinceParentClose = 120
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrphanedPositionsDataTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrphanedPositionsDataTest.sql*
