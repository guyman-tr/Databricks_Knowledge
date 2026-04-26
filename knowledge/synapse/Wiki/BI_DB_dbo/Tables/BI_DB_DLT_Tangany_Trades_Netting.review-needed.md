# BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting — Review Needed

## Tier 4 Items
None — all columns traced to SP code or upstream DWH wikis.

## Reviewer Questions

1. **SP code typo**: Line 151 has `FROM #closedPrep p1 p` — the `p1` alias appears to be a leftover typo. The SP compiles and runs correctly (p is the effective alias). Not a data issue.

2. **Change history date typo**: The change log entry for "add MicaCustomer (5)" is dated `2055-12-04` — clearly should be `2025-12-04`.

3. **DltID source inconsistency**: Opens get DltID from `Fact_SnapshotCustomer.DltID`, closes get it from `Dim_Customer.DltID`. These could differ slightly due to timing. Is this intentional?

4. **TanganyStatusID IN (2,3,5)**: Why are statuses 1 and 4 excluded? Status 5 was added for MiCA customers. Confirm the business logic for which statuses are Tangany-eligible.

5. **All amounts negative**: Both opens and closes are -1 * Amount. This means SUM always gives a negative number. Is the intention that external (Tangany) records use positive amounts, and the difference between SUM(this) + SUM(external) = 0 for a balanced reconciliation?

6. **Column count**: Batch assignment listed 20 columns; DDL has 19 (one fewer).

## Data Quality Notes
- ActionType distribution (2026): Close 51.8%, Open 48.2% — reasonable for active crypto market
- IsDLTUser: 96.6% = 0, 3.4% = 1 — DLT adoption is still a small fraction
- IsCoinsTransferedOut: 968 events (0.02%) — very rare transfer-out activity
- CloseReason top 3: Customer (39.8%), Hierarchical Close (28.5%), Manual Unregister (15.3%)
