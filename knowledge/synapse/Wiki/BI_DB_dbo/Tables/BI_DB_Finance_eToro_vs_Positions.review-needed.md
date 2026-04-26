# Review Sidecar — BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | PASS | 37 columns in DDL, 37 in wiki element table |
| All columns have tier suffix | PASS | 35 Tier 2 + 2 Tier 3 (UpdateDate, eToroUSDAmount) |
| Writer SP confirmed | PASS | SP_Finance_Non_US_Settlement_2025 matches OpsDB entry for BI_DB_Finance_eToro_vs_Positions |
| Sample data reviewed | PASS | 5 rows inspected -- Provider values (BNYMellon, Apex), exchange names, ISIN/CUSIP formats, price calculations consistent |
| Date range verified | PASS | 2024-12-31 to 2026-04-11, 359 distinct dates, ~10.4M rows |
| OpsDB schedule confirmed | PASS | Daily, SB_Daily, Priority 0, ProcessType 1 (SQL) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Column count | High | 37 columns in DDL match 37 entries in element table. Verified against INSERT INTO statement at SP line 1309. |
| 2 | eToroUSDAmount always NULL | Medium | After Oct 2025 netting-table replacement, this column is hardcoded NULL in the SP. Consider whether it should be dropped or if downstream consumers still reference it. |
| 3 | Provider mapping complexity | Medium | Three-tier COALESCE with CASE-based bank-name resolution from free-text LA names. If Karen/Inessa mapping file changes provider naming conventions, the hardcoded LIKE patterns will break silently (e.g., '%bny', '%apex%', '%jpm%'). |
| 4 | IsRelevantForRecon hardcoded HedgeServerIDs | Medium | Logic uses specific HedgeServerID values (11=Apex, 122=Saxo, 129/224=BNYMellon, 121=IB). If new hedge servers are added for these providers, they need manual SP updates. |
| 5 | No downstream SP consumers | High | No Synapse SPs read from this table. Confirm primary consumers are Tableau dashboards or external reporting tools. |
| 6 | FULL OUTER JOIN grain risk | Medium | The #tp_omni step uses FULL OUTER JOIN between #tp (client) and #duco (omnibus) on InstrumentID x HedgeServerID x DateID. If either side has rows not matched by the other, NULLs propagate into LiquidityAccountID (part of logical grain). This is by design for reconciliation but may produce unexpected duplicates if LA mapping is inconsistent. |
| 7 | USD_ConversionRate fallback | Low | ISNULL(USD_ConversionRate, 1) defaults to 1.0 for missing rates. For non-USD instruments with missing conversion data, this silently produces incorrect USD valuations. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 35 | All business columns (DateID, Date, InstrumentID, InstrumentName, InstrumentDisplayName, ISINCode, CUSIP, Exchange, HedgeServerID, Provider, LiquidityAccountID, LiquidityAccountName, LiquidityProviderName, eToro_Units, eToroUSDByPriceUnspreaded, TP_Units*, TP_Equity*, EOD_*, USD_ConversionRate, IsRelevantForRecon, SellCurrency, eToro_Units_Plus1h, eToroUSDPlus1hByPriceUnspreaded, TotalStockMarginLoanIsCreditReportValid) |
| Tier 3 | 2 | UpdateDate (GETDATE), eToroUSDAmount (hardcoded NULL) |
