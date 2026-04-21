# EXW_dbo.EXW_30DayBalanceExtract — Review Needed

**Generated**: 2026-04-20 | **Batch**: 5 | **Type**: Table

## Tier 4 / Unverified Items

No Tier 4 or Tier 5 columns. All 24 columns resolved to T1/T2.

## Open Questions for Reviewer

1. **StateCode encoding inconsistency**: In EXW_30DayBalanceExtract, StateCode = EXW_DimUser.UserRegionID (a region code integer stored as varchar). In EXW_FirstTimeWalletsAndUsers, StateCode = DWH_dbo.Dim_State_and_Province.ShortName (a string like 'NY', 'CA'). These two columns named StateCode encode different things. Confirm whether cross-table StateCode joins are expected to work, and whether standardization is needed.

2. **SP run frequency**: SP_EXW_30DayBalanceExtract has no date parameter and does a full TRUNCATE+INSERT. Confirm: (a) how often this SP is scheduled, (b) whether there are any downstream reports that depend on this table being current, and (c) whether the TRUNCATE during ETL creates any query inconsistency window.

3. **WalletID type (nvarchar vs uniqueidentifier)**: WalletID in EXW_30DayBalanceExtract is nvarchar(256), while in EXW_FinanceReportsBalancesNew it is uniqueidentifier. This is from the DDL mismatch — confirm if data is stored correctly and joins to uniqueidentifier columns require explicit CAST.

4. **Consumer coverage**: No SP consumers found in SSDT. Verify whether Power BI, SSRS, or Excel reports reference this table directly for the Region/State enrichment.

5. **ComplianceClosureEvent definition**: This comes from EXW_DimUser.ComplianceClosureEvent which is set by SP_DimUser based on EXW_WalletClosedCountryProjects. Confirm the exact trigger conditions with the EXW_WalletClosedCountryProjects documentation (Batch 1).

## Cross-Object Consistency

- CryptoId/CryptoName = blockchain level consistent with EXW_FirstTimeWalletsAndUsers.CryptoName ✓
- RealUser CASE ('TestUser'/'eTorian'/'RealUser') matches EXW_DimUser_Enriched.UserType values ✓
- FactBalance_UpdateDate preserves source table timestamp — distinct from UpdateDate (extract run time) ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
