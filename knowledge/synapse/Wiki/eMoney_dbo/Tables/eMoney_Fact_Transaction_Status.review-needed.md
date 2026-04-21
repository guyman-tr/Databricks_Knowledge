# eMoney_Fact_Transaction_Status — Review Needed

> Sidecar checklist for wiki reviewer. All wiki content is in `eMoney_Fact_Transaction_Status.md`.

## Open Questions

| # | Column | Question | Priority |
|---|--------|----------|---------|
| 1 | FiatTransactionStatusRunningID | Confirm: FiatTransactionsStatuses.Id is a true surrogate PK (no gaps, always populated, truly unique per row in the source table). The wiki treats it as the unique row key for this table. | High |
| 2 | CountStatusChanges | Denormalized field: same MAX(RNDesc) value appears on ALL rows for a given TransactionID. Confirm analysts understand this and won't accidentally sum CountStatusChanges across rows for the same transaction. | Medium |
| 3 | (Shared with Dim_Transaction) PaymentSchemaTypeID | IDs 8 and 10 with NULL names — same question as in eMoney_Dim_Transaction.review-needed.md. Both tables need the same answer. | Medium |
| 4 | (Shared with Dim_Transaction) ProviderTransactionID | Float type — same question as in eMoney_Dim_Transaction.review-needed.md. | High |
| 5 | Row count delta (~3.7M) | Confirm the ~3.7M row delta between this table and eMoney_Dim_Transaction. Does this accurately reflect the number of multi-status transactions, or could there be other causes (duplicates from SP rerun partial failures, etc.)? | Medium |
| 6 | CLUSTERED COLUMNSTORE INDEX | No NCIs on this table. Confirm: are there any known performance issues with this table in production? Are there analytic workloads that would benefit from adding a secondary NCI (e.g., on TxStatusModificationDateID or TransactionID)? | Low |
| 7 | (Shared with Dim_Transaction) SourceCugTransactionID | Same open question as Dim_Transaction — CUG system FK target not confirmed. | Medium |
| 8 | (Shared with Dim_Transaction) IsValidCustomer | Same snapshot-in-time confirmation needed — see eMoney_Dim_Transaction.review-needed.md #7. | High |

## Tier 1 Copy Verification

Tier 1 columns are identical to eMoney_Dim_Transaction (same 8 columns, same upstream sources, same copy fidelity). See `eMoney_Dim_Transaction.review-needed.md` for the full T1 Copy Verification table.

| Column | Upstream Source | Status |
|--------|----------------|--------|
| AccountID | FiatAccount.Id | IDENTICAL to Dim_Transaction |
| GCID | FiatAccount.Gcid | IDENTICAL to Dim_Transaction |
| CID | Customer.CustomerStatic (via Dim_Customer) | IDENTICAL to Dim_Transaction |
| CardID | FiatCards.Id | IDENTICAL to Dim_Transaction |
| CurrencyBalanceID | FiatCurrencyBalances.Id | IDENTICAL to Dim_Transaction |
| ExternalBankAccountID | FiatBankAccount.Id | IDENTICAL to Dim_Transaction |
| AccountProgramID | FiatAccount.AccountProgramId | IDENTICAL to Dim_Transaction |
| AccountSubProgramID | FiatAccount.SubProgramId | IDENTICAL to Dim_Transaction |

## Items Confirmed by Reviewer

- [ ] FiatTransactionStatusRunningID confirmed as unique PK of FiatTransactionsStatuses source table
- [ ] CountStatusChanges denormalization behaviour understood by analytics consumers
- [ ] Row count delta (~3.7M) confirmed as expected multi-status inflation
- [ ] No known performance issues with CLUSTERED COLUMNSTORE (or NCI gaps documented)
- [ ] PaymentSchemaTypeID values 8 and 10 identified (shared with Dim_Transaction)
- [ ] ProviderTransactionID float type confirmed (shared with Dim_Transaction)

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Completeness (all 77 cols documented) | 9/10 | All 77 element rows present with tier tags |
| Tier accuracy (T1 vs T2 correct) | 9/10 | 8 T1 from FiatDwhDB wikis; FiatTransactions/FiatTransactionsStatuses correctly Tier 2; FiatTransactionStatusRunningID correctly Tier 2 (no FiatTransactionsStatuses wiki) |
| Upstream inheritance (copy fidelity) | 9/10 | Verbatim identical to Dim_Transaction for shared columns; SHARED COLUMN = SAME DESCRIPTION rule applied |
| Business logic (logic sections complete) | 9/10 | 4 subsections covering full-history grain, snapshot-vs-current, USD approx per event, FiatTransactionStatusRunningID row key |
| Query advisory (gotchas documented) | 9/10 | 8 gotchas including columnstore NCI absence, IsTxSettled missing, double-counting warning, DKK NULL |
| Source fidelity (SP code aligned) | 9/10 | Step 11 correctly documented as NO RNDesc filter; FiatTransactionStatusRunningID sourced from FiatTransactionsStatuses.Id confirmed via SP line 174 |
| **Overall** | **8.8/10** | **PASS (threshold 7.5)** |
