MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Starting with P1 (DDL already in bundle), P2 (sampling), and parallel scans.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 9 columns: Id, Name, Occurred, CryptoCoinProviderId, AddressPattern, etr_y, etr_ym, etr_ymd, SynapseUpdateDate. Distribution: ROUND_ROBIN, HEAP.
**PHASE 2 CHECKPOINT: PASS** — 10 rows sampled. Small reference/lookup table with blockchain crypto definitions. Row count DMV failed (permissions), let me get it another way.
Good. 12 rows total. Now let me get the full dataset and check for views referencing this table.
There IS an upstream wiki at `Wallet.BlockchainCryptos.md`. The bundle missed it. Let me read it for Tier 1 inheritance.
Now I have all data. Let me check for the CopyFromLake source and any existing lineage.
Phase gates complete. Now I have the full picture:
- 12-row lookup table, CopyFromLake replica of `WalletDB.Wallet.BlockchainCryptos`
- Generic Pipeline: Override strategy, daily, parquet
- Upstream wiki found at `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md`
- 5 production columns (Tier 1) + 4 ETL columns (Tier 2)
- No writer SP — loaded via Generic Pipeline
- 2 reader SPs: SP_EXW_WalletInventory, SP_EXW_Hourly
- No views reference this table
- UC target: `wallet.bronze_walletdb_wallet_blockchaincryptos`

**PHASE 3 CHECKPOINT: PASS** — 0 categorical columns match distribution regex; full data already captured (12 rows).

**PHASE 4 CHECKPOINT: PASS** — CryptoCoinProviderId resolves to Dictionary.CryptoCoinProviders (1=BitGoBlockchainProviderV2, 2=BitGoEthereumProviderV2, 3=BitgoRippleProviderV2, 4=BitGoStellarProviderV2, 5=BitGoEOSProviderV2).

**PHASE 5 CHECKPOINT: PASS** — Table is a lookup target, not a JOIN source. Referenced via `ON a.BlockchainCryptoId = wbt.Id` in reader SPs.

**PHASE 6 CHECKPOINT: PASS** — Two business patterns: address validation via regex, provider routing.

**PHASE 7 CHECKPOINT: PASS** — No views reference BlockchainCryptos.

**PHASE 8 CHECKPOINT: PASS** — 2 reader SPs (SP_EXW_WalletInventory, SP_EXW_Hourly), 0 writer SPs.

**PHASE 9 CHECKPOINT: PASS** — No writer SP. Table loaded via Generic Pipeline (CopyFromLake). Reader SPs only use `wbt.Name AS BlockchainCryptoName` via JOIN on `wbt.Id`.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline ID 662, Override, daily (1440 min), parquet format, source: WalletDB.

**PHASE 10 CHECKPOINT: [-]** — Skipped in regen harness mode.

**PHASE 10A CHECKPOINT: PASS** — Upstream wiki found: `Wallet.BlockchainCryptos` in CryptoDBs/WalletDB.

**PHASE 10B CHECKPOINT: PASS** — Writing lineage now.

```
PHASE GATE — EXW_Wallet.BlockchainCryptos:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Let me verify they exist.

```
OUTPUT CHECK — EXW_Wallet.BlockchainCryptos:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/BlockchainCryptos/regen/attempt_1/BlockchainCryptos.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/BlockchainCryptos/regen/attempt_1/BlockchainCryptos.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/BlockchainCryptos/regen/attempt_1/BlockchainCryptos.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 5    Tier2: 4    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (upstream wiki found independently at CryptoDBs/WalletDB despite _no_upstream_found.txt marker)
```
