# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` |
| **Primary Source** | Union of platform MIMO facts + MoneyFarm synthetic FTD rows keyed off `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms` |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms` |
| **Secondary Sources** | `BI_DB_ddr…MIMO_Trading_Platform`, `BI_DB_ddr…MIMO_eMoney_Platform`, `BI_DB_ddr…MIMO_Options_Platform`, `eMoney_dbo.eMoney_Fact_Transaction_Status`, `DWH_dbo.Dim_Customer` |
| **Generated** | 2026-05-14 |

## Lineage Chain

```
DWH Fact_CustomerAction + Billing dims + eMoney statuses (via platform facts)
 → BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform → BI_DB_DDR_Fact_MIMO_Trading_Platform
 → BI_DB_dbo.SP_DDR_Fact_MIMO_eMoney_Platform  → BI_DB_DDR_Fact_MIMO_eMoney_Platform
 → Function_MIMO_Options_Platform → BI_DB_DDR_Fact_MIMO_Options_Platform
 → BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms (0) (#globalFTDs)
       |
       v
BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms (@date daily)
  (#TP_Mimo + #IBAN_Mimo → #globalMIMO UNION; LEFT JOIN global FTDs; DELETE @dateID; INSERT TP+eMoney(+Options placeholders in temp)
   ; DELETE Options platform rows; INSERT from Options fact; DELETE MoneyFarm; INSERT MoneyFarm FTD-only slice
   ; post-load FTD recovery UPDATEs + C2USD UPDATE)
 → BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (~95M rows Synapse partition sum)
 → Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_DDR_Fact_MIMO_AllPlatforms/ → UC `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` (Delta Merge; Synapse DDL 20 cols + UC surrogate partition cols)
```

## Source Objects

| Object | Role |
|--------|------|
| `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform` | TP branch feed (`#TP_Mimo`) |
| `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` | eMoney branch feed (`#IBAN_Mimo`) |
| `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms` | Global FTD lookup (`#globalFTDs`) + MoneyFarm synthetic rows |
| `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform` | Options full-table upsert slice (separate INSERT) |
| `eMoney_dbo.eMoney_Fact_Transaction_Status` | Post-insert FTD recovery join (deposit rows, `TxTypeID IN (7,14)`) |
| `DWH_dbo.Dim_Customer` | FTD recovery joins / FTD linkage |

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Copied unchanged from branch rowset (possibly after column rename in `#final`). |
| **cast/convert** | Expression changes type/name but same business grain. |
| **ETL-computed** | Assembled CASE / literal / JOIN in AllPlatforms SP. |
| **SP-adjusted** | Source value post-processed UPDATE on target table. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|------------|--------------|---------------|-----------|---------------------|-------|
| DateID | `BI_DB_DDR_Fact_MIMO_Trading_Platform` / `_eMoney_Platform` / `_Options_Platform` / `#moneyfarmFTDs` | `DateID` | passthrough / ETL-computed | Direct from branch row; MoneyFarm: `CAST(FORMAT(gf.FirstDepositDate,'yyyyMMdd') AS int)` | |
| Date | Same | `Date` | passthrough / ETL-computed | MoneyFarm: `CAST(gf.FirstDepositDate AS date)` | Main INSERT uses `@date` for TP+eMoney(+Options staging) rows |
| RealCID | Same | `RealCID` | passthrough | Direct | |
| MIMOAction | Same | `MIMOAction` | passthrough / literal | MoneyFarm `'Deposit'` | |
| OrigIdentifier | Same | `OrigIdentifier` | passthrough | Direct (TP: `DepositID` vs `WithdrawPaymentID`; eMoney: always `TransactionID`; Options: `ApexTxID`; MoneyFarm: literal `DepositID`) | See sibling platform wikis + SP MoneyFarm block |
| TransactionID | Same | `TransactionID` | cast/convert / literal | `CAST(f.TransactionID AS varchar(50))` → persisted as `INT`; Options `#final` forced `NULL` then Options INSERT `0 AS TransactionID`; MoneyFarm literals `0` | SP lines 171–173 + 258–264 + `isnull(TransactionID,-1)` on MF outer select |
| AmountUSD | Same | `AmountUSD` | passthrough | Direct; MoneyFarm `gf.FirstDepositAmount` | |
| AmountOrigCurrency | Same | `AmountOrigCurrency` | passthrough / literal | MoneyFarm sentinel `-1` | |
| FundingTypeID | Same | `FundingTypeID` | passthrough / literal | MoneyFarm `-1` sentinel | Options remains from source (`0`) |
| CurrencyID | Same | `CurrencyID` | passthrough / literal | MoneyFarm literal `3` | Options `1` from source |
| Currency | Same | `Currency` | passthrough / literal | MoneyFarm `'GBP'` | Options `USD` from source |
| IsPlatformFTD | `#globalMIMO` | `IsFTD` | rename | `#final`: `IsFTD AS IsPlatformFTD`; `INSERT ISNULL(IsPlatformFTD,0)` | Recovery UPDATE rows below |
| IsInternalTransfer | Same | `IsInternalTransfer` | passthrough / literal | `ISNULL(..,0)`; Options literals `bddfmop` then `INSERT` retains; MoneyFarm literal `0` | |
| IsRedeem | Same | `IsRedeem` | passthrough / literal | `ISNULL(..,0)`; Options INSERT literal `0`; MoneyFarm literal `0` | TP withdraw uses `fca.IsRedeem`; eMoney fact column placeholder 0 |
| IsTradeFromIBAN | `#globalMIMO` | `IsIBANTrade` / `IsTradeFromIBAN` | cast/convert | TP maps `tm.IsIBANTrade`; eMoney maps `im.IsTradeFromIBAN`; `INSERT ISNULL(..,0)`; Options literals `0` | Column renamed from TP `IsIBANTrade` vs eMoney naming |
| MIMOPlatform | — | — | ETL-computed | Literals `'TradingPlatform'`,`'eMoney'`,`'Options'`,`'MoneyFarm'` inside UNION branches | Lines 96–135 + Options INSERT + `#moneyfarmFTDs` |
| IsGlobalFTD | `#globalFTDs` + `#final` CASE | `(join match)` | ETL-computed | `CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0` with `LEFT JOIN` on Deposit + platform FTD + platform id; MoneyFarm literal `1`; Options INSERT uses `bddfmop.IsGlobalFTD`; recovery UPDATE promotes rows | Separate logic for main merge vs Options insert |
| UpdateDate | — | — | ETL-computed | `@updatedate = GETDATE()` | |
| IsCryptoToFiat | Same | `IsCryptoToFiat` | passthrough / literal / SP-adjusted | INSERT `ISNULL(..,0)`; Options literal `0`; TP rows later `UPDATE ... SET IsCryptoToFiat=1 WHERE FundingTypeID=27` | Lines 407–413 |
| IsRecurring | Same | `IsRecurring` | passthrough / literal | `ISNULL`; Options `0`; MoneyFarm `0` | |
| IsIBANQuickTransfer | Same | `IsIBANQuickTransfer` | passthrough / literal | `ISNULL`; Options `0`; MoneyFarm `0` | |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough / rename** | 8 |
| **cast/convert** | 1 |
| **ETL-computed / SP-adjusted** | 12 |
| **Total** | 21 |

```
PHASE 10A CHECKPOINT: PASS
PHASE 10B CHECKPOINT: PASS
```
