# EXW_Wallet.EXW_PriceDaily — Review Needed

## 1. Upstream Wiki Coverage

- **No upstream wiki found** for any source table (`_no_upstream_found.txt` confirmed).
- All 10 columns are Tier 2, grounded in SP_Prices code and DDL.
- No Tier 1 inheritance was possible — all source tables (EXW_Currency.Instruments, EXW_Currency.Currencies, EXW_Wallet.CryptoMarketRatesMappings, EXW_Wallet.CryptoTypes, EXW_Wallet.ETL_InstrumentRates_ByHour) lack wiki documentation.

## 2. Items for Human Review

### 2.1 Production Source Unknown

- The production source database for the EXW_Wallet schema is not documented in `_upstream_wiki_routing.json`. The data appears to originate from internal wallet/crypto systems (eToroX) but the specific production database is unresolvable.
- **Action**: Confirm the production source system for EXW_Currency and EXW_Wallet tables.

### 2.2 eToroInstrumentID NULL Rate

- 83% of rows (344K/414K) have NULL eToroInstrumentID. This appears intentional (wallet-only tokens not listed on eToro platform), but should be confirmed.
- **Action**: Verify whether these NULLs represent tokens that were never listed or tokens that were delisted.

### 2.3 AvgPrice Anomalies

- Many inactive tokens show AvgPrice = 1.00000000 (e.g., CVC, SGDX, LINK, BTT, AE on 2018-04-23). These may be placeholder/default values rather than actual prices.
- Token ZCO shows AvgPrice = 0.00000000 (0E-8) as recently as 2024-03-21.
- **Action**: Confirm whether AvgPrice = 1.0 on early dates represents real prices or gap-fill defaults.

### 2.4 InstrumentID Overloading

- InstrumentID is conditionally set to eToroInstrumentID (when >= 100000) or CryptoID (otherwise). This dual meaning complicates JOINs to EXW_Currency.Instruments.
- **Action**: Confirm whether downstream consumers are aware of this CASE logic.

### 2.5 UC Migration Status

- Object is currently `_Not_Migrated` to Unity Catalog. No UC target defined.
- **Action**: Determine if this table is in scope for UC migration.

## 3. Downstream Consumers

- No downstream consumers were identified from the bundle. SP_Prices also writes to `EXW_Wallet.EXW_Price` (hourly granularity) in the same execution.
- **Action**: Identify which reports or dashboards consume EXW_PriceDaily.
