MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline phases. Phase 1 is complete from the DDL in the bundle (103 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on CID).

PHASE 1 CHECKPOINT: PASS

Running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Phase 2 sample obtained. Row count DMV failed on permissions — let me try alternative. Also reading the referenced SPs.
PHASE 2 CHECKPOINT: PASS — 4,998,529 rows, BeginTime range 2020-01-23 to 2024-06-02, UpdateDate uniformly 2024-06-02 (table appears stale since June 2024).

Now running Phase 3 (distribution on categorical columns) and continuing SP reads.
PHASE 3 CHECKPOINT: PASS — Regulation: 8 values (CySEC 57%, FCA 24%, ASIC & GAML 7%); RiskScoreName: 4 values (Medium 91%, High 8%, Low 1%).

Now running Phases 4-7 and 10 in parallel.
PHASE 3 CHECKPOINT: PASS

Now completing remaining phases:

- **P4**: RegulationID → maps to Dim_Regulation; CID/GCID are customer identifiers
- **P5**: SP_LTV_By_FTD_MOP joins `dc.RealCID = bdrc.CID`; SP_EXW_UserSettingsWalletAllowance joins `rc.CID = e.RealCID`
- **P6**: Risk factor scoring pattern — each factor has `_RiskScore` (int) + `_Value` (varchar) pair; SCD pattern with BeginTime/EndTime
- **P7**: No views reference this table
- **P8**: No writer SP; 2 reader SPs
- **P9**: [-] No writer SP exists — table loaded externally from RiskClassification.dbo.V_RiskClassificationDataLake
- **P9B**: Generic Pipeline, weekly (10080 min), Override, `risk-fg-RiskClassification` server
- **P10**: [-] Skipped for regen harness
- **P10A**: No upstream wiki resolvable; `_no_upstream_found.txt` present

PHASE GATE — BI_DB_dbo.BI_DB_RiskClassification:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no writer SP — external load)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing the three output files. Starting with `.lineage.md`.
Now writing the main wiki `.md` file.
Now writing the `.review-needed.md` file.
All three files written. Final checklist:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_RiskClassification:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_RiskClassification/regen/attempt_1/BI_DB_RiskClassification.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_RiskClassification/regen/attempt_1/BI_DB_RiskClassification.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_RiskClassification/regen/attempt_1/BI_DB_RiskClassification.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 103    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
