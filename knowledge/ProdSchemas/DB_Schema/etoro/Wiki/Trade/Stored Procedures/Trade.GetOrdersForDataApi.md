# Trade.GetOrdersForDataApi

> Returns open orders for Apex-linked customers in a time window with optional filters for GCIDs, ApexIDs, order IDs, instrument types, and countries - the data API for Apex DMA order reporting with optional pagination.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartTime DATETIME + @EndTime DATETIME + TVP filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForDataApi` retrieves open orders from `Trade.GetAllOpenOrders` for Apex-linked customers (CustomerStatic.ApexID IS NOT NULL) within a 1-day time window. It supports multi-dimensional filtering via TVP parameters (GCIDs, ApexIDs, specific order IDs, instrument types, countries) and optional OFFSET/FETCH pagination.

**WHY:** This SP serves the Data API layer used for Apex/US DMA order reporting and analytics. It exposes open order data enriched with Apex account identifiers (GCID, ApexID), instrument metadata (CUSIP, InstrumentTypeID), and customer country data - all required for regulatory and operational reporting in the US DMA context.

**HOW:** Single SELECT from `Trade.GetAllOpenOrders` (view) joined with Customer.CustomerStatic (Apex-only filter: ApexID IS NOT NULL) and Trade.InstrumentMetaData. Dynamic filter flags (bit variables) control which TVP filters are active. Optional pagination via OFFSET/FETCH when @RowsToSkip and @RowsToTake are both provided.

Created: 06/06/2021 by Adam Porat.

---

## 2. Business Logic

### 2.1 Apex-Only Filter - US DMA Customers

**What:** The JOIN to Customer.CustomerStatic with `ApexID IS NOT NULL` restricts results to Apex-linked (US DMA) customers. Non-Apex customers are excluded.

**Columns/Parameters Involved:** `Customer.CustomerStatic.ApexID`

**Rules:**
- `INNER JOIN Customer.CustomerStatic ... ON o.CID = CustomerStatic.CID AND CustomerStatic.ApexID IS NOT NULL` -> only Apex customers returned
- Non-Apex customers (ApexID = NULL) are silently excluded
- GCID and ApexID output columns require this join

### 2.2 Date Range Validation - 1 Day Maximum

**What:** The SP enforces a maximum 1-day date range to prevent runaway queries on the open orders view.

**Columns/Parameters Involved:** `@StartTime`, `@EndTime`

**Rules:**
- `IF ABS(DATEDIFF(DAY, @StartTime, @EndTime)) > 1 -> RAISERROR('Data range must be up to one day', 16, 5); RETURN`
- Raises error and exits immediately if range exceeds 1 day
- Filters: `WHERE Occurred >= @StartTime AND Occurred < @EndTime` (half-open interval)

### 2.3 Dynamic TVP Filters

**What:** Each TVP parameter has a corresponding bit flag. If the TVP is non-empty, the flag is set to 1 and the filter is applied. Empty TVPs mean "no filter" (all values pass).

**Columns/Parameters Involved:** `@GCIDs`, `@ApexIDs`, `@Orders`, `@InstrumentTypes`, `@CountryIDs`

**Rules:**
- `@FilterByGCIDs=1` IF EXISTS records in @GCIDs -> filter by GCID
- `@FilterByApexIds=1` IF EXISTS records in @ApexIDs -> filter by ApexID
- `@FilterByOrderIDs=1` IF EXISTS records in @Orders -> filter by OrderID
- `@FilterByInstrumentTypes=1` IF EXISTS records in @InstrumentTypes -> filter by InstrumentTypeID (from InstrumentMetaData)
- `@FilterByCountryIds=1` IF EXISTS records in @CountryIDs -> filter by CustomerStatic.CountryID
- All filters are independently optional; empty TVP = no filter for that dimension

### 2.4 Optional Pagination

**What:** When both @RowsToSkip and @RowsToTake are provided with valid values (>= 0 and > 0), OFFSET/FETCH pagination is applied. Otherwise full result set is returned.

**Columns/Parameters Involved:** `@RowsToSkip`, `@RowsToTake`

**Rules:**
- Both must be non-NULL AND @RowsToSkip >= 0 AND @RowsToTake > 0 -> paginated branch executes
- Otherwise -> full ORDER BY Occurred result
- Results always ordered by Occurred ASC

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartTime | DATETIME | NO | - | CODE-BACKED | Start of the time window (inclusive). Maximum 1-day span from @EndTime. |
| 2 | @EndTime | DATETIME | NO | - | CODE-BACKED | End of the time window (exclusive). Maximum 1-day span from @StartTime. |
| 3 | @GCIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | TVP of Global Customer IDs to filter by. Empty = no filter. Trade.IdIntList has single INT column 'Id'. |
| 4 | @ApexIDs | Trade.ApexIDsList READONLY | NO | - | CODE-BACKED | TVP of Apex account IDs to filter by. Empty = no filter. Trade.ApexIDsList has single column 'ApexID'. |
| 5 | @Orders | Trade.OrderIDsTbl READONLY | NO | - | CODE-BACKED | TVP of specific order IDs to filter by. Empty = no filter. Trade.OrderIDsTbl has single INT column 'OrderID'. |
| 6 | @InstrumentTypes | Trade.IdIntList READONLY | NO | - | CODE-BACKED | TVP of instrument type IDs to filter by (from Trade.InstrumentMetaData.InstrumentTypeID). Empty = no filter. |
| 7 | @CountryIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | TVP of country IDs to filter by (Customer.CustomerStatic.CountryID). Empty = no filter. |
| 8 | @RowsToSkip | INT | YES | NULL | CODE-BACKED | Pagination: number of rows to skip (OFFSET). NULL = no pagination. Must be >= 0. |
| 9 | @RowsToTake | INT | YES | NULL | CODE-BACKED | Pagination: number of rows to return (FETCH NEXT). NULL = no pagination. Must be > 0. |

**Output columns (from Trade.GetAllOpenOrders JOIN Customer.CustomerStatic JOIN Trade.InstrumentMetaData):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID. From Trade.GetAllOpenOrders. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. From Customer.CustomerStatic (Apex-linked customers only). |
| 3 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID used in Apex reporting. From Customer.CustomerStatic. |
| 4 | ApexID | VARCHAR | YES | - | CODE-BACKED | Apex account identifier. From Customer.CustomerStatic. NOT NULL for all returned rows (Apex-only filter). |
| 5 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type: 17=open by amount, 18=open by units, 19=close by units. From Trade.GetAllOpenOrders. |
| 6 | ExitOrderPositionID | BIGINT | YES | - | CODE-BACKED | For exit orders (type 19): the position being closed. NULL for open orders. |
| 7 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. From Trade.GetAllOpenOrders. |
| 8 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier. |
| 9 | Amount | DECIMAL | YES | - | CODE-BACKED | Order amount. Unit depends on GetAllOpenOrders view definition. |
| 10 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 11 | StopLosRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate. |
| 12 | TakeProfitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate. |
| 13 | StopLosPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss as percentage. |
| 14 | TakeProfitPercentage | DECIMAL | YES | - | CODE-BACKED | Take-profit as percentage. |
| 15 | Occurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp. Filter column and ORDER BY key. |
| 16 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. |
| 17 | AmountInUnits | DECIMAL | YES | - | CODE-BACKED | Order size in instrument units. |
| 18 | IsDiscounted | INT | YES | - | CODE-BACKED | 1 if fee discount applies (Free Stocks). |
| 19 | RateFrom | DECIMAL | YES | - | CODE-BACKED | Lower price bound for order execution. |
| 20 | RateTo | DECIMAL | YES | - | CODE-BACKED | Upper price bound for order execution. |
| 21 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP security identifier. From Trade.InstrumentMetaData. Key for US securities regulatory reporting. |
| 22 | InstrumentTypeID | INT | YES | - | CODE-BACKED | Instrument type classification. From Trade.InstrumentMetaData. Used for filter and output. |
| 23 | CountryID | INT | YES | - | CODE-BACKED | Customer's country. From Customer.CustomerStatic. Used for filter and output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.GetAllOpenOrders | Trade.GetAllOpenOrders | Lookup | Source view for all open orders |
| INNER JOIN Customer.CustomerStatic | Customer.CustomerStatic | Enrichment + filter | Provides GCID, ApexID, CountryID; filters to Apex-only customers |
| INNER JOIN Trade.InstrumentMetaData | Trade.InstrumentMetaData | Enrichment + filter | Provides Cusip, InstrumentTypeID; filters by instrument type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForDataApi (procedure)
|- Trade.GetAllOpenOrders (view) - all open orders
|- Customer.CustomerStatic (table) - Apex account IDs and customer metadata
|- Trade.InstrumentMetaData (table) - CUSIP, InstrumentTypeID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetAllOpenOrders | View | Source of open order data for time window |
| Customer.CustomerStatic | Table | Apex-only filter (ApexID IS NOT NULL), GCID, CountryID enrichment |
| Trade.InstrumentMetaData | Table | CUSIP and InstrumentTypeID enrichment and filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by Data API for Apex/US DMA order reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ABS(DATEDIFF(DAY,...)) > 1 | Date validation | Enforces max 1-day range; RAISERROR if exceeded |
| ApexID IS NOT NULL | Apex filter | Silently excludes non-Apex (non-DMA) customers |
| OFFSET/FETCH | Pagination | Only active when both @RowsToSkip and @RowsToTake are valid |
| SET NOCOUNT ON | Session setting | Suppresses row count messages |
| Dynamic filter flags | Performance | Bit flags avoid repeated TVP existence checks in WHERE |

---

## 8. Sample Queries

### 8.1 Get all Apex open orders for a date range

```sql
DECLARE @GCIDs Trade.IdIntList, @ApexIDs Trade.ApexIDsList,
        @Orders Trade.OrderIDsTbl, @InstrumentTypes Trade.IdIntList,
        @CountryIDs Trade.IdIntList

EXEC Trade.GetOrdersForDataApi
    @StartTime = '2021-06-06 00:00:00',
    @EndTime   = '2021-06-07 00:00:00',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @Orders = @Orders,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs
```

### 8.2 Filtered by specific GCIDs with pagination

```sql
DECLARE @GCIDs Trade.IdIntList
INSERT INTO @GCIDs VALUES (5055022),(5056543)
DECLARE @ApexIDs Trade.ApexIDsList, @Orders Trade.OrderIDsTbl,
        @InstrumentTypes Trade.IdIntList, @CountryIDs Trade.IdIntList

EXEC Trade.GetOrdersForDataApi
    @StartTime = '2021-06-06',
    @EndTime = '2021-06-07',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @Orders = @Orders,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs,
    @RowsToSkip = 0,
    @RowsToTake = 100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 6.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForDataApi.sql*
