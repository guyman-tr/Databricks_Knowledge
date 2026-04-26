# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse

**Generated**: 2026-04-22 | **Batch**: 47 | **Reviewer**: SP owner (Lior Ben Dor) + AML team

---

## CRITICAL: Fan-Out Bug Confirmation

- [ ] **SP owner confirmation required**: Is the ~11.9 rows/PI fan-out in `BI_DB_AML_PI_Abuse` intentional or a defect?
  - Root cause: `#SameFID_AS_PI` is grouped by `(pf.ParentCID, cf.CID)` but LEFT JOINed in `#final1` on `ParentCID` only — creating a Cartesian product that the `SELECT DISTINCT` in `#final2` cannot collapse because `SameFID_AS_PI` values differ per row.
  - If defect: what is the remediation plan and timeline?
  - If intentional: what is the intended interpretation of having multiple rows per PI with different `SameFID_AS_PI` values?

- [ ] **`SameFID_AS_PI` reliability**: Given the fan-out, this column has different values per PI depending on which row is selected. Should analysts use `BI_DB_AML_PI_Abuse_FID_Same_as_pi` (the satellite table) instead for FID-based abuse analysis?

---

## Column Semantics Verification

- [ ] **`AUC_Top2/3/4/5Copier` naming**: These are **cumulative** sums of the top N copiers, NOT individual copier AUCs. Confirm this naming is consistent with how AML analysts use these columns. Consider whether column names should be updated to `AUC_CumulativeTop2/3/4/5Copier` to prevent misinterpretation.

- [ ] **`Num_of_Blocked_copiers` definition**: Currently counts copiers with `PlayerStatusID NOT IN (1, 5)` (not Normal AND not Warning). Confirm: does the AML team intend "Blocked" to include ALL restricted statuses (Under Investigation, Chat Blocked, Deposit Blocked, etc.) or only hard-block statuses?

- [ ] **`Same_IP_AS_PI` vs SameIP satellite**: `Same_IP_AS_PI` in this table uses copier registration IP vs PI registration IP (Dim_Customer.IP — a static field). The `BI_DB_AML_PI_Abuse_SameIP` satellite uses copier registration IPs vs each other. Confirm this distinction is documented correctly.

- [ ] **`CIDs_Same_Start_Copy` sentinel value**: ISNULL→'0' (the string '0') when no same-day copier cluster exists. Confirm: should this be NULL rather than '0' string for easier NULL checks in downstream queries?

- [ ] **`FirstAction/SecondAction/ThirdAction`**: Source is `BI_DB_dbo.BI_DB_First5Actions.FirstAction`. What are the valid action values? What AML workflow or case management system populates `BI_DB_First5Actions`? This table has no wiki documentation.

---

## Coverage and Scope Questions

- [ ] **Device history cutoff 2024-01-01**: The STS device history filter `DateID >= 20240101` means pre-2024 device sharing is invisible. Was this date chosen intentionally (data quality threshold)? Does coverage expand annually as data accumulates?

- [ ] **Copier qualification for abuse signals**: The `#sameIndications` block requires the PI (`dc2`) to have IsValidCustomer=1, IsDepositor=1, VerificationLevelID>1 — but NOT the copier (`dc`). Confirm: is it intentional that copier-side abuse checks have no validity filter?

---

## Documentation Flags

- [ ] **`BI_DB_First5Actions` wiki**: No wiki exists for this source table. Should be documented separately as it's referenced by both this table and potentially other AML tables.
- [ ] **`DWH_dbo.V_Liabilities` wiki**: No wiki exists for this view (also referenced by `BI_DB_AML_PI_Abuse_CopierTable`). Confirm formula: `Liabilities + ActualNWA = TotalEquity`.
