# EXW_Wallet.EXW_Price — Review Needed

## 1. No Upstream Wiki Available

- `_no_upstream_found.txt` is present. No production-level wiki was resolvable for any source table (EXW_Currency.Instruments, EXW_Currency.Currencies, CryptoMarketRatesMappings, CryptoTypes, ETL_InstrumentRates_ByHour).
- All 14 columns are Tier 2 (grounded in SP_Prices source code). Zero Tier 1 descriptions are possible without upstream documentation.
- **Action**: If upstream wikis are created for EXW_Currency or EXW_Wallet source tables, re-run to upgrade passthrough columns (eToroInstrumentID, CryptoID, CryptoName, BlockchainCryptoId, BlockchainCryptoName) to Tier 1.

## 2. InstrumentID Semantics

- InstrumentID in EXW_Price is NOT the same as EXW_Currency.Instruments.Id in all cases. The CASE remap (>=100000 → eToroInstrumentID, else CryptoId) makes this a composite key. Confirm with domain owner whether downstream consumers are aware of this dual-meaning.

## 3. eToroInstrumentID NULL Rate

- ~65% of rows have NULL eToroInstrumentID. These are crypto-native instruments without eToro trading platform mappings. Confirm whether this is expected or indicates incomplete CryptoTypes mapping data.

## 4. Zero-Price Instruments

- Instruments BTU, SGDX, and possibly others show AskLast/BidLast/AvgPrice = 0.00000000 across all hours. These appear dormant/delisted. Confirm whether these should be excluded from the daily load or retained for historical completeness.

## 5. Gap-Fill Indistinguishability

- Gap-filled rows (carried-forward prices) are indistinguishable from live market data rows. No flag or indicator column exists. If this distinction matters for downstream analytics, consider adding a source indicator column.

## 6. ETL_InstrumentRates_ByHour — Unresolved Source

- ETL_InstrumentRates_ByHour is the primary data source but has no wiki or upstream documentation. Its own data pipeline (how hourly rates arrive from market data providers) is undocumented in this repo.
