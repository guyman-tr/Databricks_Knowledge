# Price.GetActiveOMPDThresholdByInstrumentIds

> Paginated read procedure that returns the active OMPD threshold configuration (active type + resolved value) for a batch of instruments, with optional ThresholdType filtering and sort order control.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentsIDs TVP (instrument filter input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetActiveOMPDThresholdByInstrumentIds is the primary read API for OMPD (Order Management Price Deviation) threshold configuration. It returns the currently active OMPD threshold value for each instrument - joining Price.OMPDActiveThreshold (which type is active: Pips=1 or Percentage=2) with Price.OMPDThresholdValues (the actual numeric value) to return the resolved active threshold.

The procedure supports two query modes based on the @InstrumentsIDs TVP:
- **All instruments**: pass an empty TVP to return all configured instruments (paginated)
- **Specific instruments**: pass a list of InstrumentIDs in the TVP to filter results

The result tells the caller: "for instrument X, the active OMPD enforcement is ThresholdType Y with value Z." This is consumed by the pricing/order engine to evaluate whether a submitted order's price deviation is within the configured tolerance.

---

## 2. Business Logic

### 2.1 Active Threshold Resolution - JOIN of Selector and Value Store

**What**: The core join resolves the active threshold type and its numeric value by matching OMPDActiveThreshold (which type is active) with OMPDThresholdValues (all stored values) on both InstrumentID and ThresholdType.

**Columns/Parameters Involved**: `AT.InstrumentID`, `AT.ThresholdType`, `TV.Value`

**Rules**:
- JOIN Price.OMPDActiveThreshold AT with Price.OMPDThresholdValues TV ON AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType
- Only the active type's value row is returned; inactive type values remain in OMPDThresholdValues but are not joined
- An instrument without an active threshold (no row in OMPDActiveThreshold) is excluded
- An instrument with an active threshold but no matching value (inconsistent state) is also excluded (INNER JOIN)
- Example: InstrumentID=1, ThresholdType=1 (Pips active) -> returns Value=40 (the Pips value), not Value=50 (the Percentage value)

### 2.2 Dual-Mode Instrument Filter (TVP vs All)

**What**: The @InstrumentsIDs TVP controls whether to return all instruments or a specific subset.

**Columns/Parameters Involved**: `@InstrumentsIDs`, `@InstrumentsIDsExists`

**Rules**:
- @InstrumentsIDsExists = 1 if TVP contains rows; 0 if empty
- When @InstrumentsIDsExists = 0: no instrument filter applied; all instruments in OMPD returned
- When @InstrumentsIDsExists = 1: WHERE AT.InstrumentID IN (SELECT InstrumentID FROM @InstrumentsIDs) - filters to specified instruments only
- SQL implementation: `(@InstrumentsIDsExists = 0 OR AT.InstrumentID IN (SELECT InstrumentID FROM @InstrumentsIDs))`

### 2.3 Pagination and Sorting

**What**: Offset-based pagination with configurable sort order.

**Columns/Parameters Involved**: `@PageNumber`, `@PageSize`, `@SortOrder`, `@Offset`

**Rules**:
- @PageNumber < 1 -> silently reset to 1 (no error)
- @PageSize < 1 -> silently reset to 10 (no error)
- @Offset = (@PageNumber - 1) * @PageSize: rows to skip
- OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY: standard SQL paging
- @SortOrder='ASC': ORDER BY AT.InstrumentID ASC (default)
- @SortOrder='DESC': ORDER BY AT.InstrumentID DESC
- UPPER(@SortOrder) used: case-insensitive ('asc' works same as 'ASC')

### 2.4 Optional ThresholdType Filter

**What**: @ThresholdType allows filtering to only one type of threshold (e.g., return only Pips thresholds).

**Columns/Parameters Involved**: `@ThresholdType`, `TV.ThresholdType`

**Rules**:
- @ThresholdType IS NULL (default): no type filter; returns active threshold for any type
- @ThresholdType = 1: returns only instruments with active Pips threshold
- @ThresholdType = 2: returns only instruments with active Percentage threshold
- Note: since the JOIN already only returns the ACTIVE type per instrument, filtering by @ThresholdType effectively filters to instruments whose active type matches the filter

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentsIDs | Price.InstrumentsIDsList (TVP) READONLY | IN | - | CODE-BACKED | Table-valued parameter containing the InstrumentIDs to retrieve. Pass empty TVP to return all configured instruments. Pass specific IDs to filter results. Price.InstrumentsIDsList has one column: InstrumentID INT. |
| 2 | @ThresholdType | INT | IN | NULL | CODE-BACKED | Optional filter for threshold type: 1=Pips only, 2=Percentage only, NULL=all types. Since only the active type is returned per instrument, this effectively filters to instruments whose active type matches the specified value. |
| 3 | @PageNumber | INT | IN | 1 | CODE-BACKED | Page number for offset pagination. Minimum 1 (auto-corrected if < 1). First page = 1. Used to compute OFFSET = (@PageNumber - 1) * @PageSize. |
| 4 | @PageSize | INT | IN | 10 | CODE-BACKED | Number of records per page. Minimum 1 (auto-corrected to 10 if < 1). Default 10. The FETCH NEXT count. |
| 5 | @SortOrder | NVARCHAR(4) | IN | 'ASC' | CODE-BACKED | Sort direction for InstrumentID ordering. 'ASC' = ascending (default, lower IDs first). 'DESC' = descending (higher IDs first). Case-insensitive (UPPER() applied). |

**Output result set:**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | InstrumentID | INT | NO | CODE-BACKED | eToro instrument identifier. From OMPDActiveThreshold. |
| 2 | ThresholdType | INT | NO | CODE-BACKED | The active threshold type for this instrument: 1=Pips, 2=Percentage. From OMPDActiveThreshold.ThresholdType. |
| 3 | Value | DECIMAL(20,2) | NO | CODE-BACKED | The numeric threshold value for the active type. From OMPDThresholdValues.Value where ThresholdType matches the active type. For Pips: a pip count (e.g., 40.00). For Percentage: a percentage (e.g., 50.00). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentsIDs | Price.InstrumentsIDsList | INPUT TVP | Standard Price schema instrument ID filter type |
| AT.InstrumentID + AT.ThresholdType | Price.OMPDActiveThreshold | READ | Active threshold type selector per instrument |
| TV.InstrumentID + TV.ThresholdType + TV.Value | Price.OMPDThresholdValues | READ (JOIN) | Resolves active type to its numeric value |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external OMPD management and order processing services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetActiveOMPDThresholdByInstrumentIds (procedure)
├── Price.InstrumentsIDsList (type) - input TVP
├── Price.OMPDActiveThreshold (table) - active type selector
└── Price.OMPDThresholdValues (table) - threshold value store
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentsIDsList | User Defined Type | READONLY TVP parameter - instrument ID filter |
| Price.OMPDActiveThreshold | Table | FROM/JOIN - active threshold type per instrument |
| Price.OMPDThresholdValues | Table | JOIN - resolves active type to numeric value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external OMPD management API and order processing services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Both tables queried WITH (NOLOCK) for non-blocking reads. Pagination validation silently corrects invalid values (< 1) rather than raising errors. The dynamic ORDER BY uses CASE WHEN pattern to switch ASC/DESC without dynamic SQL. No total count or HasNextPage returned - caller must request the next page to determine if more data exists.

---

## 8. Sample Queries

### 8.1 Get active OMPD threshold for specific instruments

```sql
DECLARE @Instruments Price.InstrumentsIDsList;
INSERT @Instruments VALUES (1), (2), (3);

EXEC Price.GetActiveOMPDThresholdByInstrumentIds
    @InstrumentsIDs = @Instruments,
    @PageNumber = 1,
    @PageSize = 100,
    @SortOrder = 'ASC';
```

### 8.2 Get all instruments with active Pips threshold (paginated)

```sql
DECLARE @Empty Price.InstrumentsIDsList; -- empty TVP = all instruments

EXEC Price.GetActiveOMPDThresholdByInstrumentIds
    @InstrumentsIDs = @Empty,
    @ThresholdType = 1,
    @PageNumber = 1,
    @PageSize = 1000,
    @SortOrder = 'ASC';
```

### 8.3 Equivalent inline query (for debugging)

```sql
SELECT
    AT.InstrumentID,
    AT.ThresholdType,
    CASE AT.ThresholdType WHEN 1 THEN 'Pips' WHEN 2 THEN 'Percentage' END AS TypeLabel,
    TV.Value
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Price.OMPDThresholdValues TV WITH (NOLOCK)
    ON AT.InstrumentID = TV.InstrumentID
    AND AT.ThresholdType = TV.ThresholdType
WHERE AT.InstrumentID IN (1, 2, 3)
ORDER BY AT.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetActiveOMPDThresholdByInstrumentIds | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetActiveOMPDThresholdByInstrumentIds.sql*
