Starting the regen pipeline for `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the required rule files and creating the output directory.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis (from DDL)**

Columns from DDL:
1. `Date` — date, NULL
2. `NameListID` — int, NULL
3. `ListName` — varchar(max), NULL
4. `CID` — bigint, NULL
5. `TypeOfChange` — varchar(max), NULL
6. `LoginName` — varchar(max), NULL
7. `ChangeTime` — datetime, NULL
8. `UpdateDate` — datetime, NULL

Distribution: ROUND_ROBIN, Clustered Index on `[Date]` ASC. 8 columns total.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 & 3 — Live Data Sampling & Distribution**
PHASE 2 CHECKPOINT: PASS — 537 rows, 2023-12-19 to 2026-04-17, active pipeline.
PHASE 3 CHECKPOINT: PASS — 2 TypeOfChange values, 20 lists, 451 distinct CIDs, 89 active dates.

Now running phases 4–10.
PHASE 4 CHECKPOINT: PASS — No Dim/Dictionary FK lookups in this table.
PHASE 5 CHECKPOINT: PASS — SP joins #ListCIDMapping_Log to #NameLists_Log on NamedListID for list name resolution.
PHASE 6 CHECKPOINT: PASS — Binary event model: CID Added / CID Deleted.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Writer: SP_CEPDailyAudit. No other SPs reference this table.
PHASE 9 CHECKPOINT: PASS — Full SP logic traced from bundle (see column mapping below).
PHASE 9B CHECKPOINT: PASS — Daily refresh, Priority 0, OpsDB/Service Broker, DELETE+INSERT for @Date.
PHASE 10 CHECKPOINT: PASS — No Atlassian sources (consistent with sibling audit tables).
PHASE 10A CHECKPOINT: PASS — Upstream bundle provides sibling wikis (NameLists, Rules, CP, etc.) and full SP code.
PHASE 10B — Writing lineage file now.

```
PHASE GATE — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final checklist:

```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ListCIDMapping/regen/attempt_1/Dealing_CEPDailyAudit_ListCIDMapping.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ListCIDMapping/regen/attempt_1/Dealing_CEPDailyAudit_ListCIDMapping.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ListCIDMapping/regen/attempt_1/Dealing_CEPDailyAudit_ListCIDMapping.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 8    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (sibling wikis used for business context, relationship mapping, and consistency validation; SP code used for all column lineage)
```
