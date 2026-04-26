# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we + general schema

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | Copier device fingerprints — ClientDeviceId (UUID string), RealCid (copier CID); date-filtered ≥20240101; null-GUID excluded |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CID to PI (ParentCID) at @DateTime |
| 3 | `#copy` (temp) | — | Active copier population for PI scope filtering |
| 4 | `#pis` (temp) | — | PI population for scope filtering |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | Copy_DeviceID | STS_User_Operations_Data_History | ClientDeviceId | Device UUID used by the copier; DISTINCT (SELECT DISTINCT in #CopysameDeviceID) |
| 2 | CopyCID | STS_User_Operations_Data_History | RealCid | Copier's customer ID |
| 3 | ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | PI being copied — linked via CopyCID→gc.CID join at @DateTime |
| 4 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#copy (copier CIDs per PI)
JOIN STS_User_Operations_Data_History ON RealCid (DateID≥20240101, non-null GUID)
JOIN etoroGeneral_History_GuruCopiers ON RealCid=gc.CID AND Timestamp=@DateTime
JOIN #pis ON gc.ParentCID → #CopysameDeviceID (grain: Copy_DeviceID, CopyCID, ParentCID — DISTINCT)

TRUNCATE BI_DB_AML_PI_Abuse_DeviceID_Copy_Side; INSERT FROM #CopysameDeviceID

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 47 | Generated 2026-04-22*
