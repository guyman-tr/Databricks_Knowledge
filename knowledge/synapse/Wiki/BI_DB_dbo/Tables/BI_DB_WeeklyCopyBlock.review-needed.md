# BI_DB_dbo.BI_DB_WeeklyCopyBlock — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **OperationTypeID always 2**: Is OperationTypeID=2 specifically "copy block"? Are there other operation types (1, 3, etc.) that this table intentionally excludes, or is 2 the only type in the source?
2. **Conditional TRUNCATE risk**: If SP produces 0 rows in a given week, the table retains stale previous-week data. Is this intentional behavior or a bug?
3. **PlayerLevelID filter**: SP excludes Dim_Customer WHERE PlayerLevelID <> 4 — what is level 4 (likely "closed" accounts)? This means closed accounts ARE excluded from the report.
4. **GuruCopiers schema**: Source is `general.etoroGeneral_History_GuruCopiers` — is this schema documented?

## Corrections Applied

- DDL shows 21 columns (batch assignment said 22 — confirmed 21 from SSDT DDL).

## Cross-Object Consistency Verification

- UserName: matches Dim_Customer definition (Tier 1 — Customer.CustomerStatic)
- CID semantics: this table uses CID as RealCID (matches Dim_Customer.RealCID based on JOIN pattern a.RealCID = CID)
