# EXW_Wallet.FiatTypes — Review Needed

## 1. Tier 3 Columns (No Upstream Wiki)

All 8 production-sourced columns (Id, FiatId, FiatName, IsActive, AvatarUrl, Precision, InstrumentId, NumericCode) are Tier 3. The production source WalletDB.Wallet.FiatTypes has no wiki documentation. Descriptions are grounded in DDL structure and live data sampling (4 rows).

**Action**: If a wiki for WalletDB.Wallet.FiatTypes becomes available, upgrade these columns to Tier 1 with verbatim upstream descriptions.

## 2. InstrumentId FK Target Unknown

InstrumentId maps to a trading instrument table, but the exact target table is not confirmed. Values observed: NULL (USD), 1 (EUR), 2 (GBP), 7 (AUD).

**Action**: Confirm which table InstrumentId references (possibly a WalletDB instrument table or DWH_dbo.Dim_Instrument). Update relationship in Section 6.1 accordingly.

## 3. FiatId Gap

FiatId skips value 4 (values are 1, 2, 3, 5). This may indicate a removed or reserved currency.

**Action**: Confirm with wallet team whether FiatId=4 was historically used or is reserved.

## 4. ETL Partition Columns Not Populated

etr_y, etr_ym, etr_ymd are all NULL despite being present in the DDL. This is consistent with Override (full-refresh) copy strategy where partitioning is unnecessary.

**Action**: No action needed unless the pipeline changes to incremental.

## 5. Limited Currency Coverage

Only 4 fiat currencies are supported (USD, EUR, GBP, AUD). Notable absences include JPY, CHF, CAD, NZD, SGD, and other major currencies.

**Action**: Confirm with wallet team whether this reflects business scope or a data gap.
