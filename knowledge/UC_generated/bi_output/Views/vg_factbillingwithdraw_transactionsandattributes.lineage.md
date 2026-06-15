# Column Lineage: main.bi_output.vg_factbillingwithdraw_transactionsandattributes

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_factbillingwithdraw_transactionsandattributes` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_factbillingwithdraw_transactionsandattributes.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_factbillingwithdraw_transactionsandattributes.json` (rows: 17, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_cashoutreason` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutStatus.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus   (JOIN)
  + main.general.bronze_etoro_dictionary_cashoutreason   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot   (JOIN)
  + main.general.bronze_etoro_dictionary_cardtype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
  + main.general.bronze_etoro_dictionary_country   (JOIN)
        │
        ▼
main.bi_output.vg_factbillingwithdraw_transactionsandattributes   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CID` | `passthrough` | (Tier 1 — Billing.Withdraw) | fw.CID /* ====================== */ /* Core identifiers */ /* ====================== */ |
| 2 | `WithdrawPaymentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `WithdrawPaymentID` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | fw.WithdrawPaymentID |
| 3 | `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `Name` | `join_enriched` | (Tier 1 — Dictionary.FundingType) | x.Name AS FundingType |
| 4 | `ModificationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ModificationDate` | `passthrough` | (Tier 1 — Billing.Withdraw) | fw.ModificationDate /* ====================== */ /* Dates */ /* ====================== */ |
| 5 | `Amount_OriginalCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `Amount_Withdraw` | `rename` | (Tier 1 — Billing.Withdraw) | fw.Amount_Withdraw AS Amount_OriginalCurrency /* ====================== */ /* Amounts & currency */ /* ====================== */ |
| 6 | `Currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `Abbreviation` | `join_enriched` | (Tier 1 - Dictionary.Currency upstream wiki) | cur.Abbreviation AS Currency |
| 7 | `BaseExchangeRate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BaseExchangeRate` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | fw.BaseExchangeRate |
| 8 | `ExchangeFee` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ExchangeFee` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | fw.ExchangeFee |
| 9 | `WithdrawStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.CashoutStatus) | cs.Name AS WithdrawStatus /* ====================== */ /* Status */ /* ====================== */ |
| 10 | `CashoutReason` | `main.general.bronze_etoro_dictionary_cashoutreason` | `Name` | `join_enriched` | — | cr.Name AS CashoutReason |
| 11 | `PSP_Name` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Billing.Depot) | depot.Name AS PSP_Name /* ====================== */ /* PSP / Provider */ /* ====================== */ |
| 12 | `MID_SettingsID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ProtocolMIDSettingsID` | `rename` | (Tier 1 — Billing.WithdrawToFunding) | fw.ProtocolMIDSettingsID AS MID_SettingsID |
| 13 | `CardBrand_Visa_MC_Amex` | `main.general.bronze_etoro_dictionary_cardtype` | `Name` | `join_enriched` | — | ct.Name AS CardBrand_Visa_MC_Amex /* ====================== */ /* Card - Brand (Visa / MasterCard / Amex / Diners) */ /* =================== |
| 14 | `CardCategory_Tier_And_Product` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CardCategory` | `rename` | (Tier 2 — SP_Fact_BillingWithdraw) | fw.CardCategory AS CardCategory_Tier_And_Product /* ====================== */ /* Card - Category / Tier (Classic / Gold / Platinum / Debit / |
| 15 | `BIN_Code` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BinCodeAsString` | `rename` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | fw.BinCodeAsString AS BIN_Code /* ====================== */ /* Card - BIN & issuing bank */ /* ====================== */ |
| 16 | `IssuingBank` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BankNameAsString` | `rename` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | fw.BankNameAsString AS IssuingBank |
| 17 | `CardIssuingCountry_BIN` | `main.general.bronze_etoro_dictionary_country` | `Name` | `join_enriched` | — | cntry.Name AS CardIssuingCountry_BIN |

## Cross-check vs system.access.column_lineage

- Total target columns: **17**
- OK: **17**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **7**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS cur ON fw.CurrencyID = cur.CurrencyID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus AS cs ON fw.CashoutStatusID_Withdraw = cs.CashoutStatusID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_cashoutreason AS cr ON fw.CashoutReasonID = cr.CashoutReasonID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot AS depot ON fw.DepotID = depot.DepotID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_cardtype AS ct ON fw.CardTypeIDAsInteger = ct.CardTypeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS x ON fw.FundingTypeID_Withdraw = x.FundingTypeID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_country AS cntry ON fw.BinCountryIDAsInteger = cntry.CountryID
