---
object: Dealing_Apex_PnL_EE_Daily
schema: Dealing_dbo
lineage_type: lp-external-staging
generated: 2026-03-21
---

# Lineage — Dealing_Apex_PnL_EE_Daily

Same pipeline as Dealing_Apex_PnL_EE. See that lineage file for the full chain.

SP_Apex_PnL writes both EE tables in the same execution:
- `Dealing_Apex_PnL_EE` — WTD equity using Friday prior week as start
- `Dealing_Apex_PnL_EE_Daily` — daily equity using prior business day as start (temp table `#Equity_Daily`, `#Transfers_Daily`, `#Dividends_PerAcc_Daily`)
