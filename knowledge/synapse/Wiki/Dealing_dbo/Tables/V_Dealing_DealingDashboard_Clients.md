# Dealing_dbo.V_Dealing_DealingDashboard_Clients

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_DealingDashboard_Clients |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_DealingDashboard_Clients` |
| **Filter** | `WHERE DateID > 20211231` (2022-01-01 onwards, static cutoff) |
| **Distribution** | N/A (view) |
| **PII** | Inherits from base table |

---

## 1. Business Meaning

Filtered view over `Dealing_DealingDashboard_Clients` exposing only data from **2022 onwards** (DateID > 20211231). This view is designed for dashboard and operational use cases that need recent NOP/hedge data — the 2021 cutoff removes pre-2022 historical data that may include legacy instrument categories or pre-migration records.

The base table is the central daily hub for client NOP (Net Open Position), zero coverage, and volume data by instrument — used as a source for `Dealing_Regime_Flags` and other downstream analytics. The NOLOCK hint indicates high-frequency read usage.

See [Dealing_DealingDashboard_Clients.md](Dealing_DealingDashboard_Clients.md) for full business context and column definitions.

---

## 2. View Definition

```sql
SELECT *
FROM [Dealing_dbo].[Dealing_DealingDashboard_Clients] WITH (NOLOCK)
WHERE DateID > 20211231;
```

---

## 3. When to Use This View vs the Base Table

| Scenario | Use |
|----------|-----|
| Dashboard queries on recent NOP/volume (2022+) | **This view** |
| Historical analysis including 2021 or earlier | Base table `Dealing_DealingDashboard_Clients` |
| Feeding `Dealing_Regime_Flags` SP (reads from 2019-01-01) | Base table `Dealing_DealingDashboard_Clients` |

---

## 4. Common Query Patterns

```sql
-- Recent NOP by instrument
SELECT Date, InstrumentID, InstrumentName, TotalZero, TotalVolume
FROM Dealing_dbo.V_Dealing_DealingDashboard_Clients
WHERE Date >= '2026-01-01'
ORDER BY Date DESC, TotalVolume DESC;
```

---

## 5. Known Issues & Quirks

- **Static cutoff**: DateID > 20211231 is hardcoded — not a rolling window; data from 2022-01-01 onwards is always included
- **NOLOCK hint**: May return uncommitted/dirty reads; suitable for dashboards but not for strict financial reconciliation
- **No materialization**: Every query hits the base table live

---

## 6. Lineage Summary

Thin filter wrapper over `Dealing_dbo.Dealing_DealingDashboard_Clients`. No column transformations. See [Dealing_DealingDashboard_Clients.md](Dealing_DealingDashboard_Clients.md) for full lineage.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_DealingDashboard_Clients` | Base table — this view is a filtered window |
| `Dealing_dbo.Dealing_Regime_Flags` | Downstream consumer — but reads from base table (from 2019) |

---

*Quality score: 7.0/10 — clean view over an active, important base table*
