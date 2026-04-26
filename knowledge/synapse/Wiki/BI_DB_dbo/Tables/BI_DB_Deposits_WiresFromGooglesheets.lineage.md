# BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets |
| **Writer SP** | BI_DB_dbo.SP_H_Deposits_Wires_From_Googlesheet |
| **Author** | Guy Manova (2021-02-18) |
| **Primary Source** | BI_DB_dbo.External_Fivetran_google_sheets_wire_deposits_ops (Google Sheets via Fivetran) |
| **Load Pattern** | Hourly/Daily TRUNCATE + INSERT (no history) |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Account ID | External_Fivetran_google_sheets_wire_deposits_ops | — | Hardcoded NULL | Tier 2 |
| 2 | Amount received | External_Fivetran_google_sheets_wire_deposits_ops | amount_received | CASE LIKE '%N%' THEN '0' (null cleanup) | Tier 2 |
| 3 | Assignee Name | External_Fivetran_google_sheets_wire_deposits_ops | assignee_name | Passthrough | Tier 2 |
| 4 | Bank reference number | External_Fivetran_google_sheets_wire_deposits_ops | bank_reference_number | Passthrough | Tier 2 |
| 5 | CID | External_Fivetran_google_sheets_wire_deposits_ops | cid | CASE LIKE '%N%' THEN '1' (null cleanup) | Tier 2 |
| 6 | Client Bank Name | External_Fivetran_google_sheets_wire_deposits_ops | client_bank_name | Passthrough | Tier 2 |
| 7 | Comments | External_Fivetran_google_sheets_wire_deposits_ops | comments | Passthrough | Tier 2 |
| 8 | Country | External_Fivetran_google_sheets_wire_deposits_ops | country | Passthrough | Tier 2 |
| 9 | Currency | External_Fivetran_google_sheets_wire_deposits_ops | currency | Passthrough | Tier 2 |
| 10 | Date received | External_Fivetran_google_sheets_wire_deposits_ops | date_received | Passthrough | Tier 2 |
| 11 | Deposit ID | External_Fivetran_google_sheets_wire_deposits_ops | deposit_id | CASE LIKE '%N%' THEN '1' (null cleanup) | Tier 2 |
| 12 | eToro Bank Name | External_Fivetran_google_sheets_wire_deposits_ops | e_toro_bank_name | Passthrough | Tier 2 |
| 13 | Full description for MEMO BO | External_Fivetran_google_sheets_wire_deposits_ops | full_description_for_memo_bo | Passthrough | Tier 2 |
| 14 | IBAN / Account number | External_Fivetran_google_sheets_wire_deposits_ops | iban_account_number | Passthrough | Tier 2 |
| 15 | Pool date added | External_Fivetran_google_sheets_wire_deposits_ops | pool_date_added_ | Passthrough | Tier 2 |
| 16 | Pool date deducted | External_Fivetran_google_sheets_wire_deposits_ops | pool_date_deducted | Passthrough | Tier 2 |
| 17 | Processed date in BO | External_Fivetran_google_sheets_wire_deposits_ops | processed_date_in_bo | Passthrough | Tier 2 |
| 18 | Rate | External_Fivetran_google_sheets_wire_deposits_ops | rate | CASE LIKE '%N%' THEN '0' (null cleanup) | Tier 2 |
| 19 | Regulation | External_Fivetran_google_sheets_wire_deposits_ops | regulation | Passthrough | Tier 2 |
| 20 | Return date | External_Fivetran_google_sheets_wire_deposits_ops | return_date | Passthrough | Tier 2 |
| 21 | Status | External_Fivetran_google_sheets_wire_deposits_ops | status | Passthrough | Tier 2 |
| 22 | Swift Code | External_Fivetran_google_sheets_wire_deposits_ops | swift_code | Passthrough | Tier 2 |
| 23 | Ticket number | External_Fivetran_google_sheets_wire_deposits_ops | ticket_number | Passthrough | Tier 2 |
| 24 | Transaction name originator/Payment recipient | External_Fivetran_google_sheets_wire_deposits_ops | transaction_name_originator_payment_recipient | Passthrough | Tier 2 |
| 25 | USD amount | External_Fivetran_google_sheets_wire_deposits_ops | usd_amount | CASE LIKE '%N%' THEN '0' (null cleanup) | Tier 2 |
| 26 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| BI_DB_dbo.External_Fivetran_google_sheets_wire_deposits_ops | External Table (Fivetran) | Google Sheets wire deposit operations working file |
