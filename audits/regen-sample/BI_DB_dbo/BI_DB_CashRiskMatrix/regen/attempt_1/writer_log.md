**MCP PRE-FLIGHT: PASS**

Now proceeding through the pipeline phases.

---

## Phase 1 — DDL Analysis (P1)

From the pre-resolved bundle, the DDL is clear:

- **Table**: `BI_DB_dbo.BI_DB_CashRiskMatrix`
- **Distribution**: ROUND_ROBIN
- **Index**: CLUSTERED INDEX on `[Date] ASC`
- **64 columns** total: Date, CID, TotalCash, HedgeServerID, InstrumentID, InstrumentName, InstrumentType, IsBuy, Leverage, Regulation, Region, Bid, Ask, ConversionRate, UnitsNOP, then 49 scenario columns (`UnitsNOP+1%` through `UnitsNOP+900%` and `UnitsNOP-1%` through `UnitsNOP-100%`), plus UpdateDate.
Good. Live data confirmed. Running parallel sampling queries for P2, P3, P4.
I have enough data. Let me now write the three output files.
```
PHASE GATE — BI_DB_dbo.BI_DB_CashRiskMatrix:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (Atlassian MCP not in scope for regen harness)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```

Writing Phase 10B (lineage) first:
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CashRiskMatrix:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_1/BI_DB_CashRiskMatrix.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_1/BI_DB_CashRiskMatrix.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CashRiskMatrix/regen/attempt_1/BI_DB_CashRiskMatrix.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 52    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (Dim_Position, Dim_Instrument, Fact_CurrencyPriceWithSplit, Dim_Regulation, Dim_Country, V_Liabilities all quoted verbatim)
```
