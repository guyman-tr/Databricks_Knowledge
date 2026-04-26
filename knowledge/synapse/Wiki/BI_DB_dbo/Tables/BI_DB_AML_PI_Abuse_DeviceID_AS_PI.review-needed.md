# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_AS_PI

**Generated**: 2026-04-22 | **Batch**: 47 | **Reviewer**: SP owner (Lior Ben Dor) + AML team

---

## Device History Scope

- [ ] **2024-01-01 cutoff**: Confirm this date is intentional. PIs who shared devices with copiers exclusively before 2024 will not be detected. Does this cutoff shift forward annually?

- [ ] **GCID-based PI device lookup**: The SP joins `#pis.GCID` to `STS_User_Operations_Data_History.Gcid` to identify PI device records. Confirm that GCID is the correct linkage (not RealCid) — this implies PIs without a GCID (older accounts) will have no device data and will be absent from this table.

---

## Metric Formula Confirmation

- [ ] **`SameDeviceID_Users_AS_PI = COUNT(*) - COUNT(DISTINCT PI_DeviceID)`**: Confirm this formula is computing the intended metric. As written, it counts: total matching observations (where a PI device UUID appears in copier device history) minus unique PI device UUIDs that match. This equals the number of "extra" observations above unique overlapping devices — NOT the count of distinct copiers sharing a device with the PI. Is this the right metric, or should it be `COUNT(DISTINCT CopyCID)` (copiers who have used a PI device)?

---

## Coverage

- [ ] **933 rows for ~5,131 PIs (18%)**: Confirm this 18% coverage is expected. Are the other 82% of PIs absent because they have no device overlap, or because they lack GCID / have no device history in the 2024+ window?
