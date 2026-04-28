# Compare — `EXW_dbo.EXW_FactConversions`

**Bucket**: `random`

**Verdict**: **BETTER**  (score delta +1.7; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.65 | 9.35 | 1.7 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 46 | 46 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 14 | 24 | +10 |
| T2 count | 31 | 6 | -25 |
| T3 count | 0 | 16 | +16 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 10 | 9 |
| completeness | 10 | 10 |
| data_evidence | 9 | 9 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 3 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `11` | 0.292 | 2 | 3 | Timestamp of the latest status change for this conversion record. Sourced from ConversionStatuses modification timestamp. (Tier 2 — WalletDB.Wallet.ConversionStatuses) | Last modification timestamp of the conversion record. Tracks the most recent status or data change. (Tier 3 — no upstream wiki, name-derived) |
| `43` | 0.298 | 2 | 2 | Blockchain-layer cryptocurrency identifier for the FROM side. May differ from FromCryptoID (which is the Wallet platform ID). From EXW_Wallet.BlockchainCryptos. (Tier 2 — EXW_Wallet.BlockchainCryptos) | Blockchain-level crypto ID for the From-leg. For ERC-20 tokens, this maps to the underlying blockchain (e.g., ETH=2). Resolved via EXW_Wallet.CryptoTypes.BlockchainCryptoId. (Tier 2 — CryptoTypes look |
| `15` | 0.305 | 4 | 1 | Duplicate of ConversionID. Always equals ConversionID (confirmed in 100% of rows). Loading artifact — carries no additional information. Do not use for filtering or grouping. (Tier 4 — data observatio | Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows. (Tier 1 — Wallet.C |
| `25` | 0.354 | 2 | 3 | Internal EXW platform transaction ID for the TO-leg sent transaction. From EXW_Wallet.SentTransactions. NULL when the TO-leg sent transaction was not found (failed or pending conversions). (Tier 2 — E | To-leg sent transaction ID from the wallet's SentTransactions table. Used as FK to EXW_FactTransactions.TranID. (Tier 3 — no upstream wiki, from Wallet.SentTransactions) |
| `42` | 0.379 | 2 | 3 | Timestamp of the last ETL data load. Uniform value 2024-04-09 across all rows — reflects the one-time historical load date, not the conversion date. (Tier 2 — ETL load process) | ETL load timestamp. All rows show 2024-04-09 05:11:18, indicating a single bulk load. (Tier 3 — ETL metadata) |
| `6` | 0.382 | 2 | 3 | Group Customer ID of the wallet owner initiating the conversion. Derived by joining FromWalletId to CustomerWalletsView. Always equal to RecievingGCID (same user controls both wallets). (Tier 2 — EXW_ | Global customer ID of the user initiating the conversion. Always equals RecievingGCID (self-swap). Mapped from wallet ownership, not present in upstream Wallet.Conversions. (Tier 3 — no upstream wiki, |
| `18` | 0.445 | 2 | 3 | Group Customer ID of the wallet owner receiving the conversion. Derived by joining ToWalletId to CustomerWalletsView. Always equal to SendingGCID — same user owns both wallets in a self-swap. (Tier 2  | Global customer ID of the receiving side. Always equals SendingGCID (self-swap). Mapped from wallet ownership, not present in upstream tables. (Tier 3 — no upstream wiki, wallet-to-customer mapping) |
| `10` | 0.452 | 2 | 3 | Lifecycle status of the conversion stored as a numeric string. 1=Pending, 2=Failed, 3=Completed (Dictionary.ConversionStatuses). (Tier 2 — WalletDB.Wallet.ConversionStatuses) | Conversion lifecycle status code: 1=Pending, 2=Failed/Cancelled, 3=Completed. Sourced from Wallet.ConversionStatuses (no upstream wiki available). (Tier 3 — no upstream wiki, derived from data) |
| `38` | 0.457 | 2 | 3 | Internal EXW platform transaction ID for the FROM-leg received transaction. (Tier 2 — EXW_Wallet.ReceivedTransactions) | From-leg received transaction ID from the wallet's ReceivedTransactions table. Confirms receipt on the From side. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| `41` | 0.475 | 2 | 3 | Timestamp when both legs received final settlement confirmation. (Tier 2 — EXW_Wallet.ReceivedTransactions) | Timestamp when the conversion was fully received/completed. NULL for failed or incomplete conversions (1,608 NULLs). (Tier 3 — no upstream wiki, name-derived) |

## Top issues — regen wiki (per judge)

- [medium] `Footer` — Footer tier counts are wrong: claims '22 T1, 8 T2, 16 T3' but actual count from Elements table is 24 T1, 6 T2, 16 T3.
- [low] `SentToEtoroBlockchainFees / SentFromEtoroBlockchainFees` — Column names suggest actual blockchain fees on sent transactions, but lineage maps to EstimatedBlockChainFee from ConversionTransactions. The Tier 1 description faithfully quotes 'Estimated blockchain network fee' which may confuse analysts expecting actual fees. Lineage mapping may warrant data verification.
- [low] `ConversionID2` — Described as duplicate of ConversionID with same value in all rows. Purpose is unclear — review-needed sidecar correctly flags this but wiki could note whether this is a known ETL artifact or has functional meaning in edge cases.
