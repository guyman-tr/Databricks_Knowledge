# Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_Conditions_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` |
| **Filter** | `WHERE Date >= GETDATE() - 180` |
| **Columns** | Same as base table (SELECT *) |
| **PII** | NO |
| **Tags** | cep, audit, condition, view, rolling-window, dealing |

---

## 1. Business Meaning

A **rolling 180-day window** over `Dealing_CEPDailyAudit_Conditions`, which tracks daily changes to individual Conditions within CEP hedging rules. Conditions are the atomic evaluation units that determine which hedging path a position takes (e.g., instrument type, regulation, leverage bracket).

This view provides a BI-friendly time-bounded slice for dashboards monitoring CEP condition changes over the last 6 months.

---

## 2. Business Logic

```sql
SELECT * FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions WHERE Date >= GETDATE() - 180
```

No transformations. Pure time-filter view.

---

## 3. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [Dealing_CEPDailyAudit_Conditions](../Tables/Dealing_CEPDailyAudit_Conditions.md) | Base table — all columns inherited |
| `SP_CEPDailyAudit` | Writer SP for the base table |

---

## 4. Elements

All columns are inherited from `Dealing_CEPDailyAudit_Conditions`. See [base table documentation](../Tables/Dealing_CEPDailyAudit_Conditions.md) for full element descriptions.

---

## 5. Usage Notes

**Rolling window**: The 180-day boundary is evaluated at query time (`GETDATE()`), so the window shifts daily.

**~3,189 rows** in the base table (as of last sample). The 180-day window captures roughly the most recent ~1,500 rows depending on change frequency.

---

## 6. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Base Table | 5/5 | Base table fully documented |
| Business Context | 4/5 | Purpose clear from naming |
| **Total** | **7.0/10** | Simple filter view |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
