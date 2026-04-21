# Review Needed — eMoney_Risk_Portfolio

**Batch**: 7  |  **Date**: 2026-04-20  |  **Reviewer**: —

---

## Tier 4 Items

| # | Column | Issue | Priority |
|---|--------|-------|----------|
| 1 | ScreeningStatus | Source unclear from SP code summary. Likely from DWH_dbo.Dim_Customer or an AML external table referencing a sanctions/PEP screening system. Verify exact SP source (line ~200–300 of SP_eMoney_Risk_Portfolio). | Medium |
| 2 | CountryOneMoneyFTD | Derivation unclear. May be the country of the provider (Tribe entity) for the FTD transaction, or the customer's KYC country at FTD time. Verify from SP_eMoney_Risk_Portfolio #eMoneyFTD step. | Low |
| 3 | MoneyOutExternal | TxTypeID scope unclear. Verify which TxTypeIDs (beyond 5,6,7,8) are classified as External vs. Other in SP_eMoney_Risk_Portfolio #eMoneyTXprep. | Low |
| 4 | MoneyOutOther | Same as MoneyOutExternal — exact TxTypeID boundary between External and Other needs SP verification. | Low |
| 5 | MoneyInExternal | Same concern as MoneyOutExternal. | Low |
| 6 | MoneyInOther | Same concern as MoneyOutOther. | Low |

---

## Tier 1 Verification Log

```
T1 COPY VERIFICATION:
  RealCID: upstream (eMoney_Dim_Account.CID) 35 words → wiki 35 words — IDENTICAL (note added for rename direction)
  GCID: upstream 21 words → wiki 21 words — IDENTICAL
  CurrencyBalanceID: upstream 21 words → wiki 21 words — IDENTICAL
  AccountID: upstream 13 words → wiki 13 words — IDENTICAL
  AccountStatusID: upstream 21 words → wiki 21 words + DWH note — CORRECT (DWH note appended for historical resolution)
  PlayerStatusID: upstream 18 words → wiki 18 words — IDENTICAL
  PlayerLevelID: upstream 21 words → wiki 21 words + disambiguation note — CORRECT
```

---

## Open Questions

| # | Column(s) | Question | Priority |
|---|-----------|----------|----------|
| 1 | TradingRiskScore / OverallRiskScore | These are nvarchar(4000) — seems wide for a short string (Low/Medium/High). Verify if the column ever contains long text or if this is over-provisioned. | Low |
| 2 | eMoneyRiskScore | MoneyInRisk/MoneyOutRisk values are `varchar(6)` (3-char "Low"/"Med"/"Hig" would fit in 3, but "Medium" is 6 chars). Confirm "Medium" vs "Med" — sample shows "Medium" which is 6 chars. | Low |
| 3 | CurrencyBalanceCreateDate (col 30) | This appears to be a duplicate of eMoneyAccountCreateDate (col 28). Both derive from eMoney_Dim_Account.CurrencyBalanceCreateDate. Confirm if they are truly identical or if there's a subtle difference (e.g., one comes from eMoney_Dim_Account, the other from FiatDwhDB directly). | Medium |
| 4 | ScreeningStatus (varchar 255) | Much wider than other varchar fields. Confirm if this stores a single status value or possibly multiple screening flags concatenated. | Low |

---

## Reviewer Corrections

_None yet_

---

## Adversarial Evaluation Score

See Phase 16 output in session notes.
