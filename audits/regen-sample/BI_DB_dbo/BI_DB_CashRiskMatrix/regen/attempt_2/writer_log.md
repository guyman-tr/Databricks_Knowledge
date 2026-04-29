MCP PRE-FLIGHT: PASS

Now let me read the existing attempt_1 wiki files to understand what needs to be fixed.
Now I have everything I need. Let me run the data sample to confirm production statistics, then build the corrected files for attempt_2.
PHASE GATE — BI_DB_dbo.BI_DB_CashRiskMatrix:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Applying all 5 judge fixes. Writing lineage file first (Phase 10B), then main wiki, then review-needed.
Now the main wiki with all 5 judge fixes applied:
All three files written. Here is the final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CashRiskMatrix:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_2/BI_DB_CashRiskMatrix.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_2/BI_DB_CashRiskMatrix.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_2/BI_DB_CashRiskMatrix.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 51    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**Fixes applied from judge feedback:**

| # | Issue | Fix |
|---|-------|-----|
| 1 | `Bid` description had "Compare to **AskSpreaded**" | Changed to "Compare to **BidSpreaded** to derive the spread." (verbatim from upstream Fact_CurrencyPriceWithSplit wiki) |
| 2 | §5.2 was a step table | Replaced with ASCII pipeline diagram using object names and arrows |
| 3 | Section 1 claimed "**49** price-shock scenarios" | Corrected to "**47**" (25 upside + 22 downside, verified from DDL) |
| 4 | Sub-headers said "**24** columns" for both upside and downside | Corrected to "**25** columns" (upside) and "**22** columns" (downside) |
| 5 | Footer missing Quality and Phases | Added `Quality: 8.0/10 \| Phases: 11/14` |
