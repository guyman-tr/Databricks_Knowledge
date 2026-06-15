# Column Lineage: main.etoro_kpi_prep.v_mimo_emoneyplatform

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_emoneyplatform` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_mimo_emoneyplatform.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_mimo_emoneyplatform.json` (rows: 21, mismatches: 14) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_mimo_emoneyplatform   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `DateID` | `passthrough` | — | DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `Date` | `passthrough` | — | Date |
| 3 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `RealCID` | `passthrough` | — | RealCID |
| 4 | `MIMOAction` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `MIMOAction` | `passthrough` | — | MIMOAction |
| 5 | `OrigIdentifier` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `OrigIdentifier` | `passthrough` | — | OrigIdentifier |
| 6 | `TransactionID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(TransactionID, -1) AS TransactionID |
| 7 | `ReferenceNumber` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(ReferenceNumber, '-1') AS ReferenceNumber |
| 8 | `AmountUSD` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `AmountUSD` | `passthrough` | — | AmountUSD |
| 9 | `AmountOrigCurrency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `AmountOrigCurrency` | `passthrough` | — | AmountOrigCurrency |
| 10 | `FundingTypeID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `FundingTypeID` | `passthrough` | — | FundingTypeID |
| 11 | `CurrencyID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `CurrencyID` | `passthrough` | — | CurrencyID |
| 12 | `Currency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `Currency` | `passthrough` | — | Currency |
| 13 | `IsFTD` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(IsFTD, 0) AS IsFTD |
| 14 | `IsInternalTransfer` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(IsInternalTransfer, 0) AS IsInternalTransfer |
| 15 | `IsRedeem` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(IsRedeem, 0) AS IsRedeem |
| 16 | `TxTypeID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `TxTypeID` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | TxTypeID |
| 17 | `IsTradeFromIBAN` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(IsTradeFromIBAN, 0) AS IsTradeFromIBAN |
| 18 | `IsCryptoToFiat` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `—` | `coalesce` | — | COALESCE(IsCryptoToFiat, 0) AS IsCryptoToFiat |
| 19 | `IsRecurring` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsRecurring |
| 20 | `IsIBANQuickTransfer` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsIBANQuickTransfer |
| 21 | `UpdateDate` | `—` | `—` | `literal` | — | literal `CURRENT_TIMESTAMP()` — CURRENT_TIMESTAMP() AS UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **5**, WARN: **8**, ERROR: **6**, INFO: **2**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.dateid` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdateid` | WARN |
| `Date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdate`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdateid` | WARN |
| `RealCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.realcid` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.cid` | WARN |
| `TransactionID` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.transactionid` | ERROR |
| `ReferenceNumber` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.referencenumber` | ERROR |
| `AmountUSD` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.amountusd` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.usdamountapprox`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositamount` | WARN |
| `AmountOrigCurrency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.amountorigcurrency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.localamount` | WARN |
| `FundingTypeID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.fundingtypeid` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txtypeid` | WARN |
| `CurrencyID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.currencyid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency.currencyid` | WARN |
| `Currency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.currency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.holdercurrencydesc` | WARN |
| `IsFTD` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.transactionid` | ERROR |
| `IsInternalTransfer` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txtypeid` | ERROR |
| `IsTradeFromIBAN` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.referencenumber`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdateid`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txtypeid` | ERROR |
| `IsCryptoToFiat` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txtypeid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON dc1.FTDTransactionID = mfts.SourceCugTransactionID AND dc1.FTDPlatformID = 3
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc ON mfts.HolderCurrencyISO = dc.Abbreviation
- `LEFT JOIN` — LEFT JOIN ftd_iban AS f ON mfts.TransactionID = f.TransactionID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc ON mfts.HolderCurrencyDesc = dc.Abbreviation
