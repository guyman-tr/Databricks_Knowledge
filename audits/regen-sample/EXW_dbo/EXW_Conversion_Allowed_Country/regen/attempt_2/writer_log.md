MCP PRE-FLIGHT: PASS

Now let me read the previous attempt, the upstream bundle, the DDL, and the key rule files in parallel.
Now let me read the previous attempt's output files and the Dim_Country/Dim_State_and_Province wikis that the judge flagged as existing.
Good. I have the previous attempt and the Dim_Country/Dim_State_and_Province upstream wikis. The judge feedback is clear — 5 specific fixes needed. Let me run the pipeline phases now.

**Phase 1: DDL** — Already have from bundle. 21 columns confirmed.

PHASE 1 CHECKPOINT: PASS

Running Phase 2 (sample) and Phase 3 (distribution) in parallel:
PHASE 2 CHECKPOINT: PASS — 51,642 rows sampled, data confirmed.
PHASE 3 CHECKPOINT: PASS — Distribution values confirmed.

Phases 4-10 were already completed in attempt 1 — the judge confirmed the SP analysis, lineage, and business logic were correct. Only specific column descriptions and review-needed sidecar need fixing.

Let me now verify the exact upstream text from Dim_Country wiki to ensure verbatim quoting:
I now have the exact verbatim text from Dim_Country.md for both columns. Let me now write all three output files. The key fixes from the judge:

1. **Country** (line 155→row 4 of Dim_Country): `Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.` — must include "Unique per row." and append lineage context AFTER.
2. **CountryID** (line 155→row 1 of Dim_Country): `Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer.` — must include the 0=Not available sentinel. Append supplementary context AFTER.
3. **AllowedUserTagType** — inline key=value enumeration (1 value: Default=51,642 rows)
4. **FromConversionAllowed** — inline key=value: 0=not allowed (51,642 rows)
5. **ToConversionAllowed** — inline key=value: 0=not allowed (51,642 rows)
6. **review-needed.md** — flag upstream bundle resolution gap

Let me check the output directory exists, then write all three files.
Now let me print the phase gate and write all three files. Starting with the lineage file (must be written FIRST):

```
PHASE GATE — EXW_dbo.EXW_Conversion_Allowed_Country:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now the main wiki file with all judge fixes applied:
Now the review-needed sidecar with the upstream bundle resolution gap flagged:
Now let me do the T1 copy verification against the upstream wiki:

```
T1 COPY VERIFICATION:
  Country: upstream "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." → wiki "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." — IDENTICAL (stats stripped: none). Supplementary context appended after quote: "Passthrough from Dim_Country (c.Name AS Country). CountryID=0 excluded by SP WHERE clause."
  CountryID: upstream "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer." → wiki "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer." — IDENTICAL (stats stripped: none). Supplementary context appended after quote: "CountryID=0 excluded by SP WHERE clause. Distribution key for this table."
```

```
OUTPUT CHECK — EXW_dbo.EXW_Conversion_Allowed_Country:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_2/EXW_Conversion_Allowed_Country.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_2/EXW_Conversion_Allowed_Country.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_2/EXW_Conversion_Allowed_Country.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 19    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (manually resolved from Dim_Country.md despite bundle gap)
```
