# Column Lineage: BI_DB_dbo.BI_DB_AML_Email_for_KYT

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Email_for_KYT` |
| **UC Target** | Not_Migrated (decommissioned) |
| **Primary Source** | `External_Fivetran_google_sheets_kyt_alerts` (Fivetran ingestion from Google Sheets KYT alert feed) |
| **ETL SP** | `JUNK_SP_AML_Email_for_KYT` (**DECOMMISSIONED** — JUNK prefix, 0 rows in table) |
| **Secondary Sources** | `EXW_dbo.EXW_AMLProviderID`, `EXW_dbo.EXW_FactTransactions`, `EXW_dbo.EXW_UserSettingsWalletAllowance`, `DWH_dbo.Dim_Customer` (×2), `DWH_dbo.Dim_PlayerStatus` (×2), `DWH_dbo.Dim_Country` (×2), `DWH_dbo.Dim_Regulation` (×2) |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
Google Sheets KYT Alert Feed (external, Fivetran)
    │
    └─ External_Fivetran_google_sheets_kyt_alerts (external table, kk alias)
        │
        ├── LEFT JOIN EXW_dbo.EXW_AMLProviderID
        │     ON ProviderUserIDNormalized = kk.user_id COLLATE Latin1_General_100_BIN
        │     → resolves crypto provider user_id → eToro CID/GCID
        │
        ├── LEFT JOIN EXW_dbo.EXW_FactTransactions
        │     ON BlockchainTransactionId = kk.tx_hash
        │     → blockchain transaction enrichment
        │
        ├── LEFT JOIN EXW_dbo.EXW_UserSettingsWalletAllowance
        │     ON CID → UserWalletAllowance
        │
        ├── LEFT JOIN DWH_dbo.Dim_Customer (×2)
        │     → RealCID, GCID, CountryID, RegulationID, PlayerStatusID
        │
        ├── LEFT JOIN DWH_dbo.Dim_PlayerStatus (×2)
        │     → PlayerStatus name
        │
        ├── LEFT JOIN DWH_dbo.Dim_Country (×2)
        │     → Country name
        │
        ├── LEFT JOIN DWH_dbo.Dim_Regulation (×2)
        │     → Regulation name
        │
        └─ JUNK_SP_AML_Email_for_KYT [DECOMMISSIONED]
            ├─ TRUNCATE TABLE target
            └─ INSERT → BI_DB_dbo.BI_DB_AML_Email_for_KYT
```

> **Status**: DECOMMISSIONED. The SP carries the JUNK_ prefix indicating intentional decommission. The table is empty (0 rows) confirming the pipeline is no longer running. Do not use this table for analysis — data is stale (pre-decommission snapshot or zero rows).

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | EXW_dbo.EXW_AMLProviderID | RealCID | rename | Via `ProviderUserIDNormalized = kk.user_id COLLATE Latin1_General_100_BIN` | eToro customer ID resolved from crypto provider user ID |
| GCID | DWH_dbo.Dim_Customer | GCID | join-enriched | Via CID → Dim_Customer.RealCID | Global customer ID |
| Country | DWH_dbo.Dim_Country | Name | join-enriched | Via Dim_Customer.CountryID = Dim_Country.DWHCountryID | Customer country of residence |
| Regulation | DWH_dbo.Dim_Regulation | Name | join-enriched | Via Dim_Customer.RegulationID = Dim_Regulation.DWHRegulationID | Customer regulatory jurisdiction |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | join-enriched | Via Dim_Customer.PlayerStatusID = Dim_PlayerStatus.PlayerStatusID | Account status |
| UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | — | join-enriched | Via CID join | Wallet allowance setting for this customer |
| severity | External_Fivetran_google_sheets_kyt_alerts | severity | passthrough | Direct from KYT feed | Alert severity level (Low/Medium/High/Critical) |
| category | External_Fivetran_google_sheets_kyt_alerts | category | passthrough | Direct from KYT feed | KYT alert category |
| alert_created_at | External_Fivetran_google_sheets_kyt_alerts | alert_created_at | passthrough | Direct from KYT feed | When the KYT alert was raised |
| transfer_at | External_Fivetran_google_sheets_kyt_alerts | transfer_at | passthrough | Direct from KYT feed | When the crypto transfer occurred |
| status | External_Fivetran_google_sheets_kyt_alerts | status | passthrough | Direct from KYT feed | Alert resolution status |
| service_name | External_Fivetran_google_sheets_kyt_alerts | service_name | passthrough | Direct from KYT feed | KYT provider service name |
| exposure | External_Fivetran_google_sheets_kyt_alerts | exposure | passthrough | Direct from KYT feed | Risk exposure type (Direct/Indirect) |
| direction | External_Fivetran_google_sheets_kyt_alerts | direction | passthrough | Direct from KYT feed | Transfer direction (Sent/Received) |
| alert_amount | External_Fivetran_google_sheets_kyt_alerts | alert_amount | passthrough | Direct from KYT feed | Amount involved in flagged transfer (USD) |
| user_id | External_Fivetran_google_sheets_kyt_alerts | user_id | passthrough | Direct from KYT feed | Provider's user identifier (blockchain address) |
| asset | External_Fivetran_google_sheets_kyt_alerts | asset | passthrough | Direct from KYT feed | Cryptocurrency asset type (BTC, ETH, etc.) |
| tx_hash | External_Fivetran_google_sheets_kyt_alerts | tx_hash | passthrough | Direct from KYT feed | Blockchain transaction hash |
| tx_index | External_Fivetran_google_sheets_kyt_alerts | tx_index | passthrough | Direct from KYT feed | Transaction index within block |
| output_address | External_Fivetran_google_sheets_kyt_alerts | output_address | passthrough | Direct from KYT feed | Destination blockchain address |
| alert_type | External_Fivetran_google_sheets_kyt_alerts | alert_type | passthrough | Direct from KYT feed | KYT alert classification type |
| state | External_Fivetran_google_sheets_kyt_alerts | state | passthrough | Direct from KYT feed | Alert processing state |
| _of_transfer | External_Fivetran_google_sheets_kyt_alerts | _of_transfer | passthrough | Direct from KYT feed | Fraction/percentage of transfer that is high-risk |
| symbol | External_Fivetran_google_sheets_kyt_alerts | symbol | passthrough | Direct from KYT feed | Cryptocurrency symbol |
| network | External_Fivetran_google_sheets_kyt_alerts | network | passthrough | Direct from KYT feed | Blockchain network (Bitcoin, Ethereum, etc.) |
| alert_id | External_Fivetran_google_sheets_kyt_alerts | alert_id | passthrough | Direct from KYT feed | Unique alert identifier from KYT provider |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 17 |
| **Rename** | 1 |
| **Join-enriched** | 8 |
| **ETL-computed** | 1 |
| **Total** | 27 |
