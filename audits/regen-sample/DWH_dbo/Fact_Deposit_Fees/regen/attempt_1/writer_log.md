MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Starting pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 46 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on CID.

Now running Phase 2 (sampling + row count) and starting repo searches for views/SPs in parallel.
**PHASE 2 CHECKPOINT: PASS** — Sample retrieved (10 rows). Row count DMV blocked by permissions; let me try an alternative.
Data range is 2021-12-01 to 2024-06-30, no data after that — table appears dormant. Let me get distributions from the existing data range and a total row count.
**PHASE 3 CHECKPOINT: PASS** — 14.4M rows, date range 2021-12-01 to 2024-06-30, distributions captured.

Now running remaining phases. Let me get a few more distributions and check for NULL patterns, then search for upstream context.
Good. Now Phase 4 (Lookup), Phase 5 (JOINs) — the SP has no JOINs, it's a straight SELECT from staging. Let me also check for the generic pipeline mapping and Jira context.
Good. The `_no_upstream_found.txt` confirms no resolvable upstream wiki. The source is `BackOffice.BillingDepositsPCIVersion` via ADF pipelines.

**PHASE 4 CHECKPOINT: PASS** — No FK/Dim lookups in the SP; all columns are straight passthroughs from staging.
**PHASE 5 CHECKPOINT: PASS** — SP has no JOINs; single-source INSERT from `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion`.
**PHASE 6 CHECKPOINT: PASS** — Business logic extracted from data distributions (deposit statuses, funding methods, regulations, fee structures).
**PHASE 7 CHECKPOINT: [-]** — No views reference Fact_Deposit_Fees.
**PHASE 8 CHECKPOINT: PASS** — Single writer SP: `SP_Fact_Deposit_Fees_DL_To_Synapse`. No reader SPs found.
**PHASE 9 CHECKPOINT: PASS** — SP logic: straight passthrough of 44 columns from staging. Two computed columns: `ModificationDateID` (date-int from StatusModificationTime), `UpdateDate` (getdate()).
**PHASE 9B CHECKPOINT: PASS** — ETL: ADF pipeline `etoroBackOfficeToDataLake` → Data Lake → `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion` → SP inserts to fact table. Table dormant since 2024-06-30.
**PHASE 10 CHECKPOINT: [-]** — Skipping Jira/Confluence in regen harness (low-value for dormant table).
**PHASE 10A CHECKPOINT: PASS** — No upstream wiki available (confirmed by `_no_upstream_found.txt`). Source is `BackOffice.BillingDepositsPCIVersion` (production DB, no wiki documented).
**PHASE 10B CHECKPOINT: PASS** — Writing lineage file now.

```
PHASE GATE — DWH_dbo.Fact_Deposit_Fees:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files. Let me verify the output directory exists first.
Now writing the three output files. Lineage first, then wiki, then review-needed.
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — DWH_dbo.Fact_Deposit_Fees:
  [x] .lineage.md    written → audits/regen-sample/DWH_dbo/Fact_Deposit_Fees/regen/attempt_1/Fact_Deposit_Fees.lineage.md
  [x] .md            written → audits/regen-sample/DWH_dbo/Fact_Deposit_Fees/regen/attempt_1/Fact_Deposit_Fees.md
  [x] .review-needed.md written → audits/regen-sample/DWH_dbo/Fact_Deposit_Fees/regen/attempt_1/Fact_Deposit_Fees.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 2    Tier3: 45    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
