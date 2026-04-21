# Review Needed: eMoney_dbo.eMoney_Currency_Mapping_ISO

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Static Reference)

## Status

No critical Tier 4 items. Manually maintained ISO 4217 reference table with no automated refresh. Key risk: unmapped currency codes cascade nulls into instrument resolution and USD price conversion in SP_eMoney_DimFact_Transaction.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | No automated refresh | WARN | Table was manually bulk-loaded 2024-06-24. If ISO 4217 is updated or if FiatTransactions introduces new currency codes, this table will have gaps. Schedule periodic review of unmapped codes. |
| 2 | Unmapped currency codes cascade nulls | WARN | Any FiatTransactions.TransactionCurrencyIso not present in CurrencyNumericCode_ISO will produce null CurrencyAlphaThreeCode → null InstrumentID → null USD conversion in the fact table. Monitor SP_eMoney_DimFact_Transaction for null USD amounts. |
| 3 | Leading-zero numeric codes | INFO | CurrencyNumericCode_ISO is varchar(20). Some ISO codes have leading zeros (e.g., '008' = ALL - Albanian Lek). Confirm FiatTransactions stores numeric currency codes with consistent zero-padding. |
| 4 | Fact_CurrencyPriceWithSplit coverage | INFO | Resolving CurrencyAlphaThreeCode is only the first step — the code must also be present in Fact_CurrencyPriceWithSplit for USD conversion. Confirm price table covers all active eToro Money currencies. |

## Reviewer Confirmation Needed

- [ ] Run unmapped code check: compare FiatTransactions currency numeric codes against CurrencyNumericCode_ISO — confirm 0 gaps
- [ ] Confirm all eToro Money active currencies have USD rates in Fact_CurrencyPriceWithSplit
- [ ] Confirm SP_eMoney_DimFact_Transaction handles null CurrencyAlphaThreeCode gracefully (logs or skips)
- [ ] Schedule periodic ISO 4217 refresh review (e.g., annually)

*Sidecar generated: 2026-04-21 | Quality: 8.8/10 | Phases completed: P1, P2, P3, P5, P6, P8, P10B, P11*
