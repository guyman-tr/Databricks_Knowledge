# Trade.GetCalculatedFeesConfig_TRDOPS

> Retrieves paginated overnight fee configuration (V2) from Trade.InstrumentToFeeConfigV2 for the Trading Operations back-office tool, with optional instrument and settlement type filters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated fee configuration with total count and sorting |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure serves the Trading Operations (TRDOPS) tool for managing per-instrument overnight fee configuration. While `Trade.GetAllInterestRates_TRDOPS` returns instrument-type-level rates, this procedure returns instrument-level fee overrides from the V2 fee configuration table. Operations teams use this to audit and manage instrument-specific overnight fee settings.

The procedure exists because some instruments have custom overnight fees that differ from the default rates for their asset class. The TRDOPS tool needs a paginated, filterable view of these overrides to manage the thousands of possible instrument-settlement type combinations.

Data flows from `Trade.InstrumentToFeeConfigV2` with server-side pagination (OFFSET/FETCH), dynamic sorting (ASC/DESC), and optional filtering via TVP lists for InstrumentID and SettlementTypeID. A temp table is used for accurate total count calculation.

---

## 2. Business Logic

### 2.1 Server-Side Pagination

**What**: Implements OFFSET-based pagination with configurable page size and direction.

**Columns/Parameters Involved**: `@PageNumber`, `@PageSize`, `@SortDir`, `@TotalCount`

**Rules**:
- `@Offset = (@PageNumber - 1) * @PageSize`
- Sorting by InstrumentID with direction from @SortDir (defaults to DESC)
- Secondary sort by SettlementTypeID DESC within same InstrumentID
- @TotalCount OUTPUT returns the total matching records (for UI pagination controls)

### 2.2 Optional TVP List Filters

**What**: Supports optional filtering by lists of instrument IDs and settlement type IDs via TVPs.

**Columns/Parameters Involved**: `@instrumentid_list`, `@settlementtypeid_list`

**Rules**:
- `NOT EXISTS (SELECT 1 FROM @instrumentid_list) OR InstrumentID IN (SELECT InstrumentID FROM @instrumentid_list)`
- When TVP is empty, no filter is applied (returns all)
- When TVP has values, only matching records are returned
- Same pattern for both instrument and settlement type filters

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PageNumber | INT | YES | 1 | CODE-BACKED | Page number for pagination (1-based). |
| 2 | @PageSize | INT | YES | 100 | CODE-BACKED | Number of records per page. |
| 3 | @SortDir | VARCHAR(4) | YES | 'DESC' | CODE-BACKED | Sort direction for InstrumentID: 'ASC' or 'DESC'. |
| 4 | @instrumentid_list | Trade.InstrumentIDsTbl | NO | (empty) | CODE-BACKED | READONLY TVP - optional list of InstrumentIDs to filter. Empty list = no filter. |
| 5 | @settlementtypeid_list | Trade.SettlementTypeIDsTbl | NO | (empty) | CODE-BACKED | READONLY TVP - optional list of SettlementTypeIDs to filter. Empty list = no filter. |
| 6 | @TotalCount | INT | NO | - | CODE-BACKED | OUTPUT parameter returning the total number of matching records (before pagination). Used by UI for page navigation. |
| 7 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument with custom fee configuration. FK to Trade.Instrument. |
| 8 | SettlementTypeID | INT | NO | - | CODE-BACKED | Settlement type for this fee configuration (0=CFD, 1=Real, etc.). |
| 9 | FeeCalculationTypeID | INT | YES | - | CODE-BACKED | Method used to calculate the fee for this instrument-settlement combination. |
| 10 | NonLeveragedSellEndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Weekend fee rate for non-leveraged sell positions. |
| 11 | NonLeveragedBuyEndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Weekend fee rate for non-leveraged buy positions. |
| 12 | NonLeveragedBuyOverNightFee | DECIMAL | YES | - | CODE-BACKED | Daily overnight fee rate for non-leveraged buy positions. |
| 13 | NonLeveragedSellOverNightFee | DECIMAL | YES | - | CODE-BACKED | Daily overnight fee rate for non-leveraged sell positions. |
| 14 | LeveragedSellEndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Weekend fee rate for leveraged sell positions. |
| 15 | LeveragedBuyEndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Weekend fee rate for leveraged buy positions. |
| 16 | LeveragedBuyOverNightFee | DECIMAL | YES | - | CODE-BACKED | Daily overnight fee rate for leveraged buy positions. |
| 17 | LeveragedSellOverNightFee | DECIMAL | YES | - | CODE-BACKED | Daily overnight fee rate for leveraged sell positions. |
| 18 | Occurred | DATETIME | YES | - | CODE-BACKED | When this fee configuration was last modified. |
| 19 | UpdatedByUser | NVARCHAR | YES | - | CODE-BACKED | Username of who last updated this fee configuration. Audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentToFeeConfigV2 | SELECT FROM | Source table for instrument-level fee configuration |
| @instrumentid_list | Trade.InstrumentIDsTbl | TVP type | User-defined table type for instrument filter |
| @settlementtypeid_list | Trade.SettlementTypeIDsTbl | TVP type | User-defined table type for settlement type filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCalculatedFeesConfig_TRDOPS (procedure)
+-- Trade.InstrumentToFeeConfigV2 (table)
+-- Trade.InstrumentIDsTbl (type)
+-- Trade.SettlementTypeIDsTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | SELECT FROM - fee configuration data |
| Trade.InstrumentIDsTbl | User Defined Type | TVP for instrument filter |
| Trade.SettlementTypeIDsTbl | User Defined Type | TVP for settlement type filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get first page of all fee configurations
```sql
DECLARE @TotalCount INT;
DECLARE @InstrList Trade.InstrumentIDsTbl;
DECLARE @SettlList Trade.SettlementTypeIDsTbl;

EXEC Trade.GetCalculatedFeesConfig_TRDOPS
    @PageNumber = 1, @PageSize = 50, @SortDir = 'ASC',
    @instrumentid_list = @InstrList, @settlementtypeid_list = @SettlList,
    @TotalCount = @TotalCount OUTPUT;

SELECT @TotalCount AS TotalRecords;
```

### 8.2 Filter by specific instruments
```sql
DECLARE @TotalCount INT;
DECLARE @InstrList Trade.InstrumentIDsTbl;
DECLARE @SettlList Trade.SettlementTypeIDsTbl;
INSERT INTO @InstrList (InstrumentID) VALUES (1001), (1002), (1003);

EXEC Trade.GetCalculatedFeesConfig_TRDOPS
    @instrumentid_list = @InstrList, @settlementtypeid_list = @SettlList,
    @TotalCount = @TotalCount OUTPUT;
```

### 8.3 Query fee config directly
```sql
SELECT  InstrumentID, SettlementTypeID, LeveragedBuyOverNightFee, LeveragedSellOverNightFee, UpdatedByUser, Occurred
FROM    Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE   InstrumentID = 1001
ORDER BY SettlementTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCalculatedFeesConfig_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCalculatedFeesConfig_TRDOPS.sql*
