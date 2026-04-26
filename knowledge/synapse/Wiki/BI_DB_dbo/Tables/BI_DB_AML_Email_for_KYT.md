# BI_DB_dbo.BI_DB_AML_Email_for_KYT

> **DECOMMISSIONED** — 0-row AML crypto compliance feed table that was populated from KYT (Know Your Transaction) blockchain risk alerts via a Fivetran/Google Sheets data pipeline. The writer SP carries a JUNK_ prefix (intentional decommission marker) and the table is empty. Do not use for analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Status** | DECOMMISSIONED — 0 rows; writer SP is `JUNK_SP_AML_Email_for_KYT` |
| **Production Source** | `External_Fivetran_google_sheets_kyt_alerts` (KYT alert feed via Fivetran/Google Sheets) |
| **Refresh** | None — pipeline is decommissioned |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_AML_Email_for_KYT` was a compliance feed table that received Know Your Transaction (KYT) blockchain risk alerts from an external KYT provider (delivered via Google Sheets, ingested by Fivetran), and joined them with eToro customer identity to produce a compliance-ready view. The intent was to support AML monitoring for crypto-related customer activity by enriching provider-issued alerts with eToro CID, country, regulation, and account status.

KYT (Know Your Transaction) is a crypto AML compliance framework where a third-party provider analyzes blockchain transactions in real time and flags transfers involving high-risk counterparties (darknet markets, mixers, sanctions-listed addresses, etc.). Each alert from the provider carries a severity (Low/Medium/High/Critical), category, and blockchain metadata (tx_hash, asset, network, wallet address).

The table was populated by `JUNK_SP_AML_Email_for_KYT`, which resolved the KYT provider's `user_id` (a blockchain address or provider-side identifier) to an eToro CID via `EXW_dbo.EXW_AMLProviderID`, and further enriched the record with `Dim_Customer`, `Dim_PlayerStatus`, `Dim_Country`, and `Dim_Regulation` lookups.

The table is now **permanently decommissioned**: 0 rows live, SP carries the JUNK_ prefix. The KYT alert feed may have moved to a different pipeline or integrated differently.

---

## 2. Business Logic

### 2.1 KYT Identity Resolution

**What**: The KYT provider identifies users by a blockchain address or provider-specific user identifier, not by eToro CID. The SP resolved this to an eToro identity.

**Columns Involved**: `user_id`, `CID`, `GCID`

**Rules**:
- SP joined `EXW_dbo.EXW_AMLProviderID` using `ProviderUserIDNormalized = kk.user_id COLLATE Latin1_General_100_BIN` — the COLLATE clause was required to handle case-sensitivity in blockchain address matching
- LEFT JOIN only: if no identity match was found, the row was still included (CID/GCID = NULL)

### 2.2 Transaction Enrichment

**What**: Blockchain transaction metadata from the KYT feed was further enriched with transaction data from EXW.

**Columns Involved**: `tx_hash`, `tx_index`, `output_address`, `asset`, `network`, `symbol`

**Rules**:
- SP LEFT JOINed `EXW_dbo.EXW_FactTransactions ON BlockchainTransactionId = kk.tx_hash` to link KYT alert transactions to eToro's own blockchain transaction records
- If no matching transaction found, blockchain columns remain as passed through from the KYT feed

### 2.3 Alert Risk Classification

**What**: Each KYT alert row includes risk classification fields from the provider.

**Columns Involved**: `severity`, `category`, `alert_type`, `exposure`, `direction`

**Rules**:
- `severity`: Provider-assigned risk level (Low/Medium/High/Critical)
- `exposure`: Direct (customer directly transacted with high-risk entity) vs. Indirect (counterparty of counterparty)
- `direction`: Sent (outgoing transfer) or Received (incoming transfer)
- `_of_transfer`: The fraction of the transfer amount that is attributable to the high-risk exposure (e.g., 0.45 = 45% of the transaction is from a flagged source)

---

## 3. Query Advisory

### 3.1 Decommissioned — No Live Data

This table is empty (0 rows). Any query will return zero results. The table exists in SSDT/Synapse schema only because the DDL was not dropped.

### 3.2 Do Not Use for Analysis

Do not reference this table in dashboards or investigations. The KYT alert pipeline it served has been decommissioned. Contact the AML team for the current KYT alert data source.

### 3.3 Synapse Distribution & Index

ROUND_ROBIN HEAP. Empty table — no distribution considerations apply.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| CID | int | eToro customer Real account ID, resolved from KYT provider user_id via EXW_AMLProviderID | EXW_dbo.EXW_AMLProviderID | NULL if provider user_id could not be matched to an eToro identity |
| GCID | int | Global customer ID | DWH_dbo.Dim_Customer | NULL if CID not found |
| Country | nvarchar(250) | Customer country of residence | DWH_dbo.Dim_Country | Resolved via Dim_Customer.CountryID |
| Regulation | nvarchar(250) | Customer regulatory jurisdiction | DWH_dbo.Dim_Regulation | Resolved via Dim_Customer.RegulationID |
| PlayerStatus | nvarchar(250) | Account status at time of ETL run | DWH_dbo.Dim_PlayerStatus | Resolved via Dim_Customer.PlayerStatusID |
| UserWalletAllowance | nvarchar(max) | Customer's eToro Wallet allowance setting | EXW_dbo.EXW_UserSettingsWalletAllowance | NULL if customer has no wallet |
| severity | nvarchar(250) | KYT alert severity level (Low/Medium/High/Critical) | KYT provider feed | Provider-assigned |
| category | nvarchar(250) | KYT alert category classification | KYT provider feed | Provider-assigned |
| alert_created_at | datetime | When the KYT provider raised this alert | KYT provider feed | Provider timestamp |
| transfer_at | datetime | When the blockchain transfer occurred | KYT provider feed | Provider timestamp |
| status | nvarchar(250) | Alert resolution status (active/resolved/etc.) | KYT provider feed | Provider-assigned |
| service_name | nvarchar(250) | KYT service name that generated the alert | KYT provider feed | Provider name |
| exposure | nvarchar(250) | Risk exposure type: Direct (1-hop) or Indirect (2+ hops to high-risk entity) | KYT provider feed | Provider-assigned |
| direction | nvarchar(250) | Transfer direction: Sent (outgoing) or Received (incoming) | KYT provider feed | Provider-assigned |
| alert_amount | float | USD amount involved in the flagged transfer | KYT provider feed | May be NULL for some alert types |
| user_id | nvarchar(max) | KYT provider's user identifier — typically a blockchain wallet address | KYT provider feed | Used to match to EXW_AMLProviderID |
| asset | nvarchar(250) | Cryptocurrency asset type (BTC, ETH, etc.) | KYT provider feed | Provider-assigned |
| tx_hash | nvarchar(max) | Blockchain transaction hash | KYT provider feed | Used to join EXW_FactTransactions |
| tx_index | int | Transaction index within its block | KYT provider feed | Provider-assigned |
| output_address | nvarchar(max) | Destination blockchain wallet address for this transfer | KYT provider feed | Provider-assigned |
| alert_type | nvarchar(250) | KYT alert type/classification | KYT provider feed | Provider-assigned |
| state | nvarchar(250) | Internal processing state of the alert | KYT provider feed | Provider-assigned |
| _of_transfer | float | Fraction of the transfer amount attributable to high-risk exposure (0.0–1.0) | KYT provider feed | Leading underscore: ETL artifact from column name sanitization |
| symbol | nvarchar(max) | Cryptocurrency ticker symbol (BTC, ETH, USDT, etc.) | KYT provider feed | Provider-assigned |
| network | nvarchar(250) | Blockchain network (Bitcoin, Ethereum, Tron, etc.) | KYT provider feed | Provider-assigned |
| alert_id | nvarchar(max) | Unique alert identifier from the KYT provider | KYT provider feed | Provider-assigned primary key |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() — decommissioned; no live updates |

---

## 5. Lineage

```
Google Sheets KYT Alert Feed (Fivetran ingestion)
    └─ External_Fivetran_google_sheets_kyt_alerts
        ├── LEFT JOIN EXW_dbo.EXW_AMLProviderID  [user_id → CID resolution]
        ├── LEFT JOIN EXW_dbo.EXW_FactTransactions  [tx_hash enrichment]
        ├── LEFT JOIN EXW_dbo.EXW_UserSettingsWalletAllowance
        ├── LEFT JOIN DWH_dbo.Dim_Customer (×2)
        ├── LEFT JOIN DWH_dbo.Dim_PlayerStatus (×2)
        ├── LEFT JOIN DWH_dbo.Dim_Country (×2)
        ├── LEFT JOIN DWH_dbo.Dim_Regulation (×2)
        └─ JUNK_SP_AML_Email_for_KYT → BI_DB_AML_Email_for_KYT [DECOMMISSIONED]
```

**UC**: Not_Migrated. Table is decommissioned and will not be deployed to Unity Catalog.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer profile enrichment |
| EXW_dbo.EXW_AMLProviderID | ON user_id (normalized) | KYT identity resolution |
| EXW_dbo.EXW_FactTransactions | ON tx_hash = BlockchainTransactionId | Blockchain transaction lookup |

---

## 7. Sample Queries

> **Note**: Table is empty (0 rows). These queries are illustrative only.

```sql
-- Schema inspection only — confirm decommissioned status
SELECT COUNT(*) AS row_count FROM [BI_DB_dbo].[BI_DB_AML_Email_for_KYT]
-- Returns: 0

-- Column list
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'BI_DB_dbo' AND TABLE_NAME = 'BI_DB_AML_Email_for_KYT'
ORDER BY ORDINAL_POSITION
```

---

## 8. Atlassian

No active Confluence pages found for this table. The KYT pipeline it served is decommissioned. For current KYT/crypto AML processes, contact the AML/Compliance team.
