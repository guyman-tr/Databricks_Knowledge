# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

## Column Mapping

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|-------------|---------------|-----------|-------|
| DateID | -- | @date parameter | ETL-computed | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| Date | -- | @date parameter | passthrough | SP input parameter |
| RealCID | eMoney_Fact_Transaction_Status | CID | passthrough | Via Dim_Customer join for RealCID resolution |
| MIMOAction | SP logic | TxTypeID | ETL-computed | Deposit (TxType 7,5,14) / Withdraw (TxType 8,6) |
| OrigIdentifier | eMoney_Fact_Transaction_Status | -- | ETL-computed | Original transaction identifier |
| TransactionID | eMoney_Fact_Transaction_Status | TransactionID | passthrough | |
| ReferenceNumber | eMoney_Fact_Transaction_Status | ReferenceNumber | passthrough | External payment reference (varchar 4000) |
| AmountUSD | eMoney_Fact_Transaction_Status | USDAmountApprox | passthrough | Signed: positive for deposits, negative for withdrawals |
| AmountOrigCurrency | eMoney_Fact_Transaction_Status | Amount | passthrough | In original currency |
| FundingTypeID | SP logic | -- | ETL-computed | 33 for eMoney deposits, 0 for withdrawals |
| CurrencyID | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | CurrencyID | join-enriched | ISO-based currency mapping |
| Currency | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | Abbreviation | join-enriched | Currency code |
| IsFTD | SP logic + #FTDIBAN | -- | ETL-computed | First time deposit on eMoney platform |
| IsInternalTransfer | SP logic | -- | ETL-computed | Internal transfer indicator |
| IsRedeem | SP logic | -- | ETL-computed | Redeem indicator |
| TxTypeID | eMoney_Fact_Transaction_Status | TxTypeID | passthrough | eMoney transaction type |
| IsTradeFromIBAN | SP logic | -- | ETL-computed | IBAN trade indicator |
| UpdateDate | -- | -- | ETL-computed | GETDATE() |
| IsCryptoToFiat | SP logic | TxTypeID | ETL-computed | TxTypeID = 14 (crypto to fiat conversion) |
| IsRecurring | -- | -- | hardcoded | Always 0 (placeholder for AllPlatforms union compatibility) |
| IsIBANQuickTransfer | SP logic | MoneyMoveReason | ETL-computed | MoneyMoveReason = 6 |

## ETL Pipeline

```
eMoney_dbo.eMoney_Fact_Transaction_Status (TxStatusID = 2, settled)
    │
    └─ SP_DDR_Fact_MIMO_eMoney_Platform(@date)
        ├─ #FTDIBAN (FTD identification via Dim_Customer.FTDPlatformID = 3)
        ├─ #depositsIBAN (TxTypeID IN (7, 5, 14))
        ├─ Amount updates for deposits
        ├─ #cashoutIBAN (TxTypeID IN (8, 6))
        ├─ UNION deposits + cashouts
        ├─ Deduplication
        ├─ DELETE WHERE DateID = @dateID
        ├─ INSERT INTO BI_DB_DDR_Fact_MIMO_eMoney_Platform
        └─ UPDATE: FTD recovery from Dim_Customer
```

## Source Tables

| Source | Role |
|--------|------|
| eMoney_dbo.eMoney_Fact_Transaction_Status | Primary — eMoney transaction events |
| DWH_dbo.Dim_Customer | FTD identification (FTDPlatformID, FTDTransactionID) |
| eMoney_Currency_Instrument_Mapping_Static | Currency ISO mapping |
| Dim_Currency | Currency dimension fallback |

## Consumers

| Consumer | Usage |
|----------|-------|
| SP_DDR_Fact_Fact_MIMO_AllPlatforms | Consumed as eMoney component of AllPlatforms union |
| SP_DDR_Process_Monitor | Process monitoring |
