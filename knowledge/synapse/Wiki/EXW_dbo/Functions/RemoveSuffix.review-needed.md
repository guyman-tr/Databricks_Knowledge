---
object: EXW_dbo.RemoveSuffix
review_priority: LOW
batch: 9
---

# RemoveSuffix — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | Caller SPs not enumerated | LOW | The exact list of EXW SPs that call EXW_dbo.RemoveSuffix was not confirmed. Grep `EXW_dbo.RemoveSuffix` across SP files to enumerate callers. |
| 2 | NULL input behavior | LOW | Function body does not handle NULL @Input explicitly. SQL Server propagates NULL naturally but this is undocumented. |
| 3 | Relationship to RemovePrefix | LOW | RemovePrefix and RemoveSuffix are a complementary pair. Together they allow extracting middle segments of a delimited path (RemoveSuffix removes the last segment, RemovePrefix removes the first segment). Consider documenting combined usage patterns. |

## No blocking issues. File is complete.
