# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_as_pi

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + general schema)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `#PI_FID` | Temp Table | PI's own FundingIDs — DISTINCT (FundingID, ParentCID) from Fact_BillingDeposit for PI deposits |
| 2 | `#Copy_FID` | Temp Table | Copier FundingIDs — DISTINCT (FundingID, CID, ParentCID) from Fact_BillingDeposit for copier deposits |
| 3 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Upstream source of both PI and copier FundingIDs |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | ParentCID | #PI_FID | ParentCID | PI's CID — groups FID cross-matches by PI |
| 2 | SameFID_AS_PI | #PI_FID JOIN #Copy_FID | FundingID | `COUNT(*) - COUNT(DISTINCT pf.FundingID)` per (PI, copier) pair — measures how many cross-PI copier FID re-uses are attributed to this PI; see Known Issues |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#PI_FID (DISTINCT: FundingID, ParentCID)  — PI's own payment methods
JOIN #Copy_FID (DISTINCT: FundingID, CID, ParentCID_of_copier) ON FundingID
  Note: JOIN is on FundingID only — no restriction that copier belongs to this PI
GROUP BY pf.ParentCID, cf.CID → #SameFID_AS_PI
  SameFID_AS_PI = COUNT(*) - COUNT(DISTINCT pf.FundingID)
SELECT DISTINCT pf.ParentCID, SameFID_AS_PI
→ may produce multiple rows per PI if different copiers have different FID overlap counts

TRUNCATE BI_DB_AML_PI_Abuse_FID_Same_as_pi; INSERT FROM #SameFID_AS_PI + GETDATE()

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 48 | Generated 2026-04-22*
