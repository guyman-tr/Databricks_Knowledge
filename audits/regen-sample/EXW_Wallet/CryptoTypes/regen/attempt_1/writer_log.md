MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `EXW_Wallet.CryptoTypes`.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 35 columns, ROUND_ROBIN distribution, HEAP index. All columns nullable.

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 174 rows, small reference table. Sample captured.

**PHASE 3 CHECKPOINT: PASS** — Distribution: Status (1=13, 3=161), CryptoActivityStatus (2=173, 3=1), CryptoCategoryName (erc20Wave1=161, baseCrypto=10, BaseCrypto=2, erc20Wave3=1).

Now checking generic pipeline mapping for the source and looking for views/additional context.
Good. Now let me complete the remaining phases quickly.
**PHASE 4 CHECKPOINT: PASS** — AssetTypeId: 1=base crypto (12), 2=ERC-20 token (162). BlockchainCryptoId is a self-referential FK to CryptoID.

**PHASE 5 CHECKPOINT: PASS** — CryptoTypes is joined by CryptoID and BlockchainCryptoId in 15+ SPs across EXW_dbo.

**PHASE 6 CHECKPOINT: PASS** — Column groups: identity (CryptoID, Name, SymbolFull, DisplayName), blockchain config (MinReqAccounts, MinReqVerifications, MaxVerificationTimeMinutes, WebHookVerifications), balance/fee (BalanceThreshold, InitialFeeUnits, IsEtoroHandlingFee), display (AvatarUrl, OrderIndex, Precision), staking (StakingDisplayName, StakingAvatarUrl, StakingSymbolFull), ETL partition (etr_y, etr_ym, etr_ymd, SynapseUpdateDate).

**PHASE 7 CHECKPOINT: PASS** — No views reference CryptoTypes.

**PHASE 8 CHECKPOINT: PASS** — 18 SQL files reference CryptoTypes. All are readers (JOINs). No writer SP — loaded via Generic Pipeline.

**PHASE 9 CHECKPOINT: [-]** — No writer SP exists. Data loaded by Generic Pipeline (Override, daily) from WalletDB.Wallet.CryptoTypes.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline #625, Override strategy, 1440 min (daily), parquet format, source: WalletDB.Wallet.CryptoTypes.

**PHASE 10 CHECKPOINT: [-]** — Skipped (soft, low value for reference table).

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` present. No upstream wiki resolvable.

Now writing Phase 10B (lineage) and then Phase 11 (documentation).

```
PHASE GATE — EXW_Wallet.CryptoTypes:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no writer SP — Generic Pipeline)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
**PHASE 10B CHECKPOINT: PASS** — Lineage written.

Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.CryptoTypes:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/CryptoTypes/regen/attempt_1/CryptoTypes.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/CryptoTypes/regen/attempt_1/CryptoTypes.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/CryptoTypes/regen/attempt_1/CryptoTypes.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 4    Tier3: 31    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
