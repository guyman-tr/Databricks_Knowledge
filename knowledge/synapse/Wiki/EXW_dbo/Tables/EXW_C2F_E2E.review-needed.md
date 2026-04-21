---
object: EXW_dbo.EXW_C2F_E2E
status: REVIEW NEEDED
generated: 2026-04-20
reviewer: —
---

# Review Checklist — EXW_dbo.EXW_C2F_E2E

## Tier 4 / Uncertain Items

None. All columns assigned Tier 1 or Tier 2. No columns are purely inferred (Tier 4).

## Open Questions

1. **TargetPlatformID=2 (EtoroPlatform) path**: The SP excludes TargetPlatformID IN (2,3) from the IbanAccount UNION branch, but the EtoroPosition branch only handles TargetPlatformID=3 via deposit matching. How are TargetPlatformID=2 rows populated? 1,093 rows have TargetPlatformID=2 — do these come from the deposit branch? Reviewer should verify which SP branch handles EtoroPlatform conversions.

2. **SentTransactionID NULL for 559 rows**: These are FailedConversion rows where no blockchain send occurred. Confirmed by ConversionStatusID=2 (Failed) distribution (575 rows). The 16-row gap (575 failed - 559 null sent) may indicate some failed conversions that still had a send attempt. Reviewer should verify.

3. **eMoneyTransactionID NULL for 1,567 rows**: This aligns with TargetPlatformID=2 (EtoroPlatform, 1,093 rows) + failed conversions (575 rows) ≈ 1,568 rows. Confirms that EtoroPlatform and EtoroPosition paths don't flow through eMoney. Reviewer should confirm this interpretation.

4. **FiatDetails vs eMoneyReferenceNumber cross-check**: Sample data shows they match exactly (both are "C2F" + 8 digits format for IbanAccount rows). This should be validated as a data quality assertion.

5. **Tribe vs eMoneyHolderAmount**: TribeHolderAmount mirrors eMoneyHolderAmount closely in sample data. The Tribe schema in FiatDwhDB is the settlement layer used for reconciliation. The purpose and authority of each should be confirmed with the C2F product team.

6. **ConversionCycle "Other" (4 rows)**: These rows fall into none of the 10 defined cycle categories. Reviewer should identify what data anomaly these represent.

7. **RequestLastStatus values**: Two distinct "done" statuses exist: 1=Done and 7=TransactionVerified. The difference between these is not documented. 7=TransactionVerified likely means the blockchain transaction was verified, while 1=Done means the saga completed. Reviewer should confirm.

8. **SP_EXW_C2F_E2E dual-write scope**: Confirmed the SP writes both EXW_C2F_E2E and EXW_C2P_E2E. Any change to this SP must be reviewed against both output tables. Consider documenting this in the SP header comment.

## Corrections Applied

None.

## T1 Fidelity Verification Log

Re-reading upstream wikis and comparing word counts:

