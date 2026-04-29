MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 4 columns (ContractTypeID int, Name varchar(20), InsertDate datetime, UpdateDate datetime), REPLICATE distribution, CLUSTERED INDEX on ContractTypeID.

Now running P2 (sampling), P3 (distribution), and SP/view scans in parallel.
**PHASE 2 CHECKPOINT: PASS** — 9 rows, all distinct. Values: 0=N/A, 1=CPR, 2=CPA, 3=Rev, 4=Hyb, 5=Other, 6=eCost, 7=ZeroCost, 8=CPL. InsertDate/UpdateDate all NULL.

**PHASE 3 CHECKPOINT: PASS** — 9 unique rows, 1:1 mapping ContractTypeID→Name. No NULLs in key columns. InsertDate/UpdateDate entirely NULL across all rows.

Now checking SP references and views.
Good findings. Let me check the generic pipeline mapping and look for any Atlassian context.
Now I have all the data I need. Let me complete the remaining phase gates and note findings:

**PHASE 4 CHECKPOINT: PASS** — No FK lookups needed. This IS a lookup/dimension table itself.

**PHASE 5 CHECKPOINT: PASS** — SP_Marketing_Cube JOINs Dim_ContractType to Dim_Affiliate on `DA.ContractType = DCT.ContractTypeID` to resolve contract type names.

**PHASE 6 CHECKPOINT: PASS** — Simple enum lookup. 9 values representing affiliate contract types: 0=N/A, 1=CPR, 2=CPA, 3=Rev, 4=Hyb, 5=Other, 6=eCost, 7=ZeroCost, 8=CPL.

**PHASE 7 CHECKPOINT: PASS** — No views reference Dim_ContractType.

**PHASE 8 CHECKPOINT: PASS** — Reader: SP_Marketing_Cube (JOINs to resolve Name). SP_Dim_Affiliate computes ContractType column value using CASE on ContractName. No dedicated writer SP for Dim_ContractType itself — static lookup loaded via migration.

**PHASE 9 CHECKPOINT: PASS** — No writer SP. Table was loaded via DWH_Migration.Dim_ContractType (ROUND_ROBIN staging → REPLICATE target). SP_Dim_Affiliate produces the FK values that reference this table.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline: Override copy strategy, daily (1440 min), parquet, Gold export to UC.

**PHASE 10 CHECKPOINT: [-]** — Skipped (low-value static lookup, no Jira context expected).

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki found (`_no_upstream_found.txt` confirmed). Dormant/static lookup table.

Now writing the three output files. Lineage first.

```
PHASE GATE — DWH_dbo.Dim_ContractType:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (static lookup, low value)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.

Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — DWH_dbo.Dim_ContractType:
  [x] .lineage.md    written → audits/regen-sample/DWH_dbo/Dim_ContractType/regen/attempt_1/Dim_ContractType.lineage.md
  [x] .md            written → audits/regen-sample/DWH_dbo/Dim_ContractType/regen/attempt_1/Dim_ContractType.md
  [x] .review-needed.md written → audits/regen-sample/DWH_dbo/Dim_ContractType/regen/attempt_1/Dim_ContractType.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 4    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
