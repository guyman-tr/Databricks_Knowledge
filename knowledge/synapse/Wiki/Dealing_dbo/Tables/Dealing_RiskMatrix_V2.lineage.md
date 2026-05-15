# Lineage Map — Dealing_dbo.Dealing_RiskMatrix_V2

**Generated**: 2026-05-14  
**SSDT DDL**: `DataPlatform/SynapseSQLPool1/sql_dp_prod_we/Dealing_dbo/Tables/Dealing_dbo.Dealing_RiskMatrix_V2.sql`  
**Migration template**: `NoDbObjectsScripts/2024_09_16_17_30_59_Dealing_Migration.Dealing_RiskMatrix_V2.sql` → `[Dealing_Migration].[Dealing_RiskMatrix_V2]` (historic migration artifact; `PositionsTime`/`UpdateDate` staged as `varchar(50)` there, materialized as `datetime` in `Dealing_dbo`)  
**Writer SP (SSDT)**: none — `rg` across `SynapseSQLPool1/sql_dp_prod_we/**/Stored Procedures/*.sql` finds **no** `INSERT`/`MERGE`/`CREATE TABLE AS` referencing `Dealing_RiskMatrix_V2`  
**Dependent views / modules (Synapse)**: none — `sys.sql_modules` LIKE `%Dealing_RiskMatrix_V2%` returned **0** rows (2026-05-14 MCP)

## ETL Chain

```
[Unknown operational loader — not present in SSDT Stored Procedures]
    └── (one-shot snapshot evidence: single PositionsTime / UpdateDate instant across 87,642 rows)
            └── Dealing_dbo.Dealing_RiskMatrix_V2  (ROUND_ROBIN HEAP, 62 columns)
```

## Source Objects

