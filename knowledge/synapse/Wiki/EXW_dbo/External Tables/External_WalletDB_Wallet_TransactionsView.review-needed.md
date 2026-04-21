# EXW_dbo.External_WalletDB_Wallet_TransactionsView — Review Needed

**Generated**: 2026-04-20 (updated from 2026-04-19) | **Batch**: 3 | **Object**: EXW_dbo.External_WalletDB_Wallet_TransactionsView

---

## Tier 4 Items (Unverified / Needs Human Review)

None — all 22 columns have Tier 1 coverage from the documented Wallet.TransactionsView upstream wiki.

---

## Open Questions for Reviewer

1. **TransactionTypeId undocumented values**: The upstream Wallet.TransactionsView wiki documents core types 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. Live data confirms additional types: 1=CustomerMoneyOut (827K rows), 4=Funding (78K), 12=ConversionToFiat (17K), 13=ManualUserMoneyOut (29K), 10=BlockChainActivation (7K), 14=StakeAndRewardsRefund (1.4K), 2=AmlMoneyBack (362), 11=OmnibusMoneyOut (40), 15=CustomerMoneyBack (134). The upstream wiki should be updated to include these values. Confirm whether Dictionary.TransactionTypes in WalletDB is the authoritative source for all current values.

2. **WavedError status (11,072 rows)**: TransStatus='WavedError' (TransStatusId=6) is the second most observed error state in live data. It is not listed in the upstream wiki's TransStatus values (Pending, Verified, Error, Done, Cancelled, NeedsApproval). Confirm: Is WavedError a status used for manually waived errors (e.g., by the Operations team for edge cases)? Should it be treated as terminal/successful for reporting purposes?

3. **gcid=0 (omnibus system wallets)**: Some rows have gcid=0, which the upstream wiki indicates are omnibus/system wallets. Confirm: Should gcid=0 rows be excluded from customer-level reporting in EXW analytics? The SP_EXW_Fact_Transactions filters or handles these as part of its WHERE conditions.

4. **Bronze refresh now confirmed as 60-minute Override**: Previously open question resolved — the Generic Pipeline mapping confirms 60-minute Override strategy. Data freshness is approximately 1 hour behind WalletDB production.

---

## Cross-Object Consistency Check

✅ All 22 column descriptions verbatim from Wallet.TransactionsView.md upstream wiki
✅ TransactionTypeId values 0,5,6,7,9 confirmed against upstream wiki; additional types added from live data observation
✅ TransStatus values confirmed against live data; WavedError noted as undocumented addition
✅ ActionTypeName 'Recive' misspelling confirmed in live data — consistent with upstream documentation
✅ UC Target corrected to `wallet.bronze_walletdb_wallet_transactionsview` from _generic_pipeline_mapping.json

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 22 cols, external table; DATA_SOURCE=internal-sources, LOCATION=Bronze/WalletDB/Wallet/TransactionsView |
| P2 Sample | PASS | 4,711,074 rows; 284,614 distinct GCIDs; TransDate 2018-04-23 to 2026-04-20 (live) |
| P3 Distribution | PASS | ActionType (2=Recive 53%, 1=Sent 47%), TransStatus (Verified 99.7%), TransactionTypeId (15 distinct types) |
| P4 Lookup | PASS | TransStatusId, TransactionTypeId, ActionTypeId values all confirmed from live data |
| P5 JOINs | [-] | External table — no SP writes to it; Generic Pipeline is the writer |
| P6 BizLogic | PASS | CTE architecture, fee structure, status resolution documented from upstream wiki |
| P7 Views | PASS | 5 consumer SPs identified |
| P8 SP Scan | PASS | No writer SP; Generic Pipeline (ADF) writes Bronze |
| P9 SP Logic | [-] | N/A — no Synapse SP writes this external table |
| P9B ETL Orch | PASS | Generic Pipeline: Override, 60-minute cadence |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP configured |
| P10A Upstream | PASS | Wallet.TransactionsView.md (CryptoDBs repo) read; all 22 columns documented |
| P10B Lineage | PASS | .lineage.md updated (22 cols: 22 T1); UC Target: wallet.bronze_walletdb_wallet_transactionsview |
| P11 Generate | PASS | .md updated from 2026-04-19 version; .review-needed.md updated |
