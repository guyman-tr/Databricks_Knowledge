# Column Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `DWH_dbo.STS_User_Operations_Data_History` (login session device tracking) |
| **ETL SP** | `SP_AML_Multiple_Accounts` (@Date parameter, on-demand / not in OpsDB standard schedule) |
| **Secondary Sources** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID` (driving device set), `External_AlertServiceDB_*` (latest alert per CID via ROW_NUMBER) |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID   [ClientDeviceId population]
    │  → identifies all shared device IDs
    │
    ├── JOIN DWH_dbo.STS_User_Operations_Data_History
    │     ON ClientDeviceId  → get all CIDs that used these shared devices
    │     → CID, ClientDeviceId pairs
    │
    ├── LEFT JOIN External_AlertServiceDB_* (ROW_NUMBER per CID, latest alert)
    │     → AlertID, CreationDate, ModificationDate, AlertType,
    │        AlertTypeDescription, CategoryName, TriggerType, StatusType, StatusReason
    │
    └─ SP_AML_Multiple_Accounts (Step 16)
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | DWH_dbo.STS_User_Operations_Data_History | RealCid | rename | `RealCid AS CID` | eToro customer Real account ID |
| ClientDeviceId | DWH_dbo.STS_User_Operations_Data_History | ClientDeviceId | passthrough | Direct join key | Device identifier — links back to BI_DB_AML_Multiple_Accounts_DeviceID |
| AlertID | External_AlertServiceDB | AlertID | join-enriched | Latest alert per CID (ROW_NUMBER OVER PARTITION BY CID ORDER BY ModificationDate DESC = 1) | Most recent alert identifier from Alert Service |
| CreationDate | External_AlertServiceDB | CreationDate | join-enriched | From latest alert per CID | When the alert was first created |
| ModificationDate | External_AlertServiceDB | ModificationDate | join-enriched | From latest alert per CID | When the alert was last modified |
| AlertType | External_AlertServiceDB | AlertType | join-enriched | From latest alert per CID | Alert classification type (AccountStatusChange, HighRiskLogin, KycRelations, etc.) |
| AlertTypeDescription | External_AlertServiceDB | AlertTypeDescription | join-enriched | From latest alert per CID | Human-readable description of alert type |
| CategoryName | External_AlertServiceDB | CategoryName | join-enriched | From latest alert per CID | Alert category (eToroMoney, KYC, Risk, AML, Cashouts, Trading, Deposits) |
| TriggerType | External_AlertServiceDB | TriggerType | join-enriched | From latest alert per CID | What triggered the alert |
| StatusType | External_AlertServiceDB | StatusType | join-enriched | From latest alert per CID | Alert resolution status (Active/Clear/Follow Up) |
| StatusReason | External_AlertServiceDB | StatusReason | join-enriched | From latest alert per CID | Reason for current alert status |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **Join-enriched** | 9 |
| **ETL-computed** | 1 |
| **Total** | 12 |
