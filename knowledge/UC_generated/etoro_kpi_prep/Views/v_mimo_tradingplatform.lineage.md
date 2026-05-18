# Column Lineage: main.etoro_kpi_prep.v_mimo_tradingplatform

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_tradingplatform` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_mimo_tradingplatform.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_mimo_tradingplatform.json` (rows: 19, mismatches: 13) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_mimo_tradingplatform   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | DateID |
| 2 | `Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Date` | `passthrough` | — | Date |
| 3 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | RealCID |
| 4 | `MIMOAction` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `MIMOAction` | `passthrough` | — | MIMOAction |
| 5 | `OrigIdentifier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `OrigIdentifier` | `passthrough` | — | OrigIdentifier |
| 6 | `TransactionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `TransactionID` | `passthrough` | — | TransactionID |
| 7 | `AmountUSD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `AmountUSD` | `passthrough` | — | AmountUSD |
| 8 | `AmountOrigCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `AmountOrigCurrency` | `passthrough` | — | AmountOrigCurrency |
| 9 | `FundingTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FundingTypeID` | `passthrough` | (Tier 1 — History.Credit) | FundingTypeID |
| 10 | `CurrencyID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CurrencyID` | `passthrough` | — | CurrencyID |
| 11 | `Currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Currency` | `passthrough` | — | Currency |
| 12 | `IsFTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsFTD, 0) AS IsFTD |
| 13 | `IsInternalTransfer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsInternalTransfer, 0) AS IsInternalTransfer |
| 14 | `IsRedeem` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsRedeem, 0) AS IsRedeem |
| 15 | `IsRecurring` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsRecurring, 0) AS IsRecurring |
| 16 | `IsIBANTrade` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsIBANTrade, 0) AS IsIBANTrade |
| 17 | `IsCryptoToFiat` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsCryptoToFiat |
| 18 | `IsIBANQuickTransfer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(IsIBANQuickTransfer, 0) AS IsIBANQuickTransfer |
| 19 | `UpdateDate` | `—` | `—` | `literal` | — | literal `CURRENT_TIMESTAMP()` — CURRENT_TIMESTAMP() AS UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **19**
- OK: **4**, WARN: **7**, ERROR: **6**, INFO: **2**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.dateid` | WARN |
| `TransactionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.transactionid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.depositid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.withdrawpaymentid` | WARN |
| `AmountUSD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amountusd` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | WARN |
| `AmountOrigCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amountorigcurrency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.amount`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.amount`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw.amount_withdrawtofunding`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw.exchangerate` | WARN |
| `FundingTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.fundingtypeid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.fundingtypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw.fundingtypeid_funding` | WARN |
| `CurrencyID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.currencyid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.currencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw.processcurrencyid` | WARN |
| `Currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.currency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency.abbreviation` | WARN |
| `IsFTD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.ftdtransactionid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.depositid` | ERROR |
| `IsInternalTransfer` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.fundingtypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw.fundingtypeid_funding` | ERROR |
| `IsRedeem` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.isredeem` | ERROR |
| `IsRecurring` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit.isrecurring` | ERROR |
| `IsIBANTrade` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `IsIBANQuickTransfer` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.movemoneyreasonid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit AS fbd ON fca.DepositID = fbd.DepositID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc ON fbd.CurrencyID = dc.CurrencyID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON fca.RealCID = dc1.RealCID AND dc1.FTDPlatformID = 1
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw AS fbw ON fca.WithdrawPaymentID = fbw.WithdrawPaymentID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc ON fbw.ProcessCurrencyID = dc.CurrencyID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee AS bddwf ON fca.DateID = bddwf.DateID AND bddwf.TransactionType = 'Withdraw' AND TRY_CAST(REPLACE(bddwf.TransactionID, 'W', '') AS INT) = fca.WithdrawPaymentID
