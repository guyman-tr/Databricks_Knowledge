# Column Lineage: main.etoro_kpi_prep.v_mimo_allplatforms

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_allplatforms` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_mimo_allplatforms.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_mimo_allplatforms.json` (rows: 21, mismatches: 21) |
| **Primary upstream** | `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi_prep.v_mimo_emoneyplatform` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_emoneyplatform.md` |
| `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` | Primary (FROM) | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_first_deposit_all_platforms.md` |
| `main.etoro_kpi_prep.v_mimo_optionsplatform` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_optionsplatform.md` |
| `main.etoro_kpi_prep.v_mimo_tradingplatform` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_tradingplatform.md` |

## Lineage Chain

```
main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms   ←── primary upstream
  + main.etoro_kpi_prep.v_mimo_tradingplatform   (JOIN)
  + main.etoro_kpi_prep.v_mimo_emoneyplatform   (JOIN)
  + main.etoro_kpi_prep.v_mimo_optionsplatform   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `DateID` | `join_enriched` | — | m.DateID |
| 2 | `Date` | `—` | `Date` | `join_enriched` | — | m.Date |
| 3 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | m.RealCID |
| 4 | `MIMOAction` | `—` | `MIMOAction` | `join_enriched` | — | m.MIMOAction |
| 5 | `OrigIdentifier` | `—` | `OrigIdentifier` | `join_enriched` | — | m.OrigIdentifier |
| 6 | `TransactionID` | `—` | `TransactionID` | `cast` | — | cast to STRING — CAST(m.TransactionID AS STRING) AS TransactionID |
| 7 | `AmountUSD` | `—` | `AmountUSD` | `join_enriched` | — | m.AmountUSD |
| 8 | `AmountOrigCurrency` | `—` | `AmountOrigCurrency` | `join_enriched` | — | m.AmountOrigCurrency |
| 9 | `FundingTypeID` | `—` | `FundingTypeID` | `join_enriched` | — | m.FundingTypeID |
| 10 | `CurrencyID` | `—` | `CurrencyID` | `join_enriched` | — | m.CurrencyID |
| 11 | `Currency` | `—` | `Currency` | `join_enriched` | — | m.Currency |
| 12 | `IsPlatformFTD` | `—` | `—` | `coalesce` | — | COALESCE(m.IsPlatformFTD, 0) AS IsPlatformFTD |
| 13 | `IsInternalTransfer` | `—` | `—` | `coalesce` | — | COALESCE(m.IsInternalTransfer, 0) AS IsInternalTransfer |
| 14 | `IsRedeem` | `—` | `—` | `coalesce` | — | COALESCE(m.IsRedeem, 0) AS IsRedeem |
| 15 | `IsTradeFromIBAN` | `—` | `—` | `coalesce` | — | COALESCE(m.IsIBANTrade, 0) AS IsTradeFromIBAN |
| 16 | `MIMOPlatform` | `—` | `MIMOPlatform` | `join_enriched` | — | m.MIMOPlatform |
| 17 | `IsGlobalFTD` | `—` | `—` | `case` | — | CASE WHEN NOT gf.RealCID IS NULL THEN 1 ELSE 0 END AS IsGlobalFTD |
| 18 | `IsCryptoToFiat` | `—` | `—` | `case` | — | CASE WHEN m.FundingTypeID = 27 AND m.MIMOAction = 'Deposit' AND m.DateID >= 20250701 THEN 1 ELSE COALESCE(m.IsCryptoToFiat, 0) END AS IsCryp |
| 19 | `IsRecurring` | `—` | `—` | `coalesce` | — | COALESCE(m.IsRecurring, 0) AS IsRecurring |
| 20 | `IsIBANQuickTransfer` | `—` | `—` | `coalesce` | — | COALESCE(m.IsIBANQuickTransfer, 0) AS IsIBANQuickTransfer |
| 21 | `UpdateDate` | `—` | `—` | `literal` | — | literal `CURRENT_TIMESTAMP()` — CURRENT_TIMESTAMP() AS UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **0**, WARN: **0**, ERROR: **21**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.dateid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.dateid`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.firstdepositdate`, `main.etoro_kpi_prep.v_mimo_optionsplatform.dateid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.dateid` | ERROR |
| `Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.date`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.date`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.firstdepositdate`, `main.etoro_kpi_prep.v_mimo_optionsplatform.date`, `main.etoro_kpi_prep.v_mimo_tradingplatform.date` | ERROR |
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.realcid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.realcid`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.realcid`, `main.etoro_kpi_prep.v_mimo_optionsplatform.realcid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.realcid` | ERROR |
| `MIMOAction` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.mimoaction`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.mimoaction`, `main.etoro_kpi_prep.v_mimo_optionsplatform.mimoaction`, `main.etoro_kpi_prep.v_mimo_tradingplatform.mimoaction` | ERROR |
| `OrigIdentifier` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.origidentifier`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.origidentifier`, `main.etoro_kpi_prep.v_mimo_optionsplatform.officecode`, `main.etoro_kpi_prep.v_mimo_tradingplatform.origidentifier` | ERROR |
| `TransactionID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.transactionid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.transactionid`, `main.etoro_kpi_prep.v_mimo_optionsplatform.transactionid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.transactionid` | ERROR |
| `AmountUSD` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.amountusd`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.amountusd`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.firstdepositamount`, `main.etoro_kpi_prep.v_mimo_optionsplatform.amountusd`, `main.etoro_kpi_prep.v_mimo_tradingplatform.amountusd` | ERROR |
| `AmountOrigCurrency` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.amountorigcurrency`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.amountorigcurrency`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.firstdepositamount`, `main.etoro_kpi_prep.v_mimo_optionsplatform.amountusd`, `main.etoro_kpi_prep.v_mimo_tradingplatform.amountorigcurrency` | ERROR |
| `FundingTypeID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_optionsplatform.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.fundingtypeid` | ERROR |
| `CurrencyID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.currencyid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.currencyid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.currencyid` | ERROR |
| `Currency` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.currency`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.currency`, `main.etoro_kpi_prep.v_mimo_tradingplatform.currency` | ERROR |
| `IsPlatformFTD` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isplatformftd`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.isftd`, `main.etoro_kpi_prep.v_mimo_optionsplatform.isftd`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isftd` | ERROR |
| `IsInternalTransfer` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isinternaltransfer`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.isinternaltransfer`, `main.etoro_kpi_prep.v_mimo_optionsplatform.isinternaltransfer`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isinternaltransfer` | ERROR |
| `IsRedeem` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isredeem`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.isredeem`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isredeem` | ERROR |
| `IsTradeFromIBAN` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.istradefromiban`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.istradefromiban`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isibantrade` | ERROR |
| `MIMOPlatform` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.mimoplatform` | ERROR |
| `IsGlobalFTD` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isglobalftd`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.realcid` | ERROR |
| `IsCryptoToFiat` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.iscryptotofiat`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.dateid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.iscryptotofiat`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.mimoaction`, `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms.firstdepositdate`, `main.etoro_kpi_prep.v_mimo_optionsplatform.dateid`, `main.etoro_kpi_prep.v_mimo_optionsplatform.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_optionsplatform.mimoaction`, `main.etoro_kpi_prep.v_mimo_tradingplatform.dateid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.fundingtypeid`, `main.etoro_kpi_prep.v_mimo_tradingplatform.iscryptotofiat`, `main.etoro_kpi_prep.v_mimo_tradingplatform.mimoaction` | ERROR |
| `IsRecurring` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isrecurring`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.isrecurring`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isrecurring` | ERROR |
| `IsIBANQuickTransfer` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isibanquicktransfer`, `main.etoro_kpi_prep.v_mimo_emoneyplatform.isibanquicktransfer`, `main.etoro_kpi_prep.v_mimo_tradingplatform.isibanquicktransfer` | ERROR |
| `UpdateDate` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.updatedate` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **14**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN global_ftds AS gf ON m.MIMOAction = 'Deposit' AND m.RealCID = gf.RealCID AND m.IsPlatformFTD = 1 AND m.FTDPlatformID = gf.FTDPlatformID
