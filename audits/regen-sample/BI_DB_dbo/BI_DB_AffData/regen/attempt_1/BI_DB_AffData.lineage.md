# BI_DB_dbo.BI_DB_AffData — Column Lineage

> Dormant table with 0 rows. No writer SP found in the SSDT repo. No upstream wiki resolvable. Lineage is inferred from DDL structure and naming correlation with DWH_dbo.Dim_Affiliate.

## Source Objects

| # | Source Object | Schema | Role | Evidence |
|---|--------------|--------|------|----------|
| 1 | DWH_dbo.Dim_Affiliate | DWH_dbo | Probable domain source (affiliate dimension) | Column name overlap: AffiliateID, ContractName, ContractType, Channel; naming pattern Aff_* matches affiliate domain |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | Probable FK source (customer dimension) | RealCID is the standard DWH customer identifier |

> **No writer SP exists** — no stored procedure in the SSDT repo writes to `BI_DB_dbo.BI_DB_AffData`. All source mappings below are inferred from DDL structure and naming conventions, not from traced ETL code.

## Column Lineage

| DWH Column | Probable Source Table | Probable Source Column | Transform | Confidence |
|-----------|----------------------|----------------------|-----------|------------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough (inferred) | DDL structure — standard customer FK |
| AffiliateID | DWH_dbo.Dim_Affiliate | AffiliateID | passthrough (inferred) | DDL structure — standard affiliate FK |
| Aff_Registration | DWH_dbo.Dim_Affiliate | DateCreated | rename (inferred) | Naming pattern — Aff_ prefix + Registration |
| Aff_LoginName | DWH_dbo.Dim_Affiliate | LoginName | rename (inferred) | Naming pattern — Aff_ prefix + LoginName |
| Aff_Email | DWH_dbo.Dim_Affiliate | Email | rename (inferred) | Naming pattern — Aff_ prefix + Email; both are PII-masked |
| ContractName | DWH_dbo.Dim_Affiliate | ContractName | passthrough (inferred) | Exact name match |
| ContractType | DWH_dbo.Dim_Affiliate | ContractType | type change (inferred) | Same name; BI_DB uses varchar(20) vs Dim_Affiliate tinyint — may store text label |
| Aff_eLanguage | DWH_dbo.Dim_Affiliate | LanguageName | rename (inferred) | Naming pattern — Aff_eLanguage ~ LanguageName |
| AffGroup | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | rename (inferred) | Naming pattern — abbreviated group name |
| Channel | DWH_dbo.Dim_Affiliate | Channel | passthrough (inferred) | Exact name match — marketing channel classification |
| UpdateDate | — | — | ETL timestamp (inferred) | Standard DWH ETL load timestamp pattern |

## Notes

- **Dormant status**: Table has 0 rows and is not populated by any SP. May be a legacy or deprecated BI reporting table.
- **All mappings are inferred**: Without a writer SP, column-level lineage cannot be confirmed from code. Mappings are based on DDL structure, naming patterns, and domain correlation with DWH_dbo.Dim_Affiliate.
- **PII**: Aff_Email column has dynamic data masking (`FUNCTION = 'default()'`).
