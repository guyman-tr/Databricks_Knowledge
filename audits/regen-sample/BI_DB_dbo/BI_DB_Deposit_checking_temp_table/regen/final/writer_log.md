MCP PRE-FLIGHT: PASS

Now let me read the existing attempt 1 files to understand what was correct, then apply the judge's fixes.
Now let me run a quick data sample and read the golden reference for the correct section structure.
PHASE GATE — BI_DB_dbo.BI_DB_Deposit_checking_temp_table:
```
  [x] P1 DDL          — 5 columns verified from DDL
  [x] P2 Sample        — 1 row sampled (2026-04-27 03:33:55), diff=0, Error_Message=NULL
  [x] P3 Dist          — no columns match regex (no Status/Type/Code/etc.)
  [x] P4 Lookup       — no lookup dims
  [x] P5 JOIN          — result table; no JOINs on this table
  [x] P6 BizLogic     — SP source fully analyzed
  [x] P7 Views         — none found
  [x] P8 SP-scan      — SP_Client_Balance_Check_Opening_Balance identified
  [x] P9 SP-logic     — SP flow: check OB → check deposits → IF/ELSE/RAISERROR → DELETE/INSERT
  [x] P9B ETL         — ETL chain documented
  [x] P10 Jira         — none in bundle
  [x] P10A Upstream   — BI_DB_Client_Balance_Aggregate_Level_New, Fact_CustomerAction
  [x] P10B Lineage    — column-level lineage documented
  → Ready for P11
```

Now applying all judge fixes and writing the three files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Deposit_checking_temp_table:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Deposit_checking_temp_table/regen/attempt_2/BI_DB_Deposit_checking_temp_table.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Deposit_checking_temp_table/regen/attempt_2/BI_DB_Deposit_checking_temp_table.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Deposit_checking_temp_table/regen/attempt_2/BI_DB_Deposit_checking_temp_table.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**Judge fixes applied in attempt_2:**

1. **Error_Message NULL** — Section 2.1, Section 3.4, Section 4 Element row, and lineage all corrected to "NULL (not empty string)" with explanation that `@v_error_message_deposit` is declared but never SET in the success branch.

2. **UpdateDate staleness gotcha** — Added to Section 3.4: RAISERROR(severity 18) for opening-balance mismatch aborts before DELETE/INSERT, leaving stale data. Also noted in Section 1, Section 4, and Section 8.

3. **UC Target** — Added `| **UC Target** | Not yet provisioned |` to property table.

4. **Tier Confidence Legend** — Added 4-row stars/tier table to top of Section 4 Elements.

5. **Section 5 restructured** — Added 5.1 Production Sources table, moved diagram to 5.2, References To → 5.3, Referenced By → 5.4.

6. **Footer** — Replaced bare property table with proper `*Generated/Quality/Phases/Tiers/Object*` footer lines.
