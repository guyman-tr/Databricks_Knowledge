# Lineage: DWH_dbo.Fact_BillingWithdraw

## Classification

| Property | Value |
|----------|-------|
| **Lineage Type** | DWH-Denormalized (3-way JOIN of production tables + post-load enrichment) |
| **Primary Sources** | Billing.Withdraw, Billing.WithdrawToFunding, Billing.Funding |
| **Enrichment Source** | DWH_dbo.Dim_CountryBin (BIN code lookup) |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **Copy Strategy** | Merge |
| **Frequency** | Daily (1440 min) |
| **ETL SPs** | SP_Fact_BillingWithdraw_DL_To_Synapse → SP_Fact_BillingWithdraw |

## Source Chain

```
Production (etoro DB)                 DWH Staging                              DWH Synapse
─────────────────────                ───────────                              ───────────
Billing.Withdraw           ──►  DWH_staging.etoro_Billing_Withdraw (bw)  ─┐
                                                                          ├── 3-way LEFT JOIN
Billing.WithdrawToFunding  ──►  DWH_staging.etoro_Billing_WithdrawToFunding (wtf)  │
                                                                          │
Billing.Funding            ──►  DWH_staging.etoro_Billing_Funding (bf)  ──┘
                                        │
                                        ▼
                              Ext_FBW_Fact_BillingWithdraw (staging)
                                        │
                                        ▼
                              Fact_BillingWithdraw (DELETE+INSERT)
                                        │
                                        ▼ Post-load UPDATE
                              JOIN Dim_CountryBin ON BinCode
                              → BankName, CardCategory
                                        │
                                        ▼ UC Pipeline (Merge, Daily)
                              main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
```

## Column Lineage Summary

| Category | Count | Source | Description |
|----------|-------|--------|-------------|
| Direct passthrough (bw) | 17 | Billing.Withdraw | Request-level fields passed through with optional rename |
| Direct passthrough (wtf) | 14 | Billing.WithdrawToFunding | Execution-level fields passed through with optional rename |
| Direct passthrough (bf) | 1 | Billing.Funding | FundingTypeID_Funding |
| XML-extracted (wtf.WithdrawData) | 13 | Billing.WithdrawToFunding.WithdrawData XML | Payment execution metadata parsed via ExtractXMLValue |
| XML-extracted (bf.FundingData) | 20 | Billing.Funding.FundingData XML | Funding instrument metadata parsed via ExtractXMLValue |
| COALESCE (wtf+bf XML) | 11 | Both XML sources | Shared fields preferring WithdrawData, fallback FundingData |
| DWH-Computed | 3 | ETL logic | ModificationDateID (date→int), ExpirationDateID (XML→int), UpdateDate (getdate) |
| Post-load enrichment | 2 | Dim_CountryBin | BankName (IssuingBank), CardCategory via BIN code match |
| **Total** | **81** | | (83 columns, but CID and WithdrawID counted in passthrough) |

## Upstream Wiki Coverage

| Source Table | Wiki Available | Wiki Quality | Path |
|-------------|---------------|-------------|------|
| Billing.Withdraw | Yes | 9.5/10 | `DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` |
| Billing.WithdrawToFunding | Yes | 9.1/10 | `DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` |
| Billing.Funding | Yes | — | `DB_Schema/etoro/Wiki/Billing/Tables/Billing.Funding.md` |
| Dim_CountryBin | Yes (DWH) | Done | `DWH_dbo/Tables/Dim_CountryBin.md` |
