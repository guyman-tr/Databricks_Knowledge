# BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **Popular Investor (PI)** with a count of how many shared device fingerprints exist across their copier population. A high count indicates multiple copiers are using the same physical devices — suggesting a coordinated account network operating from shared infrastructure.

- **Row count**: 3,835 (as of 2026-04-12)
- **Distinct PIs (ParentCID)**: 3,835 (clean 1:1 grain)
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
| 1 | ParentCID | int | T1 | `general.etoroGeneral_History_GuruCopiers.ParentCID` | The Popular Investor's customer ID. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| 2 | SameDeviceID_Copiers | int | T2 | Computed: `COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` across copiers of this PI | Number of duplicate device fingerprint observations across this PI's copier population. Computed from #CopysameDeviceID (one row per unique device+copier+PI triple): `COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` per PI. Non-zero when at least two copiers share a device UUID. Higher values = more extensive device overlap across the copier base. (Tier 2 — SP_AML_PI_Abuse via STS_User_Operations_Data_History) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NOT NULL per DDL. (Propagation) |

**Tier summary**: 1 T1 | 1 T2 | 1 Propagation

---

## 3. Business Context

While `BI_DB_AML_PI_Abuse_DeviceID_AS_PI` detects PI-to-copier device sharing, this table detects **copier-to-copier device sharing** — multiple copiers of the same PI using the same physical device. This pattern suggests:
1. Multiple copier accounts controlled by the same person from the same device
2. A household or small group running multiple copier accounts

### What SameDeviceID_Copiers Measures

`SameDeviceID_Copiers = COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` from #CopysameDeviceID:

- Each row in #CopysameDeviceID represents a (Copy_DeviceID, CopyCID, ParentCID) triple — one per unique device per copier per PI
- `COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` = total device observations minus unique devices = number of excess/duplicate device observations above the distinct device count
- **= 0**: No device sharing — all copiers use unique device fingerprints (within device data scope)
- **> 0**: At least two copiers share a device UUID

### Grain

Strictly 1:1 with PI. All 3,835 PIs in this table have at least some copier device data. The main `BI_DB_AML_PI_Abuse` table carries this count as `SameDeviceID_Copiers` (ISNULL→0 for PIs not present here).

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 3,835 (2026-04-12) |
| Distinct PIs (ParentCID) | 3,835 (1:1 grain confirmed) |
| Coverage | ~75% of active PI population (~5,131 PIs) |
| Snapshot | 2026-04-12 (single-day full refresh) |

Device data covers 2024-01-01 onward. PIs without copier device data in this window are absent.

---

## 5. Usage Notes

### Identifying High-Risk Device-Sharing Copier Networks

```sql
SELECT c.ParentCID, c.SameDeviceID_Copiers,
       a.NumOfCopiers, a.AUC, a.GuruStatusName
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers c
JOIN (
    SELECT CID, NumOfCopiers, AUC, GuruStatusName,
           ROW_NUMBER() OVER (PARTITION BY CID ORDER BY UpdateDate DESC) rn
    FROM BI_DB_dbo.BI_DB_AML_PI_Abuse
) a ON a.CID = c.ParentCID AND a.rn = 1
WHERE c.SameDeviceID_Copiers > 10
ORDER BY c.SameDeviceID_Copiers DESC
```

### Detail View: Which Copiers Share Devices

For the specific copier device pairings:
```sql
-- BI_DB_AML_PI_Abuse_DeviceID_Copy_Side: grain (Copy_DeviceID, CopyCID, ParentCID)
SELECT Copy_DeviceID, CopyCID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side
WHERE ParentCID = @TargetPI
-- Then group by Copy_DeviceID to find which CopyCIDs share each device
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | Copier device fingerprints (ClientDeviceId) via RealCid, filtered DateID≥20240101, non-null GUID |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CIDs to PI at @DateTime |
| 3 | `#copy` | Temp Table | Active copier population for scope filtering |

---

## 7. Known Issues

1. **Device history limited to 2024-01-01+**: Same constraint as the companion DeviceID_AS_PI table.

2. **Null-GUID excluded**: `'00000000-0000-0000-0000-000000000000'` records excluded from all device analysis.

3. **High base count for large PI copier bases**: A PI with many copiers will naturally have a higher probability of device overlap even without coordinated behavior (e.g., multiple family members copying the same PI). Normalize `SameDeviceID_Copiers` by `NumOfCopiers` for meaningful comparison across PIs of different sizes.

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
| Rows | 3,835 (2026-04-12) |
| Distinct PIs | 3,835 (1:1 grain) |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 47 |
| Generated | 2026-04-22 |
