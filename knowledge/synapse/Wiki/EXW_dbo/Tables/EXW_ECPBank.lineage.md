# EXW_dbo.EXW_ECPBank — Column Lineage

**Generated**: 2026-04-20  
**Object**: EXW_dbo.EXW_ECPBank  
**Type**: Table  
**Production Source**: ECP Bank settlement report (external acquirer — loaded via Fivetran)  
**ETL Mechanism**: Fivetran connector (evidenced by `_row`, `_fivetran_deleted`, `_fivetran_synced` columns)

---

## ETL Pipeline

```
ECP Bank (payment acquirer — Gibraltar merchant account 172000000006524)
  |-- Fivetran connector (incremental sync) ---|
  v
EXW_dbo.EXW_ECPBank (113K rows, posting dates 2019-02-01 to 2022-09-20)
  |-- No UC Generic Pipeline mapping found ---|
  v
UC Target: _Not_Migrated (no mapping in bronze_opsdb_dbo_vw_unitycatalog_mapping_tables)
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|------------|-------------|---------------|-----------|------|
| 1 | _row | Fivetran | synthetic | Fivetran-generated sequential row ID (PK) | Tier 2 |
| 2 | _fivetran_deleted | Fivetran | synthetic | Fivetran soft-delete flag (True = record deleted in source) | Tier 2 |
| 3 | merchant_no_ | ECP Bank report | merchant_no_ | Passthrough (bigint; inconsistent formatting in data) | Tier 4 |
| 4 | batch_no_ | ECP Bank report | batch_no_ | Passthrough (settlement batch identifier, mainly "eMP") | Tier 4 |
| 5 | transaction_date | ECP Bank report | transaction_date | Passthrough (YYYYMMDD stored as bigint; empty for post-2020 records) | Tier 4 |
| 6 | posting_date | ECP Bank report | posting_date | Passthrough (YYYYMMDD stored as bigint; settlement date) | Tier 4 |
| 7 | type | ECP Bank report | type | Passthrough (Purchase, Refund (Credit)) | Tier 4 |
| 8 | card_no_ | ECP Bank report | card_no_ | Passthrough (masked — older: ************1234, newer: *1234) | Tier 4 |
| 9 | uti | ECP Bank report | uti | Passthrough (UTI hex string, links to EXW_SimplexMapping.uti) | Tier 4 |
| 10 | status | ECP Bank report | status | Passthrough (Cleared, Processed) | Tier 4 |
| 11 | trans_curr | ECP Bank report | trans_curr | Passthrough (transaction currency code; empty for newer records) | Tier 4 |
| 12 | acct_curr | ECP Bank report | acct_curr | Passthrough (account/settlement currency: GBP or EUR) | Tier 4 |
| 13 | acct_commission_charges | ECP Bank report | acct_commission_charges | Passthrough (commission fees deducted at settlement) | Tier 4 |
| 14 | acct_amount_net | ECP Bank report | acct_amount_net | Passthrough (net settlement: gross - commission) | Tier 4 |
| 15 | capture_method | ECP Bank report | capture_method | Passthrough (3D-SET, eCommerce Channel Encrypt, etc.) | Tier 4 |
| 16 | merch_tran_ref_ | ECP Bank report | merch_tran_ref_ | Passthrough (first 15 chars of UTI, merchant reference) | Tier 4 |
| 17 | acquirer_ref_ | ECP Bank report | acquirer_ref_ | Passthrough (ARN — 23-digit network reference, same as in EXW_SimplexChargebacks.ARN) | Tier 4 |
| 18 | merchant_name | ECP Bank report | merchant_name | Passthrough (always "Simplex_etorox"; some nulls show "eMP") | Tier 4 |
| 19 | transaction_country | ECP Bank report | transaction_country | Passthrough (always "Gibraltar" — eToro's ECP merchant country) | Tier 4 |
| 20 | acquirer_bin_ica | ECP Bank report | acquirer_bin_ica | Passthrough (453760=Visa, 14206=Mastercard) | Tier 4 |
| 21 | area_of_event | ECP Bank report | area_of_event | Passthrough (geographic classification: Domestic-UK, Foreign-EMEA, etc.) | Tier 4 |
| 22 | fpi | ECP Bank report | fpi | Passthrough (3-char FPI code, bank-scheme classification) | Tier 4 |
| 23 | acct_assessed_intchg_amount | ECP Bank report | acct_assessed_intchg_amount | Passthrough (interchange fee charged by card network) | Tier 4 |
| 24 | expiry_date | ECP Bank report | expiry_date | Passthrough (YYYYMM as bigint; mostly empty) | Tier 4 |
| 25 | cross_rate | ECP Bank report | cross_rate | Passthrough (FX rate for cross-currency settlement; bigint stored as float) | Tier 4 |
| 26 | additional_charges | ECP Bank report | additional_charges | Passthrough (extra charges beyond commission) | Tier 4 |
| 27 | _fivetran_synced | Fivetran | synthetic | Fivetran sync timestamp (when record was last synced) | Tier 2 |
| 28 | internal_batch_no_ | ECP Bank report | internal_batch_no_ | Passthrough (internal batch identifier as float: YYYYMMDDBATCH.0) | Tier 4 |
| 29 | auth_code | ECP Bank report | auth_code | Passthrough (card authorization approval code) | Tier 4 |
| 30 | acct_amount_gross | ECP Bank report | acct_amount_gross | Passthrough (gross settlement before commission) | Tier 4 |
| 31 | trans_amount | ECP Bank report | trans_amount | Passthrough (transaction amount in trans_curr; empty for newer records) | Tier 4 |
| 32 | UpdateDate | ETL | — | ETL-managed load timestamp | Tier 2 |
| 33 | UpdateDateID | ETL | — | Date integer key derived from UpdateDate (mostly NULL in data) | Tier 2 |

---

## Notes

- **Fivetran-loaded**: Presence of `_row`, `_fivetran_deleted`, `_fivetran_synced` confirms Fivetran as the ETL mechanism
- **Table frozen**: posting_date max = 20220920 (September 2022). UpdateDate max = 2024-04-09 (last sync). Simplex decommissioned as crypto buy provider ~2022
- **transaction_date vs posting_date**: transaction_date (authorization) is empty for post-2019 records; posting_date (settlement) is always present
- **Merchant data quality**: merchant_no_ has 3 variants (172000000006524, 1720000000006524, 172000000000000) — formatting inconsistency in ECP Bank export; same physical merchant
- **UTI cross-reference**: uti column matches EXW_SimplexMapping.uti for approved transactions; merch_tran_ref_ is a 15-char truncation of the same UTI
