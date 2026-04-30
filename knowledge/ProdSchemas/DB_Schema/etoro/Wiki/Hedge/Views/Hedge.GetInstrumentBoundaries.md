# Hedge.GetInstrumentBoundaries

> Thin passthrough view over Hedge.InstrumentBoundaries returning the 5 key boundary columns. 111,312 rows. Exposes OpenThresholdUSD, CloseThresholdPercentage, and HedgeRiskLimitUSD per (HedgeServerID, InstrumentID).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 111,312 |

---

## 1. Business Meaning

Hedge.GetInstrumentBoundaries is a direct passthrough view over Hedge.InstrumentBoundaries, selecting the five columns that define hedging thresholds for each (HedgeServerID, InstrumentID) combination. It provides a stable public interface to the boundary configuration data, abstracting the underlying table structure.

The three threshold columns control hedge system behavior:
- **OpenThresholdUSD**: the minimum dollar exposure before the system opens a hedge position
- **CloseThresholdPercentage**: the percentage drop in exposure that triggers closing the hedge position
- **HedgeRiskLimitUSD**: the maximum dollar exposure allowed before mandatory hedging

For full business logic and column descriptions, see [Hedge.InstrumentBoundaries](Hedge.InstrumentBoundaries.md).

---

## 2. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.InstrumentBoundaries | The hedge server these boundaries apply to (0 = global default) |
| InstrumentID | Hedge.InstrumentBoundaries | The instrument these boundaries govern |
| OpenThresholdUSD | Hedge.InstrumentBoundaries | Minimum USD exposure to open a hedge position |
| CloseThresholdPercentage | Hedge.InstrumentBoundaries | Percentage decline triggering hedge closure |
| HedgeRiskLimitUSD | Hedge.InstrumentBoundaries | Maximum USD exposure before mandatory hedge |

---

## 3. Data Overview

111,312 rows. Sample (HedgeServerID=0 = global defaults):

| HedgeServerID | InstrumentID | OpenThresholdUSD | CloseThresholdPercentage | HedgeRiskLimitUSD |
|---|---|---|---|---|
| 0 | 84 | 0 | 0 | 0 |
| 0 | 85 | 0 | 0 | 0 |
| 0 | 104 | 0 | 0 | 0 |

HedgeServerID=0 rows appear to be instrument defaults (all thresholds = 0).

---

## 4. Relationships

### 4.1 Source Tables

| Table | Join Type | Condition |
|-------|-----------|-----------|
| Hedge.InstrumentBoundaries | Base table (no filter) | - |

### 4.2 Consumed By

No stored procedures found referencing this view. Application code reads it directly. See [Hedge.InstrumentBoundaries](Hedge.InstrumentBoundaries.md) for procedures that use the underlying table.

---

## 5. Dependencies

```
Hedge.GetInstrumentBoundaries (view)
+-- Hedge.InstrumentBoundaries (table) [see Hedge.InstrumentBoundaries.md]
```

---

## 6. Atlassian Knowledge Sources

No Atlassian sources found. See Hedge.InstrumentBoundaries.md for related documentation.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.GetInstrumentBoundaries | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetInstrumentBoundaries.sql*
