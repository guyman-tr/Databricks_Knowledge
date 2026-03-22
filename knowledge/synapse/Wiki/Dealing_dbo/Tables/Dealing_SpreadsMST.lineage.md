# Dealing_dbo.Dealing_SpreadsMST — Lineage

| Property | Value |
|----------|-------|
| **Wiki File** | [Dealing_SpreadsMST.md](Dealing_SpreadsMST.md) |
| **ETL SP** | `Dealing_dbo.SP_SpreadsMST` |
| **Write Pattern** | DELETE WHERE Date = @Date → INSERT |

---

## Upstream Sources

| Table | Schema | Join Key | Data Provided |
|-------|--------|----------|---------------|
| `External_Etoro_Trade_InstrumentSpread` | Dealing_staging | `InstrumentID` | Spread configuration: Bid, Ask, SpreadTypeID, MarketSpreadThreshold, ReferenceBid, ReferenceAsk, SpreadThresholdTypeID, FeedID |
| `etoro_Trade_InstrumentMetaData` | Dealing_staging | `InstrumentID` | InstrumentDisplayName, Symbol, Exchange |
| `External_Etoro_Dictionary_SpreadType` | Dealing_staging | `SpreadTypeID` | SpreadsType name lookup ('PrecentageSpread' / 'SpreadInPips') |
| `Dim_Instrument` | DWH_dbo | `InstrumentID` | InstrumentType, VisibleInternallyOnly; provides Tradable=1 filter |

---

## Downstream Consumers

| Consumer | Type | Notes |
|----------|------|-------|
| Dealing desk spread monitoring dashboards | External (BI/reports) | Primary consumer — daily spread vs MST threshold audit |
| (No documented downstream DWH tables) | — | Not referenced as a source in any other documented Dealing_dbo or DWH_dbo SP |

---

## Data Flow

```
External_Etoro_Trade_InstrumentSpread  ──┐
etoro_Trade_InstrumentMetaData         ──┤  SP_SpreadsMST (@Date)  →  Dealing_SpreadsMST
External_Etoro_Dictionary_SpreadType   ──┤  [DELETE + INSERT by Date]
DWH_dbo.Dim_Instrument (filter/enrich) ──┘
```

**Filter applied in SP**: `Dim_Instrument.Tradable = 1 AND FeedID = 1` — only primary-feed tradable instruments appear in output.
