# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we + general schema

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Active copy relationships at @DateTime; provides copier CIDs per PI |
| 2 | `DWH_dbo.Dim_Customer` | Dim | Copier registration IP address (dc.IP) |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | PI's customer ID — passthrough from #pis population join |
| 2 | IP | Dim_Customer (copier) | IP | Shared IP address registered by ≥2 copiers of this PI |
| 3 | NumCopiers | Dim_Customer (copier) | IP | `COUNT(DISTINCT CopierCID)` per (ParentCID, IP); HAVING COUNT ≥ 2 |
| 4 | CopierList | etoroGeneral_History_GuruCopiers | CID | `STRING_AGG(CAST(CopierCID AS NVARCHAR(20)), ', ') WITHIN GROUP (ORDER BY CopierCID)` — sorted comma-delimited list of copier CIDs sharing this IP |
| 5 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#pis (PI population)
JOIN general.etoroGeneral_History_GuruCopiers (@DateTime)   → #CopierIPs (PI→Copier→IP triples, copier IP from Dim_Customer)
GROUP BY ParentCID + IP, HAVING COUNT(DISTINCT CopierCID) >= 2 → #SameIPCopiers_Final
TRUNCATE BI_DB_AML_PI_Abuse_SameIP; INSERT FROM #SameIPCopiers_Final

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 47 | Generated 2026-04-22*
