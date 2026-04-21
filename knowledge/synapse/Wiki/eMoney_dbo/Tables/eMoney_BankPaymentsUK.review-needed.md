# Review Needed: eMoney_dbo.eMoney_BankPaymentsUK

**Generated**: 2026-04-21  
**Reviewer**: Data Engineering / eToro Money Analytics Team  
**Priority**: Medium

---

## Tier 4 Items (Unverified — Require Business Confirmation)

None. All 18 columns traced to SP code, Tribe reconciliation source data, or verified via live MCP sampling. T1 columns (AccountId, ExternalBankAccountId) verified against existing eMoney_dbo wikis.

---

## Open Questions

1. **BankActivityType CASE has 6 branches but only 4 live values**: The session context noted the SP has 6 CASE expression values. Live data shows only 4 distinct BankActivityType values (BankPayIns-External, BankPayOuts-External, BankPayOuts-DebitAdj, BankPayOuts-BankingReturn). Confirm: what are the 2 missing categories? Are they Internal Payment variants (BankPayIns-Internal, BankPayOuts-Internal) that have been filtered out by TransactionCode or Network conditions in the current data range?

2. **Data start date 2025-12-21**: The earliest Date in the table is 2025-12-21, suggesting the table was either first populated or fully reset in late December 2025. Confirm: does the table contain all historical UK bank payments from eTM launch, or is there a known data gap before 2025-12-21? If there is a gap, is there a prior source for older UK bank payment history?

3. **HolderId vs ProviderHolderID**: The column HolderId (int) appears to be the Tribe provider holder identifier. In other eMoney tables, this is named ProviderHolderID and classified as T1 from dbo.AccountsProviderHoldersMapping. Confirm: is HolderId here the same as ProviderHolderId in FiatDwhDB, and if so, should the description be updated to the T1 verbatim from that table?

4. **EpmMethodId always=4 in samples**: All sampled rows have EpmMethodId=4. Confirm: is EpmMethodId always 4 for UK bank payments (Faster Payments method), or is 4 just the dominant value and other EpmMethodId values can appear for edge cases (e.g., CHAPS, BACS)?

5. **Excluded TransactionCodes (6,14,15,24,25,64)**: The SP explicitly excludes these TransactionCodes from BankPaymentsUK. Confirm: what payment types do these codes represent and why are they excluded? Are they internal eToro-to-eToro transfers, fee transactions, or card-type transactions that shouldn't appear in a bank payment report?

---

## Validation Flags

- **BankPayOuts-DebitAdj and BankPayOuts-BankingReturn have positive HolderAmount**: Despite the "Outs" naming convention, these rows represent money returned TO the account. Any query that sums ALL "BankPayOuts" as money-out will overstate outflows. Always filter on `HolderAmount < 0` for true debits.
- **BankAccountNumber is PII**: Contains the counterparty UK bank account number. Verify that UC Gold export respects column-level masking requirements before exposing in Databricks.
- **No CID/GCID in this table**: Analysts who join to customer-level data must go via eMoney_Dim_Account (AccountId → AccountID → CID/GCID). This adds a join step not required for most other eMoney tables.
- **CCI reindex cost**: If large batch corrections require DELETE + re-INSERT of many rows, CCI deltastore fragmentation may accumulate. Confirm: is there a periodic ALTER INDEX REBUILD scheduled for this table?

---

## Cross-Object Consistency Check

| Shared Column | Source Description | This Wiki Description | Match? |
|--------------|----------------------------------------------|----------------------|--------|
| AccountId | eMoney_Dim_Account #2: "Auto-incrementing surrogate primary key..." | Verbatim copy (note column name casing differs: AccountId vs AccountID) | YES |
| ExternalBankAccountId | eMoney_Dim_Transaction #9: "Auto-incrementing surrogate primary key for external bank account record..." | Verbatim copy | YES |

---

*Review generated: 2026-04-21 | Object: eMoney_dbo.eMoney_BankPaymentsUK*
