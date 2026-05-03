MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis**: DDL already in the bundle. 21 columns, HASH(Id), HEAP. `PHASE 1 CHECKPOINT: PASS`

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
Phase 2 sample retrieved. Row count DMV failed (permissions), let me get it another way and read the SPs in parallel.
`PHASE 2 CHECKPOINT: PASS` — 2,519,368 rows, Sep 2018 – Apr 2026.

Now Phase 3 (distribution on categorical columns) and Phase 4 (lookup resolution) in parallel.
`PHASE 3 CHECKPOINT: PASS` — ReceivedTransactionTypeId has 7 values, CryptoId has 128+ values (skip inline).

Now reading lookup tables and checking pipeline mapping.
`PHASE 4 CHECKPOINT: PASS` — ReceivedTransactionTypeId → 8 values (MoneyIn, Redeem, Funding, ConversionFromUser, ConversionFromEtoro, Payment, RedeemAsic, StakeAndRewardsRefund). CryptoId → 128+ cryptos via EXW_Wallet.CryptoTypes.

`PHASE 5 CHECKPOINT: PASS` — JOINed by SP_EXW_Fact_Transactions (LEFT JOIN on Id for received transaction type) and SP_EXW_FactRedeemTransactions (JOIN on BlockchainTransactionId for redeem matching).

`PHASE 6 CHECKPOINT: PASS` — Column groups: identifiers (Id, CorrelationId, ReceiveRequestCorrelationId), blockchain (SenderAddress, ReceiverAddress, NormalizedSenderAddress, NormalizedReceiverAddress, BlockchainTransactionId, BlockchainTransactionDate, BlockchainFee), amounts (Amount), classification (CryptoId, ReceivedTransactionTypeId), ETL metadata (etr_y/ym/ymd, SynapseUpdateDate, partition_date).

`PHASE 7 CHECKPOINT: PASS` — Referenced by EXW_Wallet.EXW_TransactionsView (received_transactions CTE).

`PHASE 8 CHECKPOINT: PASS` — No writer SP (CopyFromLake pipeline). Reader SPs: SP_EXW_Fact_Transactions, SP_EXW_FactRedeemTransactions.

`PHASE 9 CHECKPOINT: PASS` — No writer SP to trace. Table loaded via Generic Pipeline (CopyFromLake) from WalletDB.Wallet.ReceivedTransactions, Append strategy, 60-min frequency.

`PHASE 9B CHECKPOINT: PASS` — CopyFromLake Append pipeline, 60-minute refresh from WalletDB.Wallet.ReceivedTransactions.

`PHASE 10 CHECKPOINT: [-]` — Skipped (regen-harness mode, no Atlassian search).

`PHASE 10A CHECKPOINT: PASS` — _no_upstream_found.txt present. Production source: WalletDB.Wallet.ReceivedTransactions. No upstream wiki available.

Now writing Phase 10B lineage file, then the wiki and review-needed.

```
PHASE GATE — EXW_Wallet.ReceivedTransactions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
`PHASE 10B CHECKPOINT: PASS` — lineage file written.

Now writing the main wiki.
All three files written. Final checklist:

```
OUTPUT CHECK — EXW_Wallet.ReceivedTransactions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/ReceivedTransactions/regen/attempt_1/ReceivedTransactions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/ReceivedTransactions/regen/attempt_1/ReceivedTransactions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/ReceivedTransactions/regen/attempt_1/ReceivedTransactions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 16    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
