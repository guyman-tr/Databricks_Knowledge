# Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| HedgeServerID 2 = JP Morgan? | SP description says "JP and GS (Hedge Servers 2+101)" — is server 2 confirmed as JP Morgan and 101 as Goldman Sachs? | SP header comment by Adar Cahlon |
| Scenario loss interpretation | Do scenario values represent eToro's loss (negative credit event) or the client's unrealized loss? The formula `OPLong*(shock-Buffer)` suggests this is the portion of client loss that exceeds equity, meaning eToro's credit exposure. | Computed from buffer gap formula |
| Buffer exclusion | Instruments with Buffer=0 in either direction are excluded from the INNER JOIN to #Buffer. Is this intentional? Some instruments may have only long or only short positions. | SP: `WHERE Buffer_Long_ToDivide<>0 AND Buffer_Short_ToDivide<>0` (both must be non-zero) |
| Commission JOIN | The INNER JOIN to #Commission means instruments with zero commission in the last 30 days are excluded from the final output. Is this intended, or should it be a LEFT JOIN? | SP: `JOIN #Commission c ON s.InstrumentID = c.InstrumentID` |

## Structural Questions

| Question | Context |
|----------|---------|
| Are there separate credit risk tables for other hedge servers beyond JP/GS? | This SP is scoped to HedgeServerID IN (2,101) only |
| How does this relate to Dealing_ClientsCapitalAdequacy? Both track client CFD exposure but at different aggregation levels. | Capital adequacy is by regulation; credit risk is by instrument with stress scenarios |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
