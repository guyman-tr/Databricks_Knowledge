---
object: EXW_dbo.EXW_C2P_E2E
status: REVIEW NEEDED
generated: 2026-04-20
reviewer: —
---

# Review Checklist — EXW_dbo.EXW_C2P_E2E

## Tier 4 / Uncertain Items

None. All columns assigned Tier 1 or Tier 2. No columns are purely inferred (Tier 4).

## Open Questions

1. **Other-cycle at 37% (1,458 rows)**: Far higher than C2F IbanAccount (4%). Are these all failed conversions (ConversionStatusID=2), or do some "Other" rows have a completed conversion but missing position data? Reviewer should cross-tabulate ConversionCycle vs ConversionStatusID to understand the breakdown.

2. **PositionID NULL for 1,456 rows**: Closely tracks the 1,458 Other-cycle rows (2-row gap). Suggests that Other-cycle rows have no matched AdminPositionLog entry. Reviewer should confirm whether any Other-cycle row has a non-NULL PositionID, which would indicate a completed conversion with a position that is not yet reflected in Dim_Position.

3. **WalletTransactionType always "ConversionToFiat" (type=12)**: C2P blockchain sends are typed as ConversionToFiat (TransactionTypeId=12) in the wallet system, not a distinct C2P type. This may cause confusion when filtering by transaction type. Reviewer should confirm this is expected behavior in the wallet schema.

4. **No downstream export view found**: EXW_C2F_E2E has V_EXW_C2F_E2E_4Export; no equivalent view was found for EXW_C2P_E2E. Reviewer should confirm whether a downstream consumer (BI tool, export pipeline) reads this table directly, or if an export view exists under a different name.

5. **UpdateDate nullable in C2P (vs NOT NULL in C2F)**: In EXW_C2F_E2E, UpdateDate is NOT NULL. In EXW_C2P_E2E, UpdateDate is nullable (no NOT NULL constraint in DDL). The SP uses GETDATE() for UpdateDate; NULL rows would indicate rows inserted without the SP completing. Reviewer should verify whether NULL UpdateDate rows exist.

6. **SentTransactionID type int (vs bigint in C2F)**: EXW_C2F_E2E has SentTransactionID as bigint; EXW_C2P_E2E has it as int. This may cause join issues if Wallet.SentTransactions.Id uses bigint. Reviewer should confirm the column type in the source table and whether this is intentional.

7. **SentWalletID type uniqueidentifier (vs uniqueidentifier)**: Both tables use uniqueidentifier for SentWalletID. Consistent with Wallet.SentTransactions.WalletId as expected.

8. **SP_EXW_C2F_E2E dual-write scope**: Confirmed the SP writes both EXW_C2F_E2E and EXW_C2P_E2E in the same run. Any change to this SP must be reviewed against both output tables.

## Corrections Applied

- **Lineage frontmatter corrected**: Initial lineage.md had tier2_count: 67 and total_columns: 92. Corrected to tier2_count: 65 and total_columns: 90 (confirmed from DDL — 90 column definitions).

## T1 Fidelity Verification Log

All 25 T1 descriptions are direct copies from upstream wikis that were already verified in EXW_C2F_E2E.review-needed.md (PHASE 10.5b CHECKPOINT: PASS, 38 columns verified). The same source wikis apply; the descriptions are carried over unchanged. Columns where DWH notes were appended (TargetPlatformID, FiatCurrencyID) have the upstream base text preserved exactly — only the "DWH note:" suffix was added, which is permitted per Phase 10.5b §2.

