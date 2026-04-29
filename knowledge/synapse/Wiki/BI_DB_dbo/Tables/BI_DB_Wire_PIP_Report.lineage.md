# BI_DB_dbo.BI_DB_Wire_PIP_Report — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | BI_DB_dbo | Transaction base data (amounts, PIPs, fees, payment method) | Tier 1 — SP code confirmed |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Customer snapshot (CountryID, PlayerLevelID, AccountTypeID, RegulationID) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Country | DWH_dbo | Country name, MarketingRegionManualName | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_AccountType | DWH_dbo | Account type name resolution | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name from RegulationID | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_FundingType | DWH_dbo | FundingTypeID from PaymentMethod name | Tier 1 — SP code confirmed |
| External_Fivetran_google_sheets_conversion_fee_discounts | BI_DB_dbo (External) | Discount% and eligibility by country/funding_type/player_level | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| CID | BI_DB_DepositWithdrawFee | CID | passthrough |
| PaymentDate | — | @Date parameter | SP input date |
| eMoney Supported | External_Fivetran...discounts | is_e_tm_country_ | computed — 'YES'→1, 'NO'→0 |
| MarketingRegionManualName | Dim_Country | MarketingRegionManualName | passthrough |
| AccountType | Dim_AccountType | Name | passthrough via Fact_SnapshotCustomer.AccountTypeID |
| TransactionType | BI_DB_DepositWithdrawFee | TransactionType | passthrough |
| Country | Dim_Country | Name | passthrough via Fact_SnapshotCustomer.CountryID |
| Discount% | External_Fivetran...discounts | discount_ | passthrough — from Fivetran Google Sheets config |
| Currency | BI_DB_DepositWithdrawFee | Currency | passthrough (filtered to EUR/GBP) |
| PaymentMethod | BI_DB_DepositWithdrawFee | PaymentMethod | passthrough |
| Amount_Currency | BI_DB_DepositWithdrawFee | Amount | passthrough (in original currency) |
| Amount_USD | BI_DB_DepositWithdrawFee | AmountUSD | passthrough (USD equivalent) |
| PIPs in USD | BI_DB_DepositWithdrawFee | PIPsCalculation | passthrough — revenue spread calculation |
| Amount Compensation in $ | — | PIPsCalculation * (Discount%/100) | computed — discount compensation amount |
| UpdateDate | — | — | GETDATE() |
| Club | BI_DB_DepositWithdrawFee | Club | passthrough |
| ExchangeFee | BI_DB_DepositWithdrawFee | ExchangeFee | passthrough |
| Regulation | Dim_Regulation | Name | passthrough via Fact_SnapshotCustomer.RegulationID |
| Eligible_for_discount_private | External_Fivetran...discounts | eligible_for_discount_as_private_account_type_id_1_ | passthrough |
| Eligible_for_discount_corporate | External_Fivetran...discounts | eligible_for_discount_as_corporate_account_type_id_2_ | passthrough |

## Lineage Notes

- Only EUR and GBP currency transactions are included (WHERE Currency IN ('EUR','GBP')).
- Only records with non-NULL Discount% are included (eligible discount filter).
- UC Target: _Not_Migrated.
