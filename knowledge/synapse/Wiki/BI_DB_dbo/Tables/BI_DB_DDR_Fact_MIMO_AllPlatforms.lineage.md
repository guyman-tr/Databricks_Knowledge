# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform`, `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform`, `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform` |
| **ETL SP** | `SP_DDR_Fact_Fact_MIMO_AllPlatforms` |
| **Secondary Sources** | `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms`, `DWH_dbo.Dim_Customer`, `eMoney_dbo.eMoney_Fact_Transaction_Status` |
| **Generated** | 2026-03-26 |

## Lineage Chain

```
BI_DB_DDR_Fact_MIMO_Trading_Platform (TP deposits/withdrawals)
BI_DB_DDR_Fact_MIMO_eMoney_Platform  (eMoney deposits/withdrawals)
BI_DB_DDR_Fact_MIMO_Options_Platform (Options deposits/withdrawals)
Function_MIMO_First_Deposit_All_Platforms(0) (global FTD reference)
DWH_dbo.Dim_Customer (FTD recovery + MoneyFarm FTD)
  |
  |-- SP_DDR_Fact_Fact_MIMO_AllPlatforms(@date):
  |     1. UNION ALL TP + eMoney into #globalMIMO
  |     2. LEFT JOIN #globalFTDs → set IsGlobalFTD
  |     3. DELETE/INSERT by DateID for TP+eMoney
  |     4. DELETE ALL Options → full re-INSERT from Options_Platform
  |     5. DELETE ALL MoneyFarm → INSERT FTD-only from global FTDs
  |     6. UPDATE FTD recovery from Dim_Customer for eMoney+TP
  |     7. UPDATE C2USD (FundingTypeID=27) for TP deposits
  v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (91.5M rows, transaction-level grain)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from sub-platform table |
| **rename** | Same value, different column name |
| **ETL-computed** | Derived/calculated by SP logic |
| **join-enriched** | Joined from secondary source during ETL |
| **coerce** | ISNULL null-to-zero coercion applied |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | Sub-platform tables | DateID | passthrough | Direct: tm.DateID / im.DateID | YYYYMMDD int; DELETE key for TP+eMoney |
| Date | — | — | ETL-computed | `@date` parameter | SP parameter; cast to DATE |
| RealCID | Sub-platform tables | RealCID | passthrough | Direct: tm.RealCID / im.RealCID | Distribution key |
| MIMOAction | Sub-platform tables | MIMOAction | passthrough | Direct | 'Deposit' or 'Withdraw' |
| OrigIdentifier | Sub-platform tables | OrigIdentifier | passthrough | Direct | 'TransactionID', 'WithdrawPaymentID', 'DepositID' |
| TransactionID | Sub-platform tables | TransactionID | ETL-computed | `CAST(f.TransactionID AS VARCHAR(50))` for TP/eMoney; `0` for Options/MoneyFarm | Type cast; Options set to NULL then 0 |
| AmountUSD | Sub-platform tables | AmountUSD | passthrough | Direct | USD equivalent |
| AmountOrigCurrency | Sub-platform tables | AmountOrigCurrency | passthrough | Direct; `-1` for MoneyFarm | Original currency amount |
| FundingTypeID | Sub-platform tables | FundingTypeID | passthrough | Direct; `-1` for MoneyFarm | Payment method |
| CurrencyID | Sub-platform tables | CurrencyID | passthrough | Direct; `3` (GBP) for MoneyFarm | Currency lookup |
| Currency | Sub-platform tables | Currency | passthrough | Direct; `'GBP'` for MoneyFarm | Currency ISO code |
| IsPlatformFTD | Sub-platform tables | IsFTD | rename+coerce | `ISNULL(f.IsPlatformFTD, 0)`; renamed from IsFTD | Platform-level first deposit flag; updated by FTD recovery |
| IsInternalTransfer | Sub-platform tables | IsInternalTransfer | passthrough+coerce | `ISNULL(f.IsInternalTransfer, 0)` | Internal fund transfer between platforms |
| IsRedeem | Sub-platform tables | IsRedeem | passthrough+coerce | `ISNULL(f.IsRedeem, 0)`; `0` for Options/MoneyFarm | eMoney redeem indicator |
| IsTradeFromIBAN | Sub-platform tables | IsIBANTrade | rename+coerce | `ISNULL(f.IsIBANTrade, 0)`; `0` for Options/MoneyFarm | eMoney-initiated trade (column renamed from IsIBANTrade) |
| MIMOPlatform | — | — | ETL-computed | Literal: `'TradingPlatform'`, `'eMoney'`, `'Options'`, or `'MoneyFarm'` | Platform discriminator |
| IsGlobalFTD | Function_MIMO_First_Deposit_All_Platforms | RealCID+FTDPlatformID | join-enriched+coerce | `CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,0)` + FTD recovery UPDATEs | Cross-platform first deposit; recovered from Dim_Customer |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL timestamp |
| IsCryptoToFiat | Sub-platform tables | IsCryptoToFiat | passthrough+coerce+UPDATE | `ISNULL(f.IsCryptoToFiat, 0)`; additionally `UPDATE SET IsCryptoToFiat=1 WHERE FundingTypeID=27 AND MIMOPlatform='TradingPlatform'` | Dual source: sub-platform flag + TP override |
| IsRecurring | Sub-platform tables | IsRecurring | passthrough+coerce | `ISNULL(f.IsRecurring, 0)`; `0` for Options/MoneyFarm | Recurring deposit flag |
| IsIBANQuickTransfer | Sub-platform tables | IsIBANQuickTransfer | passthrough+coerce | `ISNULL(f.IsIBANQuickTransfer, 0)`; `0` for Options/MoneyFarm | eMoney internal transfer (MoveMoneyReasonID=6) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 8 |
| **Passthrough+coerce** | 5 |
| **Rename+coerce** | 2 |
| **ETL-computed** | 4 |
| **Join-enriched+coerce** | 1 |
| **Passthrough+coerce+UPDATE** | 1 |
| **Total** | 21 |