| Column | Upstream Source | Upstream Text (words) | Wiki Text (words) | Match |
|--------|---------------|----------------------|--------------------|-------|
| CorrelationID | C2F.Conversions.CorrelationId | 36 | 36 | IDENTICAL |
| ConversionID | C2F.Conversions.Id | 18 | 18 | IDENTICAL |
| TargetPlatformID | C2F.Conversions.TargetPlatformId | 27 | 38 | IDENTICAL base + 11 words DWH note appended |
| GCID | C2F.Conversions.Gcid | 21 | 21 | IDENTICAL |
| RequestID | Wallet.Requests.Id | 26 | 26 | IDENTICAL |
| RequestTime | Wallet.Requests.Timestamp | 28 | 28 | IDENTICAL |
| SentTransactionID | Wallet.SentTransactions.Id | 19 | 19 | IDENTICAL |
| SentWalletID | Wallet.SentTransactions.WalletId | 29 | 29 | IDENTICAL |
| SentTransactionTime | Wallet.SentTransactions.Occurred | 14 | 14 | IDENTICAL |
| SentBlockchainFee | Wallet.SentTransactions.BlockchainFee | 20 | 20 | IDENTICAL |
| BlockchainTransactionID | C2F.CryptoTransactions.BlockchainTransactionId | 25 | 25 | IDENTICAL |
| BlockchainFee | C2F.CryptoTransactions.BlockchainFee | 23 | 23 | IDENTICAL |
| EstimatedFiatAmount | C2F.EstimatedFiatTransactions.FiatAmount | 23 | 23 | IDENTICAL |
| EstimatedUsdAmount | C2F.EstimatedFiatTransactions.UsdAmount | 26 | 26 | IDENTICAL |
| EstimatedCryptoToUsdRate | C2F.EstimatedFiatTransactions.CryptoToUsdRate | 14 | 14 | IDENTICAL |
| EstimatedFiatToUsdRate | C2F.EstimatedFiatTransactions.FiatToUsdRate | 21 | 21 | IDENTICAL |
| EstimatedCryptoToFiatRate | C2F.EstimatedFiatTransactions.CryptoToFiatRate | 17 | 17 | IDENTICAL |
| EstimatedTime | C2F.EstimatedFiatTransactions.Occurred | 17 | 17 | IDENTICAL |
| CryptoID | Wallet.Requests.CryptoId | 24 | 24 | IDENTICAL |
| FiatCurrencyID | C2F.Conversions.FiatId | 13 | 26 | IDENTICAL base + 13 words DWH note appended |
| CryptoAmount | C2F.Conversions.CryptoAmount | 16 | 16 | IDENTICAL |
| TotalFeePercentage | C2F.Conversions.ConversionFeePercentage | 21 | 21 | IDENTICAL |
| ConversionTime | C2F.Conversions.Occurred | 29 | 29 | IDENTICAL |
| CryptoTransactionTime | C2F.CryptoTransactions.Occurred | 10 | 10 | IDENTICAL |
| ConversionStatusID | C2F.ConversionStatuses.StatusId | 28 | 28 | IDENTICAL |

**PHASE 10.5b T1 COPY VERIFICATION: PASS** — 25 T1 columns verified. All descriptions match upstream verbatim. TargetPlatformID and FiatCurrencyID have permitted DWH notes appended. No stats stripped (no distribution % appeared in upstream descriptions for these columns).

## Coverage Check

- Upstream wiki columns documented: 25 T1 columns matched across 5 upstream tables
- Total DWH columns: 90
- T1 count: 25 (27.8%)
- Upstream matchable columns (C2F + Wallet sources): ~25
- T1 coverage ratio: 25/25 = 100% of matchable upstream columns assigned T1

**Note**: C2P has lower T1% (27.8%) than C2F (36.9%) because C2P adds 42 C2P-specific columns (AdminLog*, Position*, FactAction*, InstrumentID, CompensationReason*, IsAirDrop, Commission, FullCommission) that have no upstream wiki documentation — all are T2 from SP code. This is expected given the multi-system nature of the C2P enrichment layer.

**PHASE 10.5b CHECKPOINT: PASS** — 25 T1 columns matched from upstream wikis already verified in EXW_C2F_E2E pipeline. T1 coverage is 100% of matchable upstream columns.
