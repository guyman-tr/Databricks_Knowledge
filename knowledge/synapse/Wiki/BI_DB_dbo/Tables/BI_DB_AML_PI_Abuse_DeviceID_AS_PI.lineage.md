# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_AS_PI

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | PI device fingerprints (ClientDeviceId) matched by GCID; date-filtered ≥20240101; null-GUID excluded |
| 2 | `#pis` (temp) | — | PI population (CID, GCID); provides GCID for device lookup |
| 3 | `#CopysameDeviceID` (temp) | — | Copier device inventory; used to detect PI-copier device overlap |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | ParentCID | STS_User_Operations_Data_History | RealCid | PI's CID, joined via GCID from #pis |
| 2 | SameDeviceID_Users_AS_PI | STS_User_Operations_Data_History (PI) + #CopysameDeviceID | ClientDeviceId | `COUNT(*) - COUNT(DISTINCT PI_DeviceID)` where PI's ClientDeviceId matches any copier's ClientDeviceId — excess count above distinct matching devices |
| 3 | UpdateDate | — | — | `GETDATE()` at SP execution time |

---

## ETL Flow

```
#pis.GCID → STS_User_Operations_Data_History.Gcid (DateID≥20240101, non-null GUID) → #PIsameDeviceID (PI device inventory)
#CopysameDeviceID (copier device inventory, built from #copy + STS_User_Operations_Data_History)
JOIN #PIsameDeviceID ON Copy_DeviceID = PI_DeviceID
GROUP BY ParentCID → #sameDeviceID_AS_PI
TRUNCATE BI_DB_AML_PI_Abuse_DeviceID_AS_PI; INSERT FROM #sameDeviceID_AS_PI

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 47 | Generated 2026-04-22*
