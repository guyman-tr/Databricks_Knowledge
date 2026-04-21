# eMoney_Dim_Transaction — Review Needed

> Sidecar checklist for wiki reviewer. All wiki content is in `eMoney_Dim_Transaction.md`.

## Open Questions

| # | Column | Question | Priority |
|---|--------|----------|---------|
| 1 | PaymentSchemaTypeID | IDs 8 and 10 exist in data with NULL PaymentSchemaType names. What payment schemes do these represent? Are they legacy/deprecated schemes or newly added ones missing from the dictionary? | Medium |
| 2 | ProviderTransactionID | DDL type is float — is this intentional or a legacy DDL artifact? Float equality is unreliable; should this be bigint? Affects ProviderTransactionID NCI usage and reconciliation queries. | High |
| 3 | TxClientBalanceCategory | SP has a CASE expression mapping 14 TxTypeID values to 9 category labels. The exact label strings were not confirmed via live MCP query. Confirm the 9 label values are stable and complete. | Medium |
| 4 | AuthorizationTypeID | 13 possible values confirmed via dictionary table query, but the actual value-to-name mapping was not fully enumerated in the wiki. Confirm values 1-13 and their names for completeness. | Low |
| 5 | ClubIDTxDate / RegulationIDTxDate etc. | Snapshot customer attributes use Fact_SnapshotCustomer at TxLocalDateID range. Confirm: for early transactions (2020-2021) where no snapshot exists, are these columns NULL or does the join fall back to current Dim_Customer values? | Medium |
| 6 | SourceCugTransactionID | Added 2025-09-08. Confirm: what is a CUG transaction? (Crypto-to-Fiat path?) What is the FK target for this ID — is it a table in CryptoDBs or FiatDwhDB? | Medium |
| 7 | IsValidCustomer | Described as snapshot-at-TxDate (from Fact_SnapshotCustomer Step 08). Confirm this is truly snapshot-in-time and not the current Dim_Customer.IsValidCustomer — the SP Step 08 joins Fact_SnapshotCustomer at TxLocalDateID range, but verify the join correctly filters to the right date range for all transaction years. | High |
| 8 | DKK NULL USD approx | DKK (ISO 208) confirmed as having no Fact_CurrencyPriceWithSplit instrument. Confirm: is DKK the ONLY currency missing from the USD approx pipeline, or are there other currencies with NULL USDAmountApprox? | Low |

## Tier 1 Copy Verification

| Column | Upstream Source | Upstream Word Count (approx) | Wiki Word Count (approx) | Status |
|--------|----------------|------------------------------|--------------------------|--------|
| AccountID | FiatAccount.Id | 20 | 20 + relay note | IDENTICAL |
| GCID | FiatAccount.Gcid | 40 | 40 + relay note | IDENTICAL |
| CID | Dim_Customer.RealCID (Customer.CustomerStatic) | 20 | 20 + relay note | IDENTICAL |
| CardID | FiatCards.Id | 21 | 21 + relay note | IDENTICAL |
| CurrencyBalanceID | FiatCurrencyBalances.Id | 28 | 28 + relay note | IDENTICAL |
| ExternalBankAccountID | FiatBankAccount.Id | 10 | 10 + relay note | IDENTICAL (PK only — Id not separately documented in FiatBankAccount wiki beyond "Auto-incrementing surrogate primary key") |
| AccountProgramID | FiatAccount.AccountProgramId | 25 | 25 + DWH note | IDENTICAL |
| AccountSubProgramID | FiatAccount.SubProgramId | 22 | 22 + DWH note | IDENTICAL |

## Items Confirmed by Reviewer

- [ ] PaymentSchemaTypeID values 8 and 10 identified and documented
- [ ] ProviderTransactionID float type confirmed or flagged as data quality issue
- [ ] TxClientBalanceCategory 9 label values confirmed
- [ ] AuthorizationTypeID full 1-13 value mapping confirmed
- [ ] SourceCugTransactionID FK target confirmed
- [ ] IsValidCustomer confirmed as snapshot-in-time (not current)
- [ ] DKK-only NULL USD approx confirmed (no other currencies affected)

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Completeness (all 77 cols documented) | 9/10 | All 77 element rows present with tier tags |
| Tier accuracy (T1 vs T2 correct) | 9/10 | 8 T1 from FiatDwhDB wikis (FiatAccount, FiatCards, FiatCurrencyBalances, FiatBankAccount); FiatTransactions/FiatTransactionsStatuses have no wikis — all their direct columns correctly Tier 2 |
| Upstream inheritance (copy fidelity) | 9/10 | Verbatim copy from 4 FiatDwhDB wikis + Customer.CustomerStatic (via Dim_Customer); relay notes added |
| Business logic (logic sections complete) | 9/10 | 5 subsections covering grain, snapshot-vs-current temporal split, USD approx, IsTxSettled, and TxType/Category |
| Query advisory (gotchas documented) | 9/10 | 8 gotchas; ProviderTransactionID float warning; DKK USD approx NULL; temporal mismatch noted |
| Source fidelity (SP code aligned) | 9/10 | All 11 SP steps traced; Step 10 vs Step 11 divergence explicitly documented |
| **Overall** | **8.8/10** | **PASS (threshold 7.5)** |
