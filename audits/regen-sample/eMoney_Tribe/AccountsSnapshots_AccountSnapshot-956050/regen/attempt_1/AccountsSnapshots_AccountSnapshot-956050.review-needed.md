# Review Needed: eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050

## Summary

This is a raw Tribe landing table with no upstream wiki available (`_no_upstream_found.txt` confirmed). All 20 business columns are Tier 3, grounded in DDL column names, live data samples, and SP_eMoney_Reconciliation_ETLs usage. 10 infrastructure columns are Tier 2 (Generic Pipeline).

## Items for Human Review

### 1. No Upstream Wiki — All Business Columns Are Tier 3

The production source FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 has no documented wiki in any upstream repo. If a FiatDwhDB wiki becomes available in the future, all 20 Tier 3 columns should be upgraded to Tier 1 with verbatim descriptions from the source.

### 2. AccountStatus Code Mapping — Verify Completeness

Observed 5 status codes from recent data: A=Active, S=Suspended, B=Blocked, P=Pending, R=Restricted. The "Active" label is confirmed from AccountStatusDescription sample data. Labels for S, B, P, R are inferred from common eMoney account status patterns and should be verified against the FiatDwhDB source system documentation.

### 3. ProgramId Values — Business Meaning Unknown

Observed values 175, 39, 177 in sample data. The business meaning of each ProgramId is not documented. A reviewer familiar with the eMoney platform should provide a mapping (e.g., 175=..., 39=..., 177=...).

### 4. BankAccounts Column — Appears Unused

The BankAccounts column is empty in all 10 sample rows. Bank account data appears to be stored in the sibling table AccountsSnapshots_BankAccounts-795870 instead. Confirm whether this column is deprecated or populated under specific conditions.

### 5. etr_y / etr_ym / etr_ymd — Mostly Empty

These ETL partition columns are empty in the sample data. They may only be populated for certain date ranges or loading patterns. Verify whether these are actively maintained or vestigial.

### 6. @AccountsSnapshots@Id-509416 — Appears Identical to @Id

In all sample rows, this column equals @Id. Confirm whether this is always the case or whether it can differ (e.g., for child records with a different parent mapping).

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 10 | @Created, @Id, @AccountsSnapshots@Id-509416, @WorkDate, etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date, Created |
| Tier 3 | 20 | FileDate, WorkDate, AccountId, HolderId, ProgramId, CurrencyIson, AvailableBalance, SettledBalance, AccountStatus, AccountStatusDescription, AccountStatusChangeDate, AccountStatusChangeSource, AccountStatusChangeReasonCode, AccountStatusChangeNote, AccountStatusChangeOriginatorId, DateUpdated, DateCreated, BankAccounts, ReservedBalance, HolderCountryIson |
| Tier 4 | 0 | — |
