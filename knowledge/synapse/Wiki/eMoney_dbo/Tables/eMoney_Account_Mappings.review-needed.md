# Review Needed: eMoney_dbo.eMoney_Account_Mappings

**Generated**: 2026-04-21 | **Batch**: 13 | **Reviewer**: TBD

## Tier 4 Items (Require Verification)

None — all columns resolved via FiatDwhDB upstream wikis (Tier 1) or SP code analysis (Tier 2).

## PII / Sensitive Data Flags

| Column | Risk | Note |
|--------|------|------|
| BankAccountName | HIGH — PII (account holder name) | DDM-masked in FiatDwhDB; no DDM in Synapse |
| BankAccountNumber | HIGH — PII (account number) | DDM-masked in source; CAST to INT in DWH |
| BankAccountIBAN | HIGH — PII (IBAN) | DDM-masked in source; 40,407 NULLs |
| BankAccountSortCode | MEDIUM — banking identifier | UK only; NULL for non-UK |

**Reviewer action required**: Confirm that access controls in Synapse / Unity Catalog restrict PII columns appropriately. Masking policies should mirror FiatDwhDB's DDM.

## Known Flags / Anomalies

- **DELETE + INSERT** (not TRUNCATE + INSERT): Unusual pattern. TRUNCATE resets identity; DELETE does not. Confirm if this is intentional (e.g., to preserve identity state for FK constraints).
- **Latest card only**: Historical card replacements are NOT tracked here; only the most recently created card per account is retained.
- **Latest bank account only**: Latest by EventTimestamp per CurrencyBalanceId. Historical bank account changes are not captured.
- **227 NULL ProviderDesc rows**: Currency balances not yet mapped to a provider. May grow as new accounts are provisioned faster than provider assignment.

## Tier 2 Items Requiring Business Context Confirmation

| Column | Question |
|--------|----------|
| ProviderDesc | Confirm 'Tribe' is the only expected provider; flag if any new providers are added |
| AccountProgram / AccountSubProgram | Confirm the JOIN to eMoney_Dictionary tables correctly resolves all IDs |

## Reviewer Checklist

- [ ] Confirm DELETE+INSERT pattern is intentional and appropriate for this table
- [ ] Confirm PII columns have access controls in UC / Synapse
- [ ] Confirm UC target: bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings
- [ ] Validate CurrencyBalanceISON values: 978=EUR, 826=GBP, 36=AUD, 208=DKK — check if any other currencies exist
- [ ] Confirm GCID not unique (multi-currency customers have multiple rows) — ensure consumers handle this correctly
