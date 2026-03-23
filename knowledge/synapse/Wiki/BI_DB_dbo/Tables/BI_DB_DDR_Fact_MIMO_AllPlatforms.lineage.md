# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

## Column Mapping

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|-------------|---------------|-----------|-------|
| DateID | -- | @date parameter | ETL-computed | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| Date | -- | @date parameter | passthrough | SP input parameter |
| RealCID | Multiple | RealCID | passthrough | From TP MIMO + eMoney MIMO union |
| MIMOAction | SP logic | -- | ETL-computed | Deposit/Withdraw classification |
| OrigIdentifier | Multiple | OrigIdentifier | passthrough | Original transaction identifier |
| TransactionID | Multiple | TransactionID | passthrough | |
| AmountUSD | Multiple | AmountUSD | passthrough | |
| AmountOrigCurrency | Multiple | AmountOrigCurrency | passthrough | |
| FundingTypeID | Multiple | FundingTypeID | passthrough | |
| CurrencyID | Multiple | CurrencyID | passthrough | |
| Currency | Multiple | Currency | passthrough | Currency abbreviation |
| IsPlatformFTD | SP logic | -- | ETL-computed | Platform-specific first time deposit flag |
| IsInternalTransfer | SP logic | -- | ETL-computed | Internal transfer indicator |
| IsRedeem | SP logic | -- | ETL-computed | Redeem indicator |
| IsTradeFromIBAN | SP logic | -- | ETL-computed | IBAN trade indicator |
| MIMOPlatform | SP logic | -- | ETL-computed | Platform identifier (TP/eMoney/Options/MoneyFarm) |
| IsGlobalFTD | Function_MIMO_First_Deposit_All_Platforms | -- | function-computed | Global FTD across all platforms |
| UpdateDate | -- | -- | ETL-computed | GETDATE() |
| IsCryptoToFiat | SP logic | FundingTypeID | ETL-computed | FundingTypeID = 27 for TP crypto-to-USD |
| IsRecurring | SP logic | -- | ETL-computed | Recurring transaction flag |
| IsIBANQuickTransfer | SP logic | MoneyMoveReason | ETL-computed | MoneyMoveReason = 6 (eMoney internal transfer) |

## ETL Pipeline

```
TP MIMO (BI_DB_DDR_Fact_MIMO_TP) + eMoney MIMO (BI_DB_DDR_Fact_MIMO_eMoney_Platform)
+ Options platform + MoneyFarm
    │
    └─ SP_DDR_Fact_Fact_MIMO_AllPlatforms(@date)
        ├─ #ibans (eMoney FTD customers from Dim_Customer)
        ├─ #globalFTDs (Function_MIMO_First_Deposit_All_Platforms)
        ├─ UNION of TP + eMoney + Options + MoneyFarm MIMO
        ├─ JOIN to #globalFTDs for IsGlobalFTD
        ├─ DELETE WHERE DateID = @dateID
        ├─ INSERT INTO BI_DB_DDR_Fact_MIMO_AllPlatforms
        └─ UPDATE: recover FTDs from Dim_Customer (came in later than run date)
```

## Source Tables

| Source | Role |
|--------|------|
| BI_DB_DDR_Fact_MIMO_TP | Trading platform MIMO transactions |
| BI_DB_DDR_Fact_MIMO_eMoney_Platform | eMoney platform MIMO transactions |
| Options platform tables | Options MIMO (best effort, no dependency) |
| MoneyFarm tables | MoneyFarm FTD data |
| Function_MIMO_First_Deposit_All_Platforms | Global FTD resolution |
| DWH_dbo.Dim_Customer | FTD recovery + platform FTD identification |

## Consumers

| Consumer | Usage |
|----------|-------|
| SP_DDR_Customer_Daily_Status | Daily customer status aggregation |
| SP_MarketingCloudDaily | Marketing cloud daily feed |
| SP_RevenueForum | Revenue forum reporting |
