# Column Lineage: main.etoro_kpi.ddr_mimo_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_mimo_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_mimo_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_mimo_v.json` (rows: 24, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
        │
        ▼
main.etoro_kpi.ddr_mimo_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `DateID` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `Date` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.`Date` |
| 3 | `WeekNumberYear` | `main.bi_output.bi_output_vg_date` | `WeekNumberYear` | `join_enriched` | (Tier 1 — DDL) | dd.WeekNumberYear |
| 4 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 5 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 6 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 7 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(map.RealCID AS STRING) AS RealCID |
| 8 | `MIMOAction` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `MIMOAction` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | map.MIMOAction |
| 9 | `OrigIdentifier` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `OrigIdentifier` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.OrigIdentifier |
| 10 | `TransactionID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `TransactionID` | `passthrough` | (Tier 2 — Fact_CustomerAction) | map.TransactionID |
| 11 | `AmountUSD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `AmountUSD` | `passthrough` | (Tier 2 — Fact_CustomerAction) | map.AmountUSD |
| 12 | `AmountOrigCurrency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `AmountOrigCurrency` | `passthrough` | (Tier 2 — Fact_BillingDeposit / Fact_BillingWithdraw) | map.AmountOrigCurrency |
| 13 | `FundingTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `FundingTypeID` | `passthrough` | (Tier 2 — Fact_BillingDeposit / Billing.Funding) | map.FundingTypeID |
| 14 | `CurrencyID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `CurrencyID` | `passthrough` | (Tier 1 — upstream wiki, Billing.Deposit / Billing.WithdrawToFunding) | map.CurrencyID |
| 15 | `Currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `Currency` | `passthrough` | (Tier 1 — Dictionary.Currency) | map.Currency |
| 16 | `IsPlatformFTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsPlatformFTD` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.IsPlatformFTD |
| 17 | `IsInternalTransfer` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsInternalTransfer` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | map.IsInternalTransfer |
| 18 | `IsRedeem` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsRedeem` | `passthrough` | (Tier 2 — Fact_CustomerAction) | map.IsRedeem |
| 19 | `IsTradeFromIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsTradeFromIBAN` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | map.IsTradeFromIBAN |
| 20 | `MIMOPlatform` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `MIMOPlatform` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.MIMOPlatform |
| 21 | `IsGlobalFTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsGlobalFTD` | `passthrough` | (Tier 2 — Function_MIMO_First_Deposit_All_Platforms / SP_DDR_Fact_Fact_MIMO_AllPlatforms) | map.IsGlobalFTD |
| 22 | `IsCryptoToFiat` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsCryptoToFiat` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | map.IsCryptoToFiat |
| 23 | `IsRecurring` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsRecurring` | `passthrough` | (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) | map.IsRecurring |
| 24 | `IsIBANQuickTransfer` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsIBANQuickTransfer` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | map.IsIBANQuickTransfer |

## Cross-check vs system.access.column_lineage

- Total target columns: **24**
- OK: **23**, WARN: **1**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.dateid` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.dateid`, `main.bi_output.bi_output_vg_date.dateid` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **4**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON map.DateID = dd.DateID
