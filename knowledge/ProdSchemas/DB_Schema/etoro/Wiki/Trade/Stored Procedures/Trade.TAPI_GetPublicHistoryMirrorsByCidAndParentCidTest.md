# Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest

> Test variant of TAPI_GetPublicHistoryMirrorsByCidAndParentCid: identical logic but reads position counts from History.Position_Active instead of History.PositionSlim.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @parentCid INT (test version - History.Position_Active source) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a test/experimental variant of `TAPI_GetPublicHistoryMirrorsByCidAndParentCid`. The business logic, parameters, and output columns are **identical** to the production version. The only difference is the source table for position data:

- **Production (`ByCidAndParentCid`)**: `LEFT JOIN History.PositionSlim`
- **Test (`ByCidAndParentCidTest`)**: `LEFT JOIN History.Position_Active`

`History.Position_Active` is the partitioned archive table where closed positions are stored after being moved from Trade.PositionTbl. `History.PositionSlim` is a view or materialized subset with fewer columns for performance. This test version was likely created to evaluate whether reading from `Position_Active` (more columns, different partitioning) produces different results than `PositionSlim`.

The `Test` suffix indicates this is not a primary production SP. It should not be called in production flows except for comparison/testing purposes.

---

## 2. Business Logic

All logic is identical to `TAPI_GetPublicHistoryMirrorsByCidAndParentCid`. See that procedure's documentation for full details.

**Single difference**:
- `LEFT JOIN History.Position_Active HP` instead of `LEFT JOIN History.PositionSlim HP`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

Identical to `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @parentCid | INT | NO | - | CODE-BACKED | Popular Investor's customer ID. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start (on ModificationDate). Combined with 1-year cap. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. |

### Output

Identical to `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid` (CID, ParentCID, MirrorID, TotalPositions, TotalMirrorProfitabilityPercentage, TotalMirrorNetProfitPercentage, StopCopyDate, StartCopyDate).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, ParentCID, MirrorID, MirrorOperationID, ModificationDate | History.Mirror | Lookup (READ) | Closed mirror session list |
| MirrorID, NetProfit, PositionID | History.Position_Active | Lookup (READ) | Position counts and profitability (TEST: different from production which uses PositionSlim) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Test/experimental SP.
Counterpart: `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid` (production version using History.PositionSlim).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.Position_Active (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror session list |
| History.Position_Active | Table (cross-schema) | Position counts and profitability (vs PositionSlim in production) |

### 6.2 Objects That Depend On This

No SQL dependents. Test SP - not called in production flows.

---

## 7. Technical Details

### 7.1 Indexes

N/A.

### 7.2 Constraints

None. Key behavioral characteristics:
- Identical to production SP except data source for positions
- `Test` suffix = experimental; do not rely on in production
- WITH (NOLOCK) on all tables

---

## 8. Sample Queries

### 8.1 Compare with production version

```sql
-- Production (uses PositionSlim)
EXEC Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid
    @cid = 12345, @parentCid = 99999,
    @startTime = DATEADD(year,-1,GETUTCDATE()),
    @pageNumber = 1, @itemsPerPage = 20

-- Test (uses Position_Active)
EXEC Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest
    @cid = 12345, @parentCid = 99999,
    @startTime = DATEADD(year,-1,GETUTCDATE()),
    @pageNumber = 1, @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest.sql*
