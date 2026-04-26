# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side

**Generated**: 2026-04-22 | **Batch**: 47 | **Reviewer**: SP owner (Lior Ben Dor) + Data Engineering

---

## DDL Column Order Mismatch

- [ ] **Column 3 = UpdateDate, Column 4 = ParentCID in DDL** — but the SP INSERT uses an explicit column list so this order mismatch has no runtime impact. Confirm the DDL is authoritative and no positional queries exist downstream that would be affected.

---

## Performance Concern

- [ ] **3.9M rows, HEAP, ROUND_ROBIN, no index**: Investigation queries filtering by `ParentCID` will trigger full table scans or broadcast joins. Consider adding a non-clustered index or statistics on `ParentCID`. For the largest PIs (e.g., 33,467 copiers × multiple devices), querying this table without a `ParentCID` filter is impractical.

---

## Grain Confirmation

- [ ] **Grain: (Copy_DeviceID, CopyCID, ParentCID) — DISTINCT**: The SP uses `SELECT DISTINCT` in `#CopysameDeviceID`. Confirm that a copier-device pair can only appear once per PI regardless of how many times the device was used (i.e., this table shows whether the combination ever occurred, not frequency of use).

---

## Device History Scope

- [ ] Same 2024-01-01 cutoff concern as sibling device tables. Confirm intentional.
