# Review Needed — Dealing_JPMReconTrades

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **Regional UNION coverage** — JP trade data is sourced from three tables: `LP_JPM_ETORO_NA_Trade_Summary`, `LP_JPM_ETORO_EMEA_Trade_Summary`, `LP_JPM_ETORO_ASIA_Trade_Summary`. Confirm all three are actively populated and that no new regional feed has been added since Nov 2023.

2. **Total_Commission_USD derivation** — Commission is computed as JPM commission × FX rate. Confirm the exact source column in the LP trade summary tables and whether commission is gross or net of any rebates.

3. **HS 9 trade grouping** — Same as EOD: HS 9 uses ISINCode + InstrumentDisplayName join rather than InstrumentID. Confirm whether trade-level HS 9 data has the same LP reporting quirk as EOD data, or if it is incidental.

4. **Clients_Units source** — `Clients_Units` comes from `Dealing_Duco_ActivityRecon.ClientUnits`. Confirm this represents gross client trade flow (not net) and that the HS filter (2,8,22,9,121,110,129,319) covers all JPM-connected servers.

## Reviewer Corrections

_None yet._
