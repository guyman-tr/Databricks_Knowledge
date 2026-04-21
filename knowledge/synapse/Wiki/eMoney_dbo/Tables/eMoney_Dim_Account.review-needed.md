# eMoney_Dim_Account — Review Needed

> Sidecar checklist for wiki reviewer. All wiki content is in `eMoney_Dim_Account.md`.

## Open Questions

| # | Column | Question | Priority |
|---|--------|----------|---------|
| 1 | GCID_Unique_Count | Confirm: is GCID_Unique_Count=1 always the "primary" account for analytics, or is there a business case to use non-primary rows? The SP only enriches rank=1 with DWH customer data. | Medium |
| 2 | TP_FTDDate | Sentinel: does '19000101' (Dim_Customer.FirstDepositDate default) propagate to TP_FTDDate for non-depositors? Seniority_TP_FTDDate would be anomalously large in that case. | Medium |
| 3 | BankAccountNumber / BankAccountSortCode | DDL types are int but FiatBankAccount stores nvarchar(128) MASKED. Confirm type conversion: are leading zeros lost on cast to int? (e.g., UK sort code "040004" → 40004) | High |
| 4 | Entity | NULL entity rows (mapped to 'N/A'): what do these represent? Missing ISO code mapping in eMoney_EntityByCurrencyISO_MappingStatic, or new currencies added after the static table was last updated? | Low |
| 5 | AccountPropertiesTime / AccountPropertiesDate | NULL when no FiatAccountsProperties record exists (left join). Does this represent accounts that predate the properties tracking, or newly created accounts before first program assignment? | Low |
| 6 | CurrencyBalanceStatusID | FiatCurrencyBalancesStatuses has no FiatDwhDB wiki; values confirmed via live MCP query (0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked). Verify these are stable / not subject to change. | Low |
| 7 | IsTestAccount | Fivetran Google Sheets source (eMoney_google_sheets.emoney_test_users): how frequently is the sheet updated? Are there test GCIDs that exist in the platform but were never added to the sheet? | Low |
| 8 | SubPrograms table | The SP was updated 2025-08-05 by Shachar Rubin to use eMoney_dbo.SubPrograms instead of eMoney_Dictionary_AccountSubProgram. Confirm eMoney_Dictionary_AccountSubProgram is still present in schema (listed as active in _index.md) but no longer the source for AccountSubProgram/RegAccountSubProgram. | Medium |

## Tier 1 Copy Verification

| Column | Upstream Source | Upstream Word Count (approx) | Wiki Word Count (approx) | Status |
|--------|----------------|------------------------------|--------------------------|--------|
| CurrencyBalanceID | FiatCurrencyBalances.Id | 20 | 20 | IDENTICAL |
| AccountID | FiatAccount.Id | 12 | 12 | IDENTICAL |
| GCID | FiatAccount.Gcid | 24 | 24 | IDENTICAL |
| CID | Dim_Customer.RealCID | 20 | 20 + rename note | IDENTICAL (note added) |
| ClubID | Dim_Customer.PlayerLevelID | 18 | 18 + rename note | IDENTICAL (stat stripped: "(94%)", note added) |
| RegulationID | Dim_Customer.RegulationID | 17 | 17 | IDENTICAL (snapshot stats kept — not row counts) |
| CountryID | Dim_Customer.CountryID | 17 | 17 | IDENTICAL |
| PlayerStatusID | Dim_Customer.PlayerStatusID | 20 | 20 (stat stripped: "(97.5% of accounts)") | IDENTICAL |
| TP_RegDate | Dim_Customer.RegisteredReal | 8 | 8 + DWH note | IDENTICAL (DWH note added for CAST) |
| CurrencyBalanceISOCode | FiatCurrencyBalances.CurrencyISON | 13 | 13 | IDENTICAL (link stripped) |
| CurrencyBalanceCreateTime | FiatCurrencyBalances.Created | 13 | 13 + rename note | IDENTICAL |
| AccountStatusID | FiatAccountStatuses.StatusType | 7 | 7 | IDENTICAL |
| AccountProgramID | FiatAccount.AccountProgramId | 13 | 13 + DWH note | IDENTICAL |
| AccountSubProgramID | FiatAccount.SubProgramId | 16 | 16 + DWH note | IDENTICAL (link stripped) |
| BankAccountIsExternal | FiatBankAccount.IsExternal | 22 | 22 | IDENTICAL |
| BankAccountName | FiatBankAccount.FullName | 16 | 16 + rename note | IDENTICAL |
| BankAccountNumber | FiatBankAccount.BankAccountNumber | 13 | 13 | IDENTICAL |
| BankAccountSortCode | FiatBankAccount.SortCode | 18 | 18 | IDENTICAL |
| BankAccountIBAN | FiatBankAccount.Iban | 16 | 16 | IDENTICAL |
| BankAccountBIC | FiatBankAccount.Bic | 13 | 13 | IDENTICAL |
| AccountCreateTime | FiatAccount.Created | 13 | 13 + rename note | IDENTICAL |
| CardID | FiatCards.Id | 14 | 14 | IDENTICAL |
| CardCreateTime | FiatCards.Created | 13 | 13 + rename note | IDENTICAL |
| CardStatusID | FiatCardStatuses.CardStatusId | 8 | 8 + expanded values | EXPANDED (added 0-8 values from Business Logic section) |
| CardStatusExpirationTime | FiatCardStatuses.ExpirationDate | 9 | 9 | IDENTICAL |
| CardStatusTime | FiatCardStatuses.EventTimestamp | 9 | 9 | IDENTICAL |

## Items Confirmed by Reviewer

- [ ] BankAccountNumber/SortCode int type coercion confirmed (or flagged as data quality issue)
- [ ] GCID_Unique_Count=1 is the correct primary account filter for analytics
- [ ] TP_FTDDate sentinel behavior verified
- [ ] Entity 'N/A' rows confirmed as mapping gap (acceptable)
- [ ] IsTestAccount Fivetran refresh cadence confirmed

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Completeness (all 89 cols documented) | 9/10 | All 89 element rows present with tier tags |
| Tier accuracy (T1 vs T2 correct) | 9/10 | 29 T1 columns from FiatDwhDB/Dim_Customer; all change flags/derived cols correctly T2 |
| Upstream inheritance (copy fidelity) | 9/10 | Verbatim copy from 6 FiatDwhDB wikis + Dim_Customer; stats stripped; rename notes added |
| Business logic (logic sections complete) | 9/10 | 5 subsections covering grain, GCID_Unique_Count filter, current/reg duality, IsValidETM, program changes |
| Query advisory (gotchas documented) | 9/10 | 7 gotchas listed; distribution key noted; common JOINs table present |
| Source fidelity (SP code aligned) | 9/10 | All 11 SP steps traced; column sources confirmed against actual SP code |
| **Overall** | **8.8/10** | **PASS (threshold 7.5)** |
