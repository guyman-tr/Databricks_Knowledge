# Review Needed: eMoney_dbo.eMoney_Dictionary_TransactionType

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

No critical Tier 4 items. Complete and consistent with upstream source (15/15 rows match FiatDwhDB).

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | `14=CryptoToFiat` classified as TBD in eMoney_Calculated_Balance | MEDIUM | The C2F transaction type is not yet mapped to a named balance category (CardActivity, Loads, etc.) in `SP_eMoney_Calculated_Balance`. It falls into the TBD bucket. As crypto-to-fiat conversions grow, this gap in balance categorization may become material for reporting. Confirm if TBD categorization is intentional. |
| 2 | UpdateDate static since 2023-06-12 | INFO | Consistent with other eMoney_Dictionary tables. All 15 values confirmed via live query — table is current. |
| 3 | No 0=Unknown in regular production use | INFO | Confirm whether TransactionTypeID=0 (Unknown) appears in active production data; if so, investigate the source classification gap. |

## Reviewer Confirmation Needed

- [ ] Confirm whether TBD (TypeID=14) categorization in eMoney_Calculated_Balance is intentional or a backlog item
- [ ] Confirm FMI definition (TxTypeID IN (5,7)) and FMO definition (TxTypeID IN (1,2,3,4,6,8,13)) are current — note that 14=CryptoToFiat is excluded from both

*Sidecar generated: 2026-04-20 | Quality: 9.3/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
