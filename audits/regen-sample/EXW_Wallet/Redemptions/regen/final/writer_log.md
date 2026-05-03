MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Starting with parallel work: Phase 1 (DDL already in bundle), Phase 2 (live sampling), Phase 8 (SP scan).

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 22 columns, HASH distribution on `SendRequestCorrelationId`, HEAP index, nonclustered index on `partition_date`.

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
Row count DMV failed (permissions). Let me get it via COUNT with a filter, and read the SP and view files.
**PHASE 2 CHECKPOINT: PASS** — 1,129,906 rows, date range 2019-07-14 to 2026-04-27. Sample shows crypto redemption records with GUIDs, amounts, fees, and statuses. `partition_date` is NULL across the sample; `SourceWalletId` and `TransactionTypeId` also NULL in sample rows. `EndDate` = 9999-12-31 sentinel in all samples.

Now Phase 3 (distribution) and Phase 4/9B (lookup + pipeline mapping).
**PHASE 3 CHECKPOINT: PASS** — Distribution analysis complete for 3 categorical columns:
- `RedemptionStatus`: 3 values (3=1,129,868, 4=34, 2=4)
- `CryptoId`: 57 distinct values (top: 4=464,978, 1=261,640, 2=142,210)
- `TransactionTypeId`: 2 values (0=1,020,228, NULL=109,678)

Now let me find the Generic Pipeline mapping for this table and check for CryptoTypes/EXW_Dictionary lookups.
Now I have all the context needed. Let me compile the phase gates and write the output files.

**PHASE 4 CHECKPOINT: PASS** — CryptoId → EXW_Wallet.CryptoTypes (57 distinct values, >15 so no inline values).

**PHASE 5 CHECKPOINT: PASS** — SP_EXW_FactRedeemTransactions joins Redemptions on PositionId and SendRequestCorrelationId to Requests, SentTransactions, SentTransactionOutputs, ReceivedTransactions, CustomerWalletsView, and CryptoTypes.

**PHASE 6 CHECKPOINT: PASS** — Business logic: Redemption lifecycle (request→sent→received), fee hierarchy (eToroFeeAmount, EstimatedBlockchainFee, InitialFeeAmount), sentinel EndDate (9999-12-31 = open).

**PHASE 7 CHECKPOINT: PASS** — EXW_TransactionsView references Redemptions in the `redeem_transactions` CTE (TransactionTypeId IN (0,8)).

**PHASE 8 CHECKPOINT: PASS** — Reader: SP_EXW_FactRedeemTransactions, EXW_TransactionsView. No writer SP — loaded via Generic Pipeline (Override, daily).

**PHASE 9 CHECKPOINT: PASS** — SP reads Id, SendRequestCorrelationId, PositionId, RequestingGcid, CryptoId, RequestedAmount, eToroFeeAmount, RedemptionStatus, BillingTransId, BillingRedeemId, BeginDate, EndDate, EstimatedBlockchainFee, InitialFeeAmount, TransactionTypeId. All are passthroughs from the source.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline Override from WalletDB.Wallet.Redemptions, daily refresh (1440 min), parquet format.

**PHASE 10 CHECKPOINT: [-]** — Skipped in regen-harness mode.

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` present. Production source: WalletDB.Wallet.Redemptions. No upstream wiki available.

```
PHASE GATE — EXW_Wallet.Redemptions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.
```
OUTPUT CHECK — EXW_Wallet.Redemptions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/Redemptions/regen/attempt_1/Redemptions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/Redemptions/regen/attempt_1/Redemptions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/Redemptions/regen/attempt_1/Redemptions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 17    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
