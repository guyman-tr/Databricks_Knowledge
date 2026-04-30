

MCP PRE-FLIGHT: Testing Synapse connectivity...
MCP PRE-FLIGHT: PASS

Now loading rules files.
Rules loaded. Now proceeding with pipeline phases. The DDL is already in the bundle — 34 columns, ROUND_ROBIN distribution, clustered index on Quarter.

**PHASE 1 CHECKPOINT: PASS** (DDL from bundle)

Running Phase 2 (sampling) and Phase 3 (distribution) in parallel.
Phase 2 data: 16 quarters from 202001 to 202304. Each row is duplicated (USD + EURO). Total rows estimated from quarter counts: ~127M rows across all quarters.

**PHASE 2 CHECKPOINT: PASS**

Now Phase 3 — distribution on top 3 categorical columns (capped at 3 per rules):
**PHASE 3 CHECKPOINT: PASS**

Distribution data collected. Now proceeding through phases 4-10B using the bundle.

Key findings from SP analysis (phases 4-9):
- **Writer SP**: `SP_Q_QSR_New` by Guy Manova (2020-07-22)
- **Pattern**: DELETE WHERE Quarter = @CurrentQuarter, then INSERT from temp tables
- Every row duplicated in USD and EURO
- Customer attributes from `Fact_SnapshotCustomer` joined through `Dim_Range` to snapshot at quarter-end date
- Balance data from `V_Liabilities` (Liabilities column)
- Unrealized PnL from `Fact_CustomerUnrealized_PnL` at quarter start/end
- Realized PnL from `Dim_Position.NetProfit` for positions closed in quarter
- Sustainability ratios from `BI_DB_PositionPnL` + `BI_DB_EquitiesWithSustainabilityStamp`
- ECB rate from `BI_DB_ECB_RateExtractFromAPI`

**Tier analysis** (applying judge fixes):
- **Tier 1** (4 columns): Regulation, PlayerStatus, Country, MifidCategory — dim-lookup passthroughs with verbatim upstream descriptions
- **Tier 2** (31 columns): All others — ETL-computed, aggregated, or transformed by SP_Q_QSR_New
- ClientBalanceEnd and ClientBalanceEndRealCrypto → re-tagged **Tier 2** (V_Liabilities marks both as computed T2 columns; SP applies ISNULL + EUR division)

PHASE GATE — BI_DB_dbo.BI_DB_QSR_Balance_New:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```

Now writing the three output files. Starting with lineage.
Now writing the main wiki:
Now writing the review-needed sidecar:
All three files written. Let me verify the Tier 1 descriptions are verbatim from upstream wikis:

**T1 COPY VERIFICATION:**
- **Regulation**: Upstream (Dim_Regulation #2 Name): "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." → Wiki: "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." + QSR value list appended — **IDENTICAL** (QSR context added AFTER verbatim quote)
- **PlayerStatus**: Upstream (Dim_PlayerStatus #2 Name): "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." → Wiki matches verbatim + value list appended — **IDENTICAL**
- **Country**: Upstream (Dim_Country #4 Name): "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." → Wiki matches verbatim + relay note appended — **IDENTICAL**
- **MifidCategory**: Upstream (Dim_MifidCategorization #2 Name): "Human-readable classification label. Used in compliance dashboards and regulatory reports." → Wiki matches verbatim + relay note + value list appended — **IDENTICAL**

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_QSR_Balance_New:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_QSR_Balance_New/regen/attempt_2/BI_DB_QSR_Balance_New.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_QSR_Balance_New/regen/attempt_2/BI_DB_QSR_Balance_New.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_QSR_Balance_New/regen/attempt_2/BI_DB_QSR_Balance_New.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 4    Tier2: 31    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
