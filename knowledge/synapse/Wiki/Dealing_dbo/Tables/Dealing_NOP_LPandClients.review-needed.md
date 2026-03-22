# Dealing_dbo.Dealing_NOP_LPandClients — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| NOP currency alignment | LP NOP is USD-converted via FX cascade, but Client NOP is `SUM(NOP)` from BI_DB_PositionPnL — is BI_DB_PositionPnL.NOP already in USD, or is this a currency mismatch? | LP path has explicit FX conversion; client path does not |
| LabelID=30 | What customer label does LabelID=30 represent? Why are these positions tracked separately from regular Clients? | SP code: `WHEN dc.LabelID = 30 THEN 'LabelID=30'` — dedicated bucket |
| IsComputeForHedge=0 | What positions are excluded from hedge computation? Are these legacy/special positions? | SP code: `WHEN dp.IsComputeForHedge=0 THEN 'IsComputeForHedge=0'` |
| 730-day retention | Is the 2-year retention period a regulatory or operational requirement? Is historical data archived elsewhere? | SP code: `DELETE WHERE DateID < DATEADD(day,-730,GETDATE())` |

## Structural Questions

| Question | Context |
|----------|---------|
| Is this table the primary NOP dashboard data source for the dealing desk? | SP authored by Jenia Simonovitch (Dealing team), large table with CCI |
| How does this relate to Dealing_LP_StocksNOP and Dealing_ClientsCapitalAdequacy — are they alternative aggregations for different reports? | All three deal with NOP data at different aggregation levels |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
