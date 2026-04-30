# Price.GetInstrumentsOMPDThresholdByInstrumentIds

> Returns paginated OMPD threshold values from Price.OMPDThresholdValues for a specified list of instruments (or all instruments when the list is empty), with optional ThresholdType filtering, configurable page size, and ASC/DESC sort order.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentsIDs (TVP filter), @PageNumber/@PageSize (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentsOMPDThresholdByInstrumentIds is the paginated instrument-scoped read procedure for OMPD threshold values. Unlike GetInstrumentsOMPDThresholdByExchangeIds (which takes exchange IDs), this procedure accepts a direct list of InstrumentIDs via a TVP and returns all threshold type rows (both Pips and Percentage) for those instruments - without the active-threshold filter.

This procedure is designed for bulk retrieval with full pagination support: page number, page size, and sort direction are all configurable. OFFSET/FETCH pagination makes it suitable for large result sets. It is used when admin tools or APIs need to display or export threshold configurations for a known set of instruments, or retrieve the full configuration with both threshold types visible simultaneously.

Key difference from the exchange-scoped variant: this procedure reads directly from OMPDThresholdValues WITHOUT joining OMPDActiveThreshold - it returns ALL stored threshold values (both active and inactive types) for the specified instruments.

---

## 2. Business Logic

### 2.1 Optional Instrument Filter via TVP

**What**: The @InstrumentsIDs TVP can be empty (return all) or populated (filter by instrument).

**Columns/Parameters Involved**: `@InstrumentsIDs`, `@InstrumentsIDsExists`

**Rules**:
- `@InstrumentsIDsExists = CASE WHEN EXISTS (SELECT TOP 1 1 FROM @InstrumentsIDs) THEN 1 ELSE 0 END`
- WHERE condition: `(@InstrumentsIDsExists = 0 OR TV.InstrumentID IN (SELECT InstrumentID FROM @InstrumentsIDs))`
- When empty TVP: `@InstrumentsIDsExists=0` -> condition passes for all rows (return all instruments)
- When populated TVP: `@InstrumentsIDsExists=1` -> filter to matching InstrumentIDs only

### 2.2 Optional ThresholdType Filter

**What**: @ThresholdType can narrow to one specific type.

**Columns/Parameters Involved**: `@ThresholdType`

**Rules**:
- NULL (default): returns both ThresholdType=1 (Pips) and ThresholdType=2 (Percentage) rows
- 1 or 2: returns only rows of that specific type
- WHERE: `(@ThresholdType IS NULL OR TV.ThresholdType = @ThresholdType)`

### 2.3 OFFSET/FETCH Pagination

**What**: Standard pagination using page number and page size.

**Columns/Parameters Involved**: `@PageNumber`, `@PageSize`, `@SortOrder`, `@Offset`

**Rules**:
- Default @PageNumber=1, @PageSize=10 - first page of 10 rows
- Validation: IF @PageNumber < 1 SET @PageNumber = 1; IF @PageSize < 1 SET @PageSize = 10 (prevents invalid negative values)
- `@Offset = (@PageNumber - 1) * @PageSize` - standard offset calculation
- ORDER BY: dynamic sort direction via CASE WHEN UPPER(@SortOrder) = 'ASC'...
  - 'ASC' (default): `ORDER BY InstrumentID ASC`
  - 'DESC': `ORDER BY InstrumentID DESC`
- OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY - SQL Server OFFSET/FETCH pagination

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentsIDs | Price.InstrumentsIDsList READONLY | NOT NULL (but can be empty) | - | CODE-BACKED | TVP of InstrumentIDs to retrieve thresholds for. When empty, returns all instruments' threshold values. Type: Price.InstrumentsIDsList (single-column: InstrumentID INT). |
| 2 | @ThresholdType | INT | YES | NULL | CODE-BACKED | Optional filter for threshold type: NULL=both types, 1=Pips only, 2=Percentage only. Corresponds to Dictionary.OMPDThresholdType values. |
| 3 | @PageNumber | INT | NOT NULL | 1 | CODE-BACKED | 1-based page number for pagination. Values < 1 are corrected to 1. |
| 4 | @PageSize | INT | NOT NULL | 10 | CODE-BACKED | Number of rows per page. Values < 1 are corrected to 10. |
| 5 | @SortOrder | NVARCHAR(4) | NOT NULL | 'ASC' | CODE-BACKED | Sort direction: 'ASC' (default, smallest InstrumentID first) or 'DESC' (largest InstrumentID first). Case-insensitive via UPPER(). |

**Result set columns** (3 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | Instrument identifier |
| 2 | ThresholdType | Threshold unit type: 1=Pips, 2=Percentage (Dictionary.OMPDThresholdType) |
| 3 | Value | Threshold amount: pips count (e.g., 40.00) for ThresholdType=1, percentage (e.g., 50.00) for ThresholdType=2 |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentsIDs | Price.InstrumentsIDsList | TVP type | Input instrument ID filter |
| InstrumentID | Price.OMPDThresholdValues | READER | Primary data source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (OMPD configuration API) | @InstrumentsIDs | CALLER | Called to retrieve both threshold types for specific instruments with pagination |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentsOMPDThresholdByInstrumentIds (procedure)
+-- Price.OMPDThresholdValues (table) - source of all threshold values
+-- Price.InstrumentsIDsList (UDT) - TVP type definition
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.OMPDThresholdValues | Table | FROM source with WHERE filter and pagination |
| Price.InstrumentsIDsList | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (OMPD configuration API) | External | Calls to retrieve paginated OMPD threshold data by instrument ID list |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

All reads use WITH (NOLOCK). The procedure does NOT join Price.OMPDActiveThreshold - returns both threshold types regardless of which is "active". The @SortOrder parameter accepts any NVARCHAR(4) value; non-'ASC' values (including invalid strings) default to DESC behavior since the CASE only matches 'ASC'. No result count or HasNextPage is returned - unlike GetPricingConfigurations, there is no cursor-based pagination metadata. The InstrumentID IN (SELECT ...) pattern may be less efficient than a JOIN for very large TVPs but is correct.

---

## 8. Sample Queries

### 8.1 Get all threshold types for specific instruments (first page)

```sql
DECLARE @InstrumentList Price.InstrumentsIDsList;
INSERT INTO @InstrumentList VALUES (1), (2), (3);
EXEC Price.GetInstrumentsOMPDThresholdByInstrumentIds
    @InstrumentsIDs = @InstrumentList,
    @PageNumber = 1,
    @PageSize = 50;
```

### 8.2 Get only Pips thresholds for all instruments, page 2

```sql
DECLARE @EmptyList Price.InstrumentsIDsList;
EXEC Price.GetInstrumentsOMPDThresholdByInstrumentIds
    @InstrumentsIDs = @EmptyList,
    @ThresholdType = 1,
    @PageNumber = 2,
    @PageSize = 100,
    @SortOrder = 'ASC';
```

### 8.3 Equivalent manual query

```sql
SELECT TV.InstrumentID, TV.ThresholdType, TV.Value
FROM Price.OMPDThresholdValues TV WITH (NOLOCK)
WHERE TV.InstrumentID IN (1, 2, 3)
ORDER BY TV.InstrumentID ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentsOMPDThresholdByInstrumentIds | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetInstrumentsOMPDThresholdByInstrumentIds.sql*
