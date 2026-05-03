# Review Needed: eMoney_Tribe.AccountsActivities_862157

## Tier 3 Items Requiring Human Review

All 9 columns are Tier 3 — no upstream wiki was found (`_no_upstream_found.txt` present). Descriptions are grounded in DDL structure, SP code analysis (`SP_eMoney_Reconciliation_ETLs`), and live data sampling.

### Columns to Verify

| # | Column | Concern |
|---|---|---|
| 1 | @Created | Confirmed always populated via live query. Verify that this is the Treezor XML creation timestamp vs. a pipeline-assigned timestamp. |
| 2 | @Id | Confirmed UUID format from sample data. Verify this is the Treezor document ID (not an internally generated key). |
| 3 | @FileName | File pattern observed: `accounts-activities-{version}-{entityId}-{accountId}-{date}-SubFile-{N}.xml`. Confirm the `862157` in the table name matches the entity ID in the file path. |
| 4-6 | etr_y, etr_ym, etr_ymd | ~99.8% NULL. These appear to be Generic Pipeline partition metadata. Confirm if they are deprecated or only populated for specific ingestion runs. |
| 7 | SynapseUpdateDate | Always populated. Confirm this is set by the Generic Pipeline (not by SP_eMoney_Reconciliation_ETLs). |
| 8 | partition_date | Always populated. Appears to correspond to the date of `@Created`. Confirm derivation logic. |
| 9 | Created | ~41.6% NULL. This column duplicates `@Created` by name but has a different NULL rate. Clarify the distinction — possibly a late addition or alternate source timestamp. |

## Open Questions

1. **Table suffix `862157`**: Is this a Treezor webhook entity ID, a file export configuration ID, or another identifier? The eMoney team should confirm the naming convention.
2. **etr_* columns nearly all NULL**: Should these be deprecated or are they expected to be backfilled?
3. **`Created` vs `@Created`**: Why do both exist? Is `Created` populated only for newer rows (schema evolution)?
4. **UC migration**: This table is marked `_Not_Migrated`. Is there a plan to migrate the reconciliation pipeline to UC/Databricks?

## Production Source

Production Source: Unknown (dormant) — no upstream wiki resolvable. Data originates from Treezor banking-as-a-service API XML exports ingested by the Generic Pipeline.

---

*Generated: 2026-04-30*
