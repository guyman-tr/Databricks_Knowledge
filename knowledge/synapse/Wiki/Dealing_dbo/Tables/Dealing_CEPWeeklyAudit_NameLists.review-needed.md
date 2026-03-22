# Review Sidecar — Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists

## Confidence Flags

| Area | Confidence | Notes |
|------|------------|-------|
| SP logic | High | `SP_W_CEPWeeklyAudit` read for NameLists path |
| Data quality | Low | Suspected JOIN bug at line 878 may null out or duplicate week rows |

## Priority: suspected JOIN bug (line 878)

The NameLists insert uses a predicate equivalent to:

```sql
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = fdtd.ToDate
```

The second term is always true. It should likely be `fdtd.ToDate = rcf.ToDate`. Until fixed or disproved, **all rows may be placeholders** and true Named List change events may not surface in this table.

**Suggested validation**

1. `SELECT COUNT(*) FROM Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists WHERE TypeOfChange IS NOT NULL`
2. Compare a sample of weeks against `Dealing_CEPDailyAudit_NameLists` for overlapping periods.
3. If validation fails, track a defect on `SP_W_CEPWeeklyAudit` and treat daily audit as authoritative where it exists.

## Reviewer corrections

<!-- Add corrections here. -->
