MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline for `EXW_Wallet.WalletPoolStatuses`.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

Columns: 13
- `Id` bigint NULL
- `WalletPoolId` bigint NULL
- `WalletPoolStatusId` int NULL
- `Occurred` datetime2(7) NULL
- `PromotionTagId` int NULL
- `CorrelationId` uniqueidentifier NULL
- `Processed` bit NULL
- `CryptoId` int NULL
- `etr_y` varchar(max) NULL
- `etr_ym` varchar(max) NULL
- `etr_ymd` varchar(max) NULL
- `SynapseUpdateDate` datetime NULL
- `partition_date` date NULL

Distribution: HASH(WalletPoolId), HEAP, Index on partition_date.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Phase 2 sample retrieved. Row count DMV failed (permissions), let me try an alternative approach. In parallel, let me read the SPs that reference this table and check the CopyFromLake staging.
PHASE 2 CHECKPOINT: PASS (3.24M rows, 2018-04-23 to 2026-04-26, sample retrieved)

PHASE 3 CHECKPOINT: PASS (WalletPoolStatusId: 9 statuses, CryptoId: 11 values, Processed: all False)

Now running remaining phases. Let me check views, the generic pipeline mapping, and Jira.
Now I have all the data needed. Let me complete the remaining phase gates.

PHASE 4 CHECKPOINT: PASS (WalletPoolStatusId → 9 dictionary values: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign)

PHASE 5 CHECKPOINT: PASS (SP_EXW_WalletInventory JOINs: WalletPool on Id=WalletPoolId, Dictionary on WalletPoolStatusId=Id)

PHASE 6 CHECKPOINT: PASS (Status lifecycle tracking; latest-status pattern via ROW_NUMBER PARTITION BY WalletPoolId ORDER BY Occurred DESC)

PHASE 7 CHECKPOINT: [-] No views reference this table

PHASE 8 CHECKPOINT: PASS (Reader SPs: SP_EXW_WalletInventory, SP_EXW_Hourly — both read WalletPoolStatuses for latest status per pool)

PHASE 9 CHECKPOINT: PASS (Both SPs use ROW_NUMBER to get latest status; columns are passthrough from source — no writer SP, loaded via Generic Pipeline)

PHASE 9B CHECKPOINT: PASS (Generic Pipeline Append, 120min, WalletDB.Wallet.WalletPoolStatuses → CopyFromLake_staging → EXW_Wallet.WalletPoolStatuses)

PHASE 10 CHECKPOINT: [-] Low-value for CopyFromLake passthrough table with no upstream wiki

PHASE 10A CHECKPOINT: [-] _no_upstream_found.txt present — no upstream wiki resolvable

PHASE 10B: Writing lineage file now.

```
PHASE GATE — EXW_Wallet.WalletPoolStatuses:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [-] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.WalletPoolStatuses:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/WalletPoolStatuses/regen/attempt_1/WalletPoolStatuses.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/WalletPoolStatuses/regen/attempt_1/WalletPoolStatuses.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/WalletPoolStatuses/regen/attempt_1/WalletPoolStatuses.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 13    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
