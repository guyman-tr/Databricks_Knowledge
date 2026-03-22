# Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_Rules_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_Rules` |
| **Filter** | `WHERE Date >= GETDATE()-180` (rolling 180-day window) |
| **Distribution** | N/A (view) |
| **PII** | None |

---

## 1. Business Meaning

Rolling 180-day window over `Dealing_CEPDailyAudit_Rules` — the daily audit log for **Rule changes** in the CEP (Client Execution Platform) hedging rule engine. Rules are the top-level constructs that combine Compound Properties and define the hedging action (e.g., "route to LP X", "internalize").

This view is the preferred entry point for recent Rule change analysis. See [Dealing_CEPDailyAudit_Rules.md](Dealing_CEPDailyAudit_Rules.md) for full business context and column definitions.

---

## 2. View Definition

```sql
SELECT *
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE Date >= GETDATE()-180;
```

---

## 3. When to Use This View vs the Base Table

| Scenario | Use |
|----------|-----|
| Recent CEP Rule audit (last ~6 months) | **This view** |
| Historical Rule analysis (> 6 months ago) | Base table `Dealing_CEPDailyAudit_Rules` with explicit date filter |

---

## 4. Common Query Patterns

```sql
-- Recent rule changes
SELECT Date, RuleName, Priority, Status, UpdateDate
FROM Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days
ORDER BY Date DESC;
```

> ⚠️ **Rolling window**: The 180-day cutoff is evaluated at query time (GETDATE()-180) — results shift daily.

---

## 5. Known Issues & Quirks

- **Rolling cutoff**: WHERE clause uses GETDATE()-180 — results change day by day
- **No materialization**: Every query hits the base table live

---

## 6. Lineage Summary

Thin filter wrapper over `Dealing_dbo.Dealing_CEPDailyAudit_Rules`. No column transformations. See [Dealing_CEPDailyAudit_Rules.md](Dealing_CEPDailyAudit_Rules.md) for full lineage.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Rules` | Base table — this view is a filtered window |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days` | Sibling view — same pattern for Compound Properties audit |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days` | Sibling view — same pattern for Conditions audit |

---

*Quality score: 7.0/10 — clean thin wrapper, active base table*
