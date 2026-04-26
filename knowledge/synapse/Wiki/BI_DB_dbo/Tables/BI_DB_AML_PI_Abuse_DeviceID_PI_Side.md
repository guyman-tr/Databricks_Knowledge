# BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **unique device fingerprint (ClientDeviceId) observed for a Popular Investor (PI) since 2024-01-01**, after excluding the null-GUID placeholder. The table enumerates every distinct device each PI has logged in from — forming the PI-side device inventory for cross-referencing against copier devices to detect shared device usage.

- **Row count**: 585,539 (as of 2026-04-22)
- **Distinct Devices (PI_DeviceID)**: 475,109 | **Distinct PIs (ParentCID)**: 5,132
- **Avg Devices per PI**: 114.1 | **Max**: 457,015 | **Min**: 1
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains device fingerprint UUIDs and PI CID only

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | PI_DeviceID | nvarchar(500) | T1 | `DWH_dbo.STS_User_Operations_Data_History.ClientDeviceId` | UUID-format device identifier (e.g. `3c24d4e9-8ef0-405f-...`). Populated primarily for mobile app sessions; typically NULL or empty for web. Null-GUID `00000000-0000-0000-0000-000000000000` excluded. Renamed from `ClientDeviceId` by the SP. (Tier 1 — STS_Audit_UserOperationsData) |
| 2 | ParentCID | int | T1 | `DWH_dbo.STS_User_Operations_Data_History.RealCid` | The Popular Investor's customer ID. Renamed from `RealCid` by the SP; joined via GCID (not CID) because STS stores GCID. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NULL in DDL but always populated by the SP. (Propagation) |

**Tier summary**: 2 T1 | 1 Propagation

---

## 3. Business Context

This table answers: *"What devices has each PI logged in from since 2024-01-01?"* It is one half of the PI-abuse device cross-reference pair — the PI's device inventory. The other half is `BI_DB_AML_PI_Abuse_DeviceID_Copiers` (copiers' devices).

By comparing this table against the copier-side table, investigators can identify PIs and copiers who have logged in from the same device — a strong indicator of coordinated account control (e.g., a PI and their copier operating from the same mobile device).

### Key Design Note: GCID Join

The SP joins `STS_User_Operations_Data_History` via GCID (`pp.GCID = dh.Gcid`), not via CID, because the STS table stores GCID-based session identifiers. The PI's `RealCid` from STS is mapped to `ParentCID` in this table.

### Date Scoping

Unlike FID tables which use all historical deposit data, device data is scoped to `DateID >= 20240101`. This reflects the STS table's data availability and reduces noise from stale device fingerprints.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 585,539 (2026-04-22) |
| Distinct Devices (PI_DeviceID) | 475,109 |
| Distinct PIs (ParentCID) | 5,132 |
| Avg Devices per PI | 114.1 |
| Max Devices per PI | 457,015 |
| Min Devices per PI | 1 |
| Snapshot | 2026-04-22 (single-day full refresh) |

The extreme max (457,015 devices for one PI) is a significant outlier and may represent an institutional account, automated activity, or a data quality issue in STS device fingerprinting. The average (114.1) is heavily skewed by this outlier.

---

## 5. Usage Notes

### Identify PIs Sharing a Device with Any Copier

```sql
SELECT p.ParentCID, c.CID AS CopierCID, p.PI_DeviceID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side p
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers c
  ON p.PI_DeviceID = c.Copy_DeviceID
  AND p.ParentCID = c.ParentCID
ORDER BY p.ParentCID
```

### Count Shared Devices per PI (Correct Approach)

```sql
SELECT p.ParentCID, COUNT(DISTINCT p.PI_DeviceID) AS SharedDeviceCount
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side p
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers c
  ON p.PI_DeviceID = c.Copy_DeviceID
  AND p.ParentCID = c.ParentCID
GROUP BY p.ParentCID
ORDER BY SharedDeviceCount DESC
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | PI device fingerprints (ClientDeviceId) via GCID; DateID>=20240101; null-GUID excluded |
| 2 | `#pis` | Temp Table | PI gate filter (GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor); join ON pp.GCID=dh.Gcid |

---

## 7. Known Issues

1. **DateID >= 20240101 scope**: Device data is limited to sessions since 2024-01-01 (STS availability). Older PI device history is not captured. This asymmetry with FID tables (which use all historical data) is intentional.

2. **Null-GUID excluded**: `'00000000-0000-0000-0000-000000000000'` is filtered out as a placeholder/invalid device ID. Web sessions that do not populate ClientDeviceId are not represented.

3. **Extreme outlier**: Max 457,015 devices per PI. Investigate whether this PI represents a high-volume automated account or STS data quality issue before including in abuse detection thresholds.

4. **One row per unique (PI_DeviceID, ParentCID)**: Session frequency is not captured — a PI logging in from the same device 1,000 times appears as one row.

---

## 8. Metadata

| Field | Value |
|-------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_AML_PI_Abuse |
| ETL Pattern | TRUNCATE + INSERT (daily full refresh) |
| OpsDB Priority | 0 |
| UC Status | Not Migrated |
| Columns | 3 (2 T1, 1 Propagation) |
| Rows | 585,539 (2026-04-22) |
| Distinct PIs | 5,132 |
| Distinct Devices | 475,109 |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 48 |
| Generated | 2026-04-22 |
