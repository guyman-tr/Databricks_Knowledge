# Review Needed: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

## 1. Tier Coverage

All 15 columns are Tier 2 (ETL-computed from SP code). This is expected and valid because:
- The Etoro side of SP_IntraHourIndexReport sources from hedge execution/netting tables (etoro_Hedge_ExecutionLog, etoro_Hedge_Netting, etoro_History_Netting_History) which have **no upstream wikis** in any documented repository
- The upstream bundle confirms Dim_Position and Dim_Customer are only used on the **client side** of the SP, not the Etoro side
- The companion table (Dealing_IndiciesIntraHour_Clients) is documented but does not serve as a data source for this table — they are peers populated by the same SP

**Bundle inheritance used: YES** — The companion wiki (Dealing_IndiciesIntraHour_Clients) was referenced for structural alignment, SP change history (SR-249626, SR-257613), and cross-table JOIN documentation. The Dim_Position and Dim_Customer wikis were reviewed but are not data sources for the Etoro side.

## 2. Items for Human Review

### 2.1 Hedge Instrument ID Mapping
- **Column**: InstrumentID
- **Issue**: The hedge instrument IDs (254, 255, 259) are what's stored, mapped from original index instruments (27, 28, 32) via PortfolioConversionConfigurations. The exact mapping (which hedge ID maps to which original index) should be confirmed with the Dealing team, as it may change over time as configurations are updated.

### 2.2 NOP vs ValueStart Redundancy
- **Columns**: NOP, ValueStart
- **Issue**: Both columns use the identical formula in the SP: `SUM(Units * ConversionFirst * (2*IsBuy-1) * CASE WHEN IsBuy=1 THEN FirstBid ELSE FirstAsk END)`. They are always equal. Confirm with the Dealing team whether this is intentional (e.g., for future differentiation) or a legacy artifact.

### 2.3 Liquidity Account Completeness
- **Columns**: LiquidityAccountID, LiquidityAccountName
- **Issue**: Current data shows only 2 active accounts (275/EMSX Marex Indices Real, 317/EMSX Marex MAEX Real). Historical data may include additional accounts. The HedgeServerID=225 appeared only 4 times in 2026 data — confirm if this is a test or a new server being onboarded.

### 2.4 No Atlassian Search Performed
- Phase 10 was skipped in harness mode. SR-249626 and SR-257613 were referenced from the companion wiki's documentation. A full Jira/Confluence search may surface additional business context for this hedge reporting table.

## 3. Data Quality Observations

- **NULL HedgeServerID**: 142 rows in 2026 data have NULL HedgeServerID despite the column being added in 2024. This suggests occasional edge cases where the HedgeServerID is not populated.
- **Sparse data**: The WHERE filter in the SP excludes zero-activity minutes, so the table does not have uniform minute coverage across all days.
