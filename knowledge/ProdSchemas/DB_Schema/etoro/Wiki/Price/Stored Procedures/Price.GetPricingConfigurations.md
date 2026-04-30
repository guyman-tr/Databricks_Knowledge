# Price.GetPricingConfigurations

> Paginated read of the pricing engine configuration table (Price.PricingConfigurations), with cursor-based (@First/@After) pagination, optional PricingType/DistributionType filters, and a second result set returning HasNextPage and EndCursor for GraphQL-style pagination.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PricingType, @DistributionType (filters), @First/@After (cursor pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetPricingConfigurations is the primary read API for the pricing engine's per-instrument configuration. It returns each instrument's pricing algorithm type (Standard vs Raw Redistribution), distribution channel flags (bitmask), provider association, throttling parameters, and precision settings - all the configuration the pricing engine needs to know how to price and distribute each instrument.

The procedure is designed for cursor-based (GraphQL-style) pagination, making it suitable for large result set retrieval by APIs that page through results incrementally. The @First/@After model is standard for GraphQL connections: @First is the page size, @After is the cursor (the last InstrumentID seen on the previous page), and the response includes a second result set with HasNextPage and EndCursor to drive the next request.

Two optional filters narrow the result:
- `@PricingType`: select only Standard (0) or Raw Redistribution (1) instruments
- `@DistributionType`: bitwise channel filter - selects instruments whose DistributionType has at least one bit in common with the filter value (with special handling for the exact-zero case)

Result enrichment via JOINs:
- `Trade.ProviderToInstrument`: adds Precision and AboveDollarPrecision (decimal formatting for the instrument's price display)
- `Trade.InstrumentMetaData`: adds PriceSourceID (exposed as "PricesBy" - which price source is authoritative for this instrument)

---

## 2. Business Logic

### 2.1 Cursor-Based Pagination (@First / @After)

**What**: GraphQL-style cursor pagination over InstrumentID ordering.

**Columns/Parameters Involved**: `@First`, `@After`, `@AfterInstrumentID`, `@EndCursor`, `@HasNextPage`

**Rules**:
- `@After` is an NVARCHAR(50) cursor string. Parsed via `TRY_CAST(@After AS INT)` -> `@AfterInstrumentID`. Invalid/NULL @After gives NULL @AfterInstrumentID.
- `@AfterInstrumentID IS NULL OR PC.InstrumentID > @AfterInstrumentID`: when NULL (first page), no cursor filter; when set, only rows with InstrumentID strictly greater than the cursor.
- `TOP (ISNULL(@First, 10000))`: page size. If @First IS NULL, 10000 is used as an effective upper bound (not truly unlimited). Ordered by PC.InstrumentID ASC.
- `@EndCursor = MAX(InstrumentID) FROM #Rows`: the cursor for the next request - the largest InstrumentID on the current page.
- `@HasNextPage = 1` if and only if `@EndCursor IS NOT NULL` AND at least one more row exists beyond the current page with the same filters applied.
- Two result sets returned: (1) the data rows, (2) PageInfo with HasNextPage BIT and EndCursor VARCHAR(50).

**Usage example**:
```
Request 1: @First=100, @After=NULL  -> returns rows 1..100, EndCursor='7654'
Request 2: @First=100, @After='7654' -> returns rows 7655..7754, EndCursor='...', HasNextPage=1 or 0
```

### 2.2 DistributionType Bitwise Filter

**What**: @DistributionType uses bitwise AND logic to filter instruments by distribution channel membership.

**Columns/Parameters Involved**: `@DistributionType`, `PC.DistributionType`

**Rules**:
- `NULL`: no filter - all instruments returned regardless of DistributionType
- `@DistributionType = 0`: exact match for zero - only instruments with DistributionType = 0 (no active channels)
- `@DistributionType <> 0 AND (PC.DistributionType & @DistributionType) <> 0`: bitwise overlap - instruments that have at least one matching distribution channel bit
- Current DistributionType values in PricingConfigurations: 1 (10,333 rows - standard channel 1), 3 (2 rows - channels 1 AND 2, InstrumentIDs 1005 and 1010), 0 (0 rows currently)
- Example: @DistributionType=2 would return the 2 instruments with DistributionType=3 (bit 2 is set in 3)

### 2.3 PricingType Filter

**What**: Optional filter to return only instruments using a specific pricing algorithm.

**Columns/Parameters Involved**: `@PricingType`, `PC.PricingType`

**Rules**:
- `PC.PricingType = ISNULL(@PricingType, PC.PricingType)`: standard NULL bypass trick
- NULL: returns all pricing types (both Standard and Raw Redistribution)
- 0 (Standard): 10,326 rows - default pricing algorithm (spread + skew + throttling applied)
- 1 (Raw Redistribution): 9 rows - prices redistributed as-is from raw feed; AccountId="RawRedistribution", ProviderId=1

### 2.4 Temp Table Strategy (#Rows)

**What**: A temp table is used to allow computing pagination metadata without repeating the main query.

**Rules**:
- `DROP TABLE IF EXISTS #Rows` - clean slate before each execution
- `SELECT ... INTO #Rows` - executes the filtered, paginated, joined query once
- `SELECT * FROM #Rows` - returns the data result set
- `SELECT MAX(InstrumentID) FROM #Rows` - computes EndCursor from temp table (no re-execution)
- HasNextPage EXISTS check queries Price.PricingConfigurations2 directly (not #Rows) with the same WHERE filters, checking if any row with InstrumentID > @EndCursor exists

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PricingType | TINYINT | YES | NULL | CODE-BACKED | Filter by pricing algorithm. NULL=all; 0=Standard (10,326 instruments); 1=Raw Redistribution (9 instruments). Applied as exact match. |
| 2 | @DistributionType | TINYINT | YES | NULL | CODE-BACKED | Bitwise distribution channel filter. NULL=all; 0=exact zero (no channels); non-zero=bitwise overlap match. Used to select instruments distributed to specific channels. |
| 3 | @First | INT | YES | NULL | CODE-BACKED | Page size. Number of rows per page. NULL uses 10000 as effective limit (not truly unlimited). Pass 100-500 for typical API pagination. |
| 4 | @After | NVARCHAR(50) | YES | NULL | CODE-BACKED | Cursor string from previous page's EndCursor. Represents the last InstrumentID seen. NULL for first page. Parsed via TRY_CAST to INT; invalid values treated as NULL (first page). |

**Result set 1 - Pricing Configuration rows** (11 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | eToro instrument identifier. PK of Price.PricingConfigurations. Ordered ascending (cursor order). |
| 2 | DistributionType | Bitmask of active distribution channels: 1=channel 1 (standard), 3=channels 1+2, 0=no channels. |
| 3 | PricingType | Pricing algorithm: 0=Standard, 1=Raw Redistribution. |
| 4 | ProviderId | Pricing provider identifier. Populated for PricingType=1 (Raw Redistribution: ProviderId=1). NULL for most standard instruments. |
| 5 | AccountId | Provider account string. "RawRedistribution" for PricingType=1; NULL/empty for standard instruments. |
| 6 | TopOfBookThrottlingInMs | Minimum ms between top-of-book price publication updates. NULL = use global default. |
| 7 | FeedThrottlingInMs | Minimum ms between internal feed price updates. NULL = use global default. |
| 8 | ClientThrottlingInMs | Minimum ms between prices sent to clients. NULL = use global default. |
| 9 | Precision | Decimal places for price display (below $1 instruments). From Trade.ProviderToInstrument; ISNULL defaults to 4. |
| 10 | AboveDollarPrecision | Decimal places for price display (above $1 instruments). From Trade.ProviderToInstrument; ISNULL defaults to 2. |
| 11 | PricesBy | PriceSourceID from Trade.InstrumentMetaData - which price source is the authoritative feed for this instrument. Exposed as alias "PricesBy". |

**Result set 2 - PageInfo** (2 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | HasNextPage | BIT. 1 = more rows exist beyond EndCursor with the same filters. 0 = last page. |
| 2 | EndCursor | VARCHAR(50). The InstrumentID of the last row on this page, as a string. Pass as @After on the next request. NULL if 0 rows returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.PricingConfigurations | READER | Primary data source; all pricing engine configuration |
| InstrumentID | Trade.ProviderToInstrument | READER (JOIN) | Adds Precision and AboveDollarPrecision for decimal formatting |
| InstrumentID | Trade.InstrumentMetaData | READER (JOIN) | Adds PriceSourceID (PricesBy) - authoritative feed source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing configuration API) | @First, @After | CALLER | Called to page through all pricing configurations for admin/monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetPricingConfigurations (procedure)
+-- Price.PricingConfigurations (table) - all per-instrument pricing config
+-- Trade.ProviderToInstrument (table) - Precision, AboveDollarPrecision
+-- Trade.InstrumentMetaData (table) - PriceSourceID (PricesBy)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PricingConfigurations | Table | Primary FROM source; filtered by PricingType, DistributionType, cursor |
| Trade.ProviderToInstrument | Table | INNER JOIN to enrich with Precision and AboveDollarPrecision |
| Trade.InstrumentMetaData | Table | INNER JOIN to enrich with PriceSourceID (PricesBy) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing configuration API) | External | Calls with cursor pagination to enumerate all pricing configurations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. Uses temp table #Rows for two-pass: populate once, return data, then compute pagination metadata. HasNextPage EXISTS check re-queries Price.PricingConfigurations directly (not #Rows) with the same WHERE predicates - this is correct but means the filter logic is duplicated between the main query and the HasNextPage check. @First IS NULL behavior: `TOP(ISNULL(@First, 10000))` uses 10000 as the effective upper bound when no limit is given - not truly unlimited; queries with more than 10000 matching rows will be silently truncated. INNER JOINs to ProviderToInstrument and InstrumentMetaData mean instruments missing from either table are excluded from results. All reads use WITH (NOLOCK) implicitly via standard session.

---

## 8. Sample Queries

### 8.1 First page of all configurations (100 per page)

```sql
EXEC Price.GetPricingConfigurations
    @First = 100,
    @After = NULL;
-- Returns: rows 1..100, PageInfo.EndCursor = '...'
```

### 8.2 Next page (using EndCursor from previous call)

```sql
EXEC Price.GetPricingConfigurations
    @First = 100,
    @After = '7654';
-- Returns: rows with InstrumentID > 7654
```

### 8.3 Get only Raw Redistribution instruments

```sql
EXEC Price.GetPricingConfigurations
    @PricingType = 1,
    @First = NULL;
-- Returns: 9 Raw Redistribution rows, HasNextPage=0
```

### 8.4 Get instruments on distribution channel 2 (bit 2 set)

```sql
EXEC Price.GetPricingConfigurations
    @DistributionType = 2,
    @First = NULL;
-- Returns: instruments 1005 and 1010 (DistributionType=3, which has bit 2 set)
```

### 8.5 Equivalent manual query (first page)

```sql
SELECT TOP 100
    PC.InstrumentID,
    PC.DistributionType,
    PC.PricingType,
    PC.ProviderId,
    PC.AccountId,
    PC.TopOfBookThrottlingInMs,
    PC.FeedThrottlingInMs,
    PC.ClientThrottlingInMs,
    ISNULL(PTI.Precision, 4) AS Precision,
    ISNULL(PTI.AboveDollarPrecision, 2) AS AboveDollarPrecision,
    IMD.PriceSourceID AS PricesBy
FROM Price.PricingConfigurations PC WITH (NOLOCK)
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON PC.InstrumentID = PTI.InstrumentID
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK)
    ON PC.InstrumentID = IMD.InstrumentID
ORDER BY PC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetPricingConfigurations | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetPricingConfigurations.sql*
