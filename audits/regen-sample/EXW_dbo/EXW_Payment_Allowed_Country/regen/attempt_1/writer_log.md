MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL + bundle.
Rules loaded. Now let me read the DDL, check for SPs, and start the pipeline phases.

**Phase 1 — Structure Analysis**

The DDL is already in the bundle. Let me confirm the structure:

- **Table**: `EXW_dbo.EXW_Payment_Allowed_Country`
- **16 columns**: CountryID, Country, StateProvince, RegionByIP_ID, CryptoID, Crypto, AllowedUserResource, AllowedUserTagType, AllowedUserTagValue, AllowedUserSelectedValue, CryptosResourceName, CryptosTagType, CryptosTagValue, CryptosSelectedValue, PaymentAllowed, UpdateDate
- **Distribution**: HASH(CountryID)
- **Index**: HEAP

Let me now search for SPs referencing this table and run sampling queries in parallel.
PHASE 1 CHECKPOINT: PASS

**Phase 2 — Live Data Sampling**

Sample retrieved. Let me get row count and read the SP.
Now let me find the `#finalpaym`, `#paymentalloweduser`, and `#cryptosresourcename` temp table definitions to trace the full column lineage.
Now let me run the distribution queries and check for views referencing this table.
PHASE 2 CHECKPOINT: PASS (52,548 rows, 250 countries × 174 cryptos, single UpdateDate 2026-04-15)

PHASE 3 CHECKPOINT: PASS (PaymentAllowed always 0, AllowedUserTagType always "Default", StateProvince non-null only for CountryID=219/US)

Now let me check for existing DWH wikis for upstream dimension tables used in this SP.
Existing wikis found for upstream dims. Let me read the relevant sections for Tier 1 inheritance.
Now let me read the Dim_Country Elements section for the columns I need.
Now let me check for UC target mapping and the generic pipeline mapping.
Let me check UC target and search for any Atlassian context.
Now I have all the information needed. Let me check the existing wiki to see if there's a UC target defined.
Good. Now let me verify the output directory exists and then generate all three files.
PHASE 4 CHECKPOINT: PASS (CountryID → Dim_Country, CryptoID → EXW_Wallet.CryptoTypes, RegionByIP_ID → Dim_State_and_Province)

PHASE 5 CHECKPOINT: PASS (JOINs: Dim_Country ON CountryID, Dim_State_and_Province ON CountryID, #wave/CryptoTypes CROSS APPLY, EXW_Settings tables via tag weight resolution)

PHASE 6 CHECKPOINT: PASS (Two permission domains: AllowedUser resource + Cryptos resource; PaymentAllowed = AND logic of both; US state-level granularity for CountryID=219)

PHASE 7 CHECKPOINT: PASS (No views reference this table)

PHASE 8 CHECKPOINT: PASS (Writer SP: SP_EXW_WalletElligibleCountries — TRUNCATE+INSERT pattern)

PHASE 9 CHECKPOINT: PASS (Full source-to-target map traced through #preppayment → #finalpaym → INSERT, #paymentalloweduser, #cryptosresourcename)

PHASE 9B CHECKPOINT: PASS (SP runs as standalone EXEC, full reload via TRUNCATE+INSERT)

PHASE 10 CHECKPOINT: [-] (Skipping Atlassian search — configuration/settings table, low Jira value)

PHASE 10A CHECKPOINT: PASS (_no_upstream_found.txt present — no production wiki resolvable. Local Synapse wikis for Dim_Country and Dim_State_and_Province read for dim-lookup Tier 1 inheritance)

Now let me write the lineage file first (Phase 10B), then the wiki, then the review-needed.

```
PHASE GATE — EXW_dbo.EXW_Payment_Allowed_Country:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (config table, low value)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```
PHASE 10B CHECKPOINT: PASS

Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_dbo.EXW_Payment_Allowed_Country:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_Payment_Allowed_Country/regen/attempt_1/EXW_Payment_Allowed_Country.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_Payment_Allowed_Country/regen/attempt_1/EXW_Payment_Allowed_Country.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_Payment_Allowed_Country/regen/attempt_1/EXW_Payment_Allowed_Country.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 14    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists; local Synapse wikis used for dim-lookup Tier 1)
```
