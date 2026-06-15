# UNION Branch Audit

Source: `audits\_desc_quality_pnl_only\proposed_fixes.csv`

SQL-derived rows audited: 3

Divergent (branches disagree): **0**


## [uniform] knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md :: `ClosedOnDate`

- SQL file: `C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Functions\BI_DB_dbo.Function_PnL_Single_Day.sql`
- Proposed: kind=`coalesce, DIVERGENT` object=`Function_PnL_Single_Day`
- 1 branches; 1 distinct terminals; kinds=['coalesce']

| Branch | Kind | Terminal expression |
|--------|------|---------------------|
| 0 | coalesce | `ISNULL(dp.ClosedOnDate, 0)` |

## [uniform] knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md :: `IsCopyFund`

- SQL file: `C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Functions\BI_DB_dbo.Function_PnL_Single_Day.sql`
- Proposed: kind=`case` object=`Function_PnL_Single_Day`
- 1 branches; 1 distinct terminals; kinds=['coalesce']

| Branch | Kind | Terminal expression |
|--------|------|---------------------|
| 0 | coalesce | `COALESCE(dp.IsCopyFund, upl.IsCopyFund)` |

## [uniform] knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md :: `IsMarginTrade`

- SQL file: `C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Functions\BI_DB_dbo.Function_PnL_Single_Day.sql`
- Proposed: kind=`coalesce, DIVERGENT` object=`Function_PnL_Single_Day`
- 1 branches; 1 distinct terminals; kinds=['coalesce']

| Branch | Kind | Terminal expression |
|--------|------|---------------------|
| 0 | coalesce | `COALESCE(dp.IsMarginTrade, upl.IsMarginTrade)` |
