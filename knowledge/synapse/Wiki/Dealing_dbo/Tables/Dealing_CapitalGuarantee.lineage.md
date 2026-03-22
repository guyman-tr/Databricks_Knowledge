# Lineage — Dealing_dbo.Dealing_CapitalGuarantee

## Summary

| Field | Value |
|-------|-------|
| **Object** | Dealing_dbo.Dealing_CapitalGuarantee |
| **Type** | Table |
| **Writer SP** | Dealing_dbo.SP_CapitalGuarantee |
| **Schedule** | Daily (P0) |
| **Primary Source** | general.etoroGeneral_History_GuruCopiers (copier AUM snapshots) |
| **Secondary Sources** | DWH_dbo.Fact_CustomerAction (ActionTypeID 15/16/17 = add/remove funds), DWH_dbo.Dim_Mirror, DWH_dbo.Dim_Customer, DWH_dbo.Dim_PlayerLevel, DWH_dbo.Dim_Manager, DWH_dbo.Dim_Country |
| **Pipeline Type** | DWH SP — no Generic Pipeline involvement |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP-input | @Date | Previous day's date (ETL date parameter) |
| DateID | SP-computed | @Date | Dealing_dbo.DateToDateID(@Date) — YYYYMMDD int |
| CID | DWH_dbo.Dim_Customer | RealCID | Copier CID (filtered to ParentCID=4657429 promotion) |
| GCID | DWH_dbo.Dim_Customer | GCID | Cross-product group identity |
| Username | DWH_dbo.Dim_Customer | UserName | Login username |
| ClubLevel | DWH_dbo.Dim_PlayerLevel | Name | Club level name (Diamond, Platinum Plus, etc.) via PlayerLevelID |
| Country | DWH_dbo.Dim_Country | Name | Country of residence via Dim_Customer.CountryID |
| Region | DWH_dbo.Dim_Country | Region | Geographic region via Dim_Customer.CountryID |
| Account_Manager_Name | DWH_dbo.Dim_Manager | FirstName + LastName | Concatenated full name via Dim_Customer.AccountManagerID |
| Eligible_Amount | SP-computed | IntitialAmount * Eligibility_Ratio | Initial invested amount × cumulative ratio |
| Total_AUM | SP-computed | YesterdaysAUM + AddedFunds | ROUND(total AUM including same-day fund additions, 4) |
| Eligibility_Ratio | SP-computed | CurrentRatio × PrevRatio | Cumulative daily product: reduced by withdrawal ratio each day, starts at 1.0 |
| Protected_PnL | SP-computed | (Total_AUM - InitialAmount) × Eligibility_Ratio | Eligible portion of net P&L (guarantee coverage) |
| UpdateDate | ETL | GETDATE() | ETL load timestamp |

## Source Filter Details

- **Promotion scope**: ParentCID = 4657429 (GainersQtr PI) — copiers who started copying between 2023-09-26 and 2023-11-20
- **Promotion end**: @EndPromo = 20250101 — promo guarantee expired Jan 1 2025 but rows continue daily until SP is decommissioned
- **ActionTypeID 15/17** = add funds; **ActionTypeID 16** = remove funds
- **IsValidCustomer = 1** filter applied on final insert

## Lost / Added Columns

- Eligible_Amount, Eligibility_Ratio, Protected_PnL: entirely computed by the promotion formula — no direct production source
- Account_Manager_Name: computed from DWH_dbo.Dim_Manager, not in production AUM snapshots
