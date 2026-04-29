# BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **External source provenance**: Same as Closed_To_IBAN — confirm where the finance BI output pipeline produces the external parquet file.
2. **R&D design flaw**: Same dedup fix as Closed_To_IBAN (2025-07-21). Confirm permanent vs temporary workaround.

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- Companion to BI_DB_Positions_Closed_To_IBAN (Object #6). Same SP structure, same dedup logic.
- Closed uses WithdrawPaymentID → Fact_BillingWithdraw; Opened uses DepositID → Fact_BillingDeposit.
