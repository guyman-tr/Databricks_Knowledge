# dbo.SSRS_AffWiz_ClosedPositions

## 1. Overview

Provides a snapshot of unprocessed closed-position records partitioned by `CID % 10` (last digit of customer ID), comparing the total count of unprocessed positions against the count that are ready to be processed (finished updating but not yet dispatched via `DeferredMessages`). Designed for use in an SSRS monitoring report to detect backlogs or stalls in the closed-position processing pipeline.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.ClosedPositions |
| Secondary Tables | dbo.DeferredMessages |
| Operation | SELECT, UPDATE (temp table internal) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per partition (0-9, based on `CID % 10`).

| Column | Description |
|---|---|
| Partition | CID modulo 10 (0-9) |
| TotalPositions | Total unprocessed closed positions in this partition |
| MinOccurred | Earliest occurrence timestamp among unprocessed positions in this partition |
| ReadyTotalPositions | Count of positions that are finished updating, not yet processed, and not already queued in DeferredMessages |

## 4. Parameters

No parameters.

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| (none) | - | - | - | - |

## 5. Business Logic

1. **Step 1:** SELECTs into temp table `#pos` the total unprocessed positions (`FinishedProcessing = 0`) grouped by `CID % 10`, capturing `Min(Occurred)` and initializing `ReadyTotalPositions = 0`.
2. **Step 2:** UPDATEs `#pos.ReadyTotalPositions` by joining to a derived query that counts positions where:
   - `FinishedUpdating = 1` (update is complete and the position is ready),
   - `FinishedProcessing = 0` (not yet processed),
   - `ClosedPositionsID` does NOT appear in `DeferredMessages` as a pending Sale/Real message (LEFT JOIN + IS NULL check). The `DeferredMessages` subquery parses a JSON-like `Source` column using `LIKE` matching.
   The index hint `WITH (INDEX([IX_Incl_FinishedUpdatingAndProcessing]))` is applied to `ClosedPositions` in this step.
3. **Step 3:** Returns all rows from `#pos`.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.ClosedPositions | Table | dbo | Source of closed-position records |
| dbo.DeferredMessages | Table | dbo | Queue of pending message dispatch; used to exclude already-queued positions |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The explicit index hint `IX_Incl_FinishedUpdatingAndProcessing` on `ClosedPositions` in step 2 forces an efficient seek; verify this index exists before modifying the procedure.
- `NOLOCK` is used on `DeferredMessages` in the subquery to avoid contention on the queue table.
- The JSON-column pattern match (`Source LIKE '{"Queue":"Sale","Mode":"Real","SourceKeyName":"ClosedPositionsID"%'`) is a string scan; if `DeferredMessages` is large, this subquery may be slow without an appropriate index on the `Source` column.
- `CONVERT(INT, SourceKey)` in the subquery assumes `SourceKey` is stored as a string representation of an integer.

## 8. Usage Examples

```sql
-- Check closed-position processing backlog
EXEC dbo.SSRS_AffWiz_ClosedPositions;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.SSRS_AffWiz_ClosedPositions | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.SSRS_AffWiz_ClosedPositions.sql*
