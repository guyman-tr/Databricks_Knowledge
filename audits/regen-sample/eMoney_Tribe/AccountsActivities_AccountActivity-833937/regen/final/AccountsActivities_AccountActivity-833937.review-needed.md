# Review Needed: eMoney_Tribe.AccountsActivities_AccountActivity-833937

## Summary

All 116 columns are Tier 3 — grounded in DDL structure and live data sampling but lacking any upstream wiki documentation. The eMoney Platform (GPS/Modulr) is an external card issuing platform with no documented production wiki in the repository.

## Items Requiring Human Review

### 1. All Columns Are Tier 3 — No Upstream Wiki Available

- **Issue**: `_no_upstream_found.txt` is present. No upstream wiki exists for the eMoney card platform (GPS/Modulr). All 116 column descriptions are derived from DDL column names, sample data patterns, and SP usage context.
- **Action**: If internal documentation for the GPS/Modulr API schema exists (e.g., vendor API docs, Confluence pages), use it to upgrade column descriptions to Tier 1.

### 2. PII Columns — Data Classification Review

- **Columns**: CardNumber, BankAccountNumber, BankAccountSortCode, BankAccountIban, BankAccountBic, ExternalIban, ExternalBban, ExternalAccountName, ExternalAccountNumber, ExternalSortCode, ExternalBIC, OriginatorName, MasterAccountIban
- **Issue**: These columns contain personally identifiable financial information (card numbers, IBANs, account names). Confirm that appropriate data masking/classification policies are in place.

### 3. Duplicate Created Columns

- **Columns**: `@Created` (datetime2(7)) and `Created` (datetime2(7))
- **Issue**: Both columns appear to store record creation timestamps with minor precision differences. Confirm which is the authoritative creation timestamp and whether the duplicate is intentional.

### 4. Duplicate WorkDate Columns

- **Columns**: `WorkDate` (varchar(max)) and `@WorkDate` (datetime2(7))
- **Issue**: Same data in two types. Confirm if both are needed or if the varchar version is a legacy artifact from the Parquet ingestion.

### 5. TransactionCode Mapping Completeness

- **Observed values**: 1=LOAD, 2=POS, 4=UNLOAD, 56=EPM_OUTBOUND, 57=EPM_INBOUND
- **Issue**: These mappings were inferred from sample data. There may be additional TransactionCode values not captured in the sample. Confirm the complete enumeration with the eMoney platform team.

### 6. LoadType Values

- **Observed values**: '1' (~71%), '' (empty, ~29%), '2' (<0.1%), '0' (rare)
- **Issue**: The meaning of LoadType values (0, 1, 2) is not documented. Confirm with the eMoney platform team.

### 7. EpmMethodId Values

- **Observed values**: 4 (UK Faster Payments inferred), 5 (SEPA inferred)
- **Issue**: The mapping of EpmMethodId to payment method is inferred from currency and country patterns. Confirm the complete enumeration.

### 8. UC Migration Status

- **Current**: _Not_Migrated
- **Action**: Determine if this table should be migrated to Unity Catalog. Given its ~29.7M rows and growing volume, consider partitioning strategy for UC.

## Confidence Assessment

| Metric | Value |
|--------|-------|
| Tier 1 columns | 0 |
| Tier 2 columns | 0 |
| Tier 3 columns | 116 |
| Tier 4 columns | 0 |
| Elements documented | 116/116 |
| Upstream wiki available | No |
| SP code reviewed | Yes (SP_eMoney_FiatDwhETL — generic SELECT * loader) |