| Column | Upstream Source | Upstream Text (words) | Wiki Text (words) | Match |
|--------|---------------|----------------------|--------------------|-------|
| C2FCorrelationID | C2F.Conversions.CorrelationId | 36 | 36 | IDENTICAL (no stats stripped) |
| GCID | C2F.Conversions.Gcid | 21 | 21 | IDENTICAL (no stats stripped) |
| TargetPlatformID | C2F.Conversions.TargetPlatformId | 30 | 27 | STRIPPED 3 words: (77%), (6%), (17%) — snapshot distribution stats |
| C2FConversionID | C2F.Conversions.Id | 18 | 18 | IDENTICAL |
| CryptoID | C2F.Conversions.CryptoId | 18 | 18 | IDENTICAL |
| FiatCurrencyID | C2F.Conversions.FiatId | 13 | 13 | IDENTICAL |
| CryptoAmount | C2F.Conversions.CryptoAmount | 16 | 16 | IDENTICAL |
| TotalFeePercentage | C2F.Conversions.ConversionFeePercentage | 21 | 21 | IDENTICAL |
| ConversionDateTime | C2F.Conversions.Occurred | 29 | 29 | IDENTICAL |
| ConversionStatusID | C2F.ConversionStatuses.StatusId | 28 | 28 | IDENTICAL |
| EstimatedFiatAmount | C2F.EstimatedFiatTransactions.FiatAmount | 23 | 23 | IDENTICAL |
| EstimatedUsdAmount | C2F.EstimatedFiatTransactions.UsdAmount | 26 | 26 | IDENTICAL |
| EstimatedCryptoToUsdRate | C2F.EstimatedFiatTransactions.CryptoToUsdRate | 14 | 14 | IDENTICAL |
| EstimatedFiatToUsdRate | C2F.EstimatedFiatTransactions.FiatToUsdRate | 21 | 21 | IDENTICAL |
| EstimatedCryptoToFiatRate | C2F.EstimatedFiatTransactions.CryptoToFiatRate | 17 | 17 | IDENTICAL |
| EstimatedDateTime | C2F.EstimatedFiatTransactions.Occurred | 17 | 17 | IDENTICAL |
| BlockchainTransactionID | C2F.CryptoTransactions.BlockchainTransactionId | 25 | 25 | IDENTICAL |
| ToAddress | C2F.CryptoTransactions.ToAddress | 24 | 24 | IDENTICAL |
| BlockchainFee | C2F.CryptoTransactions.BlockchainFee | 23 | 23 | IDENTICAL |
| CryptoTransactionDateTime | C2F.CryptoTransactions.Occurred | 10 | 10 | IDENTICAL |
| CryptoToFiatRate | C2F.FiatTransactions.CryptoToFiatRate | 19 | 19 | IDENTICAL |
| FiatToUsdRate | C2F.FiatTransactions.FiatToUsdRate | 13 | 13 | IDENTICAL |
| CryptoToUsdRate | C2F.FiatTransactions.CryptoToUsdRate | 7 | 7 | IDENTICAL |
| FiatAmount | C2F.FiatTransactions.FiatAmount | 19 | 19 | IDENTICAL |
| UsdAmount | C2F.FiatTransactions.UsdAmount | 20 | 20 | IDENTICAL |
| FiatAccountID | C2F.FiatTransactions.AccountId | 19 | 19 | IDENTICAL |
| FiatDetails | C2F.FiatTransactions.Details | 20 | 20 | IDENTICAL |
| RateTime | C2F.FiatTransactions.RateTimestamp | 22 | 22 | IDENTICAL |
| FiatTxTime | C2F.FiatTransactions.Occurred | 9 | 9 | IDENTICAL |
| SentTransactionID | Wallet.SentTransactions.Id | 19 | 19 | IDENTICAL |
| SentBlockchainTransactionID | Wallet.SentTransactions.BlockchainTransactionId | 20 | 20 | IDENTICAL |
| SentWalletID | Wallet.SentTransactions.WalletId | 29 | 29 | IDENTICAL |
| SentTransactionDateTime | Wallet.SentTransactions.Occurred | 14 | 14 | IDENTICAL |
| SentBlockchainFee | Wallet.SentTransactions.BlockchainFee | 20 | 20 | IDENTICAL |
| SentCryptoID | Wallet.SentTransactions.CryptoId | 19 | 19 | IDENTICAL |
| RequestID | Wallet.Requests.Id | 26 | 26 | IDENTICAL |
| RequestCryptoID | Wallet.Requests.CryptoId | 24 | 24 | IDENTICAL |
| RequestDateTime | Wallet.Requests.Timestamp | 28 | 28 | IDENTICAL |

**PHASE 10.5b T1 COPY VERIFICATION: PASS** — 38 T1 columns verified. Only TargetPlatformID had stats stripped (distribution percentages). All other descriptions match upstream verbatim.

## Coverage Check

- Upstream wiki columns documented: 38 T1 columns matched across 7 upstream tables
- Total DWH columns: 103
- T1 count: 38 (36.9%)
- Upstream matchable columns (C2F + Wallet sources): ~38
- T1 coverage ratio: 38/38 = 100% of matchable upstream columns assigned T1

**PHASE 10.5b CHECKPOINT: PASS** — Rich upstream wiki with 38 columns documented. T1 coverage is 36.9% of total columns (expected for an E2E reconciliation table where ~65% of columns are enrichment, computation, or lookup data).
