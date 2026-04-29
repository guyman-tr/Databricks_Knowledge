MCP PRE-FLIGHT: PASS

Now loading the required rule files and the previous attempt's output to understand what needs fixing.
Good — attempt 1 exists. Let me read the previous attempt's wiki and lineage to understand what needs fixing based on the judge feedback.
Now let me read the previous lineage file and review-needed file.
Now I have a clear picture. The previous attempt was solid but the judge flagged 7 specific issues. Let me run the required pipeline phases and then generate corrected output.

**Phase 1 — DDL**: Already in the bundle. 139 columns, HASH(CID), CLUSTERED INDEX.

**Phase 2 — Sample + row count**:
PHASE 2 CHECKPOINT: PASS — 46.7M rows, sample confirms live data.

**Phase 3 — Distribution**: Quick check on key columns.
PHASE 3 CHECKPOINT: PASS

Now I have all the data I need. The previous attempt was comprehensive — I just need to fix the 7 judge-flagged issues. Let me now create the output directory and write the corrected files.
Now let me print the phase gate and write all three files. I'll apply all 7 judge fixes:

```
PHASE GATE — BI_DB_dbo.BI_DB_CIDFirstDates:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Writing lineage first, then wiki, then review-needed. The key fixes from the judge:

1. **Channel/SubChannel**: Tier 1 → **Tier 2** (SP-computed CASE in Dim_Channel)
2. **Region**: Tier 2 → **Tier 1** (dim-lookup → Dictionary.MarketingRegion)
3. **State**: Tier 2 → **Tier 1** (dim-lookup → Dictionary.RegionName)
4. **Email**: Restore upstream text verbatim (uniqueness, LowerEmail, trigger)
5. **Club**: Restore upstream text verbatim (Internal/N/A, BackOffice)
6. **BirthDate**: Restore LinkedAccountHash1 reference
7. **LabelName**: Restore multi-LabelID sharing note
Now writing the main wiki with all 7 judge fixes applied. I'll copy the previous attempt and apply targeted fixes to the flagged elements only.
Now apply the 7 targeted fixes:

**Fix 1: Club (#5) — restore upstream verbatim text**
Now I'll apply all 7 fixes:
Now update the footer tier counts to reflect the changes (Channel and SubChannel moved from T1 to T2 = -2 T1, +2 T2; Region and State moved from T2 to T1 = +2 T1, -2 T2; net T1 stays at 27, T2 stays at 68).
Now write the review-needed file (copy from attempt 1 since it was not flagged):
Now verify all three files exist:
All three files exist. Let me verify the key fixes were applied correctly:
All 7 fixes confirmed:
1. **Club** (line 231): Now includes "Internal, N/A" and "BackOffice reporting JOINs"
2. **Channel** (line 233): Now Tier 2 with AffWizz CASE expression origin
3. **SubChannel** (line 234): Now Tier 2 with CASE expression derivation
4. **LabelName** (line 235): Now includes multi-LabelID sharing note (0, 1, 9)
5. **Region** (line 238): Now Tier 1 -- Dictionary.MarketingRegion
6. **Email** (line 240): Now includes uniqueness, LowerEmail, trigger semantics
7. Let me verify BirthDate and State:
All 7 fixes confirmed:
- **BirthDate** (line 256): Now includes LinkedAccountHash1 reference
- **State** (line 263): Now Tier 1 -- Dictionary.RegionName

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CIDFirstDates:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFirstDates/regen/attempt_2/BI_DB_CIDFirstDates.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFirstDates/regen/attempt_2/BI_DB_CIDFirstDates.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFirstDates/regen/attempt_2/BI_DB_CIDFirstDates.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 27    Tier2: 68    Tier3: 44    Tier4: 0
  Bundle inheritance used: YES
```
