# Trade.GetPositionsBreakdownForDataApi

> Returns a point-in-time position snapshot for the Data API - both open and historically-open positions at @PointOfTime for a given instrument, with optional GCID/ApexID/Country filtering and pagination.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PointOfTime + @InstrumentID - temporal and instrument scope |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionsBreakdownForDataApi` returns a per-position (non-aggregated) snapshot of all positions that were open at @PointOfTime for a specific @InstrumentID. Sources both currently-open positions (Trade.Position WHERE InitDateTime <= @PointOfTime) and historically-open positions (History.PositionSlim WHERE @PointOfTime BETWEEN InitDateTime AND CloseOccurred). Optionally filtered by GCID list, ApexID list, or CountryID list. Optionally paginated via @RowsToSkip/@RowsToTake.

**WHY:** The eToro Data API provides institutional and regulatory consumers with granular position-level data. By supporting point-in-time queries, consumers can reconstruct what positions existed at any historical moment for a given instrument. This is required for regulatory reporting (who held what position at a given time), compliance reconciliation, and analytics.

**HOW:** Pre-materializes #customer_static (ApexID IS NOT NULL customers only) for efficient filter joins. Two code paths: paginated (OFFSET/FETCH) and non-paginated. Both paths UNION ALL Trade.Position (open) and History.PositionSlim (historical) with the same WHERE conditions. Trade.InstrumentMetaData joined for Cusip and InstrumentTypeID.

**Note:** Comment in SQL: "THIS PROCEDURE MUST REMAIN COMPATIBLE TO Trade.GetAggregatedPositionsForDataApi - BOTH RETURN THE SAME DATA, BUT ONE IS AGGREGATED AND ONE IS NOT." Changes to columns must be synchronized.

---

## 2. Business Logic

### 2.1 Point-in-Time Position Detection

**What:** "Was this position open at @PointOfTime?" is checked differently for live vs. historical positions.

**Columns/Parameters Involved:** `@PointOfTime`, `InitDateTime`, `CloseOccurred`

**Rules:**
- Live (Trade.Position): `WHERE p.InitDateTime <= @PointOfTime` (opened before or at the point)
- Historical (History.PositionSlim): `WHERE @PointOfTime BETWEEN h.InitDateTime AND h.CloseOccurred` (was open during the point)
- Live positions are returned with `CloseOccurred=NULL` and `EndForexRate=NULL`

### 2.2 Optional Filters (GCID, ApexID, CountryID)

**What:** Three independent optional filters let API consumers scope the result to specific customer segments.

**Columns/Parameters Involved:** `@GCIDs`, `@ApexIDs`, `@CountryIDs`, `@FilterBy*` flags

**Rules:**
- `@FilterByGCIDs = EXISTS (SELECT 1 FROM @GCIDs)`
- Applied as: `AND (@FilterByGCIDs=0 OR c.GCID IN (SELECT Id FROM @GCIDs))`
- Same pattern for ApexIDs (SELECT ApexID FROM @ApexIDs) and CountryIDs (SELECT Id FROM @CountryIDs)
- Only customers with ApexID IS NOT NULL are included (filtered in #customer_static)

### 2.3 Pagination via OFFSET/FETCH

**What:** When @RowsToSkip and @RowsToTake are provided and valid, OFFSET/FETCH paging is applied.

**Rules:**
- Applied only when: `@RowsToSkip IS NOT NULL AND @RowsToTake IS NOT NULL AND @RowsToSkip >= 0 AND @RowsToTake > 0`
- `ORDER BY OpenOccurred OFFSET @RowsToSkip ROWS FETCH NEXT @RowsToTake ROWS ONLY`
- Without paging: all matching rows returned (no ORDER BY - arbitrary order)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PointOfTime | DATETIME | NO | - | CODE-BACKED | The historical timestamp to evaluate. Returns positions open at this exact moment. |
| 2 | @GCIDs | Trade.IdIntList | YES | empty | CODE-BACKED | Optional GCID filter. Empty = no filter. GCID = Global Customer ID. |
| 3 | @ApexIDs | Trade.ApexIDsList | YES | empty | CODE-BACKED | Optional Apex account ID filter. Empty = no filter. |
| 4 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to filter. Required (no default). |
| 5 | @CountryIDs | Trade.IdIntList | YES | empty | CODE-BACKED | Optional country filter (Customer.CustomerStatic.CountryID). |
| 6 | @RowsToSkip | INT | YES | NULL | CODE-BACKED | Pagination offset. NULL = no paging. |
| 7 | @RowsToTake | INT | YES | NULL | CODE-BACKED | Pagination page size. NULL = no paging. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Position identifier. |
| 9 | GCID | BIGINT | YES | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic. |
| 10 | ApexID | VARCHAR | YES | - | CODE-BACKED | Apex brokerage account ID from Customer.CustomerStatic. |
| 11 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 12 | InstrumentID | INT | NO | - | CODE-BACKED | Echo of @InstrumentID filter. |
| 13 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop loss rate on the position. |
| 14 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take profit rate. |
| 15 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. NULL for manual. |
| 16 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | Leader's position ID for copy positions. |
| 17 | IsSettled | BIT | YES | - | CODE-BACKED | Real stock (1) or CFD (0). |
| 18 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type FK. |
| 19 | IsBuy | BIT | NO | - | CODE-BACKED | 1=Long, 0=Short. |
| 20 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier. |
| 21 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in units. |
| 22 | Amount | MONEY | YES | - | CODE-BACKED | Position amount in account currency. |
| 23 | IsDiscounted | BIT | YES | - | CODE-BACKED | Commission discount flag. |
| 24 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Open forex rate. |
| 25 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp. |
| 26 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Trade.Position.Occurred alias (live); History.PositionSlim.OpenOccurred (historical). |
| 27 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP code from Trade.InstrumentMetaData. For stock instruments. |
| 28 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Instrument type from Trade.InstrumentMetaData. |
| 29 | CountryID | INT | YES | - | CODE-BACKED | Customer's country from #customer_static. |
| 30 | CloseOccurred | DATETIME | YES | NULL | CODE-BACKED | NULL for live positions; CloseOccurred from History.PositionSlim for historical. |
| 31 | EndForexRate | DECIMAL | YES | NULL | CODE-BACKED | NULL for live positions; EndForexRate from History.PositionSlim for historical. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID + @PointOfTime | Trade.Position | Lookup | Currently-open positions at point in time |
| @InstrumentID + @PointOfTime | History.PositionSlim | Lookup | Historically-open positions at point in time |
| InstrumentID | Trade.InstrumentMetaData | Lookup | Cusip, InstrumentTypeID |
| CID | Customer.CustomerStatic (#customer_static) | Lookup | GCID, ApexID, CountryID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by eToro Data API for institutional/regulatory consumers. Must stay compatible with Trade.GetAggregatedPositionsForDataApi.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsBreakdownForDataApi (procedure)
|- Trade.Position (view) - currently open positions
|- History.PositionSlim (table) - historical position data
|- Trade.InstrumentMetaData (table) - CUSIP, InstrumentTypeID
|- Customer.CustomerStatic (table) - GCID, ApexID, CountryID
|- Trade.IdIntList (UDT) - GCID and CountryID filter TVP
|- Trade.ApexIDsList (UDT) - ApexID filter TVP
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by eToro Data API |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ApexID IS NOT NULL in #customer_static | Scope | Only customers with Apex brokerage accounts |
| @InstrumentID required | Input | No default - must be provided |
| @PointOfTime BETWEEN check | Temporal | Historical positions: open AND not yet closed at point in time |
| Pagination conditional | Optional | OFFSET/FETCH only when both skip and take are non-null and valid |
| ORDER BY OpenOccurred (paginated only) | Ordering | Stable pagination order by open time |
| NOLOCK on all tables | Performance | Dirty read for historical/analytics queries |
| DROP TABLE IF EXISTS #customer_static | Safety | Safe re-execution in same session |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 All positions for an instrument at a point in time

```sql
DECLARE @gcids Trade.IdIntList
DECLARE @apexids Trade.ApexIDsList
DECLARE @countries Trade.IdIntList

