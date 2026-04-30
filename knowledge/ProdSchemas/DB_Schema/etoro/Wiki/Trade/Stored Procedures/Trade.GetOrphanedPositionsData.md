# Trade.GetOrphanedPositionsData

> Detects copy-trade child positions that remain open after their parent position has been closed - the primary orphan detection query used for automated copy-close processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @minutesSinceParentClose - controls the recency window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrphanedPositionsData` identifies open copy-trade child positions whose parent (leader) position has been closed but which have not yet received a close order. These are "orphaned" positions - the copy relationship's parent has ended but the child is still live. The SP returns all data needed to calculate and execute the close of each orphaned position.

**WHY:** In eToro's CopyTrader feature, when a leader closes their position, all copier positions that copied that position should be closed too. If the automated close mechanism fails or is delayed, orphaned positions accumulate. This SP is called by the orphan detection service to find them and trigger the missing close.

**HOW:** The SP queries Trade.Position (live open positions) for those with ParentPositionID > 0 (copy positions), joins to History.PositionSlim to verify the parent is closed (in history), filters to a 3-day lookback window at least @minutesSinceParentClose minutes old, and uses three LEFT JOIN anti-join patterns to exclude positions that already have an exit mechanism in progress (OrdersExit, CloseExecutionPlan, or DelayedOrderForClose).

---

## 2. Business Logic

### 2.1 Orphan Detection Pattern

**What:** A position is "orphaned" when its parent is closed but it has no pending close mechanism.

**Columns/Parameters Involved:** `ParentPositionID`, `OE.PositionID`, `CEP.PositionID`, `DOFC.PositionID`

**Rules:**
```
ORPHANED = TRUE when ALL of:
  1. S.ParentPositionID > 0          -- is a copy-trade position
  2. H.PositionID = S.ParentPositionID -- parent exists in History (closed)
  3. H.CloseOccurred BETWEEN @fromDate AND @toDate -- parent closed in window
  4. OE.PositionID IS NULL           -- no exit order exists
  5. CEP.PositionID IS NULL          -- no close execution plan
  6. DOFC.PositionID IS NULL         -- no delayed close order
