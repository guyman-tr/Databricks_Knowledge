# Dealing_dbo.V_Dealing_DealingDashboard_Clients

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_DealingDashboard_Clients |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_DealingDashboard_Clients` |
| **Filter** | `WHERE DateID > 20211231` (from 2022 onwards) |
| **Hint** | `WITH (NOLOCK)` |
| **Columns** | Same as base table (SELECT *) |
| **PII** | NO — aggregated data, no CID |
| **Tags** | dealing, dashboard, clients, view, nolock, volumetrics, nop, dealing-desk |

---

## 1. Business Meaning

A **time-filtered view** over the massive `Dealing_DealingDashboard_Clients` fact table (~1.83B rows), restricting to data from 2022 onwards. The base table is the **primary fact table powering the eToro Dealing Dashboard**, providing daily aggregated client trading activity at the grain of `Date × HedgeServerID × InstrumentID × Regulation × Country × Region × Mifid × IsCopy × IsCFD × Leverage × IsFuture`.

The `DateID > 20211231` filter removes pre-2022 historical data that is no longer relevant for operational dashboards, significantly reducing query scan scope on this 1.83B-row CCI table.

The `WITH (NOLOCK)` hint is applied for non-blocking reads — acceptable for dashboard reporting where absolute transactional consistency is not required.

---

## 2. Business Logic

```sql
SELECT * FROM Dealing_dbo.Dealing_DealingDashboard_Clients WITH (NOLOCK)
WHERE DateID > 20211231
```

No transformations. Time filter + dirty-read hint.

### Key Downstream Consumer

`SP_Regime_Flags` reads from this view to compute `TotalZero`, `TotalVolume`, `NOP`, and `NOP Change` for client regime classification. This makes the view a critical dependency in the compliance/regulatory pipeline.

---

## 3. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [Dealing_DealingDashboard_Clients](../Tables/Dealing_DealingDashboard_Clients.md) | Base table — all columns inherited |
| `SP_DealingDashboard_ClientData` | Writer SP for the base table |
| `SP_Regime_Flags` | Consumer — reads TotalZero, TotalVolume, NOP |
| `Dealing_Regime_Flags` | Downstream — receives computed flags |

---

## 4. Elements

All columns are inherited from `Dealing_DealingDashboard_Clients`. See [base table documentation](../Tables/Dealing_DealingDashboard_Clients.md) for full element descriptions. Key columns include:

- **DateID** / **Date**: Partitioning key, the filter boundary
- **TotalVolume**: Daily trading volume per segment
- **TotalZero**: Zero-commission activity volume
- **NOP**: Net Open Position
- **HedgeServerID**, **InstrumentID**, **Regulation**, **Country**, **IsCopy**, **IsCFD**, **Leverage**, **IsFuture**: Segmentation dimensions

---

## 5. Usage Notes

**Performance**: Despite the filter, this view still covers ~4+ years of data from a 1.83B-row table. For narrow queries, always add additional `DateID` or `Date` filters to leverage the CCI column pruning.

**NOLOCK**: This view uses dirty reads. For reconciliation or compliance queries requiring consistency, query the base table directly without NOLOCK.

**SP_Regime_Flags dependency**: Any changes to this view's filter boundary may break the regime flag computation pipeline.

---

## 6. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Base Table | 5/5 | Base table extensively documented |
| Business Context | 5/5 | Critical dashboard view, downstream SP dependency identified |
| **Total** | **7.5/10** | Filter view over well-documented base table |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