| Source Object | Role |
|---------------|------|
| `Dealing_Migration.Dealing_RiskMatrix_V2` | Migration-era staging DDL that mirrors current column names/types (except datetime vs varchar staging for timestamps) |
| `DWH_dbo.Dim_Instrument` | Analyst join target to resolve `InstrumentID` / instrument naming semantics (not proven as physical ETL source) |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|--------------|---------------|-----------|
| PositionsTime | Unknown / snapshot job | — | Single timestamp `2024-06-02 08:01:49.697` across **all** rows (live MCP); nullable per DDL |
| HedgeServerID | Unknown | — | Hedge / LP server slice identifier in snapshot; **32** distinct values (live MCP) |
| InstrumentID | Unknown (join: `DWH_dbo.Dim_Instrument`) | InstrumentID | Stored key; **verbatim semantic match** to `Dim_Instrument.InstrumentID` when joined |
| InstrumentName | Unknown (join: `DWH_dbo.Dim_Instrument`) | Name | Denormalized pair label; aligns with `Dim_Instrument.Name` construction pattern |
| InstrumentType | Unknown (join: `DWH_dbo.Dim_Instrument`) | InstrumentType | Labels match `Dim_Instrument.InstrumentType` CASE output (see wiki) |
| IsBuy | Unknown | — | `{0,1}` only (live MCP) |
| Leverage | Unknown | — | Leverage tier at snapshot; distinct set includes `1,2,5,10,20,25,30,50,100,200,400` (live MCP) |
| Regulation | Unknown | — | Regulatory bucket text (e.g., CySEC, FCA) |
| Region | Unknown | — | **Populated as NULL/blank for 100% of rows** in live Synapse snapshot (87,642 / 87,642) |
| Bid | Unknown | — | `decimal(16,6)` snapshot bid |
| Ask | Unknown | — | `decimal(16,6)` snapshot ask |
| ConversionRate | Unknown | — | `decimal(16,6)` FX multiplier to USD (includes `1.000000` majors sample) |
| UnitsNOP | Unknown | — | Baseline net open position units before shock grid (`decimal(38,8)`); **0 NULLs** (live MCP) |
| UnitsNOP+1% | Unknown | — | NOP after **+1%** scenario (non-NULL in sampled aggregate check) |
| UnitsNOP+2% | Unknown | — | NOP after **+2%** scenario |
| UnitsNOP+3% | Unknown | — | NOP after **+3%** scenario |
| UnitsNOP+4% | Unknown | — | NOP after **+4%** scenario |
| UnitsNOP+5% | Unknown | — | NOP after **+5%** scenario |
| UnitsNOP+6% | Unknown | — | NOP after **+6%** scenario |
| UnitsNOP+7% | Unknown | — | NOP after **+7%** scenario |
| UnitsNOP+8% | Unknown | — | NOP after **+8%** scenario |
| UnitsNOP+9% | Unknown | — | NOP after **+9%** scenario |
| UnitsNOP+10% | Unknown | — | NOP after **+10%** scenario |
| UnitsNOP+15% | Unknown | — | NOP after **+15%** scenario |
| UnitsNOP+20% | Unknown | — | NOP after **+20%** scenario |
| UnitsNOP+25% | Unknown | — | NOP after **+25%** scenario |
| UnitsNOP+30% | Unknown | — | NOP after **+30%** scenario |
| UnitsNOP+40% | Unknown | — | NOP after **+40%** scenario |
| UnitsNOP+50% | Unknown | — | NOP after **+50%** scenario |
| UnitsNOP+60% | Unknown | — | NOP after **+60%** scenario |
| UnitsNOP+70% | Unknown | — | NOP after **+70%** scenario |
| UnitsNOP+80% | Unknown | — | NOP after **+80%** scenario |
| UnitsNOP+90% | Unknown | — | NOP after **+90%** scenario |
| UnitsNOP+100% | Unknown | — | NOP after **+100%** scenario |
| UnitsNOP+200% | Unknown | — | NOP after **+200%** scenario |
| UnitsNOP+300% | Unknown | — | NOP after **+300%** scenario |
| UnitsNOP+400% | Unknown | — | NOP after **+400%** scenario |
| UnitsNOP+900% | Unknown | — | NOP after **+900%** scenario |
| UnitsNOP-1% | Unknown | — | NOP after **−1%** scenario |
| UnitsNOP-2% | Unknown | — | NOP after **−2%** scenario |
| UnitsNOP-3% | Unknown | — | NOP after **−3%** scenario |
| UnitsNOP-4% | Unknown | — | NOP after **−4%** scenario |
| UnitsNOP-5% | Unknown | — | NOP after **−5%** scenario |
| UnitsNOP-6% | Unknown | — | NOP after **−6%** scenario |
| UnitsNOP-7% | Unknown | — | NOP after **−7%** scenario |
| UnitsNOP-8% | Unknown | — | NOP after **−8%** scenario |
| UnitsNOP-9% | Unknown | — | NOP after **−9%** scenario |
| UnitsNOP-10% | Unknown | — | NOP after **−10%** scenario |
| UnitsNOP-15% | Unknown | — | NOP after **−15%** scenario |
| UnitsNOP-20% | Unknown | — | NOP after **−20%** scenario |
| UnitsNOP-25% | Unknown | — | NOP after **−25%** scenario |
| UnitsNOP-30% | Unknown | — | NOP after **−30%** scenario |
| UnitsNOP-40% | Unknown | — | NOP after **−40%** scenario |
| UnitsNOP-50% | Unknown | — | NOP after **−50%** scenario |
| UnitsNOP-60% | Unknown | — | NOP after **−60%** scenario |
| UnitsNOP-70% | Unknown | — | NOP after **−70%** scenario |
| UnitsNOP-80% | Unknown | — | NOP after **−80%** scenario |
| UnitsNOP-90% | Unknown | — | NOP after **−90%** scenario |
| UnitsNOP-99% | Unknown | — | NOP after **−99%** scenario |
| UnitsNOP-100% | Unknown | — | NOP after **−100%** scenario |
| UpdateDate | Unknown | — | Single load instant `2024-06-02 08:02:49.217` across **all** rows |
| IsSettled | Unknown | — | `{0,1}` flag; **semantic meaning not proven in SSDT** |

## Governance Notes

- Live row count `COUNT(*)` = **87,642** (Synapse MCP). `sys.dm_pdw_nodes_db_partition_stats` approximation **not available** — caller lacks permission (error 6004).
- No consumer `VIEW`/`PROC` references surfaced in `sys.sql_modules` LIKE search — treat as **standalone analytical snapshot**.

## Phase 15 — UC External Lineage (manual / deferred)

External Lineage API payloads are **not** emitted from this repo run. Recommended next link (once writer is found): `Synapse job → Dealing_dbo.Dealing_RiskMatrix_V2 → main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2`. Bronze production mapping is **unknown** because Phase 8/9 found **no** SSDT loader.
