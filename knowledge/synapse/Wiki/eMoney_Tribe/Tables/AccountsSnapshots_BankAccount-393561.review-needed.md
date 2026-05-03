# Review Needed: eMoney_Tribe.AccountsSnapshots_BankAccount-393561

## Summary

All 23 columns are **Tier 3** — no upstream production wiki was found (`_no_upstream_found.txt` confirmed). Descriptions are grounded in DDL structure, live data samples, and SP code analysis from `SP_eMoney_Reconciliation_ETLs`.

## Items for Human Review

### 1. BankAccountStatus Values

- Observed values: `A` (Active), `B` (Blocked), `S` (Suspended) — inferred from data patterns and common banking terminology.
- **Review**: Confirm the exact meaning of each status code with the eMoney/Tribe team. Are there additional statuses not seen in current data?

### 2. BankAccountBankProviderId Mapping

- Provider `3` is associated with UK accounts (MRMI BIC, GB IBAN prefix, sort codes present).
- Provider `4` is associated with Malta accounts (CFTE BIC, MT IBAN prefix, no sort code).
- **Review**: Confirm provider ID → provider name mapping. Are there other providers (1, 2, 5+)?

### 3. EpmMethodId Values

- Observed values: `4`, `5`, and empty/NULL.
- **Review**: Confirm what each EpmMethodId value represents (Electronic Payment Method). No dictionary/lookup table found.

### 4. PII Classification

- Columns containing PII: `BankAccountAccountName`, `BankAccountAccountNumber`, `BankAccountSortCode`, `BankAccountIban`, `BankAccountBic`.
- **Review**: Confirm PII tagging requirements for UC Bronze export. Should these columns be masked or tagged?

### 5. Sparse Columns

- `BankAccountBankStateBranch` and `BankAccountBankBranchCode` are entirely NULL in sampled data.
- `BankAccountStatusChangeReasonCode`, `BankAccountStatusChangeNote`, `BankAccountStatusChangeSource` are entirely empty in 2026 data.
- `etr_y`, `etr_ym`, `etr_ymd` are frequently NULL in recent data.
- **Review**: Are these columns deprecated or only populated for specific providers/regions?

### 6. Row Count Growth

- ~1.6B rows and growing daily (append strategy, full snapshots).
- **Review**: Is there a retention policy? Should historical snapshots be pruned or archived?

### 7. No Upstream Wiki

- `_no_upstream_found.txt` marker present. The production source (`FiatDwhDB.Tribe`) has no wiki documentation.
- **Review**: Consider creating an upstream wiki for the Tribe platform bank account entities to enable Tier 1 inheritance in future iterations.

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 3 | 23 | All columns — no upstream wiki available |
