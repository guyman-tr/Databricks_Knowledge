# EXW_DimUser_Enriched — Review Needed

**Generated**: 2026-04-20 | **Batch**: 2 | **Object**: EXW_dbo.EXW_DimUser_Enriched

---

## Tier 4 Items (Unverified / Needs Human Review)

None — all 37 columns have Tier 1 or Tier 2 lineage traced to confirmed sources.

---

## Open Questions for Reviewer

1. **UpperLimit NULL edge case**: The SP uses `ISNULL(UpperLimit, 0)` in the over-limit calculation, meaning users who never answered KYC Q14 will be flagged as IsOverLimit=1 if they have any RealizedEquity. Only 50 users have NULL UpperLimit — is this intentional behavior or a bug? Should Q14-skippers be excluded from over-limit checks?

2. **RegisterState vs IPState distinction**: RegisterState joins on `Dim_Customer.RegionID = Dim_State_and_Province.RegionByIP_ID` while IPState joins on `Dim_Customer.RegionByIP_ID`. The SP aliases for `dsp1` vs `dsp2` in the #dwh_dim_customer block use the same RegionByIP_ID column twice — verify whether this is correct or if RegisterState should join on a different column (e.g., RegionID → RegionID rather than RegionByIP_ID).

3. **EXW_FinanceReportsBalancesNew as TotalBalanceUSD source**: The SP uses `EXW_FinanceReportsBalancesNew` for TotalBalanceUSD, not `EXW_FactBalance`. EXW_FinanceReportsBalancesNew is undocumented (Pending in index). Confirm whether FinanceReportsBalancesNew is the correct/canonical balance source for this use case or if EXW_FactBalance would be more appropriate.

4. **PlayerStatusID / CurrentStatus discrepancy**: The `PlayerStatusID` column (col 21) comes from Dim_Customer (current state) while `CurrentStatus` (col 24) is derived from Fact_SnapshotCustomer history. These can disagree if Dim_Customer was updated after the last snapshot. Which is authoritative for compliance reporting?

5. **AMLProviderID=2 gap**: From EXW_AMLProviderID batch context — AMLProviderID=2 is absent from live data. Confirm whether this affects the AML completeness of EXW_DimUser_Enriched's compliance fields (PEPStatusID, EvMatchStatus).

---

## Cross-Object Consistency Check

✅ GCID description matches EXW_DimUser.md verbatim (modified for HEAP index)
✅ RealCID description matches Dim_Customer.md verbatim
✅ EvMatchStatus description: "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed." — verbatim from Dim_Customer.md (Tier 1 — BackOffice.Customer)
✅ RegulationID description matches EXW_DimUser.md (EXW enum values preserved)
✅ PlayerLevelID, VerificationLevelID match EXW_DimUser.md
✅ IsTestAccount, CreditReportValid, IsValidCustomer match EXW_DimUser.md verbatim

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 37 cols, HASH(GCID), HEAP |
| P2 Sample | PASS | 699,692 rows confirmed |
| P3 Distribution | PASS | UserType, UpperLimit, RegulationID distributions |
| P4 Lookup | PASS | Dim_Customer, EXW_DimUser wikis read |
| P5 JOINs | PASS | No outbound joins from this table (it's the join target) |
| P6 BizLogic | PASS | 4 subsections documented |
| P7 Views | PASS | No views reference EXW_DimUser_Enriched |
| P8 SP Scan | PASS | 2 consuming SPs identified |
| P9 SP Logic | PASS | Full source-to-target map from SP code |
| P9B ETL Orch | PASS | Daily TRUNCATE+INSERT, 7 source tables |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP results |
| P10A Upstream | PASS | Dim_Customer + EXW_DimUser wikis read |
| P10B Lineage | PASS | .lineage.md written |
| P11 Generate | PASS | .md and .review-needed.md written |
