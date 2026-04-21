# EXW_WalletClosedCountryProjects — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 4 Items (Require Human Verification)

| # | Column | Question / Uncertainty |
|---|--------|----------------------|
| 1 | Project | Exact meaning and history of each Project label (A, B, French, RussiaCySEC, etc.) is inferred from data alone. Confirm with Wallet ops team. |
| 2 | Regulation | Column is mostly NULL (78/89 rows) yet RegulationID has values in 11 rows. Confirm whether this column should be populated from Dim_Regulation.Name or left as-is. |
| 3 | UpdateDate | Is UpdateDate auto-set at insert time or manually entered? The range 2021-03-08 to 2024-12-22 suggests multiple insert events over time. |
| 4 | Table owner | Confirm which team maintains this table (Wallet ops, analytics, compliance?). |

## Open Questions

- Are there additional Project values expected in future closures?
- Should this table be migrated to UC / made available in the data lake for self-service analytics?
- The `Angola,Eritrea,Rwanda,Senegal` Project value has all 4 countries as a comma-separated string in a single Project value. Is this intentional or a data entry artifact?
- `CountryName` uses nchar(50) with whitespace padding — should it be normalised against Dim_Country.CountryName?

## No Reviewer Corrections at Time of Generation
