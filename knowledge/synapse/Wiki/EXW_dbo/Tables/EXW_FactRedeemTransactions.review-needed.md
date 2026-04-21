---
object: EXW_dbo.EXW_FactRedeemTransactions
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_FactRedeemTransactions

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 29 columns resolved to Tier 1 (upstream verbatim from WalletDB wikis) or Tier 2 (SP code analysis). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — eToroFeeAmount: Intentional Deprecation?

**Column**: eToroFeeAmount (#6)
**Observation**: SP explicitly sets `NULL AS eToroFeeAmount`, discarding the Redemptions.eToroFeeAmount source value. SP comment at the field: no comment.
**Question**: Was eToroFeeAmount deliberately removed in favor of SentEtoroFees (which applies FeeExchangeRate conversion)? If so, when was this change made? The wiki warns analysts to use SentEtoroFees instead — is there a Confluence page or Jira ticket documenting this fee column migration?

### Q2 — SentAmount ROW_NUMBER Selection

**Column**: SentAmount (#15)
**Observation**: The SP selects outputs using `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Amount DESC, ToAddress DESC) AS RN` filtered to RN=1. This takes the highest Amount output per SentTransactionId.
**Question**: For multi-output UTXO transactions (e.g., BTC with change output), does the highest-Amount output always correspond to the redemption transfer? Or are there cases where the change output (back to eToro's own address) might be larger than the redemption output?

### Q3 — ReceivedTransactionID: 725 NULL Rows

**Column**: ReceivedTransactionID (#20)
**Observation**: 725 rows have ReceivedTransactionID IS NULL, FinalRedeemStatus = 'Completed'. The re-run logic should pick these up on subsequent daily runs.
**Question**: Are these 725 rows actively being reprocessed? Some may be legitimately stuck (e.g., BitGo replacements not yet captured, or blockchain confirmation delayed). Is there a separate monitoring or alerting mechanism for long-standing NULL ReceivedTransactionID rows?

### Q4 — SendingGCID for Redemptions

**Column**: SendingGCID (#12)
**Observation**: SendingGCID is the GCID of the owner of the sending wallet (via CustomerWalletsView JOIN on SentTransactions.WalletId). For redemptions, the sending wallet is eToro's omnibus/redeem wallet, not the customer's wallet.
**Question**: Does SendingGCID have any meaningful value for redemption analysis? If the omnibus wallet is owned by a single GCID (eToro's system account), is this column always the same value for all redemption rows? Should this be documented as "omnibus wallet GCID" rather than the redemption customer?

### Q5 — EffectiveBlockchainFees vs SentBlockchainFees

**Column**: EffectiveBlockchainFees (#28), SentBlockchainFees (#17)
**Observation**: Both columns exist for blockchain fee tracking. EffectiveBlockchainFees comes from External_WalletDB_Wallet_TransactionsView; SentBlockchainFees is per-output from SentTransactions.BlockchainFee / output count.
**Question**: In what scenarios do these two columns differ? Is EffectiveBlockchainFees the actual customer-facing fee after eToro subsidization, while SentBlockchainFees is the raw network cost? If so, which should be used for customer-facing fee reporting vs internal cost analysis?

### Q6 — BlockchainCryptoId Purpose

**Column**: BlockchainCryptoId (#29)
**Observation**: Sourced from EXW_Wallet.CryptoTypes.BlockchainCryptoId via LEFT JOIN on CryptoId. This maps token cryptos (e.g., USDC, USDT) to their underlying blockchain (e.g., ETH).
**Question**: Is there a reference mapping CryptoId → BlockchainCryptoId for the main assets? For example: what is BlockchainCryptoId for XRP (CryptoId=4), BTC (CryptoId=1), ETH (CryptoId=2), and ERC-20 tokens? This would help analysts understand when CryptoId ≠ BlockchainCryptoId (i.e., token assets vs native chain assets).

---

## Cross-Object Consistency Notes

### Note 1 — RequestingGcid / ReceivingGCID

Both map to WalletDB.Wallet.Redemptions.RequestingGcid. The same production source and value is documented under two column names. The wiki notes this relationship explicitly. Consistent with other EXW_dbo objects' treatment of GCID as the wallet user identifier.

### Note 2 — CryptoId

Consistent with EXW_FactBalance.md and EXW_FactTransactions.md (Batch 3) — all describe CryptoId as the crypto asset identifier referencing Wallet.CryptoTypes. No inconsistency.

### Note 3 — FinalRedeemStatus vs RedemptionStatus in upstream wiki

The upstream Wallet.Redemptions wiki documents `RedemptionStatus` (0=Persisted, 1=Retrieved, 2=SentToExecuter, 3=SuccessReported, 4=FailureReported). The DWH derives `FinalRedeemStatus` from a different source (Wallet.RequestStatuses.RequestStatusId), not from Redemptions.RedemptionStatus. These are logically different: RedemptionStatus tracks the redemption request lifecycle; FinalRedeemStatus tracks the send request execution status. Both T2 derivations are correct.

---

## Known Limitations in This Wiki

1. **SendingGCID semantic ambiguity**: The wiki documents this as "GCID of the wallet owner who holds the sending wallet (omnibus)" but cannot confirm the omnibus wallet's GCID value without live data query on CustomerWalletsView.
2. **TotalrxAmountInBCTX / CountReceivedTXInBCTX**: These are subquery aggregations in the INSERT SELECT — their values depend on the full #re_temp dataset for that run, not just the current row. The wiki notes this but cannot provide distribution data without a complex query.
3. **Re-run positions date range**: The wiki notes that re-run positions extend back to 2018-10-09 (oldest SentTime). The actual re-run scope is any row meeting the NULL ReceivedTransactionID condition regardless of original insertion date.
4. **EffectiveBlockchainFees vs SentBlockchainFees**: The distinction between these two fee columns is documented based on code analysis but not confirmed by a domain expert.
