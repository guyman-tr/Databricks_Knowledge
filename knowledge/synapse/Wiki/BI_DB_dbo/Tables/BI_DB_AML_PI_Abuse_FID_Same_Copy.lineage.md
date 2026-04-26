# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_Copy

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + general schema)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `#Copy_FID` | Temp Table | Copier FundingIDs per PI — DISTINCT (FundingID, CID, ParentCID) from Fact_BillingDeposit for active copiers |
| 2 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Upstream source of copier FundingIDs |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | ParentCID | #Copy_FID | ParentCID | PI's CID — groups all copier FID records belonging to this PI |
| 2 | Same_FID_Copier | #Copy_FID | FundingID | `COUNT(*) - COUNT(DISTINCT FundingID)` over all copier FundingID records for this PI — measures funding method convergence across the copier base |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#Copy_FID (DISTINCT: FundingID, CID=copier, ParentCID)
  ← Fact_BillingDeposit (copier deposits, FundingID NOT IN 1..7)
  ← History_GuruCopiers (copier→PI linkage at @DateTime)

GROUP BY cf.ParentCID → #SameFID_Copier
  Same_FID_Copier = COUNT(*) - COUNT(DISTINCT cf.FundingID)
  (= number of FundingID "duplicates" across copiers of this PI)

TRUNCATE BI_DB_AML_PI_Abuse_FID_Same_Copy; INSERT FROM #SameFID_Copier + GETDATE()

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 48 | Generated 2026-04-22*
