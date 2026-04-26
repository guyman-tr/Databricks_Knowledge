# Review Needed: BI_DB_dbo.BI_DB_Flare_Eligibility

**Generated**: 2026-04-22 | **Batch**: 26 | **Pipeline phase**: 12 (Post-generation review sidecar)

---

## Questions for Domain Expert

1. **Campaign status**: Is this table still actively maintained for the Flare Network airdrop campaign, or is the campaign concluded? If concluded, should this table be decommissioned? The Finance-uploaded CSV (`Flare_list_of_CIDs.csv`) must still be present and current for the daily ETL to produce meaningful rows.

2. **CountryID exclusion list**: The SP excludes CountryID IN (67,167,148,79,63,105,96) under the "Cash Equivalent" flag. What countries do these IDs map to? The wiki documents the IDs but not the country names (would require runtime JOIN to Dim_Country).

3. **RegulationID exclusion list**: RegulationID IN (6,7,8) triggers the Cash Equivalent exclusion. What regulations are IDs 6, 7, and 8? The wiki documents the IDs but not the names.

4. **PlayerStatusReasonID=28**: This triggers the "Negative Target Market" exclusion. What is the business meaning of PlayerStatusReasonID=28?

5. **BVI = RegulationID=5**: The "Negative Target Market" exclusion includes `RegulationID=5 (BVI)`. Confirm this is British Virgin Islands regulatory treatment and that BVI-regulated customers are excluded from Flare eligibility.

6. **Column naming**: Three columns use space-containing names (`[Negative Target Market]`, `[AML Status Restriction]`, `[Account status]`). Was this intentional, or should these be migrated to underscore-separated names (e.g., `Negative_Target_Market`) when/if UC migration is done?

---

## Known Issues / Anomalies

| Issue | Severity | Description |
|-------|----------|-------------|
| External CSV fragility | Medium | The ETL depends on `BI_OUTPUT/Finance/Uploads/Flare_list_of_CIDs.csv` being present in the lake. If Finance doesn't upload the file, the table will be truncated to 0 rows on the next run with no error raised. Monitor for empty-table scenarios. |
| Space-containing column names | Low | `[Negative Target Market]`, `[AML Status Restriction]`, `[Account status]` — require bracket-quoting in all SQL. These names are unusual for a Synapse table and may cause issues with some BI tools or ETL frameworks that don't handle spaces in column names. |
| No row count baseline | Low | Because the candidate list is Finance-uploaded and variable, there's no stable expected row count to validate against. Consider adding an alert if the post-reload row count drops below a historical minimum. |

---

## UC Migration Notes

- **UC Target**: Not Migrated
- **No `.alter.sql`** — this session ran in wiki-only mode
- When UC migration is planned:
  - Rename space-containing columns to underscore format
  - Confirm whether the campaign-specific external table (`External_Flare_CID3`) should also be migrated or whether future campaigns will use a different input mechanism
  - The TRUNCATE + INSERT pattern is straightforward to migrate; no date-partitioning complexity
