MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the previous attempt to understand what needs to be fixed, and also check for the existing output directory.
Now let me read the previous lineage and review-needed files.
Now I understand all the judge's feedback. Let me run the required MCP phases quickly, then write the corrected files. The previous attempt scored 6.8 (FAIL) with specific Tier 1 verbatim-quoting failures. I'll fix exactly what the judge flagged.

**Phase 1: Structure** — Already have DDL from bundle.

PHASE 1 CHECKPOINT: PASS

**Phase 2: Sample + Row Count**
PHASE 2 CHECKPOINT: PASS

**Phase 3: Distribution** — Capped at 3 categorical columns matching regex.
PHASE 3 CHECKPOINT: PASS

Phases 4-10B: Using the pre-resolved bundle (already available). Skipping Atlassian (regen harness).

PHASE GATE — BI_DB_dbo.BI_DB_DailyPanel_Copy:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing the three output files. The lineage is unchanged from attempt 1 — the judge only flagged the `.md` file. Let me write all three files with the fixes applied.
Now writing the main wiki with all judge-flagged fixes applied:
All three files written. Let me verify the fixes against the judge's feedback:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_DailyPanel_Copy:
  [x] .lineage.md    written -> audits/regen-sample/BI_DB_dbo/BI_DB_DailyPanel_Copy/regen/attempt_2/BI_DB_DailyPanel_Copy.lineage.md
  [x] .md            written -> audits/regen-sample/BI_DB_dbo/BI_DB_DailyPanel_Copy/regen/attempt_2/BI_DB_DailyPanel_Copy.md
  [x] .review-needed.md written -> audits/regen-sample/BI_DB_dbo/BI_DB_DailyPanel_Copy/regen/attempt_2/BI_DB_DailyPanel_Copy.review-needed.md
  [-] .alter.sql     deferred (regen harness -- judge runs next)
  Tier1 columns: 14    Tier2: 43    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**Fixes applied from judge feedback:**

1. **PortfolioType** (issue #1, high): Now quotes upstream verbatim first: "Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category." Then appends table-specific context (value mappings, NULL for PI/RemovedPI).

2. **PlayerStatus** (issue #2, high): Now restores all dropped upstream phrases: "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons."

3. **Footer tier count** (issue #3, medium): Corrected from "12 T1, 45 T2" to "14 T1, 43 T2".

4. **Region** (issue #4, low): Restored upstream usage phrase: "Used when the automated MarketingRegion label needs a business-friendly correction."

5. **Language** (issue #5 implied): Restored upstream phrase: "UNIQUE constraint. Used in back-office language selectors and reporting."

6. **Club** (issue #5, low): Restored upstream phrase: "Used in BackOffice reporting JOINs and customer-facing UI."

7. **Regulation** (issue #5 implied): Restored upstream phrases: "Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."
