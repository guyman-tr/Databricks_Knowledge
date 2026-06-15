# UC comment deploy — 2026-05-28

Deployed the wiki §4 descriptions (post-trivial-pass) as `COMMENT ON COLUMN`
on the underlying UC views.

## Result

| Bucket | Wikis | UC stmts | Outcome |
|---|---:|---:|---|
| Deployed | 29 | 452 | **0 failed** |
| Skipped (UC view not found) | 1 | 0 | `Function_PnL_Single_Day` — no `etoro_kpi_prep.v_pnl_single_day` |
| Skipped (no UC target identified) | 9 | 0 | see below |
| **Touched in this rollout** | **39** | **452** | |

## Coverage post-deploy (`information_schema.columns`)

28 of 29 deployed views at **100% comment coverage**:

`v_revenue_adminfee`, `v_revenue_cashoutfee_excluderedeem`,
`v_revenue_cashoutfee_incredeem`, `v_revenue_commission`,
`v_revenue_conversionfee`, `v_revenue_conversionfee_withpositiondata`,
`v_revenue_cryptotofiat_c2f`, `v_revenue_dividend`, `v_revenue_dormantfee`,
`v_revenue_fullcommission`, `v_revenue_interestfee`, `v_revenue_rollover`,
`v_revenue_sdrt`, `v_revenue_share_lending`, `v_revenue_spotadjustfee`,
`v_revenue_stakingfee`, `v_revenue_ticketfee_bypercent`,
`v_revenue_ticketfee_fixed`, `v_revenue_transfercoinfee`,
`v_population_active_traders`, `v_population_first_time_funded`,
`v_population_first_trading_action`, `v_mimo_first_deposit_all_platforms`,
`v_mimo_options_platform`, `v_instrument_conversion_rates_dwh`,
`v_dim_instrument_enriched`, `v_trading_volume_positionlevel`,
`dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities`.

1 outlier: `v_revenue_optionsplatform` at **96.2%** (25/26) — the UC view has
one column not present in the wiki §4 (`Function_Revenue_OptionsPlatform.md`).
Wiki gap, not a deploy bug.

## Lessons-learned hazards — all addressed

| Hazard | Mitigation | Verified |
|---|---|---|
| Raw `\|` splits markdown rows / misparses §4 | Renderer uses ` OR ` between divergent branches; audit confirms **0** raw pipes in 1024 new descriptions | yes |
| Newlines / control chars in cell | None produced by rewriter — audit confirms **0** | yes |
| Single quote breaks SQL string | `apply_tvf_col_comments.py.esc()` doubles them; round-tripped through `information_schema` cleanly | yes |
| Markdown leak (`**bold**`, backticks) into UC comment | `clean_md()` strips them before `COMMENT ON COLUMN`; 0 leaks in the deployed text | yes |
| Description misplaced to wrong column | Comments keyed by lowercased column name from `DESCRIBE TABLE`, not by row position — impossible to misalign | yes |
| `EXPECT_TABLE_NOT_VIEW` failure | `COMMENT ON COLUMN` (ANSI) used everywhere, works on tables and views | yes |
| Comment exceeds UC's char limit | `MAX_COMMENT=500`; truncates with `...` | yes (one column hit it: `RealizedEquity`) |
| Cross-session OAuth CSRF mismatch | Script now falls back to `WorkspaceClient(profile='guyman')` (same auth path as MCP) when no PAT is set | yes |

## Skipped — 9 wikis, no UC target identified

These were inspected against `main.information_schema.tables`; no matching
view exists (or the materialized view's columns don't match the wiki §4).
Their wiki §4 was rewritten in the trivial pass, but the UC layer has
nothing to update yet.

- `Function_AUM_OptionsPlatform`
- `Function_DDR_Aggregation_ThisMonth`
- `Function_DDR_Aggregation_ThisQuarter`
- `Function_DDR_Aggregation_ThisWeek`
- `Function_DDR_Aggregation_ThisYear`
- `Function_DDR_Aggregation_Yesterday`
- `Function_Revenue_Trading_Fees_Breakdown`  *(closest UC object is `mv_revenue_trading` but only 8/24 column overlap)*
- `Function_Revenue_Trading_Instrument_Level` *(10/24 overlap with `mv_revenue_trading`)*
- `Function_Search_Functions`
- *(plus `Function_PnL_Single_Day` — has a MAPPING entry but the UC view `v_pnl_single_day` does not exist)*

## Artifacts

- `audits/_uc_deploy_descriptions/roster.txt` — exact list of 30 wikis sent to deploy
- `audits/_uc_deploy_descriptions/dry_run.log` — full SQL the deploy would send (1201 statements in dry-run mode)
- `audits/_uc_deploy_descriptions/apply.log` — full deploy output (452 applied, 0 failed)
- `tools/apply_tvf_col_comments.py` — extended with `--only-file`, `WIKI_OVERRIDES` (for V_Liabilities), and SDK-profile auth fallback
