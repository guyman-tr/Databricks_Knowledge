

**MCP PRE-FLIGHT CHECK**
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — DDL Structure** (from bundle)

- 5 columns: Date (datetime NOT NULL), CID (int NOT NULL), Gain_y (float NULL), Year1 (int NULL), UpdateDate (datetime NOT NULL)
- Distribution: ROUND_ROBIN
- Index: CLUSTERED INDEX (Date ASC)

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
PHASE 2 CHECKPOINT: PASS

- ~20.2M rows total
- Date range: 2007-12-01 to 2024-01-01
- 17 distinct Year1 values (2007–2023)
- Historical pattern shift: Dec 1 snapshots (2007–2020), Jan 1 snapshots (2022–2024)
- Gain_y values are decimals (e.g., 0.0914 = 9.14% gain, -0.0179 = 1.79% loss)

**PHASE 3 — Distribution Analysis**

No obviously-categorical columns match the regex `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`. Year1 is an integer year (17 values), but it's not categorical in the regex sense. Skipping distribution queries per Phase 3 cap.

PHASE 3 CHECKPOINT: PASS (0 categorical columns — no distribution queries needed)

**PHASE 4 — Lookup Resolution**

No FK columns referencing Dim/Dictionary tables directly. CID → Dim_Customer.RealCID is the only lookup.

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**

From SP code section 3.7, the table is consumed via:
```sql
SELECT Year1, CID, Gain_y FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
```
UNIONed with current YTD to calculate average yearly gain.

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**

- Table stores one yearly gain snapshot per customer per completed year
- Used to compute `AVG(Gain_y)` across all years for PI average yearly performance
- Date column historically used Dec 1 (pre-2021) and Jan 1 (2022+) as snapshot dates
- Year1 = the completed calendar year the gain covers

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependency Scan**
No views reference this table. Only the writer SP references it.

PHASE 7 CHECKPOINT: PASS (no views)

**PHASE 8 — SP Scan**

Writer SP: `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (already in bundle).

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic Extraction**

From the SP (section 3.4), the INSERT into BI_DB_PastYearsGain:
- Source: `DWH_GainDaily` joined with `#FullDate` (V_Dim_Date WHERE DayNumberOfYear=1)
- Condition: `a.Date = @yesterday` AND `a.Date = b.FullDate` — only fires when @yesterday is Jan 1
- Column mapping:
  - Date ← DWH_GainDaily.Date (passthrough)
  - CID ← DWH_GainDaily.CID (passthrough)
  - Gain_y ← DWH_GainDaily.Gain_y (passthrough)
  - Year1 ← `YEAR(Date)-1` (ETL-computed)
  - UpdateDate ← `GETDATE()` (ETL-computed)

Consumer (section 3.7): UNIONed with current YTD gain to calculate `AVG(Gain_y)` per CID for PI dashboard.

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**

- Refresh: Annual — INSERT only fires when @yesterday = Jan 1 of a year
- No DELETE before INSERT (append-only)
- Part of SP_PI_Dashboard_COPYDATA_RuningSideBySide which runs daily, but the PastYearsGain INSERT is conditional

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**

[-] Skipped — regen harness mode

PHASE 10 CHECKPOINT: [-] Skipped (regen harness)

**PHASE 10A — Upstream Wiki**

Bundle contains DWH_GainDaily wiki (the primary source). CID traces to Dim_Customer.RealCID (wiki available).

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**

Now writing the lineage file first.

```
PHASE GATE — BI_DB_dbo.BI_DB_PastYearsGain:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PastYearsGain:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PastYearsGain/regen/attempt_1/BI_DB_PastYearsGain.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PastYearsGain/regen/attempt_1/BI_DB_PastYearsGain.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PastYearsGain/regen/attempt_1/BI_DB_PastYearsGain.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 4    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
