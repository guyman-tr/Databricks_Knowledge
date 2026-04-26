# Review Needed — BI_DB_dbo.BI_DB_AM_Portfolio_Summary

**Generated**: 2026-04-23
**Batch**: 55
**Quality Score**: 9.0 / 10

---

## Items for Human Review

### 1. TotalContactDeposit IsContacted Flag Source

`TotalContactDeposit` is derived from `BI_DB_NewBonusReport.IsContacted`. The documentation assumes `IsContacted=1` means the client was contacted by the account manager. However, the definition of `IsContacted` in `BI_DB_NewBonusReport` was not traced — it may have a different business definition or lag behavior. **Verify**: does `IsContacted` reflect Salesforce contact activity by the AccountManager specifically, or a broader contact flag from another system?

### 2. CurrentPortfolio vs PortfolioSOM Business Usage

The table has two portfolio size columns with different semantics: `PortfolioSOM` (start-of-month, fixed after day 7) and `CurrentPortfolio` (daily live count). Downstream Tableau reports may use one or both. **Verify**: which column appears in the official AM performance dashboard KPIs? Are there known cases where PortfolioSOM and CurrentPortfolio diverge significantly within a month?

### 3. Manager Name Cardinality (596 IDs vs 632 Names)

Live data shows 596 distinct `AccountManagerID` values but 632 distinct `Manager` name strings across 103 months. **Verify**: is this entirely explained by manager name updates in Dim_Manager propagating forward (new months get the new name while old months retain the old name)? Or are there data quality issues in name generation (e.g., inconsistent FirstName/LastName formats)?

### 4. CopyFund Intent — Permanent or Temporary?

Both `TotalMoneyInCF` and `TotalMoneyOutCF` are permanently 0. It is unclear whether this was a deliberate business decision (CopyFund metrics no longer relevant to this report) or a technical debt item awaiting re-implementation. **Verify with AM/Finance team**: should these columns be deprecated and removed from the DDL, or is there a future plan to reactivate CopyFund tracking?

### 5. OpsDB Priority and Schedule Confirmation

All Batch 55 objects are classified as Priority 0. **Verify**: is SP_AM_Portfolio_Summary confirmed as P0 (no intra-BI_DB dependencies)? The SP reads from `BI_DB_NewBonusReport` and `BI_DB_UsageTracking_SF` which themselves are documentation targets. If those are also P0, there is no ordering issue, but this should be confirmed.
