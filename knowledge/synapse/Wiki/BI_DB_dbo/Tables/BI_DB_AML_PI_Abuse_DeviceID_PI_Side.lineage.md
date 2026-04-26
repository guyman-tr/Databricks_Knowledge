# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + general schema)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | PI device fingerprints (ClientDeviceId) via GCID; DateID>=20240101; null-GUID excluded |
| 2 | `#pis` | Temp Table | PI gate: GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor; join ON pp.GCID=dh.Gcid |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | PI_DeviceID | STS_User_Operations_Data_History | ClientDeviceId | Renamed passthrough — UUID device fingerprint from PI sessions; excludes null-GUID '00000000-0000-0000-0000-000000000000' |
| 2 | ParentCID | STS_User_Operations_Data_History | RealCid | Renamed passthrough — PI's real-money CID; used as FK to PI in other suite tables |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
DWH_dbo.STS_User_Operations_Data_History (dh)
JOIN #pis (pp.GCID = dh.Gcid — GCID join, NOT CID)
WHERE dh.DateID >= 20240101
  AND dh.ClientDeviceId <> '00000000-0000-0000-0000-000000000000'
SELECT DISTINCT dh.ClientDeviceId AS PI_DeviceID, dh.RealCid AS ParentCID
→ #PIsameDeviceID

TRUNCATE BI_DB_AML_PI_Abuse_DeviceID_PI_Side; INSERT FROM #PIsameDeviceID + GETDATE()

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 48 | Generated 2026-04-22*
