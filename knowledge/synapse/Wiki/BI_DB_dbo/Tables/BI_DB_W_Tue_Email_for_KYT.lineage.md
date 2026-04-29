# BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT — Column Lineage

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| External_Fivetran_google_sheets_kyt_alerts | BI_DB_dbo | Primary — KYT alert data from Google Sheets via Fivetran | Base table |
| EXW_dbo.EXW_AMLProviderID | EXW_dbo | LEFT JOIN — resolve user_id to RealCID/GCID | ProviderUserIDNormalized or ProviderUserID = user_id |
| EXW_dbo.EXW_FactTransactions | EXW_dbo | LEFT JOIN — fallback CID resolution by tx_hash | BlockchainTransactionId = tx_hash AND ReciverAddress = output_address |
| EXW_dbo.EXW_UserSettingsWalletAllowance | EXW_dbo | LEFT JOIN — wallet allowance status | GCID = eai.GCID |
| DWH_dbo.Dim_Customer | DWH_dbo | LEFT JOIN (x2) — customer enrichment | RealCID from EXW_AMLProviderID or EXW_FactTransactions |
| DWH_dbo.Dim_Country | DWH_dbo | LEFT JOIN (x2) — country name | CountryID from Dim_Customer |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | LEFT JOIN (x2) — player status | PlayerStatusID from Dim_Customer |
| DWH_dbo.Dim_Regulation | DWH_dbo | LEFT JOIN (x2) — regulation name | DWHRegulationID from Dim_Customer |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | EXW_AMLProviderID / EXW_FactTransactions | RealCID | ISNULL(eai.RealCID, eft.RealCID) |
| GCID | EXW_AMLProviderID / EXW_FactTransactions | GCID | ISNULL(eai.GCID, eft.GCID) |
| Country | DWH_dbo.Dim_Country | Name | ISNULL from two Dim_Customer paths |
| Regulation | DWH_dbo.Dim_Regulation | Name | ISNULL from two Dim_Customer paths |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | ISNULL from two Dim_Customer paths |
| UserWalletAllowance | EXW_UserSettingsWalletAllowance | UserWalletAllowance | Passthrough |
| severity | External_Fivetran_google_sheets_kyt_alerts | severity | Passthrough |
| category | External_Fivetran_google_sheets_kyt_alerts | category | Passthrough |
| alert_created_at | External_Fivetran_google_sheets_kyt_alerts | alert_created_at | Passthrough |
| transfer_at | External_Fivetran_google_sheets_kyt_alerts | transfer_at | Passthrough |
| status | External_Fivetran_google_sheets_kyt_alerts | status | Passthrough |
| service_name | External_Fivetran_google_sheets_kyt_alerts | service_name | Passthrough |
| exposure | External_Fivetran_google_sheets_kyt_alerts | exposure | Passthrough |
| direction | External_Fivetran_google_sheets_kyt_alerts | direction | Passthrough |
| alert_amount | External_Fivetran_google_sheets_kyt_alerts | alert_amount | Passthrough |
| user_id | External_Fivetran_google_sheets_kyt_alerts | user_id | Passthrough (Base64-encoded GCID) |
| asset | External_Fivetran_google_sheets_kyt_alerts | asset | Passthrough |
| tx_hash | External_Fivetran_google_sheets_kyt_alerts | tx_hash | Passthrough |
| tx_index | External_Fivetran_google_sheets_kyt_alerts | tx_index | Passthrough |
| output_address | External_Fivetran_google_sheets_kyt_alerts | output_address | Passthrough |
| alert_type | External_Fivetran_google_sheets_kyt_alerts | alert_type | Passthrough |
| state | External_Fivetran_google_sheets_kyt_alerts | state | Passthrough |
| _of_transfer | External_Fivetran_google_sheets_kyt_alerts | _of_transfer | Passthrough |
| symbol | External_Fivetran_google_sheets_kyt_alerts | symbol | Passthrough |
| network | External_Fivetran_google_sheets_kyt_alerts | network | Passthrough |
| alert_id | External_Fivetran_google_sheets_kyt_alerts | alert_id | Passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |

*Generated: 2026-04-27*
