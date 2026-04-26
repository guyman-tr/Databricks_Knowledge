# BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_AS_PI

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **Popular Investor (PI)** with a count of how many of their own device fingerprints are also found in their copiers' device history. A non-zero value means the PI and at least one copier have physically used the same device — one of the strongest abuse signals in the suite.

- **Row count**: 933 (as of 2026-04-12)
- **Distinct PIs (ParentCID)**: 933 (clean 1:1 grain)
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains CID and device count only

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | ParentCID | int | T1 | `DWH_dbo.STS_User_Operations_Data_History.RealCid` via `#pis.GCID` | The Popular Investor's customer ID. PI is identified by GCID match to STS_User_Operations_Data_History.Gcid, then resolved back to RealCid. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| 2 | SameDeviceID_Users_AS_PI | int | T2 | Computed: `COUNT(*) - COUNT(DISTINCT PI_DeviceID)` | Number of PI-owned device fingerprints (ClientDeviceId UUIDs) that also appear in the device history of this PI's copiers. Computed as excess count above distinct (non-zero when at least two device-copier observations share a device). `COUNT(*) - COUNT(DISTINCT PI_DeviceID)` from #sameDeviceID_AS_PI where PI devices JOIN copier devices ON ClientDeviceId match. A value > 0 means at least one copier has operated the same physical device as the PI. (Tier 2 — SP_AML_PI_Abuse via STS_User_Operations_Data_History) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NOT NULL per DDL. (Propagation) |

**Tier summary**: 1 T1 | 1 T2 | 1 Propagation

---

## 3. Business Context

Device fingerprint overlap between a PI and their copiers is a high-fidelity abuse signal. If the same physical device (identified by ClientDeviceId UUID from the STS audit log) has been used by both the PI and a copier, it strongly suggests:
1. The PI controls the copier account (sockpuppet), or
2. The copier and PI share a physical device (family/household — lower risk)

### Device History Scope

Device data comes from `DWH_dbo.STS_User_Operations_Data_History` filtered to `DateID >= 20240101`. Device activity before January 2024 is not included. PIs or copiers who shared devices exclusively before that date will NOT be flagged.

### What SameDeviceID_Users_AS_PI Measures

`SameDeviceID_Users_AS_PI = COUNT(*) - COUNT(DISTINCT PI_DeviceID)` where the matching set is PI devices ∩ copier devices:

- **= 0**: No overlap detected. The PI's devices are not found in any copier's device history (in the 2024+ window).
- **> 0**: At least one PI device UUID appears in a copier's device history. Higher values indicate more overlapping device observations.

Note: The metric counts observations, not distinct copiers sharing a device. A single copier using 3 PI devices contributes 3 to this count (before DISTINCT removes the device duplicates, the "excess" reflects the number of copier-device pairs above unique device count).

### Grain

Strictly 1:1 with PI (ParentCID). Only PIs where device overlap was detected are included (inner join semantics in #sameDeviceID_AS_PI). As of 2026-04-12, 933 of ~5,131 active PIs (≈18%) have at least one PI-copier device overlap.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 933 (2026-04-12) |
| Distinct PIs (ParentCID) | 933 (1:1 grain confirmed) |
| PIs with device overlap | ~18% of active PI population |
| Snapshot | 2026-04-12 (single-day full refresh) |

---

## 5. Usage Notes

### Highest-Risk PIs: Device Overlap Combined with High AUC

```sql
SELECT d.ParentCID, d.SameDeviceID_Users_AS_PI, a.AUC, a.NumOfCopiers, a.GuruStatusName
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_AS_PI d
JOIN (
    SELECT CID, AUC, NumOfCopiers, GuruStatusName,
           ROW_NUMBER() OVER (PARTITION BY CID ORDER BY UpdateDate DESC) rn
    FROM BI_DB_dbo.BI_DB_AML_PI_Abuse
) a ON a.CID = d.ParentCID AND a.rn = 1
WHERE d.SameDeviceID_Users_AS_PI > 5
ORDER BY d.SameDeviceID_Users_AS_PI DESC
```

### See Specific Device IDs

For the actual device UUIDs used by the PI, query the companion table:
```sql
-- BI_DB_AML_PI_Abuse_DeviceID_PI_Side: one row per PI-device fingerprint
SELECT PI_DeviceID, ParentCID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side
WHERE ParentCID = @TargetPI
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | Device fingerprints (ClientDeviceId) for PI (via GCID) and copiers (via RealCid), filtered DateID≥20240101, non-null GUID |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CIDs to PI at @DateTime |
| 3 | `#pis` | Temp Table | PI population with GCID for device lookup |

---

## 7. Known Issues

1. **Device history starts 2024-01-01**: The `WHERE DateID >= 20240101` filter in STS_User_Operations_Data_History means older device sharing (pre-2024) is invisible. Newly enrolled PIs and copiers benefit from full history coverage; legacy relationships may be missed.

2. **Null-GUID exclusion**: Device records with ClientDeviceId = '00000000-0000-0000-0000-000000000000' are excluded. These represent sessions where device fingerprinting failed or was unavailable.

3. **Only overlap cases present**: PIs with no PI-copier device overlap are NOT in this table. This is an inner join, not left outer. Use `LEFT JOIN` when checking whether a PI has an entry.

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
| Columns | 3 (1 T1, 1 T2, 1 Propagation) |
| Rows | 933 (2026-04-12) |
| Distinct PIs | 933 (1:1 grain) |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 47 |
| Generated | 2026-04-22 |
