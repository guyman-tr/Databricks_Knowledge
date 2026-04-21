# EXW_dbo.EXW_FactPayments — Review Notes

**Generated**: 2026-04-20  
**Batch**: 11  
**Quality Score**: 9.0/10

---

## Tier 4 Items (Reviewer Verification Needed)

| Column | Issue | Action Required |
|--------|-------|----------------|
| SentTransactionID | Inferred as Wallet.SagaSendTx.Id or TransactionId — exact source table not confirmed | Confirm with CryptoDBs team which WalletDB table supplies the sent blockchain transaction reference |
| ReceivedTransactionID | Inferred as Wallet.Transactions.Id — exact source table not confirmed | Confirm with CryptoDBs team which WalletDB table supplies the received transaction reference |
| BlockchainTransactionId | Inferred as Wallet.SagaSendTx.BlockchainTransactionId — exact source table not confirmed | Confirm blockchain tx hash source; clarify whether it matches the on-chain txhash format |
| BlockChainFee | Inferred as Wallet.SagaSendTx.BlockchainFee — exact source table not confirmed | Confirm actual (realized) fee source vs EstimatedBlockChainFee from PaymentTransactions |
| BlockchainCryptoID | Inferred as Wallet.CryptoTypes.CryptoID — relationship to CryptoId column unclear | Clarify whether BlockchainCryptoID is a different identifier than CryptoId (Payments.CryptoId) — possibly a network-specific crypto code |

## Open Questions

1. **GCID derivation path** — GCID is populated via wallet-to-customer lookup. Is this via Wallet.Wallets → CustomerWalletsView → GCID, or a direct mapping table? The exact join path is not documented in the WalletDB wiki.
2. **Are all PaymentStatus events included?** WalletDB.Wallet.PaymentStatuses has ~11 status events per payment; EXW_FactPayments shows ~5.57 rows per payment. Are some status events filtered at ETL time? If so, which statuses are excluded?
3. **ETL pipeline identity** — Documented as "External pipeline (no SSDT SP)" but the exact orchestrator is unknown. Is this ADF, a generic pipeline, or a bespoke Python job? Confirm with data engineering team.
4. **No UpdateDateID** — UpdateDateID is absent from the DDL (present in EXW_ECPBank, absent here). Was this intentional, or was it dropped when the ETL pipeline was built?

## Data Quality Issues Documented

1. **Accumulating snapshot pattern** — 553,884 rows for 99,410 distinct PaymentIDs (~5.57 rows/payment). Analysts must filter on PaymentStatus to avoid double-counting payment amounts.
2. **Data frozen 2022-09-20** — Simplex decommissioned as eToro's crypto buy provider ~September 2022. No new records will ever be added.
3. **Missing Tier 1 columns (SentTransactionID, ReceivedTransactionID, BlockchainTransactionId, BlockChainFee, BlockchainCryptoID)** — WalletDB wikis for SagaSendTx/Transactions tables not confirmed; sourced from available WalletDB context only.

## No Critical Blockers

All hard phase gates passed. Wiki is comprehensive for a 28-column accumulating snapshot fact table with strong T1 coverage (16/28 = 57%).
