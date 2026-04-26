# BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **device fingerprint used by a specific copier of a specific PI** — the raw device-to-copier-to-PI triples from which copier device sharing signals are computed. This is the detail layer underlying `BI_DB_AML_PI_Abuse_DeviceID_Copiers` (which holds only the PI-level aggregate count).

- **Row count**: 3,929,583 (as of 2026-04-12)
- **Distinct PIs (ParentCID)**: 3,835
- **Average rows per PI**: ~1,025 (high fan-out expected — one row per unique device per copier per PI)
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains CIDs and device UUIDs (no direct personal PII)

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | Copy_DeviceID | nvarchar(500) | T2 | `DWH_dbo.STS_User_Operations_Data_History.ClientDeviceId` | UUID string identifying the device used by the copier. Sourced from STS audit log device fingerprints (DateID≥20240101). Null-GUID ('00000000-0000-0000-0000-000000000000') excluded. DISTINCT applied in #CopysameDeviceID — each (device, copier, PI) tuple appears at most once. (Tier 2 — SP_AML_PI_Abuse via STS_User_Operations_Data_History) |
| 2 | CopyCID | int | T2 | `DWH_dbo.STS_User_Operations_Data_History.RealCid` | The copier's customer ID. References `DWH_dbo.Dim_Customer.RealCID`. Join to `BI_DB_AML_PI_Abuse_CopierTable.CID` for full copier details. (Tier 2 — SP_AML_PI_Abuse via STS_User_Operations_Data_History) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. (Propagation) |
| 4 | ParentCID | int | T1 | `general.etoroGeneral_History_GuruCopiers.ParentCID` | The Popular Investor's customer ID — the PI whose copier network is being analyzed. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |

**Tier summary**: 1 T1 | 2 T2 | 1 Propagation

---

## 3. Business Context

This table is the **raw evidence layer** for copier device analysis. It enables investigation of:

1. **Which copiers of a PI share the same device?** — GROUP BY (Copy_DeviceID, ParentCID) to find CopyCIDs on each device
2. **How many devices has a specific copier used while copying this PI?** — COUNT(DISTINCT Copy_DeviceID) per (CopyCID, ParentCID)
3. **Is a given device UUID appearing across multiple PIs' copier bases?** — COUNT(DISTINCT ParentCID) per Copy_DeviceID

### Grain

`(Copy_DeviceID, CopyCID, ParentCID)` — DISTINCT. One row per unique combination of device + copier + PI. A copier who has used 5 different devices while copying 1 PI will contribute 5 rows. A device used by 3 different copiers of the same PI will appear 3 times for that PI.

### Why 3.9M Rows for 3,835 PIs

The high row count (~1,025 rows/PI on average) reflects the legitimate fan-out of the grain: large PIs with thousands of active copiers, each using multiple devices, generate many rows. For the largest PI (ParentCID=12569157 with ~33,467 copiers), this table alone would contribute tens of thousands of device-copier pair rows.

### Relationship to Aggregate Table

The `SameDeviceID_Copiers` column in `BI_DB_AML_PI_Abuse_DeviceID_Copiers` summarizes this table at PI level. When that aggregate flags a PI as suspicious, this table provides the device UUIDs and copier CIDs to investigate. Also related to `BI_DB_AML_PI_Abuse_DeviceID_PI_Side` — if a device in this table also appears in DeviceID_PI_Side for the same PI, that device bridges a PI and their copier.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 3,929,583 (2026-04-12) |
| Distinct PIs (ParentCID) | 3,835 |
| Average rows per PI | ~1,025 |
| Snapshot | 2026-04-12 (single-day full refresh) |

---

## 5. Usage Notes

### Find Copiers Sharing a Device Within a PI's Copier Base

```sql
-- Copiers of PI 12345678 who share any device
SELECT Copy_DeviceID, COUNT(DISTINCT CopyCID) AS NumCopiers,
       STRING_AGG(CAST(CopyCID AS VARCHAR(20)), ', ') AS CopierCIDs
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side
WHERE ParentCID = 12345678
GROUP BY Copy_DeviceID
HAVING COUNT(DISTINCT CopyCID) >= 2  -- only devices used by 2+ copiers
ORDER BY NumCopiers DESC
```

### Cross-Check with PI Device Table

```sql
-- Devices appearing in BOTH PI's history AND a copier's history (strongest signal)
SELECT cs.Copy_DeviceID, cs.CopyCID, cs.ParentCID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side cs
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side ps
    ON cs.Copy_DeviceID = ps.PI_DeviceID
    AND cs.ParentCID = ps.ParentCID
WHERE cs.ParentCID = @TargetPI
```

### Performance Note

At 3.9M rows with ROUND_ROBIN distribution and HEAP index, always filter on `ParentCID` to avoid full scans. Consider querying through the aggregate table first to identify PI candidates.

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | Copier device fingerprints — ClientDeviceId (UUID), RealCid (copier CID); DateID≥20240101 |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links CopyCID to ParentCID at @DateTime |
| 3 | `#copy` | Temp Table | Active copier population (validity-filtered) |
| 4 | `#pis` | Temp Table | PI population gate |

---

## 7. Known Issues

1. **Device history limited to 2024-01-01+**: Same scope constraint as sibling device tables.

2. **Null-GUID excluded**: '00000000-0000-0000-0000-000000000000' omitted — represents failed or unavailable device fingerprinting sessions.

3. **No index on ParentCID**: HEAP distribution means no ordering or clustering. Large PI copier bases (tens of thousands of copiers × multiple devices each) will result in slow scans without ParentCID filter. Use column projection to reduce data volume.

4. **UpdateDate in DDL position**: The DDL column order is (Copy_DeviceID, CopyCID, UpdateDate, ParentCID) — UpdateDate is column 3, ParentCID is column 4. The SP INSERT uses explicit column list so this order discrepancy has no correctness impact, but positional queries will fail.

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
| Columns | 4 (1 T1, 2 T2, 1 Propagation) |
| Rows | 3,929,583 (2026-04-12) |
| Distinct PIs | 3,835 |
| PII | LOW (device UUIDs + CIDs) |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 47 |
| Generated | 2026-04-22 |
