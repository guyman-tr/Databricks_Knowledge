# dbo.MoveSomeAffiliateToAnotherGroup

## 1. Overview

Moves a specified subset of affiliates (identified by a comma-separated ID list) to a target affiliate group. For each affiliate the procedure updates `tblaff_Affiliates.AffiliatesGroupsID` and writes an audit log entry recording the move. Unlike `MoveAffiliatesGroup`, which moves an entire group, this procedure moves a caller-selected subset.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Affiliates |
| Secondary Tables | dbo.AuditLog |
| Operation | UPDATE, INSERT (audit) |
| Transaction | No (each row committed individually) |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @affiliateIds | IN | varchar(max) | required | Comma-separated list of AffiliateID integers to move. |
| @groupToMoveToId | IN | integer | required | ID of the destination affiliate group. |
| @UserID | IN | integer | required | ID of the user performing the operation; written to the audit log. |

## 5. Business Logic

1. Splits `@affiliateIds` using `fn_Split(@affiliateIds, ',')` into individual IDs and opens a `FAST_FORWARD` cursor over the results.
2. For each `AffiliateID`:
   a. UPDATEs `tblaff_Affiliates.AffiliatesGroupsID` to `@groupToMoveToId`.
   b. Constructs a dynamic SQL string for an audit INSERT: current date, `@UserID`, `ChangedSectionID = 1`, reason `'Move AffiliateID:X to AffiliatesGroupID:Y'`, affiliated ID as reference, `ActionID = 2`.
   c. Executes via `EXEC(@command)`.
3. Cursor is closed and deallocated after all rows.
4. `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Affiliates | Table | dbo | Target table for group reassignment |
| dbo.AuditLog | Table | dbo | Receives one audit entry per moved affiliate |
| dbo.fn_Split | Function | dbo | Splits a delimited string into a table of values |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Cursor-based processing has the same per-row overhead concerns as `MoveAffiliatesGroup`; a set-based rewrite would scale better.
- No source-group validation: if any ID in `@affiliateIds` does not exist or already belongs to the target group, the UPDATE silently affects 0 rows for that ID.
- No wrapping transaction; partial success is possible on error.

## 8. Usage Examples

```sql
-- Move affiliates 101, 205, and 340 to group 20
EXEC dbo.MoveSomeAffiliateToAnotherGroup
    @affiliateIds    = '101,205,340',
    @groupToMoveToId = 20,
    @UserID          = 99;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.MoveSomeAffiliateToAnotherGroup | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.MoveSomeAffiliateToAnotherGroup.sql*
