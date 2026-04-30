# Trade.GetInterestRateOverrides_TRDOPS

> Paginated version of GetInterestRateOverrides for Trading Ops Tool, using dynamic SQL with sp_executesql for server-side paging, filtering, and sorting with total count output.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Paginated interest rate override query for TRDOPS admin UI |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInterestRateOverrides_TRDOPS is the Trading Ops Tool (TRDOPS) variant of GetInterestRateOverrides, designed for admin grid/table UIs that require server-side pagination. It queries the same Dictionary.InterestRateOverride table but adds:

- **Pagination**: OFFSET/FETCH with configurable page number and size
- **Sorting**: Dynamic ASC/DESC ordering by InstrumentID, InterestRateOverrideID
- **Total count**: OUTPUT parameter for the total matching records (for UI pager controls)
- **Additional columns**: OverNightFeePatternID, SettlementTypeID (not in the base version)

Unlike GetInterestRateOverrides, this version does NOT join to reference tables for human-readable names -- it returns raw IDs only. The UI layer is expected to resolve display names client-side.

---

## 2. Business Logic

### 2.1 Dynamic Filter Construction

**What**: Builds WHERE clause conditionally using string concatenation, then executes via sp_executesql.

**Rules**:
- Base: `WHERE 1=1` (always true)
- Appends `AND IOR.InterestRateOverrideID = @pInterestRateOverrideID` only when parameter is non-NULL
- Same pattern for @InstrumentID, @InstrumentTypeID, @ExchangeID
- All filter values are properly parameterized (no SQL injection risk)

### 2.2 Pagination

**What**: OFFSET/FETCH server-side paging.

**Rules**:
- @Offset = (@PageNumber - 1) * @PageSize
- Results materialized into #Base temp table first (for COUNT)
- @TotalCount = COUNT(*) from #Base (reflects filtered but not paged count)
- Final SELECT applies OFFSET/FETCH for the requested page

### 2.3 Sort Direction

**What**: Dynamic ORDER BY direction.

**Rules**:
- @SortDirection = 'ASC': ORDER BY InstrumentID ASC, InterestRateOverrideID ASC
- @SortDirection = 'DESC' (default): ORDER BY InstrumentID DESC, InterestRateOverrideID DESC
- Sort direction is injected via string concatenation (not parameterized), but validated via CASE expression

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PageNumber | INT | NO | 1 | CODE-BACKED | Page number (1-based). |
| 2 | @PageSize | INT | NO | 100 | CODE-BACKED | Rows per page. |
| 3 | @SortDirection | VARCHAR(4) | NO | 'DESC' | CODE-BACKED | Sort order: 'ASC' or 'DESC'. |
| 4 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Filter by instrument. |
| 5 | @InterestRateOverrideID | INT | YES | NULL | CODE-BACKED | Filter by override ID. |
| 6 | @InstrumentTypeID | INT | YES | NULL | CODE-BACKED | Filter by asset class. |
| 7 | @ExchangeID | INT | YES | NULL | CODE-BACKED | Filter by exchange. |
| 8 | @TotalCount | INT | - | OUTPUT | CODE-BACKED | Returns total matching records (for UI pager). |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InterestRateOverrideID | int | Dictionary.InterestRateOverride | CODE-BACKED | PK of the override record. |
| R2 | InstrumentID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target instrument (nullable). |
| R3 | ExchangeID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target exchange (nullable). |
| R4 | InstrumentTypeID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target asset class. |
| R5 | UpdatedByUser | nvarchar | Dictionary.InterestRateOverride | CODE-BACKED | Last modifier username. |
| R6 | InterestRateBuy | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Buy-side overnight rate override. |
| R7 | InterestRateSell | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Sell-side overnight rate override. |
| R8 | MarkupBuy | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Buy-side markup. |
| R9 | MarkupSell | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Sell-side markup. |
| R10 | OverNightFeePatternID | int | Dictionary.InterestRateOverride | CODE-BACKED | Overnight fee calculation pattern. |
| R11 | SettlementTypeID | int | Dictionary.InterestRateOverride | CODE-BACKED | Settlement method classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.InterestRateOverride | Read (SELECT) | Source of all override data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Ops Tool (TRDOPS) | Admin UI | EXEC | Interest rate override management grid |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInterestRateOverrides_TRDOPS (procedure)
+-- Dictionary.InterestRateOverride (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRateOverride | Table | SELECT - source of override records, filtered dynamically |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS admin UI | Application | Paginated override management |

---

## 7. Technical Details

### 7.1 Dynamic SQL

- Uses sp_executesql with proper parameterization for all filter values
- Sort direction injected via CASE expression (safe from injection)
- Temp table #Base used to materialize CTE results for COUNT + paginated read
- SET NOCOUNT ON for clean output

### 7.2 Comparison with Trade.GetInterestRateOverrides

| Feature | GetInterestRateOverrides | GetInterestRateOverrides_TRDOPS |
|---------|--------------------------|--------------------------------|
| Pagination | No | Yes (OFFSET/FETCH) |
| Total Count | No | Yes (OUTPUT param) |
| Sorting | Fixed (InstrumentID ASC) | Dynamic (ASC/DESC) |
| Name Resolution | Yes (JOINs to 4 reference tables) | No (raw IDs only) |
| Extra Columns | InterestRateID, Symbol, CurrencyType, ExchangeDescription | OverNightFeePatternID, SettlementTypeID |
| Query Type | Static SQL | Dynamic SQL (sp_executesql) |

---

## 8. Sample Queries

### 8.1 Get first page of overrides

```sql
DECLARE @Total INT;
EXEC Trade.GetInterestRateOverrides_TRDOPS
    @PageNumber = 1,
    @PageSize = 50,
    @TotalCount = @Total OUTPUT;
SELECT @Total AS TotalOverrides;
```

### 8.2 Filter by instrument type, ascending

```sql
DECLARE @Total INT;
EXEC Trade.GetInterestRateOverrides_TRDOPS
    @InstrumentTypeID = 10,
    @SortDirection = 'ASC',
    @TotalCount = @Total OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInterestRateOverrides_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInterestRateOverrides_TRDOPS.sql*
