# dbo.MoveAffiliatesGroup

## 1. Overview

Reassigns every affiliate in a specified source group to a target group by iterating through them one at a time via a cursor, updating their `AffiliatesGroupsID` and writing an audit log entry for each move. Used when an entire affiliate group needs to be merged into or replaced by another group.

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
| @groupToMoveFromId | IN | INT | required | ID of the source affiliate group whose members will be moved. |
| @groupToMoveToId | IN | INT | required | ID of the destination affiliate group. |
| @UserID | IN | INT | required | ID of the user performing the operation; written to the audit log. |

## 5. Business Logic

1. Opens a `FAST_FORWARD` cursor over all `AffiliateID` values in `tblaff_Affiliates` where `AffiliatesGroupsID = @groupToMoveFromId`.
2. For each affiliate:
   a. UPDATEs `tblaff_Affiliates.AffiliatesGroupsID` to `@groupToMoveToId`.
   b. Constructs a dynamic SQL string to INSERT an audit log row into `AuditLog` with: current date, `@UserID`, `ChangedSectionID = 1`, a reason string describing the move (`'Move AffiliateID:X from AffiliatesGroupID:Y to AffiliatesGroupID:Z'`), the affiliate ID as the referenced ID, and `ActionID = 2`.
   c. Executes the dynamic SQL via `EXEC(@command)`.
3. Cursor is closed and deallocated after the loop.
4. `SET NOCOUNT ON` prevents row-count messages from each iteration.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Affiliates | Table | dbo | Source and target for the group reassignment |
| dbo.AuditLog | Table | dbo | Receives one audit entry per moved affiliate |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Cursor-based row-by-row processing is appropriate for a management operation but becomes slow if a group contains thousands of affiliates; a set-based UPDATE with a single batch INSERT into `AuditLog` would be more efficient.
- Dynamic SQL is used for the audit INSERT; this avoids a plan-reuse concern but introduces string-concatenation overhead per row.
- No explicit transaction wraps the cursor loop, so a failure mid-way leaves some affiliates moved and others not; callers should consider wrapping the EXEC in a transaction.
- `CAST(@currDate AS varchar)` uses the session default date format; this may produce locale-dependent strings in the audit log.

## 8. Usage Examples

```sql
-- Move all affiliates from group 10 to group 20, logged as user 99
EXEC dbo.MoveAffiliatesGroup
    @groupToMoveFromId = 10,
    @groupToMoveToId   = 20,
    @UserID            = 99;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.MoveAffiliatesGroup | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.MoveAffiliatesGroup.sql*
