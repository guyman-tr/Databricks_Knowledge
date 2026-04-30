MCP PRE-FLIGHT: PASS

Now let me read the previous attempt files and the required rule files in parallel.
Now let me run the Phase 2 sample query and Phase 3 distribution queries, plus read additional rules.
Let me check for UC target information.
Good. Now I have all the data I need. Let me print the phase gates and write the three output files with the judge's fixes applied.

PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_Cashouts:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness — skipped)
  [x] P10A Upstream    [x] P10B Lineage    → Ready for P11

Now writing all three files. The changes from attempt 1 based on judge feedback:

1. **CardType**: Full verbatim from Dim_CardType wiki with all 18 types, uniqueness constraint, rename note
2. **IsCreditReportValidCB**: Re-tagged as Tier 1 — Fact_SnapshotCustomer
3. **BaseExchangeRate**: Re-tagged as Tier 1 — BI_DB_DepositWithdrawFee  
4. **ExchangeFee**: Re-tagged as Tier 1 — BI_DB_DepositWithdrawFee
5. **Amount**: Upstream verbatim + DWH note for cashout context
6. **UC Target**: Added to property table (not exported)
7. **Occurred**: Full upstream text preserved
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_Cashouts:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Cashouts/regen/attempt_2/BI_DB_EY_Audit_Cashouts.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Cashouts/regen/attempt_2/BI_DB_EY_Audit_Cashouts.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Cashouts/regen/attempt_2/BI_DB_EY_Audit_Cashouts.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 8    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
