# DWH_dbo.Dim_AccountType — Review Needed

## Upstream Bundle Mismatch

The regen harness resolved `Dictionary.AccountType` to `USABroker.Dictionary.AccountType` (Apex Clearing brokerage types: CASH, MARGIN, OPTION). This is **incorrect** — the SP reads from `DWH_staging.etoro_Dictionary_AccountType`, which traces to `etoro.Dictionary.AccountType` (eToro account classification: Private, Corporate, IB, Fund, etc.). No `etoro.Dictionary.AccountType` wiki exists on disk in any repo.

**Action**: Create the upstream wiki for `etoro.Dictionary.AccountType` in the DB_Schema pipeline. Once that wiki exists, re-run this object to upgrade AccountTypeID and Name from Tier 3 to Tier 1 with verbatim inherited descriptions.

## AccountTypeID and Name — Tier 3 (No Upstream Wiki)

Both columns are passthrough/rename from `etoro.Dictionary.AccountType`, but no upstream wiki exists for that table. The bundle-provided `USABroker.Dictionary.AccountType` is a completely different system (Apex Clearing, 3 rows: CASH/MARGIN/OPTION) and cannot be used as a Tier 1 source. Descriptions are grounded in SP code analysis and live data sampling instead.

**Action**: Generate `etoro.Dictionary.AccountType` wiki in DB_Schema pipeline, then update these columns to Tier 1.

## AccountTypeID=18 (Trust) — Not in Bundle Upstream

Live data contains AccountTypeID=18 with Name='Trust'. The USABroker upstream wiki (wrong system) only documents 3 types. The etoro source likely has all 18 types but no wiki exists to confirm the business meaning of Trust.

**Action**: When the etoro.Dictionary.AccountType wiki is created, verify Trust account type documentation.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 4 | DWHAccountTypeID, StatusID, UpdateDate, InsertDate |
| Tier 3 | 2 | AccountTypeID, Name |
| Tier 4 | 0 | — |
