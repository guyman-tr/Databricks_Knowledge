MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. DDL read. No upstream wiki — `_no_upstream_found.txt` confirmed. Starting pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — 21 columns, HASH(CountryID), HEAP.

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Row count DMV failed (permissions). Let me get the count via COUNT and read the SP.
Large SP. Let me read the relevant portions — first the top to understand the structure, and grep for the target table references.
Now I need to trace the crypto columns and the temp table chain. Let me read more of the SP and check for local Synapse wikis.
Let me trace the #wave temp table (for CryptoID/Crypto source) and read the Dim_Country wiki.
Now let me run Phase 3 distribution queries and read the Dim_Country Elements section for Tier 1 inheritance.
**PHASE 2 CHECKPOINT: PASS** — 51,642 rows, 250 countries × 171 cryptos (US exploded to 53 state/region rows = 9,063 US rows). All data refreshed 2026-04-15.

**PHASE 3 CHECKPOINT: PASS** — FromConversionAllowed/ToConversionAllowed both 100% zero. AllowedUserTagType/TagValue/SelectedValue all "Default"/"Default"/"false". FromTagType has 12 distinct combinations (Default/Country). US has state-level granularity (CountryID=219).

Now let me check remaining phases. Views scan was empty. SP scan found only SP_EXW_WalletElligibleCountries. Let me also search for Jira/Confluence and check the generic pipeline mapping.
**PHASE 4 CHECKPOINT: PASS** — CountryID → Dim_Country (wiki found), RegionByIP_ID → Dim_State_and_Province (wiki found), CryptoID → EXW_Wallet.CryptoTypes (no DWH dim/wiki).

**PHASE 5 CHECKPOINT: PASS** — SP joins Dim_Country, Dim_State_and_Province, EXW_Wallet.CryptoTypes, EXW_Settings.Resources/Tags/SystemRestrictions.

**PHASE 6 CHECKPOINT: PASS** — Crypto conversion eligibility matrix: country × crypto × direction (from/to), with tag-based EXW_Settings restriction weight system determining allowed/blocked status.

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: SP_EXW_WalletElligibleCountries (TRUNCATE+INSERT).

**PHASE 9 CHECKPOINT: PASS** — All 21 columns traced through SP code. Country/CountryID from Dim_Country; StateProvince/RegionByIP_ID from Dim_State_and_Province (CASE for US only); CryptoID/Crypto from EXW_Wallet.CryptoTypes; AllowedUser*/From*/To* settings from EXW_Settings via weight-priority resolution; FromConversionAllowed/ToConversionAllowed CASE-computed; UpdateDate=GETDATE().

**PHASE 9B CHECKPOINT: PASS** — Full TRUNCATE+INSERT on each run; no incremental logic.

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness, low value for dormant settings table).

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki (`_no_upstream_found.txt` confirmed). Local Synapse wikis checked: Dim_Country.md (Tier 1 source for Country, CountryID), Dim_State_and_Province.md (Tier 2 context for StateProvince, RegionByIP_ID).

**PHASE 10B CHECKPOINT: PASS** — Lineage resolved.

```
PHASE GATE — EXW_dbo.EXW_Conversion_Allowed_Country:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Let me ensure the directory exists.
Directory exists. Now writing the three files in order: lineage first, then wiki, then review-needed.
Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_dbo.EXW_Conversion_Allowed_Country:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_1/EXW_Conversion_Allowed_Country.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_1/EXW_Conversion_Allowed_Country.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_1/EXW_Conversion_Allowed_Country.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 19    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists; local Synapse wikis Dim_Country.md and Dim_State_and_Province.md used for Tier 1 transitivity on Country and CountryID)
```
