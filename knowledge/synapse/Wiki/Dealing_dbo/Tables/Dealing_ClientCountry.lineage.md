---
object: Dealing_ClientCountry
lineage_type: DWH Aggregation
production_source: BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo dimensions
---

# Dealing_ClientCountry — Lineage Map

## Data Flow

```
DWH_dbo.Dim_Instrument (Exchange/InstrumentID → Country)
            │
            ▼
BI_DB_dbo.BI_DB_PositionPnL ──► #Countries (CID, NOP, Instrument_Country, Client_Country)
            │                                           │ FILTER: Instrument_Country = Client_Country
DWH_dbo.Dim_Customer ──────────────────────────────────┤
DWH_dbo.Dim_Country ───────────────────────────────────┘
                                         │
                                         ▼
                              #Final1 (Client_Country, SUM(NOP))
                                         │
                                         ▼
                              Dealing_ClientCountry (Date, Client_Country, NOP)
```

## Source Tables

| Source | Schema | Used For |
|--------|--------|---------|
| `BI_DB_PositionPnL` | BI_DB_dbo | NOP per CID per DateID |
| `Dim_Instrument` | DWH_dbo | Exchange → Country mapping |
| `Dim_Customer` | DWH_dbo | CID → CountryID |
| `Dim_Country` | DWH_dbo | CountryID → country name |

## Generic Pipeline Mapping
No direct generic pipeline entry. This table aggregates from BI_DB_PositionPnL (itself loaded from lake).

## Refresh Schedule
Daily — SP_ClientCountry, OpsDB Priority 0, ProcessType 1 (SQL)
