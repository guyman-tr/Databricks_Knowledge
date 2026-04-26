# BI_DB_dbo.BI_DB_CID_VerificationLevel — Lineage

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (VerificationLevelID, RealCID)
  + DWH_dbo.Dim_Range (dr.FromDateID = @dateID — only SCD rows starting on @date)
  + DWH_dbo.Dim_VerificationLevel (ID values 1, 2, 3 via CROSS JOIN)
  -> SP_CID_VerificationLevel(@date)
     [DELETE WHERE FromDateID = @dateID]
     [INSERT WHERE customer not already in table for that level]
  -> BI_DB_dbo.BI_DB_CID_VerificationLevel
```

**Orchestration**: OpsDB ProcessName=SB_Daily, Priority=0, Frequency=Daily.

## Source → Target Column Mapping

| Target Column | Source Object | Source Column / Expression | Tier |
|--------------|---------------|----------------------------|------|
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | T2 |
| VerificationLevelID | Computed | Dim_VerificationLevel.ID — each level the customer has achieved (VerificationLevelID >= v.ID where v.ID IN (1,2,3)) | T2 |
| FromDateID | DWH_dbo.Dim_Range | FromDateID — the date the Fact_SnapshotCustomer SCD2 row started on @date | T2 |
| UpdateDate | Computed | GETDATE() at INSERT time | T2 |
| FromDate | Computed | CONVERT(DATE, CONVERT(CHAR(8), FromDateID)) — date equivalent of FromDateID | T2 |

## Key Design Logic

**Cross-join expansion**: The SP cross-joins customers with `Dim_VerificationLevel` and filters `VerificationLevelID >= v.ID AND v.ID NOT IN (-1, 0)`. For a customer with VerificationLevelID=3, this generates 3 rows (for levels 1, 2, and 3). For VerificationLevelID=2, it generates 2 rows. For VerificationLevelID=1, it generates 1 row.

**First-achievement dedup**: The INSERT uses LEFT JOIN to check if the customer already has a row for that VerificationLevelID in the table. If yes, no insert (the earlier date is preserved). This means FromDateID represents the FIRST time the SP processed this customer at each level — effectively approximating the date they first reached that verification level.

**Date source caveat**: `FromDateID` is the FSC SCD2 row's `FromDateID` — the date a change event was detected in Fact_SnapshotCustomer. This approximates (but may not exactly equal) the date the customer's KYC status changed. If a customer's verification level was unchanged but another attribute changed on @date, the SP does not re-insert (dedup prevents it). The first time the SP processed the customer at a given level determines their FromDateID.
