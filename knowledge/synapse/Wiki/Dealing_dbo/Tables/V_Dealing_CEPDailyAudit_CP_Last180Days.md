# Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_CP_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_CP` |
| **Filter** | `WHERE Date >= GETDATE()-180` (rolling 180-day window) |
| **Distribution** | N/A (view) |
| **PII** | None |

---

## 1. Business Meaning

Rolling 180-day window over `Dealing_CEPDailyAudit_CP` — the daily audit log for **Compound Property (CP) changes** in the CEP (Client Execution Platform) hedging rule engine. This view is the preferred entry point for recent CP change analysis, limiting query scope to the last 6 months.

All column semantics are identical to the base table. See [Dealing_CEPDailyAudit_CP.md](Dealing_CEPDailyAudit_CP.md) for full business context and column definitions.

---

## 2. View Definition

```sql
SELECT *
FROM Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE Date >= GETDATE()-180;
```

---

## 3. When to Use This View vs the Base Table

| Scenario | Use |
|----------|-----|
| Recent CEP CP audit (last ~6 months) | **This view** |
| Historical CP change analysis (> 6 months ago) | Base table `Dealing_CEPDailyAudit_CP` with explicit date filter |
| Building a dashboard showing current CEP state | **This view** |

---

## 4. Common Query Patterns

```sql
-- Recent CP changes
SELECT Date, CP_Name, Status, ConditionsCount, UpdateDate
FROM Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days
ORDER BY Date DESC;
```

> ⚠️ **Rolling window**: The 180-day cutoff is evaluated at query time (GETDATE()-180), not stored. Results will shift daily.

---

## 5. Known Issues & Quirks

- **Rolling cutoff**: The WHERE clause uses GETDATE()-180 — results change day by day
- **No materialization**: This is a view with no caching; every query hits the base table live

---

## 6. Lineage Summary

Thin filter wrapper over `Dealing_dbo.Dealing_CEPDailyAudit_CP`. No column transformations. See [Dealing_CEPDailyAudit_CP.md](Dealing_CEPDailyAudit_CP.md) for full lineage.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | Base table — this view is a filtered window |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days` | Sibling view — same pattern for Conditions audit |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days` | Sibling view — same pattern for Rules audit |

---

*Quality score: 7.0/10 — clean thin wrapper, active base table, rolling window is useful for dashboards*
