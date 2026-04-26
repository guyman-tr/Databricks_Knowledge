# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we + general schema

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | Copier device fingerprints (ClientDeviceId) via RealCid; date-filtered ≥20240101; null-GUID excluded |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CIDs to PI (ParentCID) at @DateTime |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | PI's CID — passthrough from #CopysameDeviceID |
| 2 | SameDeviceID_Copiers | STS_User_Operations_Data_History (copiers) | ClientDeviceId | `COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` across all copiers of this PI — excess count above distinct device fingerprints (i.e., how many copier-device observations share a device already seen by another copier) |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#copy (copier CIDs per PI)
JOIN STS_User_Operations_Data_History ON RealCid (DateID≥20240101, non-null GUID)
JOIN etoroGeneral_History_GuruCopiers ON RealCid + Timestamp = @DateTime
JOIN #pis ON ParentCID → #CopysameDeviceID (grain: Copy_DeviceID, CopyCID, ParentCID)

GROUP BY ParentCID → #sameDeviceID_Copiers
  SameDeviceID_Copiers = COUNT(*) - COUNT(DISTINCT Copy_DeviceID)

TRUNCATE BI_DB_AML_PI_Abuse_DeviceID_Copiers; INSERT FROM #sameDeviceID_Copiers

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 47 | Generated 2026-04-22*
