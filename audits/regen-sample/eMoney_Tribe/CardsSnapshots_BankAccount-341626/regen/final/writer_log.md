MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the DDL (already in the bundle) and check for SPs referencing this table, then run the live data phases.

**PHASE 1 — Structure Analysis**

The DDL is already in the bundle. Let me summarize:
- **Table**: `eMoney_Tribe.CardsSnapshots_BankAccount-341626`
- **19 columns** total
- **Distribution**: HASH on `@CardsSnapshots_BankAccounts@Id-83854`
- **Index**: HEAP (no clustered index)
- **Indexes**: `XI_partition_date` on `partition_date`, `idx_341626_Id` on `@CardsSnapshots_BankAccounts@Id-83854`

Columns:
1. `@Id` — varchar(max), NULL
2. `@CardsSnapshots_BankAccounts@Id-83854` — varchar(255), NULL
3. `BankAccountNumber` — varchar(max), NULL
4. `BankAccountSortCode` — varchar(max), NULL
5. `BankAccountIban` — varchar(max), NULL
6. `BankAccountBic` — varchar(max), NULL
7. `BankAccountStatus` — varchar(max), NULL
8. `BankAccountDirectDebitsIn` — varchar(max), NULL
9. `BankAccountDirectDebitsOut` — varchar(max), NULL
10. `BankAccountInstantPaymentsIn` — varchar(max), NULL
11. `BankAccountInstantPaymentsOut` — varchar(max), NULL
12. `etr_y` — varchar(max), NULL
13. `etr_ym` — varchar(max), NULL
14. `etr_ymd` — varchar(max), NULL
15. `SynapseUpdateDate` — datetime, NULL
16. `Created` — datetime2(7), NULL
17. `partition_date` — date, NULL
18. `BankAccountBankStateBranch` — varchar(max), NULL
19. `BankAccountBankBranchCode` — varchar(max), NULL

PHASE 1 CHECKPOINT: PASS

Now let me run Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
Let me get the row count differently and read the SP.
PHASE 2 CHECKPOINT: PASS — 88.3M rows, date range 2023-12-20 to 2026-04-26. Raw Tribe data feed, UK bank accounts (GB IBANs, MRMI BIC).

Now Phase 3 — distribution analysis on categorical columns matching the regex. `BankAccountStatus` matches.
PHASE 3 CHECKPOINT: PASS — BankAccountStatus: 100% "Yes" (2026 data). DirectDebitsIn/InstantPaymentsIn: empty strings in 2026 (were "Yes" in earlier data, pattern change).

Now running remaining phases efficiently.
Phase analysis complete. Let me now compile the phase gates and write all three output files.

**Phase Summary:**
- **P4 Lookup**: [-] No FK/ID columns referencing Dim/Dict tables
- **P5 JOIN**: The SP joins on `@CardsSnapshots_BankAccounts@Id-83854` to `CardsSnapshots_BankAccounts-83854.@Id`
- **P6 BizLogic**: Raw bank account snapshot data from Tribe card issuer
- **P7 Views**: [-] No views reference this table
- **P8 SP-scan**: SP_eMoney_Reconciliation_ETLs is a READER (not writer)
- **P9 SP-logic**: SP reads BankAccount columns as passthrough to ETL_CardSnapshot
- **P9B ETL**: Tribe API → Generic Pipeline → this table → SP → ETL_CardSnapshot
- **P10 Jira**: [-] Raw Tribe table, low Jira value
- **P10A Upstream**: No upstream wiki (confirmed by `_no_upstream_found.txt`)
- **P10B Lineage**: Ready to write

```
PHASE GATE — eMoney_Tribe.CardsSnapshots_BankAccount-341626:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [-] P4 Lookup (no FK/ID refs)  [x] P5 JOIN  [x] P6 BizLogic
  [-] P7 Views (no views ref)    [x] P8 SP-scan  [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (raw Tribe table)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.CardsSnapshots_BankAccount-341626:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_BankAccount-341626/regen/attempt_1/CardsSnapshots_BankAccount-341626.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_BankAccount-341626/regen/attempt_1/CardsSnapshots_BankAccount-341626.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_BankAccount-341626/regen/attempt_1/CardsSnapshots_BankAccount-341626.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 19    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
