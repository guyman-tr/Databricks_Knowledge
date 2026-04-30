# Trade.GetAggregatedPositionsForDataApi

> Returns aggregated position data (total units, position count, date ranges) per customer-instrument-direction at a given point in time, combining open and historically-closed positions for the Data API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated position metrics grouped by CID, InstrumentID, IsBuy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a point-in-time snapshot of aggregated positions for the Data API (regulatory and reporting layer). For any given datetime, it combines currently-open positions (from Trade.Position) with positions that were open at that time but have since closed (from History.PositionSlim), then aggregates them by customer, instrument, and direction (buy/sell). This gives a complete picture of what each customer held at any historical moment.

The procedure exists to serve the external Data API, which likely supports regulatory reporting (SEC, FINRA) and compliance requirements for the Apex Clearing integration. It is explicitly noted as the aggregated companion to Trade.GetPositionsBreakdownForDataApi (which returns the same data non-aggregated).

Data flows from Trade.Position (current open), History.PositionSlim (historical closed), Customer.CustomerStatic (customer identifiers including GCID and ApexID), and Trade.InstrumentMetaData (instrument metadata including CUSIP). Multiple optional TVP filters (GCID, ApexID, InstrumentType, CountryID) narrow the results, with OFFSET/FETCH pagination support.

---

## 2. Business Logic

### 2.1 Point-in-Time Position Reconstruction

**What**: Combines currently-open and historically-closed positions to reconstruct what was held at a specific datetime.

**Columns/Parameters Involved**: `@PointOfTime`, `InitDateTime`, `CloseOccurred`

**Rules**:
- Open positions: InitDateTime <= @PointOfTime (were opened before the point in time and are still open)
- Historical positions: @PointOfTime BETWEEN InitDateTime AND CloseOccurred (were open during the point in time but have since closed)
- UNION ALL combines both sets before aggregation

### 2.2 Multi-Filter TVP Pattern

**What**: Four optional TVP filters controlled by bit flags for efficient conditional filtering.

**Columns/Parameters Involved**: `@GCIDs`, `@ApexIDs`, `@InstrumentTypes`, `@CountryIDs`

**Rules**:
- Each TVP is checked for emptiness; a bit flag (e.g., @FilterByGCIDs) is set accordingly
- Filter logic: `(@FilterByGCIDs=0 OR c.GCID IN (SELECT Id FROM @GCIDs))` - bypasses filter when TVP is empty
- All four filters can be combined

### 2.3 Aggregation Grouping

**What**: Positions are aggregated by customer + instrument + direction.

**Columns/Parameters Involved**: `CID`, `GCID`, `ApexID`, `InstrumentID`, `Cusip`, `InstrumentTypeID`, `CountryID`, `IsBuy`

**Rules**:
- SUM(AmountInUnitsDecimal) AS TotalUnits
- COUNT(1) AS Positions
- MIN/MAX(InitDateTime) for date ranges
- AVG(InitForexRate), AVG(EndForexRate) for average price rates

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PointOfTime | DATETIME | NO | - | CODE-BACKED | The historical datetime to snapshot positions at. Returns all positions that were open at this exact moment. |
| 2 | @GCIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Optional filter: list of Global Customer IDs. If empty, no GCID filtering applied. |
| 3 | @ApexIDs | Trade.ApexIDsList (TVP) | NO | - | CODE-BACKED | Optional filter: list of Apex Clearing account IDs. If empty, no ApexID filtering applied. |
| 4 | @InstrumentTypes | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Optional filter: list of instrument type IDs (e.g., 1=Stock, 2=ETF, 5=Crypto, 6=CFD). If empty, no type filtering. |
| 5 | @CountryIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Optional filter: list of country IDs. If empty, no country filtering. |
| 6 | @RowsToSkip | INT | YES | NULL | CODE-BACKED | OFFSET pagination: number of rows to skip. Both @RowsToSkip and @RowsToTake must be provided for pagination. |
| 7 | @RowsToTake | INT | YES | NULL | CODE-BACKED | FETCH pagination: number of rows to return. Both must be provided for pagination. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | ApexID | VARCHAR | YES | - | CODE-BACKED | Customer's Apex Clearing account ID for regulatory reporting. |
| 9 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being held. |
| 10 | TotalUnits | DECIMAL | NO | - | CODE-BACKED | Sum of AmountInUnitsDecimal across all positions in this group. |
| 11 | Positions | INT | NO | - | CODE-BACKED | Count of individual positions in this aggregated group. |
| 12 | FirstOpenDate | DATE | YES | - | CODE-BACKED | Earliest InitDateTime in the group - when the first position in this instrument was opened. |
| 13 | LastOpenDate | DATE | YES | - | CODE-BACKED | Most recent InitDateTime in the group. |
| 14 | LastCloseDate | DATE | YES | - | CODE-BACKED | Most recent CloseOccurred (NULL for groups with only currently-open positions). |
| 15 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID for cross-system identification. |
| 16 | CID | INT | NO | - | CODE-BACKED | Internal customer ID. |
| 17 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier for the instrument (US securities). |
| 18 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Type of instrument (stock, ETF, crypto, etc.). |
| 19 | CountryID | INT | YES | - | CODE-BACKED | Customer's country of residence. |
| 20 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 21 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Average forex conversion rate at position open across the group. |
| 22 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Average forex conversion rate at position close across the group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | Direct Read (View) | Current open positions |
| FROM | History.PositionSlim | Cross-Schema Read | Historical closed positions |
| INNER JOIN | Trade.InstrumentMetaData | Lookup | Instrument CUSIP and type resolution |
| INNER JOIN | Customer.CustomerStatic | Cross-Schema Read | Customer GCID, ApexID, CountryID |
| TVP types | Trade.IdIntList, Trade.ApexIDsList | UDT | Input parameter types |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsBreakdownForDataApi | Related | Companion procedure | Non-aggregated version of same data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAggregatedPositionsForDataApi (procedure)
├── Trade.Position (view)
├── History.PositionSlim (table)
├── Trade.InstrumentMetaData (table)
├── Customer.CustomerStatic (table)
├── Trade.IdIntList (type)
└── Trade.ApexIDsList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - current open positions |
| History.PositionSlim | Table | SELECT - historical closed positions |
| Trade.InstrumentMetaData | Table | INNER JOIN - CUSIP and instrument type |
| Customer.CustomerStatic | Table | INNER JOIN - customer identifiers |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get aggregated positions at a point in time (no filters)

```sql
EXEC Trade.GetAggregatedPositionsForDataApi
    @PointOfTime = '2026-01-15 12:00:00',
    @RowsToSkip = 0,
    @RowsToTake = 100;
```

### 8.2 Filter by specific GCIDs

```sql
DECLARE @GCIDs Trade.IdIntList;
INSERT INTO @GCIDs VALUES (5063140), (5063157);
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @InstrumentTypes Trade.IdIntList;
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetAggregatedPositionsForDataApi
    @PointOfTime = '2026-01-15',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs,
    @RowsToSkip = 0,
    @RowsToTake = 50;
```

### 8.3 Filter by instrument types (stocks and ETFs only)

```sql
DECLARE @GCIDs Trade.IdIntList;
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @InstrumentTypes Trade.IdIntList;
INSERT INTO @InstrumentTypes VALUES (1), (2);
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetAggregatedPositionsForDataApi
    @PointOfTime = '2026-03-01',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs,
    @RowsToSkip = 0,
    @RowsToTake = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAggregatedPositionsForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAggregatedPositionsForDataApi.sql*
