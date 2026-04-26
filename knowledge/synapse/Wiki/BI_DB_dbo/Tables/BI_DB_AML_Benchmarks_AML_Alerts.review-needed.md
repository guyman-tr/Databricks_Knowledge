---
object: BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AML_Benchmarks_AML_Alerts

## Tier 4 Items / Uncertainties

1. **CID (Tier 4)**: Source system unknown. If a writer SP or external integration is identified, upgrade to Tier 2 or Tier 3.

2. **GCID (Tier 4)**: Source system unknown. Description adopted from Dim_Customer wiki ("Group Customer ID — cross-product identity key"). Tier 4 because source is external/unknown for this table.

3. **AMLAlert_ChangeDateTime (Tier 4)**: The "change" this timestamp refers to — is it when an AML officer manually flagged the customer in the AML tool, or when the system automatically applied the status change in Synapse? Confirm with AML compliance team.

4. **Table purpose — "Benchmarks"**: The AML benchmarking use case is inferred from the table name. Confirm: does this table drive an AML effectiveness dashboard or report? Is it used in combination with BI_DB_AML_Benchmarks_Risk_Classification?

5. **Writer mechanism**: No SSDT SP writes to this table. Is it populated by: (a) a direct push from an AML case management tool (e.g., NICE Actimize), (b) a manual CSV upload, (c) a Fivetran connector, or (d) something else?

## Questions for Domain Experts

- What system populates this table? (Confirm the "Ext" writer)
- Is this table actively maintained or decommissioned?
- What is the "benchmark" being measured — rate of AML alerts → status changes? Time-to-action?
- Are both tables (AML_Alerts + Risk_Classification) always populated together as a pair?

## No Cross-Object Corrections Needed

PlayerStatus values confirmed from live Dim_PlayerStatus (16 distinct values). PlayerStatusID mapping inline in the Elements table is accurate.
