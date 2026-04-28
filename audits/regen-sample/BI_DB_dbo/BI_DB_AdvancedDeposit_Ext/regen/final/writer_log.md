MCP PRE-FLIGHT: PASS

Now let me load the rules and read the existing attempt 1 files in parallel.
Rules loaded, bundle confirmed: **NO UPSTREAM WIKI** available. All columns must be Tier 2 or Tier 3. Let me now find the SP source, read attempt 1, and start sampling.
Table is empty (0 rows) — confirmed dormant. Let me read the SP code and attempt 1 files.
PHASE 1 CHECKPOINT: PASS — DDL read from SSDT (47 columns, ROUND_ROBIN, HEAP)
PHASE 2 CHECKPOINT: PASS — 0 rows returned (table is dormant/empty)
PHASE 3 CHECKPOINT: PASS — Distribution analysis not possible on empty table (0 rows)
PHASE 4 CHECKPOINT: PASS — Lookup tables identified from SP_H_Deposits JOINs
PHASE 5 CHECKPOINT: PASS — JOIN analysis complete from SP_H_Deposits (10 dim/external JOINs)
PHASE 6 CHECKPOINT: PASS — Business logic: deposit denormalization, BIN analysis, acquisition attribution
PHASE 7 CHECKPOINT: PASS — No views reference this dormant table
PHASE 8 CHECKPOINT: PASS — SP_H_Deposits creates #AdvancedDeposit_Ext temp (identical structure), writes to BI_DB_Deposits
PHASE 9 CHECKPOINT: PASS — Full SP code traced, all 47 columns mapped to sources
PHASE 9B CHECKPOINT: PASS — Daily incremental ETL (targets BI_DB_Deposits, not this table)
PHASE 10 CHECKPOINT: PASS — No Jira/Confluence sources found
PHASE 10A CHECKPOINT: PASS — No upstream wiki available (confirmed by bundle + _no_upstream_found.txt)
PHASE 10B CHECKPOINT: PASS — Lineage file ready to write

Now let me write all three output files. Creating output directory first.
PHASE GATE — BI_DB_dbo.BI_DB_AdvancedDeposit_Ext:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (0 rows — empty table)
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (dormant, no views)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (none found)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing all three files — lineage first, then wiki, then review-needed.
All three files written. Let me verify they exist.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_AdvancedDeposit_Ext:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_AdvancedDeposit_Ext/regen/attempt_2/BI_DB_AdvancedDeposit_Ext.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_AdvancedDeposit_Ext/regen/attempt_2/BI_DB_AdvancedDeposit_Ext.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_AdvancedDeposit_Ext/regen/attempt_2/BI_DB_AdvancedDeposit_Ext.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 47    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```

**Fixes applied from judge feedback:**
1. All 47 columns re-tagged to `(Tier 2 — SP_H_Deposits code analysis)` — no upstream wiki in bundle, Tier 1 impossible
2. Removed fabricated "Full 39-value enum in upstream wiki" from PaymentStatusID
3. Funnel, FunnelFrom, AcquisitionFunnel now have **distinct descriptions**: deposit-level funnel (fbd.FunnelID), customer's originating registration funnel (CC.FunnelFromID), customer's current acquisition funnel (CC.FunnelID)
4. Country vs BINCountry differentiated: Country = customer registration country (via Dim_Customer.CountryID); BINCountry = card-issuing bank country (via fbd.BinCountryIDAsInteger)
5. Phase Gate Checklist section added to Section 4
6. Footer tier breakdown updated to 0 T1, 47 T2
