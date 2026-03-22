# Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_Conditions_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` |
| **Filter** | `WHERE Date >= GETDATE()-180` (rolling 180-day window) |
| **Distribution** | N/A (view) |
| **PII** | None |

---

## 1. Business Meaning

Rolling 180-day window over `Dealing_CEPDailyAudit_Conditions` — the daily audit log for **Condition changes** in the CEP (Client Execution Platform) hedging rule engine. Conditions are atomic rule components (e.g., "InstrumentType = Stock") that are combined into Compound Properties and ultimately control how client positions are hedged.

This view is the preferred entry point for recent Condition change analysis. See [Dealing_CEPDailyAudit_Conditions.md](Dealing_CEPDailyAudit_Conditions.md) for full business context and column definitions.

---

## 2. View Definition

```sql
SELECT *
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE Date >= GETDATE()-180;
```

---

## 3. When to Use This View vs the Base Table

| Scenario | Use |
|----------|-----|
| Recent CEP Condition audit (last ~6 months) | **This view** |
| Historical Condition analysis (> 6 months ago) | Base table `Dealing_CEPDailyAudit_Conditions` with explicit date filter |

---

## 4. Common Query Patterns

```sql
-- Recent condition changes
SELECT Date, ConditionName, ConditionType, Status, UpdateDate
FROM Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days
ORDER BY Date DESC;
```

> ⚠️ **Rolling window**: The 180-day cutoff is evaluated at query time (GETDATE()-180) — results shift daily.

---

## 5. Known Issues & Quirks

- **Rolling cutoff**: WHERE clause uses GETDATE()-180 — results change day by day
- **No materialization**: Every query hits the base table live

---

## 6. Lineage Summary

Thin filter wrapper over `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`. No column transformations. See [Dealing_CEPDailyAudit_Conditions.md](Dealing_CEPDailyAudit_Conditions.md) for full lineage.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | Base table — this view is a filtered window |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days` | Sibling view — same pattern for Compound Properties audit |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days` | Sibling view — same pattern for Rules audit |

---

*Quality score: 7.0/10 — clean thin wrapper, active base table*