```

### 2.2 Time Window Construction

**What:** Two date boundaries define the "eligible orphan" window.

**Columns/Parameters Involved:** `@minutesSinceParentClose`, derived `@fromDate`, `@toDate`

**Rules:**
- `@fromDate = DATEADD(DAY, -3, GETUTCDATE())` - only look 3 days back (avoids ancient records)
- `@toDate = DATEADD(MINUTE, @minutesSinceParentClose * -1, GETUTCDATE())` - excludes very recently closed parents (processing lag allowance)
- A parent closed LESS than @minutesSinceParentClose minutes ago is NOT considered orphaned yet (system may still be processing)

### 2.3 Regulation and Jurisdiction Enrichment

**What:** Each orphaned position is enriched with regulatory and geographic data for compliance-aware close processing.

**Columns/Parameters Involved:** `RegulationID`, `CountryID`, `ParentCountryID`

**Rules:**
- `ISNULL(DesignatedRegulationID, RegulationID) AS RegulationID` - DesignatedRegulationID takes priority if set (manual override)
- `CS.CountryID` - child customer's country (from Customer.CustomerStatic)
- `ParentCS.CountryID` - parent (leader) customer's country
- Different regulations may apply depending on jurisdiction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @minutesSinceParentClose | INT | NO | - | CODE-BACKED | Minimum age (in minutes) of parent close before child is considered orphaned. Used to exclude positions whose parent closed very recently (still within normal processing lag). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Orphaned child position ID. Currently open in Trade.Position. |
| 3 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | The leader's position ID that was closed. From Trade.Position.ParentPositionID (>0 for copy trades). |
| 4 | ParentCloseTime | DATETIME | YES | - | CODE-BACKED | When the parent position was closed (History.PositionSlim.CloseOccurred). Used to prioritize oldest orphans. |
| 5 | IsBuy | BIT | NO | - | CODE-BACKED | Direction of the PARENT position: 1=Long, 0=Short. Inherited from History.PositionSlim.IsBuy. Used to calculate close direction. |
| 6 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | The rate at which the PARENT position closed (History.PositionSlim.EndForexRate). Reference rate for the orphan close calculation. |
| 7 | FullCommissionOnClose | DECIMAL | YES | - | CODE-BACKED | Commission charged at the parent's close. From History.PositionSlim.FullCommissionOnClose. Used as reference for orphan close fee calculation. |
| 8 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Units of the PARENT position at close. From History.PositionSlim.AmountInUnitsDecimal. |
| 9 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Last operation conversion rate from the parent position. From History.PositionSlim.LastOpConversionRate. Used in PnL calculation for the orphan close. |
| 10 | Precision | INT | YES | - | CODE-BACKED | Instrument decimal precision from Trade.GetProviderToInstrument. Used for price/amount rounding. |
| 11 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Instrument type from Trade.GetProviderToInstrument. Determines close logic (CFD vs stock, etc.). |
| 12 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID of the orphaned position. From Trade.GetProviderToInstrument. |
| 13 | RegulationID | INT | YES | - | CODE-BACKED | Effective regulation ID for compliance: ISNULL(DesignatedRegulationID, RegulationID) from BackOffice.Customer. |
| 14 | CountryID | INT | YES | - | CODE-BACKED | Child (copier) customer's country from Customer.CustomerStatic. |
| 15 | CID | INT | NO | - | CODE-BACKED | Child (copier) customer ID. |
| 16 | ParentIsSettled | BIT | YES | - | CODE-BACKED | IsSettled flag of the PARENT position (History.PositionSlim.IsSettled). 1=real stock, 0=CFD. Determines close processing path. |
| 17 | ParentCountryID | INT | YES | - | CODE-BACKED | Leader (parent) customer's country from Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | Lookup | Live open copy-trade child positions (view over PositionTbl) |
| ParentPositionID | History.PositionSlim | Lookup | Closed parent positions with close data |
| InstrumentID | Trade.GetProviderToInstrument | Lookup | Instrument metadata (Precision, InstrumentTypeID) |
| CID | BackOffice.Customer | Lookup | RegulationID and DesignatedRegulationID for compliance |
| CID | Customer.CustomerStatic | Lookup | CountryID for child customer |
| H.CID | Customer.CustomerStatic (ParentCS) | Lookup | CountryID for parent customer |
| PositionID | Trade.OrdersExit | Anti-join | Exclude positions with existing exit orders |
| PositionID | Trade.CloseExecutionPlan | Anti-join | Exclude positions with pending close plans |
| PositionID | Trade.DelayedOrderForClose | Anti-join | Exclude positions with delayed close orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by orphan detection background service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrphanedPositionsData (procedure)
|- Trade.Position (view) - live open copy positions
|- History.PositionSlim (table) - closed parent positions
|- Trade.GetProviderToInstrument (view) - instrument metadata
|- BackOffice.Customer (table) - regulation IDs
|- Customer.CustomerStatic (table) - CountryID for child and parent
|- Trade.OrdersExit (table) - anti-join: no existing exit order
|- Trade.CloseExecutionPlan (table) - anti-join: no pending close plan
|- Trade.DelayedOrderForClose (table) - anti-join: no delayed close
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Live open copy-trade child positions (ParentPositionID > 0) |
| History.PositionSlim | Table | Closed parent position data (CloseOccurred, EndForexRate, IsBuy, etc.) |
| Trade.GetProviderToInstrument | View | Precision, InstrumentTypeID, InstrumentID |
| BackOffice.Customer | Table | RegulationID, DesignatedRegulationID |
| Customer.CustomerStatic | Table | CountryID for child (CS) and parent (ParentCS) |
| Trade.OrdersExit | Table | Anti-join: positions with exit orders are excluded |
| Trade.CloseExecutionPlan | Table | Anti-join: positions with close plans are excluded |
| Trade.DelayedOrderForClose | Table | Anti-join: positions with delayed closes are excluded |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by orphan detection background service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ParentPositionID > 0 | Filter | Only copy-trade positions (manual opens have ParentPositionID=0) |
| H.CloseOccurred BETWEEN @fromDate AND @toDate | Time window | 3-day lookback; @minutesSinceParentClose minutes recency gap |
| Triple anti-join | Filter | Excludes positions already in close processing pipeline |
| OPTION (RECOMPILE) | Performance | Fresh plan due to variable @minutesSinceParentClose affecting date range cardinality |

---

## 8. Sample Queries

### 8.1 Find orphans closed at least 30 minutes ago

```sql
EXEC Trade.GetOrphanedPositionsData @minutesSinceParentClose = 30
```

### 8.2 Find orphans with a more conservative window (2 hours)

```sql
EXEC Trade.GetOrphanedPositionsData @minutesSinceParentClose = 120
```

### 8.3 Count orphaned positions by instrument type

```sql
-- Run the SP and aggregate
DECLARE @t TABLE (PositionID BIGINT, InstrumentTypeID INT, CID INT, ParentCloseTime DATETIME)
INSERT @t
EXEC Trade.GetOrphanedPositionsData @minutesSinceParentClose = 60

SELECT InstrumentTypeID, COUNT(*) AS OrphanCount
FROM @t WITH (NOLOCK)
GROUP BY InstrumentTypeID
ORDER BY OrphanCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrphanedPositionsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrphanedPositionsData.sql*
