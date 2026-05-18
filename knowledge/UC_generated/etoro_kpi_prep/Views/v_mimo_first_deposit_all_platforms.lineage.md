# Column Lineage: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_mimo_first_deposit_all_platforms.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_mimo_first_deposit_all_platforms.json` (rows: 6, mismatches: 6) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.emoney.bronze_fiatdwhdb_dbo_fiattransactions` | JOIN / referenced | ✓ `knowledge\ProdSchemas\BankingDBs\FiatDwhDB\Wiki\dbo\Tables\dbo.FiatTransactions.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status   (JOIN)
  + main.emoney.bronze_fiatdwhdb_dbo_fiattransactions   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | RealCID |
| 2 | `DepositID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DepositID` | `passthrough` | (Tier 1 — History.Credit) | DepositID |
| 3 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FirstDepositDate` | `passthrough` | — | FirstDepositDate |
| 4 | `FirstDepositAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FirstDepositAmount` | `passthrough` | — | FirstDepositAmount |
| 5 | `FTDPlatform` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FTDPlatform` | `passthrough` | — | FTDPlatform |
| 6 | `FTDPlatformID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FTDPlatformID` | `passthrough` | — | FTDPlatformID |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **0**, WARN: **6**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.realcid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | WARN |
| `DepositID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.depositid` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.transactionid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.ftdplatformid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.ftdtransactionid` | WARN |
| `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.firstdepositdate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | WARN |
| `FirstDepositAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.firstdepositamount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositamount` | WARN |
| `FTDPlatform` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.ftdplatform` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.ftdplatformid` | WARN |
| `FTDPlatformID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.ftdplatformid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.ftdplatformid` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN new_iban AS ib ON dc.RealCID = ib.RealCID AND TRY_CAST(dc.FTDTransactionID AS BIGINT) = TRY_CAST(ib.SourceCugTransactionID AS BIGINT) AND dc.FTDPlatformID = 3
- `LEFT JOIN` — LEFT JOIN new_tp AS tp ON dc.RealCID = tp.RealCID AND TRY_CAST(ib.DepositID AS BIGINT) = TRY_CAST(tp.DepositID AS BIGINT)
- `LEFT JOIN` — LEFT JOIN c2usd AS cus ON dc.RealCID = cus.CID AND TRY_CAST(tp.DepositID AS BIGINT) = TRY_CAST(dc.FTDTransactionID AS BIGINT) AND dc.FTDPlatformID = 1
- `LEFT JOIN` — LEFT JOIN main.emoney.bronze_fiatdwhdb_dbo_fiattransactions AS eft ON mfts.SourceCugTransactionID = eft.SourceCugTransactionId
