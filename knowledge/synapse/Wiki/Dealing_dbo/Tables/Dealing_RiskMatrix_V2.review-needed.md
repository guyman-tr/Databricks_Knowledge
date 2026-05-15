# Review Notes — Dealing_dbo.Dealing_RiskMatrix_V2

**Status**: ⚠️ **STALE** single snapshot (`PositionsTime`/`UpdateDate` = 2024-06-02 only) — **87,642** rows (2026-05-14 `COUNT(*)`).

## SLOPPY / corrected prior-wiki drift (now fixed in `.md`)

1. **Instrument scope**: Old text claimed “Real Stocks and ETFs only”; live `InstrumentType` includes **Currencies, Crypto Currencies, Commodities, Indices** (`GROUP BY InstrumentType` MCP).
2. **Shock ladder**: Old “26 scenarios (+9% steps missing; no +200/300/400/60…90, no −99)” was **wrong** vs SSDT + `INFORMATION_SCHEMA` — table has **48** shock columns with the **full** `+6…+10`, `+60…+90`, `+200/+300/+400`, and **`−99`** columns.
3. **Data types**: Prior doc used `bit`, `float`, `nvarchar`; Synapse types are **`int` `IsBuy`**, **`decimal(16,6)`** prices/FX, **`decimal(38,8)`** NOP vector, **`varchar(50)`** names/types.
4. **`Region` usefulness**: Old text treated as geography; live data = **100% NULL/empty** — **do not** use for geo analytics without repopulation evidence.
5. **`IsSettled`**: Old “real vs CFD” assertion is **unsupported in SSDT** — downgraded to Tier 5 pending dealing SMEs (kept distinct `{0,1}` fact).

## Open items (human)

1. **Identify writer** — nothing in `SynapseSQLPool1/.../Stored Procedures` references this table; locate notebook / service / ad-hoc batch.
2. **`HedgeServerID` catalog** — confirm mapping to LP / internal server names (32 values in snapshot).
3. **UC catalog** — parity target `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2` (gap CSV) **replaces** legacy `main.dealing.*` comment header; verify in Databricks catalog if both ever existed.
4. **OpsDB** — automated scheduler row not validated (OpsDB table name guess failed in subagent — re-run with correct metadata table).
5. **Confluence** — run authenticated CQL/JQL for “risk matrix”, “NOP shock”, “Dealing_RiskMatrix_V2”.

## Phase 16 adversarial notes

- **Strength**: Every column now matches **SSDT DDL** + **`INFORMATION_SCHEMA.COLUMNS`** Synapse check; live samples + `COUNT(*)` + categorical histograms included.
- **Weakness**: Tier 1 inheritance only on **InstrumentID/Name** (+ Tier 2 verbatim for `InstrumentType`); **no** production job file proves physical copy from `Dim_Instrument`.
- **Score target**: ≥7.5 after SME answers on `IsSettled` + writer attribution.
