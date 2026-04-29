MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL in parallel.
PHASE 1 CHECKPOINT: PASS — 43 columns, HASH(GCID), HEAP

Now running Phase 2 (sampling), Phase 8 (SP scan), and checking the output directory in parallel.
PHASE 2 CHECKPOINT: PASS (sample retrieved, 10 rows)

Row count via DMV failed (permission). Let me try an alternative and read the writer SP.
4.7M rows. Now running Phase 3 distribution queries and checking for Dim_Customer wiki for RealCID lineage.
PHASE 3 CHECKPOINT: PASS

Now let me get the Dim_Customer RealCID description, check for ReceivedTransactionType lookup, and look for any views referencing EXW_FactTransactions.
PHASE 4 CHECKPOINT: PASS — CryptoTypes lookup resolved, Dim_Customer.RealCID lineage confirmed
PHASE 5 CHECKPOINT: PASS — JOINs traced in SP code
PHASE 6 CHECKPOINT: PASS — business logic patterns identified (flag columns, USD conversion, AML enrichment)
PHASE 7 CHECKPOINT: PASS — no views reference EXW_FactTransactions

Let me check the reader SPs and find the UC target.
PHASE 8 CHECKPOINT: PASS — Writer: SP_EXW_Fact_Transactions; 5 reader SPs identified
PHASE 9 CHECKPOINT: PASS — Full column mapping traced from SP code
PHASE 9B CHECKPOINT: PASS — Daily incremental load pattern, @d parameter, DELETE+INSERT by TranID+ActionTypeID

Now checking UC target and proceeding to Phase 10.
PHASE 10 CHECKPOINT: [-] (Jira search skipped — no Atlassian context for EXW_FactTransactions)
PHASE 10A CHECKPOINT: PASS — Upstream wiki Wallet.TransactionsView resolved from bundle

Now I have all the information needed. Let me produce the three output files. First, the lineage file.

```
PHASE GATE — EXW_dbo.EXW_FactTransactions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Writing all three files now.
PHASE 10B CHECKPOINT: PASS — lineage written

Now writing the main wiki.
Now writing the review-needed sidecar.
Now let me verify the Tier 1 copy accuracy against the upstream wiki.

```
T1 COPY VERIFICATION:
  GCID: upstream "Global Customer ID of the wallet owner..." → wiki matches — IDENTICAL
  CryptoId: upstream "The cryptocurrency of this transaction..." → wiki matches — IDENTICAL
  WalletID: upstream "The wallet involved in this transaction..." → wiki matches — IDENTICAL
  TranID: upstream "Transaction identifier. SentTransactions.Id..." → wiki matches — IDENTICAL
  TranStatusID: upstream "Latest status ID. Resolved via..." → wiki matches — IDENTICAL
  TranStatus: upstream "Human-readable status name..." → wiki matches — IDENTICAL
  TranDate: upstream "Transaction date. For sends:..." → wiki matches — IDENTICAL
  Amount: upstream "Transaction amount in native crypto..." → wiki matches — IDENTICAL
  ProviderFees: upstream "External provider fees..." → wiki matches — IDENTICAL
  FeeExchangeRate: upstream "Exchange rate for fee currency..." → wiki matches — IDENTICAL
  BlockchainFees: upstream "Actual blockchain network fee..." → wiki matches — IDENTICAL
  EstimatedBlockchainFee: upstream "Estimated/effective blockchain fee..." → wiki matches — IDENTICAL
  ActionTypeID: upstream "Transaction direction: 1=Sent..." → wiki matches — IDENTICAL
  ActionTypeName: upstream "Human-readable direction: 'Sent'..." → wiki matches — IDENTICAL
  SenderAddress: upstream "Sender's blockchain address..." → wiki matches — IDENTICAL
  ReciverAddress: upstream "Receiver's blockchain address..." → wiki matches — IDENTICAL
  BlockchainTransactionId: upstream "On-chain transaction hash..." → wiki matches — IDENTICAL
  TransactionTypeID: upstream "Sent transaction type: 0=Redeem..." → wiki matches — IDENTICAL
  TransactionType: upstream "Human-readable type name..." → wiki matches — IDENTICAL
  Occurred: upstream "When the transaction record was created..." → wiki matches — IDENTICAL
  LastStatusUpdateOccurred: upstream "Timestamp of the most recent..." → wiki matches — IDENTICAL
  RealCID: upstream Dim_Customer "Customer ID - platform-internal..." → wiki matches — IDENTICAL
```

```
OUTPUT CHECK — EXW_dbo.EXW_FactTransactions:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_FactTransactions/regen/attempt_1/EXW_FactTransactions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_FactTransactions/regen/attempt_1/EXW_FactTransactions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_FactTransactions/regen/attempt_1/EXW_FactTransactions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 22    Tier2: 23    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
