# Lineage — Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **View** | `Dealing_dbo.Dealing_CEPDailyAudit_Rules` | SELECT * WHERE Date >= GETDATE()-180 |

## Column Lineage

All columns pass through from `Dealing_CEPDailyAudit_Rules` — see [base table lineage](../Tables/Dealing_CEPDailyAudit_Rules.lineage.md).

---

*Generated: 2026-03-21 | Batch 20*
