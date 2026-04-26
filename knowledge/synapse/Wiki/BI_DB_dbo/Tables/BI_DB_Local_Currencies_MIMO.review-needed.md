# BI_DB_dbo.BI_DB_Local_Currencies_MIMO — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **USD Amount for cashouts**: For cashouts, USD Amount = raw currency amount (not converted to USD). The column name is misleading. Is this intentional?
2. **FX Cost exclusion currencies**: CHF, NOK, SEK, PLN, HUF, DKK, CZK, RON have FX Cost = 0. Why are these excluded from the cost calculation?
3. **IND pluralization**: 'Deposits' vs 'Cashout' -- inconsistent naming. Should this be standardized?
4. **Deposit FX Income calculation change (2025-05-15)**: Markos Chris changed the deposit FX income formula. Is the current formula stable, or are there pending adjustments?
5. **Cashout FX Income uses BI_DB_DepositWithdrawFee**: The withdrawal FX rates come from a separate table with TransactionID substring matching. Is this join reliable for all withdrawal records?
