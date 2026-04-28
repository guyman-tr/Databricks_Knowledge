# DWH_dbo.Dim_AccountType — Review Needed

## Upstream Bundle Mismatch

The regen harness resolved `Dictionary.AccountType` to `USABroker.Dictionary.AccountType` (Apex Clearing brokerage types: CASH, MARGIN, OPTION). This is **incorrect** — the SP reads from `DWH_staging.etoro_Dictionary_AccountType`, which traces to `etoro.Dictionary.AccountType` (eToro account classification: Private, Corporate, IB, Fund, etc.). The writer used the correct upstream wiki at `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md` instead of the bundle-provided USABroker wiki.

**Action**: Update the harness upstream resolution logic to prefer `etoro.Dictionary.AccountType` over `USABroker.Dictionary.AccountType` when the staging table name contains `etoro_`.

## AccountTypeID=18 (Trust) — Not in Upstream Wiki

Live data contains AccountTypeID=18 with Name='Trust'. The upstream wiki (`etoro.Dictionary.AccountType`, generated 2026-03-13) documents types 1-17 only. This is likely a recently added account type.

**Action**: Regenerate the upstream wiki for `etoro.Dictionary.AccountType` to capture the Trust account type, then update this wiki's Tier 1 descriptions if the upstream adds new detail.

## Relationships Section — Incomplete

Section 6.2 lists only generic references (`Dim_Customer`, `Various Fact_* tables`). A full dependency scan of the DWH schema was not performed in this single-object regen run. The upstream wiki documents 12+ consuming objects in production — the DWH equivalents should be enumerated.

**Action**: During the next full batch run, enrich Section 6.2 with specific Fact table and view references from the DWH schema.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | AccountTypeID, Name |
| Tier 2 | 4 | DWHAccountTypeID, StatusID, UpdateDate, InsertDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
