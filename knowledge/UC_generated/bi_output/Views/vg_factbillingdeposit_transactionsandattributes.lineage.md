# Column Lineage: main.bi_output.vg_factbillingdeposit_transactionsandattributes

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_factbillingdeposit_transactionsandattributes` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_factbillingdeposit_transactionsandattributes.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_factbillingdeposit_transactionsandattributes.json` (rows: 27, mismatches: 4) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |
| `main.general.bronze_etoro_dictionary_riskmanagementstatus` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot   (JOIN)
  + main.general.bronze_etoro_dictionary_cardtype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
  + main.general.bronze_etoro_dictionary_riskmanagementstatus   (JOIN)
  + main.general.bronze_etoro_dictionary_country   (JOIN)
  + main.general.bronze_etoro_dictionary_regulation   (JOIN)
        │
        ▼
main.bi_output.vg_factbillingdeposit_transactionsandattributes   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `CID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.CID /* ====================== */ /* Core identifiers */ /* ====================== */ |
| 2 | `DepositID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `DepositID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.DepositID |
| 3 | `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `Name` | `join_enriched` | (Tier 1 — Dictionary.FundingType) | x.Name AS FundingType |
| 4 | `PaymentDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `PaymentDate` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.PaymentDate /* ====================== */ /* Dates */ /* ====================== */ |
| 5 | `ModificationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ModificationDate` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.ModificationDate |
| 6 | `Amount_OriginalCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `Amount` | `rename` | (Tier 2 — Billing.Deposit.Amount) | fd.Amount AS Amount_OriginalCurrency /* ====================== */ /* Amounts & currency */ /* ====================== */ |
| 7 | `AmountUSD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `AmountUSD` | `passthrough` | (Tier 2 — Billing.Deposit.Amount/ExchangeRate) | fd.AmountUSD |
| 8 | `Currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `Abbreviation` | `join_enriched` | (Tier 1 - Dictionary.Currency upstream wiki) | cur.Abbreviation AS Currency |
| 9 | `BaseExchangeRate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BaseExchangeRate` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.BaseExchangeRate |
| 10 | `ExchangeFee` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ExchangeFee` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.ExchangeFee |
| 11 | `IsFTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `IsFTD` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.IsFTD /* ====================== */ /* Status & approval */ /* ====================== */ |
| 12 | `PaymentStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | `Name` | `join_enriched` | (Tier 1 — Dictionary.PaymentStatus) | ps.Name AS PaymentStatus |
| 13 | `RRE_DeclineReason` | `main.general.bronze_etoro_dictionary_riskmanagementstatus` | `Name` | `join_enriched` | — | rms.Name AS RRE_DeclineReason /* ====================== */ /* RRE (Risk Rule Engine) - pre-PSP decline */ /* ====================== */ |
| 14 | `ThreeDS_Result` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `—` | `case` | — | CASE WHEN fd.ThreeDsAsJson IS NULL AND fd.ThreeDsResponseType IS NULL THEN 'No 3DS' WHEN fd.ThreeDsResponseType = '1' THEN '3DS Success' WHE |
| 15 | `ThreeDS_FullJson` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ThreeDsAsJson` | `rename` | (Tier 2 — Billing.Deposit.PaymentData) | fd.ThreeDsAsJson AS ThreeDS_FullJson |
| 16 | `PSP_Name` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Billing.Depot) | depot.Name AS PSP_Name /* ====================== */ /* PSP / Provider */ /* ====================== */ |
| 17 | `MerchantAccountID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `MerchantAccountID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.MerchantAccountID |
| 18 | `MID_SettingsID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ProtocolMIDSettingsID` | `rename` | (Tier 1 — Billing.Deposit) | fd.ProtocolMIDSettingsID AS MID_SettingsID |
| 19 | `CardBrand_Visa_MC_Amex` | `main.general.bronze_etoro_dictionary_cardtype` | `Name` | `join_enriched` | — | ct.Name AS CardBrand_Visa_MC_Amex /* ====================== */ /* Card - Brand (Visa / MasterCard / Amex / Diners) */ /* =================== |
| 20 | `CardCategory_Tier_And_Product` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `CardCategory` | `rename` | (Tier 2 — Dim_CountryBin.CardCategory) | fd.CardCategory AS CardCategory_Tier_And_Product /* ====================== */ /* Card - Category / Tier (Classic / Gold / Platinum / Debit / |
| 21 | `BIN_Code` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BinCodeAsString` | `rename` | (Tier 2 — Billing.Funding.FundingData) | fd.BinCodeAsString AS BIN_Code /* ====================== */ /* Card - BIN & issuing bank */ /* ====================== */ |
| 22 | `IssuingBank` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BankNameAsString` | `rename` | (Tier 2 — Billing.Funding.FundingData) | fd.BankNameAsString AS IssuingBank |
| 23 | `CardIssuingCountry_BIN` | `main.general.bronze_etoro_dictionary_country` | `Name` | `join_enriched` | — | cntry.Name AS CardIssuingCountry_BIN |
| 24 | `AFT_Supported` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `—` | `case` | — | CASE WHEN fd.IsAftSupportedAsBool = TRUE THEN 'Yes' ELSE 'No' END AS AFT_Supported /* ====================== */ /* AFT (Account Funding Tran |
| 25 | `AFT_Eligible` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `—` | `case` | — | CASE WHEN fd.IsAftEligibleAsBool = TRUE THEN 'Yes' ELSE 'No' END AS AFT_Eligible |
| 26 | `AFT_Processed` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `—` | `case` | — | CASE WHEN fd.IsAftProcessedAsBool = TRUE THEN 'Yes' ELSE 'No' END AS AFT_Processed |
| 27 | `Regulation` | `main.general.bronze_etoro_dictionary_regulation` | `Name` | `join_enriched` | — | reg.Name AS Regulation /* ====================== */ /* Regulation */ /* ====================== */ |

## Cross-check vs system.access.column_lineage

- Total target columns: **27**
- OK: **23**, WARN: **0**, ERROR: **4**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `ThreeDS_Result` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.threedsasjson`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.threedsresponsetype` | ERROR |
| `AFT_Supported` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.isaftsupportedasbool` | ERROR |
| `AFT_Eligible` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.isafteligibleasbool` | ERROR |
| `AFT_Processed` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.isaftprocessedasbool` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **12**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS cur ON fd.CurrencyID = cur.CurrencyID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus AS ps ON fd.PaymentStatusID = ps.PaymentStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot AS depot ON fd.DepotID = depot.DepotID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_cardtype AS ct ON fd.CardTypeIDAsInteger = ct.CardTypeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS x ON fd.FundingTypeID = x.FundingTypeID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_riskmanagementstatus AS rms ON fd.RiskManagementStatusID = rms.RiskManagementStatusID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_country AS cntry ON fd.BinCountryIDAsInteger = cntry.CountryID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_regulation AS reg ON fd.ProcessRegulationID = reg.ID
