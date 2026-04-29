# Review Needed: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals

## Open Questions for Reviewer

1. **"Partialy Reversed" spelling in TransactionStatus**: This appears in live data (4 rows in 2026). Is this a known production typo in Fact_Cashout_State preserved for backward compatibility, or should it be corrected at source?
2. **MOPCountry / IsGermanBaFin / CreditTypeID**: All three are NULL literals in the current SP. Should these columns be deprecated from the DDL, or are they reserved for future implementation?
3. **LabelID source inconsistency**: On the deposit path, LabelID comes from `Dim_Customer.LabelID` (current state); on the withdraw path, it comes from `Fact_SnapshotCustomer.LabelID` (point-in-time). This means deposit reversals use the customer's current label while withdraw rollbacks use the label at reversal time. Is this intentional?
4. **RegCountry source inconsistency**: Similar to LabelID — deposit path uses `Dim_Customer.CountryID` (current) while withdraw path uses `Fact_SnapshotCustomer.CountryID` (point-in-time). Confirm whether this divergence is intentional.

## Validation Notes

- All 45 columns documented; 0 Tier 4 items
- Column names and types verified against DDL
- All transforms traced through SP_DepositWithdrawFee source code (full SP in bundle)
- Amount sign logic validated against #amountDirections table and edge-case UPDATE patterns
- ExchangeFeePercentage (column 45) confirmed present in live data and SP code (added SR-359957, 2026-03-04)
- Tier 1 count: 11 columns (dim-lookup passthroughs with production dictionary origins)
- Tier 2 count: 34 columns (SP-computed, snapshot lookups, state fact passthroughs)
- Bundle inheritance: YES (19 upstream wikis used for tier assignments and description inheritance)
