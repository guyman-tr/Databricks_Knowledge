# Review Needed: eMoney_dbo.eMoney_Dictionary_PaymentSchemaType

**Generated**: 2026-04-21 | **Batch**: 11 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Low-risk dictionary table with confirmed upstream source. Prior batch context (batch 4) had WRONG enum values — live MCP data used exclusively.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | UpdateDate static since 2023-06-11 | INFO | Table loaded one day earlier than other batch 11 dictionaries (2023-06-11 vs 2023-06-12). Confirm Generic Pipeline is still scheduled for `External_FiatDwhDB_Dictionary_PaymentSchemaType`. |
| 2 | SEPAstandart typo (ID=5) | WARN | The value "SEPAstandart" is a typo preserved verbatim from FiatDwhDB. All string filters MUST use "SEPAstandart" not "SEPAstandard". Confirm no downstream queries use the corrected spelling. |
| 3 | 0=Unknown sentinel | INFO | Unknown (ID=0) exists as sentinel. Confirm whether any active transactions carry PaymentSchemaTypeID=0 and whether this is expected. |
| 4 | Transfer (1) vs scheme-specific routing | INFO | Transfer (ID=1) is generic internal — not a named payment rail. Confirm it is excluded from scheme-specific regulatory reporting. |

## Reviewer Confirmation Needed

- [ ] Confirm Generic Pipeline schedule for `External_FiatDwhDB_Dictionary_PaymentSchemaType`
- [ ] Confirm all downstream queries referencing SEPA standard use "SEPAstandart" (not "SEPAstandard")
- [ ] Confirm Transfer (1) is excluded from UK/SEPA regulatory scheme reporting

*Sidecar generated: 2026-04-21 | Quality: 9.2/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
