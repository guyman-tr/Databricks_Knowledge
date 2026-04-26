# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers

**Generated**: 2026-04-22 | **Batch**: 47 | **Reviewer**: SP owner (Lior Ben Dor) + AML team

---

## Metric Formula Confirmation

- [ ] **`SameDeviceID_Copiers = COUNT(*) - COUNT(DISTINCT Copy_DeviceID)`**: This formula counts total copier-device observations minus unique device UUIDs, yielding the number of "excess" device observations (i.e., how many additional copier-device pairs share a device already seen). Confirm this is the intended interpretation. Alternative interpretations:
  - `COUNT(DISTINCT CopyCID sharing a device with ≥1 other copier)` — copiers involved in sharing
  - `COUNT(DISTINCT Copy_DeviceID used by ≥2 copiers)` — distinct shared device UUIDs

- [ ] **Normalization**: `SameDeviceID_Copiers` is an absolute count. For PIs with thousands of copiers, this count will be naturally higher. Confirm whether AML analysts normalize by `NumOfCopiers` for fair comparison across PI sizes.

---

## Device History Scope

- [ ] Same 2024-01-01 cutoff concern as `DeviceID_AS_PI` table. Confirm intentional.

---

## Coverage

- [ ] **3,835 rows for ~5,131 PIs (75%)**: Confirm this coverage is expected. Are the remaining ~1,296 PIs absent due to no copier device data in the 2024+ window, or because they have no qualifying copiers?
