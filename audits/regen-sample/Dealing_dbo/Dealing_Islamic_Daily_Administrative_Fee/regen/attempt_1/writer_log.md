MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis** (from bundle DDL):
- 42 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `[Date] ASC`
- All columns nullable
- Key types: date, int, bigint, varchar, numeric, money, decimal, datetime

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
PHASE 2 CHECKPOINT: PASS — 17.9M rows, 2022-12-30 to 2026-04-25, ~1K distinct customers in April 2026.
PHASE 3 CHECKPOINT: PASS — Distribution: Stocks (48%), Crypto (31%), Commodities (12%), Indices (3%), Currencies (3%), ETF (3%). All IsSettled=0, ClosedOnWeekend=0, Fee_Type_ID=1, GracePeriod=7.

**Phase 4 — Lookup Resolution**: From SP code and DDL, key lookups are:
- InstrumentTypeID → Dim_Instrument.InstrumentTypeID (1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto)
- InstrumentGroup → Dealing_Islamic_Instruments_Groups (1-4 fee tiers)
- ExchangeID → Dim_ExchangeInfo
- Fee_Type_ID → hardcoded as 1 in INSERT

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**: From SP code, JOINs are:
- Dim_Position dp ON CID = RealCID → positions
- Dim_Customer dc ON CID = RealCID → Islamic accounts (WeekendFeePrecentage=0)
- Dim_Instrument i ON InstrumentID
- Dealing_Islamic_Instruments_Groups g ON instrument_id
- Dealing_Islamic_Units_Per_Contract u ON instrument_id
- Dim_ExchangeInfo e ON Exchange
- Fact_CurrencyPriceWithSplit f ON DateID + InstrumentID
- Dealing_Islamic_Admin_Fee_Per_Group a ON instrument_group + instrument_type_id
- Dim_Date → #Dates temp table for day counting

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: From SP code analysis:
- Islamic accounts identified by WeekendFeePrecentage=0
- Grace period of 7 days before fees start
- Days counting varies by exchange (Wed=3x for NYSE/LSE, Fri=3x for commodities/Asian, Thu=3x for InstrumentID=62, All for crypto)
- Fee formula varies by asset class
- Final_Fee is negated (charged as negative)
- Suspended instruments excluded via hardcoded list
- German Islamic customers' crypto long leverage-1 positions excluded

PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency Scan**: This is a fact/output table, not typically referenced by views.

PHASE 7 CHECKPOINT: PASS ([-] no views reference this table — it's a daily output table)

**Phase 8 — SP Scan**: Writer SP is `SP_Islamic_Administrative_Fee`. Already in the bundle.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: Full SP analysis complete from bundle. All 42 columns traced to source.

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL**: Daily run, DELETE for @Date then INSERT. Parameterized by @Date (yesterday).

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Jira**: Skipping Atlassian in regen harness.

PHASE 10 CHECKPOINT: [-] Atlassian MCP not available in regen harness

**Phase 10A — Upstream Wiki**: Bundle provides 6 upstream wikis (Dim_Position, Dim_Customer, Fact_CurrencyPriceWithSplit, Dealing_Islamic_Admin_Fee_Per_Group, Dealing_Islamic_Instruments_Groups, Dealing_Islamic_Units_Per_Contract) + SP source.

PHASE 10A CHECKPOINT: PASS

Now writing Phase 10B lineage, then the wiki, then review-needed.

```
PHASE GATE — Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Let me verify the output directory exists.
Good, directory exists. Now writing the three files. Starting with `.lineage.md`.
Now writing the main wiki file.
Now writing the review-needed file.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_1/Dealing_Islamic_Daily_Administrative_Fee.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_1/Dealing_Islamic_Daily_Administrative_Fee.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_1/Dealing_Islamic_Daily_Administrative_Fee.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 8    Tier2: 34    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
