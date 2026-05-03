# EXW_Wallet.AmlValidations — Review Needed

## 1. No Upstream Wiki Available

- Production source `WalletDB.Wallet.AmlValidations` has no upstream wiki in any documented repo (DB_Schema, CryptoDBs, etc.).
- All 14 production-passthrough columns are Tier 3 — descriptions are grounded in DDL column names, sample data, SP reader code (SP_EXW_Fact_Transactions), and Confluence documentation, but lack authoritative production-side documentation.
- **Action needed**: If a wiki for `WalletDB.Wallet.AmlValidations` is created in the CryptoDBs repo, re-run this object to upgrade Tier 3 columns to Tier 1.

## 2. AmlProviderId Value Mapping Uncertain

- Observed values: 1, 3, 4. Provider 1 is identified as Chainalysis from DetailsJson structure and Confluence references.
- Providers 3 and 4 are not confirmed — inferred from data patterns (provider 3 returns ProviderStatus='NA' predominantly, provider 4 returns Green/Amber).
- **Action needed**: Confirm provider ID mappings with the Crypto Wallet team.

## 3. CryptoId Value Mapping Partial

- Observed values in sample: 1=BTC, 2=ETH, 4=XRP, 18=ADA (inferred from DetailsJson Asset field and blockchain address formats).
- Full mapping not available without the crypto asset dictionary table.
- **Action needed**: Confirm full CryptoId mapping from WalletDB crypto asset dictionary.

## 4. CategoryId Semantics Unknown

- Only 1.1% of rows have a CategoryId value. 17 distinct values observed (4, 7, 9, 11, 16, 17, 18, 21, 25, 27, 32, 37, 38, 41, 46, 47).
- These likely correspond to Chainalysis entity category codes (e.g., sanctions, darknet market, ransomware, exchange) but the exact mapping is not documented.
- **Action needed**: Obtain CategoryId dictionary from the AML/Compliance team or Chainalysis documentation.

## 5. etr_y/etr_ym/etr_ymd Columns Appear Unpopulated

- All sampled rows show NULL/empty for these three Generic Pipeline partition columns.
- These may be deprecated or only populated for specific data lake export paths.
- **Action needed**: Confirm with Data Platform team whether these columns are actively used or can be removed.

## 6. DetailsJson Schema Varies by Provider

- Provider 1 (Chainalysis): `{Asset, TransferReference, Cluster:{Name,Category}, Rating}`
- Provider 4: `{alerts:[]}` structure observed
- Provider 3: Often empty string
- **Action needed**: Document the full DetailsJson schema per provider if downstream consumers parse this field.
