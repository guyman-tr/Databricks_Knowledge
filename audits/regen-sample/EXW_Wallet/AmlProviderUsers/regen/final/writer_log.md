MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis (from DDL in bundle)**

- 10 columns, all nullable
- Distribution: HASH(AmlProviderId), HEAP
- Index: XI_partition_date on partition_date ASC

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS (207,352 rows, 2020-05-27 to 2026-04-26)

Now running Phase 3 (distribution) and continuing SP analysis.
PHASE 3 CHECKPOINT: PASS (AmlProviderId: 3 distinct values — 1=167K, 3=27K, 4=13K)
Upstream wiki found despite `_no_upstream_found.txt`. Reading upstream sources.
PHASE 4 CHECKPOINT: PASS (AmlProviderId → Dictionary.AmlProviders: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN)
PHASE 5 CHECKPOINT: PASS (SP_EXW_AMLProviderID reads this table, JOINs with EXW_DimUser on Gcid)
PHASE 6 CHECKPOINT: PASS
PHASE 7 CHECKPOINT: PASS (no views reference this table directly)
PHASE 8 CHECKPOINT: PASS (SP_EXW_AMLProviderID is reader; no writer SP — loaded by Generic Pipeline)
PHASE 9 CHECKPOINT: PASS (SP_EXW_AMLProviderID analyzed — reads from this table, enriches with RealCID from EXW_DimUser, writes to EXW_AMLProviderID)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline, Append strategy, 1440 min / daily, from WalletDB.Wallet.AmlProviderUsers)
PHASE 10 CHECKPOINT: [-] Low-value for landing table, skipped
PHASE 10A CHECKPOINT: PASS (Upstream wiki found: WalletDB Wallet.AmlProviderUsers + Dictionary.AmlProviders)
PHASE 10B CHECKPOINT: PASS — writing lineage now

```
PHASE GATE — EXW_Wallet.AmlProviderUsers:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (low-value landing table) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Running the T1 copy verification:

```
T1 COPY VERIFICATION:
  Id: upstream "Auto-incrementing surrogate primary key." → wiki "Auto-incrementing surrogate primary key." — IDENTICAL
  AmlProviderId: upstream "The AML screening provider this registration is for: 1=Chainalysis, 4=ChainalysisCDN. See [AML Provider](...). FK to Dictionary.AmlProviders." → wiki "The AML screening provider this registration is for: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. FK to Dictionary.AmlProviders." — ENHANCED (added values 2 and 3 from Dictionary.AmlProviders wiki, stripped markdown link)
  Gcid: upstream "Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId." → wiki identical — IDENTICAL
  ProviderUserId: upstream "The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> \"NDY4NzA1OTQ=\"). Used in all API calls to the provider." → wiki identical — IDENTICAL
  Occurred: upstream "Timestamp when this customer was first registered with the AML provider." → wiki identical — IDENTICAL
```

```
OUTPUT CHECK — EXW_Wallet.AmlProviderUsers:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/AmlProviderUsers/regen/attempt_1/AmlProviderUsers.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/AmlProviderUsers/regen/attempt_1/AmlProviderUsers.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/AmlProviderUsers/regen/attempt_1/AmlProviderUsers.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 5    Tier2: 0    Tier3: 5    Tier4: 0
  Bundle inheritance used: YES (Wallet.AmlProviderUsers upstream wiki discovered independently via CryptoDBs/WalletDB routing, despite _no_upstream_found.txt marker)
```
