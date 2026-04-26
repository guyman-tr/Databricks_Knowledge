# Review Needed: BI_DB_dbo.BI_DB_ABook_Exposure_History

**Generated**: 2026-04-23
**Quality Score**: 7.0/10
**Status**: Needs domain expert review

## Open Questions

1. **Writer SP identity** — No writer SP found in SSDT BI_DB_dbo or OpsDB. Was this table ever populated? If so, what process populated it (on-prem SQL Server agent job, SSIS, legacy feed)?

2. **Relationship to BI_DB_ABook_Exposure** — Was the intent that `BI_DB_ABook_Exposure` (current state) would be archived daily into `BI_DB_ABook_Exposure_History`? If so, what process performed that archival, and when was it discontinued?

3. **Supersession by NOPHedged** — Is `BI_DB_ABook_Exposure_NOPHedged` (Generic Pipeline #471) truly the operational successor, or does a separate historical log exist in UC / Delta Lake?

4. **NOPHedged column position** — In this History table DDL, `NOPHedged` is column 16 and `UpdateDate` is column 17. In the companion `BI_DB_ABook_Exposure` wiki, these columns appear in reverse order in the Elements section. This has been noted and reflected correctly (per DDL order) in this wiki.

5. **Empty table retention** — Both `BI_DB_ABook_Exposure` and `BI_DB_ABook_Exposure_History` are empty with no active pipeline. Should these tables be decommissioned or are they reserved for future use?

## Columns Requiring Confirmation

| Column | Concern |
|--------|---------|
| NOP_unhedged through Long | All Tier 3 — inferred from ABook domain knowledge and sibling wiki. No direct SP code (Tier 2) or upstream wiki (Tier 1) found. |
| DATE | Described as "trading date of historical exposure record." Clustered index key. If the table was populated, confirm whether DATE = snapshot date or trade execution date. |
| UpdateDate | Tier 5 (propagation). Confirm this is the ETL load timestamp, not a business date. |

## Lineage Gaps

- Production source entirely unknown — no Generic Pipeline, no External Table, no SSDT SP
- No OpsDB registration found
- Assumed to be fed from the same discontinued ABook hedging system as `BI_DB_ABook_Exposure`
