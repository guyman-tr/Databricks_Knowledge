# BI_DB_dbo.BI_DB_PI_StatusPanel — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **GuruStatusID=1 exclusion**: Both upgrades and downgrades exclude target ID=1 (Certified). Is this intentional? It means transitions No→Certified or Certified→No are not tracked.
2. **Accumulating pattern**: Unlike most BI_DB tables, this one UPDATE+INSERTs. Stale rows for inactive PIs persist indefinitely. Is there a cleanup process?
3. **Column count**: Batch assignment said 14, DDL has 13.
