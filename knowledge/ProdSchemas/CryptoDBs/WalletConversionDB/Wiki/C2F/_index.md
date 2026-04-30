# C2F Schema - WalletConversionDB

> Semantic documentation index for the C2F (Crypto-to-Fiat) schema.
> C2F stores the business data for crypto-to-fiat conversion operations: conversions, their statuses, crypto transactions, estimated and actual fiat transactions.

| Metric | Value |
|--------|-------|
| **Total Objects** | 13 |
| **Documented** | 13 (100%) |
| **Pending** | 0 |
| **Last Updated** | 2026-04-15 |

---

## Tables (5)

| Object | Quality | Status |
|--------|---------|--------|
| [C2F.Conversions](Tables/C2F.Conversions.md) | 9.4 | Done (Batch 1) |
| [C2F.ConversionStatuses](Tables/C2F.ConversionStatuses.md) | 9.4 | Done (Batch 1) |
| [C2F.CryptoTransactions](Tables/C2F.CryptoTransactions.md) | 9.2 | Done (Batch 1) |
| [C2F.EstimatedFiatTransactions](Tables/C2F.EstimatedFiatTransactions.md) | 9.2 | Done (Batch 1) |
| [C2F.FiatTransactions](Tables/C2F.FiatTransactions.md) | 9.4 | Done (Batch 1) |

## Stored Procedures (8)

| Object | Quality | Status |
|--------|---------|--------|
| [C2F.GenerateUniqueClientLoadReferenceId](Stored Procedures/C2F.GenerateUniqueClientLoadReferenceId.md) | 9.0 | Done (Batch 1) |
| [C2F.InsertConversion](Stored Procedures/C2F.InsertConversion.md) | 9.4 | Done (Batch 1) |
| [C2F.InsertConversionStatus](Stored Procedures/C2F.InsertConversionStatus.md) | 9.0 | Done (Batch 1) |
| [C2F.InsertCryptoTransaction](Stored Procedures/C2F.InsertCryptoTransaction.md) | 9.0 | Done (Batch 1) |
| [C2F.InsertFiatTransaction](Stored Procedures/C2F.InsertFiatTransaction.md) | 9.0 | Done (Batch 1) |
| [C2F.GetConversionAmounts](Stored Procedures/C2F.GetConversionAmounts.md) | 9.0 | Done (Batch 1) |
| [C2F.GetConversionSummary](Stored Procedures/C2F.GetConversionSummary.md) | 9.0 | Done (Batch 1) |
| [C2F.GetConversionsUsdSum](Stored Procedures/C2F.GetConversionsUsdSum.md) | 9.0 | Done (Batch 1) |