EXEC Trade.GetPositionsBreakdownForDataApi
    @PointOfTime = '2024-06-01 12:00:00',
    @GCIDs = @gcids,
    @ApexIDs = @apexids,
    @InstrumentID = 1001,
    @CountryIDs = @countries
```

### 8.2 Paginated - first 100 rows

```sql
DECLARE @gcids Trade.IdIntList
DECLARE @apexids Trade.ApexIDsList
DECLARE @countries Trade.IdIntList

EXEC Trade.GetPositionsBreakdownForDataApi
    @PointOfTime = '2024-06-01',
    @GCIDs = @gcids,
    @ApexIDs = @apexids,
    @InstrumentID = 1001,
    @CountryIDs = @countries,
    @RowsToSkip = 0,
    @RowsToTake = 100
```

### 8.3 Filter by specific GCIDs

```sql
DECLARE @gcids Trade.IdIntList
INSERT @gcids VALUES (5063140),(5063157)
DECLARE @apexids Trade.ApexIDsList
DECLARE @countries Trade.IdIntList

EXEC Trade.GetPositionsBreakdownForDataApi
    @PointOfTime = '2024-01-01',
    @GCIDs = @gcids,
    @ApexIDs = @apexids,
    @InstrumentID = 1001,
    @CountryIDs = @countries
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsBreakdownForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsBreakdownForDataApi.sql*
