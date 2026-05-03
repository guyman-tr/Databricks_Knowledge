MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `EXW_Wallet.PaymentTransactions`.

**PHASE 1 — Structure Analysis (from DDL)**

From the bundle DDL:
- 14 columns: Id, PaymentId, ExchangeRate, ToAddress, Amount, EtoroFeePercentage, EtoroFeeCalculated, ProviderFeePercentage, ProviderFeeCalculated, EstimatedBlockChainFee, Occurred, etr_y, etr_ym, etr_ymd
- Distribution: HASH(PaymentId), HEAP
- All columns nullable

PHASE 1 CHECKPOINT: PASS

Now running P2 (sampling), P3 prep, and P8 (SP scan) in parallel.
P2 sample retrieved. Row count DMV failed (permissions). Let me get count and check the view and look for SPs.
PHASE 2 CHECKPOINT: PASS (24,181 rows, 2019-02 to 2022-09)

Now checking generic pipeline mapping and running distribution queries.
PHASE 3 CHECKPOINT: PASS (distribution on EtoroFeePercentage and ProviderFeePercentage done; no other categorical columns match the regex)

Let me get the full pipeline mapping entry and check NULLs.
Good. Now let me check the upstream wiki routing for WalletDB and search for any existing EXW_Wallet wikis.
Let me check the Payments wiki (closely related) and look for upstream WalletDB wiki.
Found the upstream wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`. The bundle said no upstream was found, but I found one independently. Let me read it.
Found upstream wiki with column descriptions. All production columns are direct passthroughs via Generic Pipeline (Append).

PHASE 4 CHECKPOINT: PASS (PaymentId FK to Wallet.Payments)
PHASE 5 CHECKPOINT: PASS (EXW_TransactionsView joins on PaymentId)
PHASE 6 CHECKPOINT: PASS (Fee structure, exchange rate patterns identified)
PHASE 7 CHECKPOINT: PASS (EXW_TransactionsView references this table)
PHASE 8 CHECKPOINT: PASS (No writer SP — loaded via Generic Pipeline Append)
PHASE 9 CHECKPOINT: [-] No SP to analyze (Generic Pipeline passthrough, no transform)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline, daily 1440 min, Append strategy)
PHASE 10 CHECKPOINT: [-] Frozen table since Sep 2022, low Jira value
PHASE 10A CHECKPOINT: PASS (Found Wallet.PaymentTransactions upstream wiki)

```
PHASE GATE — EXW_Wallet.PaymentTransactions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no SP — Generic Pipeline passthrough)
  [x] P9B ETL         [-] P10 Jira (frozen table)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Starting with `.lineage.md`.
PHASE 10B CHECKPOINT: PASS

Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Running T1 copy verification against the upstream wiki.

```
T1 COPY VERIFICATION:
  Id: upstream "Auto-incrementing primary key." → wiki "Auto-incrementing primary key." — IDENTICAL
  PaymentId: upstream "Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment." → wiki IDENTICAL
  ExchangeRate: upstream "Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto." → wiki IDENTICAL
  ToAddress: upstream "Blockchain destination address for the purchased crypto." → wiki IDENTICAL
  Amount: upstream "Amount of crypto being purchased/transferred." → wiki IDENTICAL
  EtoroFeePercentage: upstream "eToro service fee as a percentage." → wiki IDENTICAL
  EtoroFeeCalculated: upstream "Calculated eToro fee in crypto units." → wiki IDENTICAL
  ProviderFeePercentage: upstream "Payment provider's fee as a percentage." → wiki IDENTICAL
  ProviderFeeCalculated: upstream "Calculated provider fee in crypto units." → wiki IDENTICAL
  EstimatedBlockChainFee: upstream "Estimated blockchain network fee." → wiki IDENTICAL
  Occurred: upstream "Timestamp of record creation." → wiki IDENTICAL
```

```
OUTPUT CHECK — EXW_Wallet.PaymentTransactions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/PaymentTransactions/regen/attempt_1/PaymentTransactions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/PaymentTransactions/regen/attempt_1/PaymentTransactions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/PaymentTransactions/regen/attempt_1/PaymentTransactions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 3    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (upstream wiki found independently at knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md despite _no_upstream_found.txt marker)
```
