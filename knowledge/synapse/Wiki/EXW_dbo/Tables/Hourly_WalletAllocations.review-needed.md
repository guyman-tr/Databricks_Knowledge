# EXW_dbo.Hourly_WalletAllocations — Review Needed

**Object**: EXW_dbo.Hourly_WalletAllocations  
**Generated**: 2026-04-20  
**Review Priority**: High (AllocationDate column contains incorrect data)

---

## Open Items

### RN-001 — AllocationDate Is Always the SP Run Date, Not the Allocation Date

**Category**: Data quality / business logic bug  
**Severity**: High

The `AllocationDate` column is hardcoded to `CAST(GETDATE() AS DATE)` in the SP, making it always equal to `ReportDate`. Both `AllocationDate` and `ReportDate` show the same value (the SP run date). The actual wallet allocation date is `CAST(Occurred AS DATE)`.

Confirmed from live data: `MIN(AllocationDate) = MAX(AllocationDate) = ReportDate = 2026-04-20` while `Occurred` spans 2026-04-13 to 2026-04-20.

**Action needed**: Determine whether Tableau consumers are using `AllocationDate` or `CAST(Occurred AS DATE)` for date-based analysis. If consumers rely on `AllocationDate`, they are filtering to today only (all rows share the same date). The SP should likely change `allocationdate` to `CAST(cwv.Occurred AS DATE)` rather than `CAST(GETDATE() AS DATE)`. Coordinate the fix with any Tableau workbook filters that reference AllocationDate.

---

### RN-002 — CrytpoType Column Name Typo

**Category**: Data quality / naming  
**Severity**: Low (functional, but misleading)

The column is named `CrytpoType` (letters transposed: "Crytpo" not "Crypto") in both the DDL and the SP. This typo is baked into the schema and propagated to any Tableau data source or SQL query that references it.

**Action needed**: If the column is queried by name in Tableau or downstream SQL, the typo must be preserved (or a CTAS/view can alias it). Consider adding a corrected alias in a Tableau data source rather than an ALTER TABLE (which would require updating all downstream references). Document the typo explicitly in any data source descriptions.

---

### RN-003 — GCID Type Mismatch (int vs bigint)

**Category**: Data quality / type safety  
**Severity**: Low

The DDL defines `[GCID] [int] NULL` but `WalletDB.Wallet.CustomerWalletsView.Gcid` is `bigint`. INT max is 2,147,483,647. If eToro's GCID assignment ever exceeds INT range, this column would silently truncate or fail.

**Action needed**: Confirm whether GCID values in eToro's production systems are bounded within INT range. If yes, document this guarantee. If no, ALTER TABLE to change GCID to bigint to match the source and prevent future data loss. Check all other EXW_dbo tables for the same pattern.

---

### RN-004 — Downstream Tableau Consumers Not Identified

**Category**: Lineage completeness  
**Severity**: Medium (change impact, especially given RN-001)

No SSDT stored procedures or views reference EXW_dbo.Hourly_WalletAllocations. Given RN-001 (AllocationDate bug), identifying Tableau consumers is particularly urgent — any dashboard filtering by AllocationDate may be silently showing only "today" rather than the intended allocation period.

**Action needed**: Identify Tableau workbooks consuming Hourly_WalletAllocations. Prioritize review of any dashboards that use AllocationDate as a date filter — these are showing incorrectly scoped data if they're relying on AllocationDate for historical window filtering.

---

### RN-005 — Occurred Column Precision Reduction (datetime2 → datetime)

**Category**: Type fidelity  
**Severity**: Low

`WalletDB.Wallet.CustomerWalletsView.Occurred` is `datetime2(7)` (100ns precision), but the DDL defines `[Occurred] [datetime] NULL` (3.33ms precision). Sub-millisecond allocation timing is lost in the DWH.

**Action needed**: No immediate action needed — datetime precision is sufficient for allocation date analysis. Document as a known DWH type reduction.

---

*Review items: 5 | Blocking: 0 | Priority updates: RN-001 (AllocationDate bug — HIGH, may affect existing Tableau dashboards), RN-004 (Tableau lineage — MEDIUM, urgent given RN-001)*
