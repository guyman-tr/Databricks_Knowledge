# Column Lineage: main.bi_output.vg_fact_billingwithdraw_for_genie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingwithdraw_for_genie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_fact_billingwithdraw_for_genie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_fact_billingwithdraw_for_genie.json` (rows: 21, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.billing.bronze_etoro_billing_depot` | JOIN / referenced | ✓ `knowledge/UC_generated/billing/Tables/bronze_etoro_billing_depot.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.bi_db.bronze_etoro_dictionary_withdrawtype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
  + main.billing.bronze_etoro_billing_depot   (JOIN)
  + main.bi_db.bronze_etoro_dictionary_withdrawtype   (JOIN)
        │
        ▼
main.bi_output.vg_fact_billingwithdraw_for_genie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CID` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.CID /* ===== Identity ===== */ |
| 2 | `WithdrawID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `WithdrawID` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.WithdrawID |
| 3 | `FundingID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `FundingID` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.FundingID /* ===== Amount & Currency ===== */ |
| 4 | `Amount_Withdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `Amount_Withdraw` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.Amount_Withdraw /* Amount */ |
| 5 | `ExchangeRate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ExchangeRate` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | bw.ExchangeRate |
| 6 | `BaseExchangeRate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BaseExchangeRate` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | bw.BaseExchangeRate |
| 7 | `Fee` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `Fee` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.Fee /* ===== Status / Processing ===== */ |
| 8 | `CashoutStatusID_Withdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CashoutStatusID_Withdraw` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.CashoutStatusID_Withdraw /* WithrawProcessingID */ |
| 9 | `CashoutReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CashoutReasonID` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.CashoutReasonID /* RRE Reason */ |
| 10 | `ErrorCodeAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ErrorCodeAsString` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.ErrorCodeAsString /* Decline Reason */ |
| 11 | `ResponseMessageAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ResponseMessageAsString` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.ResponseMessageAsString /* Response */ /* ===== Dates ===== */ |
| 12 | `ModificationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ModificationDate` | `passthrough` | (Tier 1 — Billing.Withdraw) | bw.ModificationDate /* Last modified date */ /* ===== Funding / Provider ===== */ |
| 13 | `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `Name` | `join_enriched` | (Tier 1 — Dictionary.FundingType) | dft.Name AS FundingType /* Funding Type (name instead of ID) */ |
| 14 | `WithdrawType` | `main.bi_db.bronze_etoro_dictionary_withdrawtype` | `WithdrawType` | `join_enriched` | — | e.WithdrawType AS WithdrawType |
| 15 | `DepotName` | `main.billing.bronze_etoro_billing_depot` | `Name` | `join_enriched` | (Tier 1 — inherited from etoro.Billing.Depot) | d.Name AS DepotName /* Depot */ |
| 16 | `BankNameAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BankNameAsString` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.BankNameAsString /* Provider / Bank Name By BIN Code */ |
| 17 | `ProtocolMIDSettingsID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `ProtocolMIDSettingsID` | `passthrough` | (Tier 1 — Billing.WithdrawToFunding) | bw.ProtocolMIDSettingsID /* MID */ /* ===== Card / BIN ===== */ |
| 18 | `BinCodeAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BinCodeAsString` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.BinCodeAsString /* BIN Code */ |
| 19 | `BinCountryIDAsInteger` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `BinCountryIDAsInteger` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.BinCountryIDAsInteger /* BIN Country */ |
| 20 | `CardTypeIDAsInteger` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CardTypeIDAsInteger` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) | bw.CardTypeIDAsInteger /* Card Type / Card Sub Type */ |
| 21 | `CardCategory` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | `CardCategory` | `passthrough` | (Tier 2 — SP_Fact_BillingWithdraw) | bw.CardCategory /* Card Category / Card Sub Category */ |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **21**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS dft ON bw.FundingTypeID_Withdraw = dft.FundingTypeID
- `LEFT JOIN` — LEFT JOIN main.billing.bronze_etoro_billing_depot AS d ON bw.DepotID = d.DepotID
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_etoro_dictionary_withdrawtype AS e ON bw.WithdrawTypeID = e.withdrawtypeid
