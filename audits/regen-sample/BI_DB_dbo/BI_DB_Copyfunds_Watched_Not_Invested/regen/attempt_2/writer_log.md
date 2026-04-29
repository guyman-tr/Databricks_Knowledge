MCP PRE-FLIGHT: PASS

Now let me read the existing attempt_1 files to understand what was correct and what needs fixing, then read the rules.
Now let me run live data sampling (P2/P3) to ensure fresh data evidence:
PHASE GATE — BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (Atlassian MCP not invoked)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

All five judge issues are now understood from live data:
1. `NullAccountManager=0` confirms INNER JOIN excludes non-manager rows entirely
2. Fan-out confirmed: RealCID=24457833 has up to 330 duplicate rows per (RealCID, FundName) pair
3. MoneyAvailable prefix error confirmed in attempt_1 line 127
4. Section 5 deferred to lineage file — must embed inline
5. Footer says '6 T1, 8 T2' — correct is '7 T1, 7 T2'

Now writing all three output files into `audits/regen-sample/BI_DB_dbo/BI_DB_Copyfunds_Watched_Not_Invested/regen/attempt_2/`:
All three files written. Final verification against judge requirements:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Copyfunds_Watched_Not_Invested/regen/attempt_2/BI_DB_Copyfunds_Watched_Not_Invested.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Copyfunds_Watched_Not_Invested/regen/attempt_2/BI_DB_Copyfunds_Watched_Not_Invested.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Copyfunds_Watched_Not_Invested/regen/attempt_2/BI_DB_Copyfunds_Watched_Not_Invested.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 7    Tier2: 7    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**All 5 judge issues addressed:**

1. **MoneyAvailable description** — Removed the erroneous 'Answer text for Q11.' prefix. Now reads: *"Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities. Range: -$2,572.79 to $855,862.42..."*

2. **[Account Manager] NULL semantics** — Corrected to document the INNER JOIN behaviour: *"The SP uses an INNER JOIN to Dim_Manager... investors with no assigned AccountManagerID fail the join predicate and are excluded from the table entirely — this column is never NULL in practice (confirmed: 0 NULL rows across 360,846 sampled rows)."*

3. **Section 2 fan-out mechanism** — Added §2.6 documenting the #final N×K fan-out root cause with live evidence (up to 330 duplicates per (RealCID, FundName) pair), the exact SP code defect (FundCID in GROUP BY but not in SELECT), and the fix options.

4. **ETL pipeline ASCII diagram inline in Section 5** — Embedded directly in the wiki's Section 5, not deferred to the lineage file.

5. **Footer tier count and quality metadata** — Corrected to `7 T1, 7 T2, 0 T3, 0 T4` with quality score `8.5/10` and phases-completed list `P1,P2,P3,P4,P5,P6,P7,P8,P9,P9B,P10A,P10B,P11`.
