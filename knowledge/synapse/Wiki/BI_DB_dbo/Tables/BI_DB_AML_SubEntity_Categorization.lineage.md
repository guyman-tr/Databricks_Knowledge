# BI_DB_dbo.BI_DB_AML_SubEntity_Categorization — Column Lineage

> Generated: 2026-04-21 | Pipeline Phase: 10B | Writer SP: SP_AML_SubEntity_Categorization

## ETL Chain

```
DWH_dbo.Dim_Customer (RealCID, GCID, CountryID, RegulationID, VerificationLevelID)
DWH_dbo.Dim_Country  (CountryID=DWHCountryID → Name)
DWH_dbo.Dim_Regulation (DWHRegulationID → Name)
eMoney_dbo.eMoney_Dim_Account (AccountSubProgramID for eMoney UK/Malta populations)
  |
  |-- SP_AML_SubEntity_Categorization (4 populations UNION → STRING_AGG) ---|
  v
BI_DB_dbo.BI_DB_AML_SubEntity_Categorization (2.11M rows, daily)
  |
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID → CID) | Tier 1 — Customer.CustomerStatic |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 3 | CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough via DWHCountryID=CountryID identity | Tier 1 — Customer.CustomerStatic |
| 4 | Country | DWH_dbo.Dim_Country | Name | Denormalized join (Name AS Country) | Tier 2 — SP_AML_SubEntity_Categorization |
| 5 | RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough | Tier 1 — BackOffice.Customer |
| 6 | Regulation | DWH_dbo.Dim_Regulation | Name | Denormalized join (Name AS Regulation) | Tier 2 — SP_AML_SubEntity_Categorization |
| 7 | UpdateDate | ETL system | GETDATE() | ETL timestamp at INSERT | Tier 2 — SP_AML_SubEntity_Categorization |
| 8 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 1 — BackOffice.Customer |
| 9 | AML_Sub_Entity | DWH_dbo.Dim_Customer + eMoney_dbo | 4 entity labels | STRING_AGG of computed AML sub-entity labels across 4 population segments (eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta) | Tier 2 — SP_AML_SubEntity_Categorization |

## Population Logic Summary

| Sub-Entity | Criteria |
|-----------|---------|
| eToro_Germany | CySEC + KYC Country = Germany (CountryID=79) + VerLevel≥2 + IsDepositor + (HasWallet=1 OR RealCrypto positions) |
| eToro_Gibraltar | Non-Germany + (CySEC/FCA/ASIC/ASIC&GAML/FSA_Seychelles) + VerLevel≥2 + IsDepositor + HasWallet=1 |
| eToro_Money_UK | CySEC/FCA + VerLevel≥2 + IsDepositor + (Card UK AccountSubProgramID IN 1,2 + UK country) OR (IBAN UK AccountSubProgramID IN 3,4,8) |
| eToro_Money_Malta | CySEC + VerLevel=3 + IsDepositor + IBAN EU (AccountSubProgramID IN 5,6,7,9) + EU/EEA country |

## UC External Lineage

| UC Target | `compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` |
|-----------|---|
| Copy Strategy | Override (full daily replace) |
| Format | delta |
| Business Group | compliance |
