# Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_CEPDailyAudit_CP_Last180Days |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_CEPDailyAudit_CP` |
| **Filter** | `WHERE Date >= GETDATE() - 180` |
| **Columns** | Same as base table (SELECT *) |
| **PII** | NO |
| **Tags** | cep, audit, compound-property, view, rolling-window, dealing |

---

## 1. Business Meaning

A **rolling 180-day window** over `Dealing_CEPDailyAudit_CP`, which tracks daily changes to Compound Properties (CPs) in the CEP (Client Execution Platform) hedging rule engine. CPs are reusable logical groupings of conditions used within hedging rules.

This view provides a BI-friendly time-bounded slice that avoids scanning the full history table. Used for dashboards and reporting that only need recent CEP audit data.

---

## 2. Business Logic

```sql
SELECT * FROM Dealing_dbo.Dealing_CEPDailyAudit_CP WHERE Date >= GETDATE() - 180
```

No transformations, joins, or computed columns. Pure time-filter view.

---

## 3. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [Dealing_CEPDailyAudit_CP](../Tables/Dealing_CEPDailyAudit_CP.md) | Base table — all columns inherited |
| `SP_CEPDailyAudit` | Writer SP for the base table |

---

## 4. Elements

All columns are inherited from `Dealing_CEPDailyAudit_CP`. See [base table documentation](../Tables/Dealing_CEPDailyAudit_CP.md) for full element descriptions.

---

## 5. Usage Notes

**Rolling window**: The 180-day boundary is evaluated at query time (`GETDATE()`), so the window shifts daily without any ETL action.

**Prefer this view over the base table** for dashboard queries to limit scan scope.

---

## 6. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Base Table | 5/5 | Base table fully documented |
| Business Context | 4/5 | Purpose clear from naming and pattern |
| **Total** | **7.0/10** | Simple filter view — score reflects limited standalone complexity |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
