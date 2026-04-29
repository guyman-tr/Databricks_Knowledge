# BI_DB_dbo.BI_DB_All_Deposit_Hourly -- Review Needed

## Dormant Table Assessment

- **Status**: 0 rows, no writer SP, fully orphaned
- **Actual column count**: 126 (orchestrator estimate was 117)
- **Recommendation**: Consider DROP -- massive 126-column table with full PSP response payload has never been populated in Synapse
- **PII concern**: ~20 columns contain PII data (names, addresses, card numbers, IBANs, emails, phone numbers, IP addresses) -- if ever populated, requires PII masking and access controls
- **Security concern**: SecretKeyAsString and SecuredCardDataAsString columns would hold sensitive security tokens

## Tier 4 Items (All Columns)

All 125 non-ETL columns are Tier 4 (inferred from column names). No upstream wiki, no SP code, no live data to verify against. Descriptions are based on:
1. Column naming conventions (standard payments/PSP terminology)
2. `*AsString`/`*AsDecimal`/`*AsInteger` naming pattern (dynamically extracted PSP response fields)
3. Domain knowledge of payment processing (3DS, BIN, ACH, Plaid, IBAN, SWIFT)

## Questions for Reviewer

1. **Was this table populated on-prem?** What was the source (likely Billing.Deposit + PSP API response parsing)?
2. **Relationship to BI_DB_AllDeposits_Tempalte**: Is this the hourly variant of the template table? Which came first?
3. **Has deposit reporting moved?** Possible destinations: Databricks payment analytics, direct PSP dashboards, compliance reporting tools
4. **Should PSP response fields be a separate table?** The ~80 PSP fields could be a response detail table linked by DepositID rather than denormalized
5. **Category column**: Only varchar(9) -- what are the possible values?
6. **DepotID**: Is this a sub-account ID for multi-account customers?

## Column Name Issues

- **Spaces in names**: Many columns use spaces (e.g., `[Amount In Orig Curr]`, `[Country (customer)]`) -- non-standard, requires bracket quoting
- **Inconsistent *AsString suffix**: Some later columns (99-123) switch from varchar to nvarchar, suggesting they were added from a different PSP provider's response schema

## Cross-Object Consistency

- Related: BI_DB_AllDeposits_Tempalte (126 cols, also dormant -- likely the template/master version)
