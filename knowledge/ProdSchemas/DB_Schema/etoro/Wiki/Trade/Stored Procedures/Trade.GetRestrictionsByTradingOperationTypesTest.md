# Trade.GetRestrictionsByTradingOperationTypesTest

> Performance-test variant of Trade.GetRestrictionsByTradingOperationTypes - uses a two-pass temp table + JOIN strategy instead of dynamic SQL. No EXECUTE AS OWNER. Retained for performance comparison benchmarking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OperationTypeIDs, @PageNumber, @PageSize |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the performance-test alternative to `Trade.GetRestrictionsByTradingOperationTypes`. It was created to evaluate whether a two-pass temp table + JOIN approach could outperform the production procedure's dynamic SQL + STRING_AGG IN clause approach.

The production procedure was changed from a JOIN to a dynamic IN clause specifically for performance (see production procedure comment). This Test variant preserves the earlier JOIN-based design with additional temp table and pre-filtering optimizations for benchmarking. The production dynamic SQL approach was ultimately kept, making this Test variant a historical record rather than an active execution path.

The two procedures produce the same output (same 4 columns, same ORDER BY CID, same OFFSET/FETCH semantics). Key differences:
- No `WITH EXECUTE AS OWNER` (the Test variant does not use dynamic SQL, so the cross-schema permission workaround is not needed)
- Two-pass execution: first pass pre-filters to a temp table (#b), second pass enriches with Occurred
- No index hint on the second pass (commented out)
- `SELECT TOP (@PageNumber * @PageSize)` in first pass (not standard OFFSET pagination)

---

## 2. Business Logic

### 2.1 Two-Pass Pre-Filter + Enrich Strategy

**What**: First pass fetches all rows up to the end of the requested page (key columns only) with a clustered index. Second pass re-joins for full data of the requested page.

**Columns/Parameters Involved**: `#OperationTypeIDs`, `#b`, `CID`, `OperationTypeID`, `BlockReasonID`, `Occurred`

**Rules**:
- Pass 0: INSERT @OperationTypeIDs -> #OperationTypeIDs (temp table) + CREATE CLUSTERED INDEX on TradingOperationTypeID
- Pass 1 (filtered): SELECT TOP (@PageNumber * @PageSize) CID, OperationTypeID, BlockReasonID INTO #b FROM BlockedCustomerOperations INNER JOIN #OperationTypeIDs on OperationTypeID; CREATE CLUSTERED INDEX IX on #b(CID, OperationTypeID, BlockReasonID)
- Pass 2: SELECT CID, OperationTypeID, Occurred, BlockReasonID FROM BlockedCustomerOperations INNER JOIN #b on (CID, OperationTypeID, BlockReasonID) OFFSET/FETCH for the target page

**Diagram**:
```
Pass 0: @OperationTypeIDs TVP -> #OperationTypeIDs (temp) with clustered index
  Avoids repeated TVP scans in subsequent passes

Pass 1: TOP (PageNumber * PageSize) key-only rows from BlockedCustomerOperations
  INNER JOIN #OperationTypeIDs -> filtered by operation type
  ORDER BY CID -> deterministic ordering
  -> #b (CID, OperationTypeID, BlockReasonID) with clustered index
  Purpose: materialize the "candidate pool" efficiently using key columns only (no Occurred fetch)

Pass 2: Re-join BlockedCustomerOperations on (CID, OperationTypeID, BlockReasonID) from #b
  -> retrieve Occurred + OFFSET/FETCH for the target page
  Purpose: enrich only the final page with the Occurred datetime column

Design intent: SQL Server can do a narrow index scan for Pass 1 (no Occurred needed),
then a targeted lookup for Pass 2 (few rows after OFFSET).
Compare: production dynamic SQL fetches all 4 columns in one pass.
```

### 2.2 Unfiltered Mode

When @OperationTypeIDs TVP is empty, falls through to ELSE branch with simple OFFSET/FETCH - no temp table is created. No index hint in this branch (commented out in DDL).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationTypeIDs | Trade.TradingOperationTypeIDs READONLY | NO | - | CODE-BACKED | TVP of operation type IDs to filter by. Same semantics as production variant. |
| 2 | @PageNumber | INT | NO | - | CODE-BACKED | 1-based page number. |
| 3 | @PageSize | INT | NO | 1000 | CODE-BACKED | Rows per page, defaults to 1000. |

**Output Columns** - identical to production variant:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CID | INT | NO | - | ATLASSIAN | Customer ID with an active restriction. |
| 5 | OperationTypeID | INT | NO | - | ATLASSIAN | TradeRestrictionType: CopyUser=1 ... ManualExecutionBlock=21. See production doc for full enum. |
| 6 | Occurred | DATETIME | NO | - | ATLASSIAN | Timestamp when the restriction was applied. |
| 7 | BlockReasonID | INT | NO | - | ATLASSIAN | BlockUnBlockReason: NONE=0 ... MaxAumPerTier=23. See production doc for full enum. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID, Occurred, BlockReasonID | Customer.BlockedCustomerOperations | Reader (cross-schema) | Two-pass: Pass 1 reads key columns for filter, Pass 2 reads full row for output |
| @OperationTypeIDs | Trade.TradingOperationTypeIDs | UDT reference | TVP type for operation type filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetRestrictionsByTradingOperationTypes | - | Sibling (perf test) | Production variant; this Test proc was the benchmarking alternative |
| Trade developers | Manual EXEC | Benchmarking | Side-by-side comparison against production proc to compare query plans and execution times |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRestrictionsByTradingOperationTypesTest (procedure)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
+-- Trade.TradingOperationTypeIDs (UDT - same schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (Customer schema) | Two-pass JOIN: Pass 1 key-only with IX_OperationTypeID hint + #OperationTypeIDs JOIN; Pass 2 full join via #b |
| Trade.TradingOperationTypeIDs | UDT (Trade schema) | TVP type for @OperationTypeIDs parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none - test/benchmark only) | - | Not called by application services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No EXECUTE AS OWNER | Security | Not needed - no dynamic SQL, cross-schema access handled by normal permissions |
| SELECT TOP (@PageNumber * @PageSize) | Pre-filter | Limits first pass to candidate pool size; avoids full scan but reads more than one page |
| CREATE CLUSTERED INDEX IX on #b | Temp table optimization | Allows efficient join in Pass 2; trades CREATE INDEX cost for better Pass 2 lookup |
| #OperationTypeIDs clustered index | Temp table optimization | Enables efficient INNER JOIN in Pass 1 compared to TVP join |
| option(recompile) | Query hint | Fresh plans in both passes to handle varying row counts |
| INDEX hint commented out in unfiltered ELSE | Design note | `---WITH (INDEX = IX_OperationTypeID)` commented out; unfiltered case may use a different plan |

---

## 8. Sample Queries

### 8.1 Run the test variant for benchmarking

```sql
DECLARE @OpTypes Trade.TradingOperationTypeIDs;
INSERT INTO @OpTypes VALUES (4), (5);
-- Compare execution plans with production:
EXEC Trade.GetRestrictionsByTradingOperationTypesTest
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1,
    @PageSize = 1000;
-- vs.
EXEC Trade.GetRestrictionsByTradingOperationTypes
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1,
    @PageSize = 1000;
```

---

## 9. Atlassian Knowledge Sources

See `Trade.GetRestrictionsByTradingOperationTypes` - same Confluence TDD source applies for enum values and data model context.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 4 ATLASSIAN, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 1 Confluence (inherited from sibling doc) + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRestrictionsByTradingOperationTypesTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRestrictionsByTradingOperationTypesTest.sql*
