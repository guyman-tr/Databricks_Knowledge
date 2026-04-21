# EXW_dbo.EXW_WalletClosedCountryProjects — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_WalletClosedCountryProjects |
| **ETL Type** | Manual reference table — no automated SP writer |
| **Production Source** | None (manually maintained by Wallet operations team) |
| **Refresh Pattern** | Ad-hoc manual inserts when a new country closure project is initiated |
| **UC Target** | Not determined |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | Project | Manual | — | — | Manually entered closure campaign identifier (e.g., A, B, RussiaCySEC, French) | Tier 4 |
| 2 | CountryID | Manual | — | — | FK to DWH_dbo.Dim_Country; manually entered | Tier 4 |
| 3 | CountryName | Manual | — | — | Denormalized country name for readability; manually entered | Tier 4 |
| 4 | UpdateDate | Manual | — | — | Last update timestamp; manually entered | Tier 4 |
| 5 | CompensationDate | Manual | — | — | Date users in this country received compensation for wallet closure; manually entered | Tier 4 |
| 6 | Regulation | Manual | — | — | Regulation name (text); NULL = all regulations; manually entered | Tier 4 |
| 7 | RegulationID | Manual | — | — | FK to DWH_dbo.Dim_Regulation.ID; NULL = applies to all regulations; manually entered | Tier 4 |

## Source Objects

No automated production source. This table is manually maintained by the Wallet operations team to track country closure projects (compensation campaigns where the Wallet service was shut down in specific countries).

## Consumers (Downstream)

| SP / Object | Usage |
|-------------|-------|
| EXW_dbo.SP_DimUser | LEFT JOIN on CountryID+RegulationID to flag users in closed-wallet countries |
| EXW_dbo.SP_EXW_CompensationClosingCountries | JOIN to filter users by closed-country scope |
| EXW_dbo.SP_EXW_UserSettingsWalletAllowance | LEFT JOIN to determine wallet eligibility restrictions |
