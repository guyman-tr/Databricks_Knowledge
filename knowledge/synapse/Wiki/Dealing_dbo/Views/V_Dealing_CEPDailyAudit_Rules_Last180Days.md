# Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_Rules_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_Rules` |
| **Filter** | `WHERE Date >= GETDATE() - 180` |
| **Columns** | Same as base table (SELECT *) |
| **PII** | NO |
| **Tags** | cep, audit, rule, hedging, view, rolling-window, dealing |

---

## 1. Business Meaning

A **rolling 180-day window** over `Dealing_CEPDailyAudit_Rules`, which tracks daily changes to top-level CEP hedging Rules. Rules are the highest-level unit in the CEP rule engine — each Rule contains Compound Properties, which in turn contain Conditions. Rule changes directly affect which hedging strategy is applied to client positions.

This view provides a BI-friendly time-bounded slice. With ~1,003 rows in the base table over ~2.3 years, this view captures roughly the most recent ~300-400 rule changes.

---

## 2. Business Logic

```sql
SELECT * FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules WHERE Date >= GETDATE() - 180
```

No transformations. Pure time-filter view.

---

## 3. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [Dealing_CEPDailyAudit_Rules](../Tables/Dealing_CEPDailyAudit_Rules.md) | Base table — all columns inherited |
| `SP_CEPDailyAudit` | Writer SP for the base table |
| [V_Dealing_CEPDailyAudit_CP_Last180Days](V_Dealing_CEPDailyAudit_CP_Last180Days.md) | Sibling view — CP changes in same window |
| [V_Dealing_CEPDailyAudit_Conditions_Last180Days](V_Dealing_CEPDailyAudit_Conditions_Last180Days.md) | Sibling view — Condition changes in same window |

---

## 4. Elements

All columns are inherited from `Dealing_CEPDailyAudit_Rules`. See [base table documentation](../Tables/Dealing_CEPDailyAudit_Rules.md) for full element descriptions.

---

## 5. Usage Notes

**CEP audit trio**: This view is one of three sibling 180-day views (`CP`, `Conditions`, `Rules`), all written by `SP_CEPDailyAudit`. Together they provide a complete picture of CEP rule engine changes at all three levels of the hierarchy.

---

## 6. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Base Table | 5/5 | Base table fully documented (8.5/10) |
| Business Context | 4/5 | Purpose clear from naming and sibling pattern |
| **Total** | **7.0/10** | Simple filter view |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
