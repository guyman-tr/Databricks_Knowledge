MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the upstream bundle and check for SP references.
No upstream wiki available, `_no_upstream_found.txt` confirmed. Let me now search for the writer SP and start the pipeline phases.

**PHASE 1: Structure Analysis** — DDL already read from bundle. 80 columns total.

PHASE 1 CHECKPOINT: PASS

Now let me search for SPs referencing this table and run Phase 2 (sampling) in parallel.
PHASE 2 CHECKPOINT: Sample retrieved (10 rows). Row count DMV failed on permissions — let me get approximate count and read the SPs.
No writer SP found — all SPs reference this table as a SOURCE (reader), not a target. The table name "SF_Cases" suggests Salesforce origin. Let me check the pipeline mapping and run Phase 3.
PHASE 2 CHECKPOINT: PASS — 4,794,836 rows, date range 2020-01-01 to 2024-04-07.

PHASE 3 CHECKPOINT: PASS — Distributions collected for TicketStatus (17 values), Type_AtOpen (18 values), Country_AtOpen (223 values).

Now let me check for reader SPs more closely to understand the table's role, and search for any Salesforce-related loading pattern.
Let me read the OpsDB dependency entries and the batch context for this table.
Found the writer SP: `SP_SF_Cases`. Let me read it.
SP_SF_Cases is not in the SSDT repo — likely an external ETL (Salesforce data load). Let me check OpsDB status and read the reader SPs for context.
Now let me check for views referencing this table.
Good — no views reference this table. Now I have enough context to emit the phase gates and generate the three files.

**Summary of findings:**

- **Writer SP**: `SP_SF_Cases` — referenced in OpsDB but NOT present in SSDT repo. External ETL from Salesforce.
- **Reader SPs**: SP_CID_MonthlyPanel_FullData, SP_US_Apex_Rejected_Accounts, SP_M_AML_Account_Closed, SP_AML_Periodic_Review, SP_AML_KYC_SOF, SP_AML_ASIC_Dashboard (all use it for AML/compliance queries, joining on CID_Last).
- **No upstream wiki** — `_no_upstream_found.txt` confirmed.
- **All columns → Tier 3**: Writer SP code unavailable, no upstream wiki. Descriptions grounded in DDL names + live data sample evidence.

PHASE 4 CHECKPOINT: PASS — No resolvable Dim/Dict lookups (VerificationLevelID has no matching dim).
PHASE 5 CHECKPOINT: PASS — Reader SPs join on CID_Last to link cases to customers.
PHASE 6 CHECKPOINT: PASS — Dual-snapshot pattern (_AtOpen / _Last), boolean classification flags, CSAT metrics.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Writer: SP_SF_Cases (external). 5 reader SPs identified.
PHASE 9 CHECKPOINT: [-] Writer SP not in SSDT repo — cannot trace column-level source.
PHASE 9B CHECKPOINT: PASS — OpsDB: SP_SF_Cases, ProcessType=SQL, ProcessName=COPY DATA, depth=0.
PHASE 10 CHECKPOINT: [-] Skipped per regen harness.
PHASE 10A CHECKPOINT: PASS — No upstream wiki found (dormant marker present).
PHASE 10B CHECKPOINT: Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_SF_Cases_Panel:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (writer SP not in SSDT repo)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Lineage file written. Now writing the main wiki.
Now writing the review-needed file.
All three files written. Final checklist:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_SF_Cases_Panel:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_SF_Cases_Panel/regen/attempt_1/BI_DB_SF_Cases_Panel.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_SF_Cases_Panel/regen/attempt_1/BI_DB_SF_Cases_Panel.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_SF_Cases_Panel/regen/attempt_1/BI_DB_SF_Cases_Panel.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 83    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
