# Column Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `DWH_dbo.STS_User_Operations_Data_History` (login session device tracking) |
| **ETL SP** | `SP_AML_Multiple_Accounts` (@Date parameter, on-demand / not in OpsDB standard schedule) |
| **Secondary Sources** | None |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
DWH_dbo.STS_User_Operations_Data_History
    │  WHERE DateID >= 20230101
    │  AND ClientDeviceId <> '00000000-0000-0000-0000-000000000000'  [exclude null-sentinel GUID]
    │  GROUP BY ClientDeviceId
    │  HAVING COUNT(DISTINCT RealCid) > 1                            [shared device = AML signal]
    │
    └─ SP_AML_Multiple_Accounts (Step 15)
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| NumOfClientsSameDeviceID | DWH_dbo.STS_User_Operations_Data_History | RealCid | ETL-computed | `COUNT(DISTINCT RealCid)` per ClientDeviceId | Number of distinct customers who logged in using this device ID since 2023 |
| ClientDeviceId | DWH_dbo.STS_User_Operations_Data_History | ClientDeviceId | passthrough | GROUP BY ClientDeviceId | Device identifier from the Session Tracking Service login audit log |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **ETL-computed** | 2 |
| **Total** | 3 |
