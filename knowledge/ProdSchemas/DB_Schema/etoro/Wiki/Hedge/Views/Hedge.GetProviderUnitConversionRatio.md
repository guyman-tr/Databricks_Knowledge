# Hedge.GetProviderUnitConversionRatio

> Thin passthrough view over Hedge.ProviderUnitConversionRatio returning the 4 key columns. 5,739 rows. Provides the unit conversion ratio and lot size per (LiquidityProviderID, InstrumentID) combination.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 5,739 |

---

## 1. Business Meaning

Hedge.GetProviderUnitConversionRatio is a thin passthrough view over Hedge.ProviderUnitConversionRatio, exposing the four columns used by the hedge system to convert between eToro's internal unit representation and the LP's lot/unit conventions.

Different LPs quote and trade instruments in different lot sizes. For example, eToro internally may track positions in units, but an LP quotes crude oil in barrels (1 contract = 1,000 barrels). The UnitConversionRatio and LotSize columns bridge this gap for each (provider, instrument) combination.

LiquidityProviderID=0 rows represent default conversions applying when no provider-specific override exists.

For full column descriptions and business logic, see [Hedge.ProviderUnitConversionRatio](Hedge.ProviderUnitConversionRatio.md).

---

## 2. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityProviderID | Hedge.ProviderUnitConversionRatio | The LP this conversion applies to (0 = default/global) |
| InstrumentID | Hedge.ProviderUnitConversionRatio | The instrument being converted |
| UnitConversionRatio | Hedge.ProviderUnitConversionRatio | Multiplier converting eToro units to LP units |
| LotSize | Hedge.ProviderUnitConversionRatio | LP lot size for this instrument |

---

## 3. Data Overview

5,739 rows. Sample (LiquidityProviderID=0 = global defaults):

| LiquidityProviderID | InstrumentID | UnitConversionRatio | LotSize |
|---|---|---|---|
| 0 | 17 | 1 | 1 |
| 0 | 18 | 1 | 1 |
| 0 | 20 | 1 | 1 |

Default conversions (ratio=1, lotsize=1) for commodities.

---

## 4. Relationships

### 4.1 Source Tables

| Table | Join Type | Condition |
|-------|-----------|-----------|
| Hedge.ProviderUnitConversionRatio | Base table (no filter) | - |

### 4.2 Consumed By

No stored procedures reference this view. The underlying table is queried via `Hedge.GetProviderUnitConversion` SP. See [Hedge.ProviderUnitConversionRatio](Hedge.ProviderUnitConversionRatio.md).

---

## 5. Dependencies

```
Hedge.GetProviderUnitConversionRatio (view)
+-- Hedge.ProviderUnitConversionRatio (table) [see Hedge.ProviderUnitConversionRatio.md]
```

---

## 6. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.GetProviderUnitConversionRatio | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetProviderUnitConversionRatio.sql*
