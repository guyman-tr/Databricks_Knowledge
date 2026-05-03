MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the DDL and upstream bundle, then start executing phases.
PHASE 1 CHECKPOINT: PASS — 13 columns, HASH(Gcid), HEAP, EXW_Wallet schema.

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
Row count DMV failed (permissions). Let me get a count estimate and search for SPs referencing this table.
PHASE 2 CHECKPOINT: PASS — 5,001,153 total rows, date range 2018-07-11 to 2026-04-27.

Now Phase 3 (Distribution) — `RequestTypeId` matches the categorical regex. Let me also check for NULL patterns and the generic pipeline mapping.
PHASE 3 CHECKPOINT: PASS — RequestTypeId has 10 distinct values (0-9). DetailsJson is NULL in ~50% of rows. DeviceId, etr_y/ym/ymd are 100% NULL.

Let me also check the RequestTypes dictionary and look for views referencing this table.
PHASE 4 CHECKPOINT: PASS — RequestTypeId resolves to WalletDB Dictionary with 10 values (0=CreateWallet through 9=ConversionToPosition). CryptoId resolves to EXW_Wallet.CryptoTypes.

PHASE 5 CHECKPOINT: PASS — JOINs identified in SP_EXW_C2F_E2E (RequestStatuses, DimUser, CustomerWalletsView) and SP_EXW_FactRedeemTransactions (RequestStatuses).

PHASE 6 CHECKPOINT: PASS — Request lifecycle pattern (type + status + correlation); JSON details for send/conversion requests; etr_* partition columns (all NULL — deprecated).

PHASE 7 CHECKPOINT: [-] No views reference this table.

PHASE 8 CHECKPOINT: PASS — Two reader SPs found: SP_EXW_C2F_E2E, SP_EXW_FactRedeemTransactions. No writer SP — loaded via Generic Pipeline.

PHASE 9 CHECKPOINT: [-] No writer SP exists. Table is a raw mirror of WalletDB.Wallet.Requests via Generic Pipeline (Append, daily, parquet).

PHASE 9B CHECKPOINT: PASS — Generic Pipeline, Append strategy, 1440 min (daily), parquet. Source: WalletDB.Wallet.Requests. UC: wallet.bronze_walletdb_wallet_requests.

PHASE 10 CHECKPOINT: [-] Skipped in regen harness mode.

PHASE 10A CHECKPOINT: PASS — Production source: WalletDB.Wallet.Requests. No upstream wiki exists (_no_upstream_found.txt confirmed).

PHASE 10B CHECKPOINT: Writing lineage file now.

```
PHASE GATE — EXW_Wallet.Requests:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.Requests:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/Requests/regen/attempt_1/Requests.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/Requests/regen/attempt_1/Requests.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/Requests/regen/attempt_1/Requests.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 13    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
