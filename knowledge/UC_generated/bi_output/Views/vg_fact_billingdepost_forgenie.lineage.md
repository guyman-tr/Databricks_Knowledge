# Column Lineage: main.bi_output.vg_fact_billingdepost_forgenie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingdepost_forgenie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_fact_billingdepost_forgenie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_fact_billingdepost_forgenie.json` (rows: 21, mismatches: 1) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot   (JOIN)
  + main.general.bronze_etoro_dictionary_cardtype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
        │
        ▼
main.bi_output.vg_fact_billingdepost_forgenie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `CID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.CID /* ====================== */ /* Core identifiers */ /* ====================== */ |
| 2 | `DepositID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `DepositID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.DepositID |
| 3 | `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `Name` | `join_enriched` | (Tier 1 — Dictionary.FundingType) | x.Name AS FundingType |
| 4 | `ModificationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ModificationDate` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.ModificationDate /* ====================== */ /* Dates */ /* ====================== */ |
| 5 | `AmountUSD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `AmountUSD` | `passthrough` | (Tier 2 — Billing.Deposit.Amount/ExchangeRate) | fd.AmountUSD /* ====================== */ /* Amounts & currency */ /* ====================== */ |
| 6 | `Currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `Abbreviation` | `join_enriched` | (Tier 1 - Dictionary.Currency upstream wiki) | cur.Abbreviation AS Currency |
| 7 | `BaseExchangeRate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BaseExchangeRate` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.BaseExchangeRate |
| 8 | `IsFTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `IsFTD` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.IsFTD /* ====================== */ /* Status & flags */ /* ====================== */ |
| 9 | `PaymentStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | `Name` | `join_enriched` | (Tier 1 — Dictionary.PaymentStatus) | ps.Name AS PaymentStatus |
| 10 | `Provider` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Billing.Depot) | depot.Name AS Provider /* ====================== */ /* Funding / provider */ /* ====================== */ |
| 11 | `DepotID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `DepotID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.DepotID |
| 12 | `PSPCodeAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `PSPCodeAsString` | `passthrough` | (Tier 2 — Billing.Deposit.PaymentData) | fd.PSPCodeAsString |
| 13 | `BinCodeAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BinCodeAsString` | `passthrough` | (Tier 2 — Billing.Funding.FundingData) | fd.BinCodeAsString /* ====================== */ /* Card / BIN / bank */ /* ====================== */ |
| 14 | `CardType` | `main.general.bronze_etoro_dictionary_cardtype` | `Name` | `join_enriched` | — | ct.Name AS CardType |
| 15 | `CardSubType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `CardCategory` | `rename` | (Tier 2 — Dim_CountryBin.CardCategory) | fd.CardCategory AS CardSubType |
| 16 | `BankName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `BankNameAsString` | `rename` | (Tier 2 — Billing.Funding.FundingData) | fd.BankNameAsString AS BankName |
| 17 | `DeclineReason` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ResponseMessageAsString` | `rename` | (Tier 2 — Billing.Deposit.PaymentData) | fd.ResponseMessageAsString AS DeclineReason /* ====================== */ /* Responses / 3DS */ /* ====================== */ |
| 18 | `RREReason` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ErrorCodeAsString` | `rename` | (Tier 2 — Billing.Deposit.PaymentData) | fd.ErrorCodeAsString AS RREReason |
| 19 | `ThreeDSResponseJson` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ThreeDsAsJson` | `rename` | (Tier 2 — Billing.Deposit.PaymentData) | fd.ThreeDsAsJson AS ThreeDSResponseJson |
| 20 | `ProtocolMIDSettingsID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `ProtocolMIDSettingsID` | `passthrough` | (Tier 1 — Billing.Deposit) | fd.ProtocolMIDSettingsID /* ====================== */ /* Misc useful */ /* ====================== */ |
| 21 | `TransactionIDAsString` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `TransactionIDAsString` | `passthrough` | (Tier 2 — Billing.Deposit.PaymentData) | fd.TransactionIDAsString |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **20**, WARN: **1**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype.name` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype.name`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.fundingtype` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **5**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS cur ON fd.CurrencyID = cur.CurrencyID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus AS ps ON fd.PaymentStatusID = ps.PaymentStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot AS depot ON fd.DepotID = depot.DepotID
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_cardtype AS ct ON fd.CardTypeIDAsInteger = ct.CardTypeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS x ON fd.FundingTypeID = x.FundingTypeID
