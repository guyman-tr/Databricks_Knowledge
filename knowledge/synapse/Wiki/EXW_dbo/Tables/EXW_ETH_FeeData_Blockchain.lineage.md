# EXW_dbo.EXW_ETH_FeeData_Blockchain — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_EXW_ETH_FeeData_Blockchain | **Load Pattern**: UPSERT (INSERT new txhash + UPDATE existing, no date param)

## ETL Pipeline

```
Etherscan Blockchain API (eToro hot wallet 0x8c4b...eebf4)
  |-- Manual export to Google Sheets ---|
  v
BI_DB_dbo.External_Fivetran_google_sheets_eth_fee_data_blockchain
  |-- SP_EXW_ETH_FeeData_Blockchain
  |   INSERT WHERE txhash NOT IN existing
  |   UPDATE WHERE txhash already in target
  |   (no date param — delta by txhash) ---|
  v
EXW_dbo.EXW_ETH_FeeData_Blockchain (402,288 rows)
  |-- SP_EXW_EthFeeSent_Blockchain (daily @d DATE) ---|
  v
EXW_dbo.EXW_EthFeeSent_Blockchain (documented, Batch 5)
  |-- (no UC migration) ---|
  v
_Not_Migrated
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| txhash | External_Fivetran_google_sheets_eth_fee_data_blockchain | txhash | Passthrough (COLLATE SQL_Latin1_General_CP1_CI_AS for JOIN) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| date_time | External_Fivetran_google_sheets_eth_fee_data_blockchain | date_time | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| unix_timestamp | External_Fivetran_google_sheets_eth_fee_data_blockchain | unix_timestamp | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| blockno | External_Fivetran_google_sheets_eth_fee_data_blockchain | blockno | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| txn_fee_eth | External_Fivetran_google_sheets_eth_fee_data_blockchain | txn_fee_eth_ | Rename (trailing _ stripped) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| historical_price_eth | External_Fivetran_google_sheets_eth_fee_data_blockchain | historical_price_eth | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| txn_fee_usd | External_Fivetran_google_sheets_eth_fee_data_blockchain | txn_fee_usd_ | Rename (trailing _ stripped) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| value_in_eth | External_Fivetran_google_sheets_eth_fee_data_blockchain | value_in_eth_ | Rename (trailing _ stripped) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| value_out_eth | External_Fivetran_google_sheets_eth_fee_data_blockchain | value_out_eth_ | Rename (trailing _ stripped) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| current_value_eth | External_Fivetran_google_sheets_eth_fee_data_blockchain | current_value_411_37_eth | Rename (snapshot-specific name normalized) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| from | External_Fivetran_google_sheets_eth_fee_data_blockchain | from | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| to | External_Fivetran_google_sheets_eth_fee_data_blockchain | to | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| contract_address | External_Fivetran_google_sheets_eth_fee_data_blockchain | contract_address | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| err_code | External_Fivetran_google_sheets_eth_fee_data_blockchain | err_code | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| fivetran_synced | External_Fivetran_google_sheets_eth_fee_data_blockchain | _fivetran_synced | Rename (_ prefix stripped) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| status | External_Fivetran_google_sheets_eth_fee_data_blockchain | status | Passthrough | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |
| method | External_Fivetran_google_sheets_eth_fee_data_blockchain | method | Passthrough (added 2022-03-22; NULL for older rows) | Tier 2 — SP_EXW_ETH_FeeData_Blockchain |

## Source Objects

| Object | Role |
|---|---|
| BI_DB_dbo.External_Fivetran_google_sheets_eth_fee_data_blockchain | Sole source — Fivetran Google Sheets import of Etherscan ETH fee export |
| EXW_dbo.SP_EXW_ETH_FeeData_Blockchain | Writer SP |
| EXW_dbo.SP_EXW_EthFeeSent_Blockchain | Reader SP — uses txhash, date_time, contract_address, method, txn_fee_eth for ETH fee analytics |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 2 | 18 | All columns — no upstream wiki for Fivetran Google Sheets source |
