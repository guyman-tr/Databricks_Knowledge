# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + general schema)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Copier deposit payment instruments (FundingID, CID=CopierCID), FundingID NOT IN (1..7) |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CIDs to their PI (ParentCID) at @DateTime |
| 3 | `#pis` | Temp Table | PI gate: GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | FundingID | Fact_BillingDeposit | FundingID | Passthrough — unique payment instrument used by a copier; FundingID NOT IN (1,2,3,4,5,6,7) excludes generic/internal methods |
| 2 | CID | Fact_BillingDeposit | CID | Copier's customer ID — the person who copied the PI |
| 3 | ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | The PI being copied — links copier deposit to their PI at @DateTime |
| 4 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
DWH_dbo.Fact_BillingDeposit (fbd.CID = gc.CID — copier)
JOIN general.etoroGeneral_History_GuruCopiers (gc.CID=copier, gc.Timestamp=@DateTime)
JOIN #pis (PI gate: gc.ParentCID in active PI set)
WHERE fbd.FundingID NOT IN (1,2,3,4,5,6,7)
SELECT DISTINCT fbd.FundingID, fbd.CID, gc.ParentCID
→ #Copy_FID

TRUNCATE BI_DB_AML_PI_Abuse_FID_Copy_Side; INSERT FROM #Copy_FID + GETDATE()

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 48 | Generated 2026-04-22*
