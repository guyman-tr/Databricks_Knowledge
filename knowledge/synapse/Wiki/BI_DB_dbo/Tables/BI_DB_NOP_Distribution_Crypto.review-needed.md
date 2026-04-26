# BI_DB_NOP_Distribution_Crypto — Review Needed

## Tier 4 / Uncertain Items

1. **Leverage scope intent**: The SP filters `Leverage IN (1,2)`. Confirm with risk/BI team whether this is intentional (low-leverage crypto NOP only) or whether higher-leverage crypto positions are tracked in a separate table. The table name doesn't hint at a leverage restriction.

2. **ROUND_ROBIN distribution for a NOP/risk query table**: The table is ROUND_ROBIN rather than HASH(RealCID) or HASH(InstrumentID). For typical use cases (NOP by CID or by crypto token), ROUND_ROBIN means full-distribution scans. Confirm whether this is intentional given the CCI compression or whether HASH(InstrumentID) would be more appropriate.

3. **NOP sign convention**: NOP is the net open position in USD. Confirm the sign convention: is NOP always positive (representing gross exposure), or does it reflect signed direction (positive=Buy, negative=Sell)? The SP takes NOP directly from BI_DB_PositionPnL without sign transformation.

4. **DaysAge computed from BI_DB_PositionPnL.Occurred**: Occurred is the position open timestamp. Confirm that Occurred is never NULL in BI_DB_PositionPnL for the population in scope (IsSettled=0, Leverage IN(1,2), crypto). A NULL Occurred would produce NULL DaysAge.

5. **Historical data back to 2021-10-31 despite Sunday-only retention**: The oldest date is 2021-10-31, which happens to be a Sunday. Confirm whether the full history back to 2021 was always stored under this retention policy, or whether an initial bulk load was performed and retention began later.

6. **EndOfMonth data type**: Column is `varchar(20)` in DDL (not bit or char(1)). Sourced from Dim_Date.IsLastDayOfMonth. Confirm that the only values are 'Y' and 'N' — varchar(20) is unusually wide for a binary flag and the DELETE logic depends on exact string matching (`EndOfMonth='N'`).

## No Review Needed
- Table name, distribution, index: confirmed from DDL (ROUND_ROBIN, CCI)
- Crypto scope (InstrumentTypeID=10): confirmed from SP code
- Leverage IN(1,2) filter: confirmed from SP code
- Row count, date range, retention mix: confirmed via MCP
- BuyCurrency distribution (BTC dominant): confirmed via MCP
- Club distribution (Bronze, Gold, Platinum Plus leading): confirmed via MCP
- Regulation distribution (CySEC ~93%): confirmed via MCP
- T1 descriptions for Club, Regulation, Country: verbatim from Dim_PlayerLevel, Dim_Regulation, Dim_Country upstream wikis
- WeekDayNum=1 = Sunday: confirmed from sample (2026-04-12 = Sunday, WeekDayNum=1)
