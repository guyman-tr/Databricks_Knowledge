# BI_DB_dbo.BI_DB_CIDFirstDates_metric_view — Review Needed

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None flagged in Elements — expression-level mappings are anchored on `BI_DB_CIDFirstDates.md`.

## Columns Needing Clarification

- Exact Lakehouse/Catalog SQL definition of METRIC_VIEW (not surfaced on connected Synapse; confirm view text matches column renames Club→ClubName, CID→CustomerID).

## Structural Questions

- Roster UC path `main.bi_db...` vs live `main.pii_data...` METRIC_VIEW: confirm authoritative catalog for deployments.
