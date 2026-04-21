---
object: EXW_dbo.RemovePrefix
review_priority: LOW
batch: 9
---

# RemovePrefix — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | Caller SPs not enumerated | LOW | The exact list of EXW SPs that call EXW_dbo.RemovePrefix was not confirmed. Grep `EXW_dbo.RemovePrefix` across SP files to enumerate callers. |
| 2 | NULL input behavior | LOW | Function body does not handle NULL @Input explicitly. SQL Server will propagate NULL naturally but this is undocumented. Confirm NULL behavior if callers may pass NULL. |
| 3 | Empty delimiter edge case | LOW | Behavior when @Delimiter is an empty string is undefined (CHARINDEX of '' returns 1). Not documented in function. |

## No blocking issues. File is complete.
