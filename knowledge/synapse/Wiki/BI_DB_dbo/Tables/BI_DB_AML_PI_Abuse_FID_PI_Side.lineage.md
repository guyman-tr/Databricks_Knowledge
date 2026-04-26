# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + general schema)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | PI's own deposit payment instruments (FundingID, CID=ParentCID), FundingID NOT IN (1..7) |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Validates PI membership (ParentCID) at @DateTime |
| 3 | `#pis` | Temp Table | PI gate: GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | FundingID | Fact_BillingDeposit | FundingID | Passthrough — unique payment instrument used by PI in their own deposits; FundingID NOT IN (1,2,3,4,5,6,7) excludes generic/internal methods |
| 2 | ParentCID | Fact_BillingDeposit / History_GuruCopiers | CID / ParentCID | PI's CID — Fact_BillingDeposit.CID where CID=PI from #pis |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
DWH_dbo.Fact_BillingDeposit (fbd.CID = gc.ParentCID)
JOIN general.etoroGeneral_History_GuruCopiers (gc.Timestamp=@DateTime)
JOIN #pis (PI gate: GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor)
WHERE fbd.FundingID NOT IN (1,2,3,4,5,6,7)
SELECT DISTINCT fbd.FundingID, gc.ParentCID
→ #PI_FID

TRUNCATE BI_DB_AML_PI_Abuse_FID_PI_Side; INSERT FROM #PI_FID + GETDATE()

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 48 | Generated 2026-04-22*
