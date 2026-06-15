# Column Lineage: main.etoro_kpi.vg_dealing_dealingdashboard_cid

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_dealing_dealingdashboard_cid` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_dealing_dealingdashboard_cid.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_dealing_dealingdashboard_cid.json` (rows: 30, mismatches: 14) |
| **Primary upstream** | `main.dealing.bi_output_dealing_dealingdashboard_cid` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dealing.bi_output_dealing_dealingdashboard_cid` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.dealing.bi_output_dealing_dealingdashboard_cid   ←── primary upstream
        │
        ▼
main.etoro_kpi.vg_dealing_dealingdashboard_cid   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Date` | `passthrough` | — | Date |
| 2 | `HedgeServerID` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `HedgeServerID` | `passthrough` | — | HedgeServerID |
| 3 | `InstrumentType` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `InstrumentType` | `passthrough` | — | InstrumentType |
| 4 | `InstrumentID` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 5 | `InstrumentDisplayName` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `InstrumentDisplayName` | `passthrough` | — | InstrumentDisplayName |
| 6 | `InstrumentName` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 7 | `Symbol` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Symbol` | `passthrough` | — | Symbol |
| 8 | `SellCurrency` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `SellCurrency` | `passthrough` | — | SellCurrency |
| 9 | `Exchange` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Exchange` | `passthrough` | — | Exchange |
| 10 | `Regulation` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Regulation` | `passthrough` | — | Regulation |
| 11 | `Country` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Country` | `passthrough` | — | Country |
| 12 | `Region` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Region` | `passthrough` | — | Region |
| 13 | `Mifid` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Mifid` | `passthrough` | — | Mifid |
| 14 | `IsCopy` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `IsCopy` | `passthrough` | — | IsCopy |
| 15 | `IsCFD` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `IsCFD` | `passthrough` | — | IsCFD |
| 16 | `Leverage` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `Leverage` | `passthrough` | — | Leverage |
| 17 | `NOP` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(NOP) AS NOP |
| 18 | `LongOpenPositions` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(LongOpenPositions) AS LongOpenPositions |
| 19 | `ShortOpenPositions` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(ShortOpenPositions) AS ShortOpenPositions |
| 20 | `UnitsNOP` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(UnitsNOP) AS UnitsNOP |
| 21 | `UnitsBuy` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(UnitsBuy) AS UnitsBuy |
| 22 | `UnitsSell` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(UnitsSell) AS UnitsSell |
| 23 | `RealizedZero` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(RealizedZero) AS RealizedZero |
| 24 | `ChangeInUnrealizedZero` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(ChangeInUnrealizedZero) AS ChangeInUnrealizedZero |
| 25 | `TotalZero` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(TotalZero) AS TotalZero |
| 26 | `VariableSpread` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(VariableSpread) AS VariableSpread |
| 27 | `OverNightFee` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(OverNightFee) AS OverNightFee |
| 28 | `Dividend` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(Dividend) AS Dividend |
| 29 | `OverNightFee_Long` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(OverNightFee_Long) AS OverNightFee_Long |
| 30 | `OverNightFee_Short` | `main.dealing.bi_output_dealing_dealingdashboard_cid` | `—` | `aggregate` | — | SUM(OverNightFee_Short) AS OverNightFee_Short |

## Cross-check vs system.access.column_lineage

- Total target columns: **30**
- OK: **16**, WARN: **0**, ERROR: **14**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `NOP` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.nop` | ERROR |
| `LongOpenPositions` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.longopenpositions` | ERROR |
| `ShortOpenPositions` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.shortopenpositions` | ERROR |
| `UnitsNOP` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.unitsnop` | ERROR |
| `UnitsBuy` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.unitsbuy` | ERROR |
| `UnitsSell` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.unitssell` | ERROR |
| `RealizedZero` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.realizedzero` | ERROR |
| `ChangeInUnrealizedZero` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.changeinunrealizedzero` | ERROR |
| `TotalZero` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.totalzero` | ERROR |
| `VariableSpread` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.variablespread` | ERROR |
| `OverNightFee` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.overnightfee` | ERROR |
| `Dividend` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.dividend` | ERROR |
| `OverNightFee_Long` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.overnightfee_long` | ERROR |
| `OverNightFee_Short` | — | `main.dealing.bi_output_dealing_dealingdashboard_cid.overnightfee_short` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **14**
