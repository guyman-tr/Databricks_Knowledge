# EXW_dbo.EXW_UserSettingsWalletAllowance — Column Lineage

**Writer SP**: `EXW_dbo.SP_EXW_UserSettingsWalletAllowance`
**Load Pattern**: TRUNCATE + INSERT (full daily refresh)
**Generated**: 2026-04-20

---

## ETL Source Objects

| Object | Role |
|--------|------|
| `EXW_dbo.EXW_DimUser` | Source of GCID, RealCID, CountryID, RegulationID for user scope and tag matching |
| `EXW_Settings.Tags` | Tag definitions (TagType, TagValue) for settings system |
| `EXW_Settings.SystemRestrictions` | Allowance rules per tag (SelectedValue, RestrictionWeight, BeginDate) for ResourceId=5903 |
| `EXW_Settings.GcidToDynamicGroups` | User-to-dynamic-group membership |
| `CopyFromLake.SettingsDB_Dictionary_DynamicGroup` | Dynamic group name lookup |
| `BI_DB_dbo.External_WalletDB_Eligibility_StatusMap` | Status map for resolving group vs customer-level settings conflicts |
| `BI_DB_dbo.External_SettingsDB_DWH_V_CustomerDataWallet` | Individual customer-level settings overrides (ResourceId=35467) |
| `EXW_dbo.EXW_CompensationClosingCountries` | Source of CompensationDate and Project for compensated users |
| `EXW_dbo.EXW_WalletClosedCountryProjects` | Source for ComplianceClosureEvent flag |
| `DWH_dbo.Dim_State_and_Province` | State/province name resolution for US regional rules |

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | EXW_dbo.EXW_DimUser | GCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 2 | RealCID | EXW_dbo.EXW_DimUser | RealCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 3 | UserWalletAllowance | (computed) | — | CASE on resolved Status: 0=NotAllowed; 1=ReadOnly; 2 or 3=Allowed; else NotAllowed | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 4 | TagType | EXW_Settings.Tags | TagType | Winning tag type by highest RestrictionWeight; 'CustomerData' for individual overrides | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 5 | TagValue | EXW_Settings.Tags | TagValue | Winning tag value (lowercase country/regulation/group name or GCID) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 6 | SelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Raw settings value from winning rule: 0=NotAllowed, 1=ReadOnly, 2=Allowed, 3=AllowedForExistingUsers | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 7 | AllowanceBeginDate | EXW_Settings.SystemRestrictions | BeginDate | BeginDate of the winning settings restriction | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 8 | Compensated | EXW_dbo.EXW_CompensationClosingCountries | GCID | CASE WHEN GCID match found in EXW_CompensationClosingCountries (with CompensationDate, qualifying criteria) THEN 1 ELSE 0 | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 9 | ComplianceClosureEvent | EXW_dbo.EXW_WalletClosedCountryProjects | CountryID | CASE WHEN user's CountryID (and RegulationID or NULL) found in EXW_WalletClosedCountryProjects THEN 1 ELSE 0 | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 10 | CompensationDate | EXW_dbo.EXW_CompensationClosingCountries | CompensationDate | TOP 1 CompensationDate per GCID ORDER BY DateClosure DESC (latest closure) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 11 | Project | EXW_dbo.EXW_CompensationClosingCountries | Project | TOP 1 Project per GCID ORDER BY DateClosure DESC (latest closure) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 12 | UpdateDate | (computed) | — | GETDATE() at INSERT | Tier 2 — SP_EXW_UserSettingsWalletAllowance |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | GCID, RealCID |
| Tier 2 | 10 | UserWalletAllowance, TagType, TagValue, SelectedValue, AllowanceBeginDate, Compensated, ComplianceClosureEvent, CompensationDate, Project, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

**PHASE 10B CHECKPOINT: PASS**
