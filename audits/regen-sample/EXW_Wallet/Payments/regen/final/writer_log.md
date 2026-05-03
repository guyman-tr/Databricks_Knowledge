MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `EXW_Wallet.Payments`.

**Phase 1 — Structure Analysis (from DDL)**

| Column | Type | Nullable |
|--------|------|----------|
| Id | bigint | YES |
| WalletId | varchar(4000) | YES |
| ProviderPaymentId | uniqueidentifier | YES |
| Amount | numeric(36,18) | YES |
| FiatId | int | YES |
| CorrelationId | uniqueidentifier | YES |
| Occurred | datetime2(7) | YES |
| CryptoId | int | YES |
| etr_y | varchar(max) | YES |
| etr_ym | varchar(max) | YES |
| etr_ymd | varchar(max) | YES |

- **Distribution**: HASH(Id)
- **Index**: HEAP
- **11 columns**, all nullable

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and SP/view scans in parallel.
Good — sample retrieved. Row count DMV failed (permission), let me try an alternative and read the referencing view.
PHASE 2 CHECKPOINT: PASS (113,579 rows, date range 2019-01-29 to 2022-09-20)

Now Phase 3 (distribution) and Phase 4+ research in parallel.
PHASE 3 CHECKPOINT: PASS

Phase 4-9: Let me check for related objects, lookup tables, and any existing wikis.
Let me check the related lookup tables and the view usage.
Let me get lookup values and check for any existing EXW wiki for context.
PHASE 4 CHECKPOINT: PASS (FiatId → FiatTypes: 2=EUR, 3=GBP; CryptoId → CryptoTypes: 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 21=XLM)

PHASE 5 CHECKPOINT: PASS (Payments referenced in EXW_TransactionsView via JOIN on CorrelationId → SentTransactions and Payments.Id → PaymentTransactions.PaymentId)

PHASE 6 CHECKPOINT: PASS (Simplex fiat-to-crypto payment requests; raw bronze landing from WalletDB)

PHASE 7 CHECKPOINT: PASS (Referenced by EXW_Wallet.EXW_TransactionsView in payment_transactions CTE)

PHASE 8 CHECKPOINT: PASS (No SPs write to or read from this table — generic pipeline landing)

PHASE 9 CHECKPOINT: [-] No writer SP — table is loaded via Generic Pipeline (Append) from WalletDB.Wallet.Payments

PHASE 9B CHECKPOINT: PASS (Generic Pipeline, Append strategy, daily 1440 min, from WalletDB.Wallet.Payments; table frozen since 2022-09-20)

PHASE 10 CHECKPOINT: [-] Skipped in regen harness single-object mode

PHASE 10A CHECKPOINT: PASS (_no_upstream_found.txt present; production source is WalletDB.Wallet.Payments but no upstream wiki exists)

PHASE 10B — Writing lineage file now.

```
PHASE GATE — EXW_Wallet.Payments:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no writer SP — generic pipeline landing)
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final checklist:

```
OUTPUT CHECK — EXW_Wallet.Payments:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/Payments/regen/attempt_1/Payments.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/Payments/regen/attempt_1/Payments.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/Payments/regen/attempt_1/Payments.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 3    Tier3: 8    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
