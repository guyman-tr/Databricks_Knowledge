# BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT

> 267-row crypto compliance KYT (Know Your Transaction) alert report used to generate weekly emails to the Wallet/AML compliance team. Each row is a blockchain transaction alert from the KYT provider (via Fivetran Google Sheets), enriched with customer identity (CID/GCID resolved from EXW_AMLProviderID or EXW_FactTransactions), wallet allowance status, country, regulation, and player status. Refreshed daily via TRUNCATE+INSERT by SP_W_Tue_Email_for_KYT (SB_Daily).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Fivetran_google_sheets_kyt_alerts (primary) + EXW_AMLProviderID + EXW_FactTransactions + EXW_UserSettingsWalletAllowance + Dim_Customer + Dim_Country + Dim_PlayerStatus + Dim_Regulation via SP_W_Tue_Email_for_KYT |
| **Refresh** | Daily TRUNCATE+INSERT via SB_Daily |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a compliance-facing KYT (Know Your Transaction) alert report for blockchain/crypto transaction monitoring. It consolidates alerts from an external KYT provider (ingested via Fivetran from Google Sheets) and enriches each alert with eToro customer identity and account details.

Each row represents one blockchain transaction alert. The alerts flag suspicious crypto transactions involving categories like darknet markets, fraud shops, drug vendors, child abuse material, sanctioned entities, and no-KYC exchanges.

The SP resolves the KYT provider's Base64-encoded user_id to an eToro CID through two paths:
1. **EXW_AMLProviderID**: matches the provider's user_id against the AML provider user ID (primary)
2. **EXW_FactTransactions**: falls back to matching by tx_hash + output_address if the provider ID match fails

The table currently contains 267 alerts, mostly Bitcoin (BTC) and TRON (TRX) transactions flagged at MEDIUM or SEVERE severity, predominantly in "Unreviewed" status.

Author: Lior Ben Dor (created 2024-06-13).

---

## 2. Business Logic

### 2.1 Dual-Path Customer Resolution

**What**: Resolves KYT provider user_id to eToro CID via two fallback paths.
**Columns Involved**: CID, GCID, user_id
**Rules**:
- Path 1: LEFT JOIN EXW_AMLProviderID ON user_id = ProviderUserIDNormalized OR ProviderUserID (case-insensitive)
- Path 2 (fallback): LEFT JOIN EXW_FactTransactions ON tx_hash = BlockchainTransactionId AND output_address = ReciverAddress AND GCID > 0 — only when Path 1 returns NULL
- CID = ISNULL(path1.RealCID, path2.RealCID)
- GCID = ISNULL(path1.GCID, path2.GCID)

### 2.2 Customer Enrichment (Dual Dim_Customer Join)

**What**: Enriches with country, regulation, and player status from whichever Dim_Customer path resolved.
**Columns Involved**: Country, Regulation, PlayerStatus
**Rules**:
- Two parallel Dim_Customer JOINs: one for each resolution path
- Country = ISNULL(dc1_country, dc2_country)
- Same ISNULL pattern for Regulation and PlayerStatus

### 2.3 Wallet Allowance Status

**What**: Shows the customer's wallet permission level.
**Columns Involved**: UserWalletAllowance
**Rules**:
- Joined via GCID from EXW_AMLProviderID path only
- Values: Allowed, NotAllowed, ReadOnly

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — 267 rows, trivially small. No performance concerns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Alert count by severity and category | `GROUP BY severity, category` |
| Unreviewed alerts requiring action | `WHERE status = 'Unreviewed'` |
| Alerts by regulation | `GROUP BY Regulation` |
| High-value alerts | `ORDER BY alert_amount DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| EXW_dbo.EXW_FactTransactions | tx_hash match | Full transaction details |

### 3.4 Gotchas

- **user_id is Base64-encoded GCID**: Not a plain customer ID — decode with Base64 to get the numeric GCID
- **CID/GCID can be NULL**: If neither resolution path matches, the alert is orphaned (no eToro customer match)
- **alert_created_at and transfer_at are strings**: Not datetime — stored as nvarchar(250) with inconsistent date formats (DD/MM/YYYY HH:MM vs YYYY-MM-DD HH:MM:SS)
- **_of_transfer column name**: Leading underscore — likely "% of transfer" with the "%" stripped during ingestion
- **Small table**: Only 267 rows — this is an operational compliance table, not an analytics dataset

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data sampling |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Standard ETL metadata or infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID resolved from KYT provider user_id. ISNULL(EXW_AMLProviderID.RealCID, EXW_FactTransactions.RealCID). NULL if no customer match found. (Tier 2 — SP_W_Tue_Email_for_KYT) |
| 2 | GCID | int | YES | Group Customer ID resolved alongside CID. ISNULL(EXW_AMLProviderID.GCID, EXW_FactTransactions.GCID). NULL if no customer match. (Tier 2 — SP_W_Tue_Email_for_KYT) |
| 3 | Country | nvarchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from Dim_Country via whichever Dim_Customer path matched. (Tier 1 — Dictionary.Country) |
| 4 | Regulation | nvarchar(250) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Resolved via whichever Dim_Customer path matched. (Tier 1 — Dictionary.Regulation) |
| 5 | PlayerStatus | nvarchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. (Tier 1 — Dictionary.PlayerStatus) |
| 6 | UserWalletAllowance | nvarchar(max) | YES | Customer's crypto wallet permission level from EXW_UserSettingsWalletAllowance. Values: Allowed, NotAllowed, ReadOnly. NULL if not resolved. (Tier 2 — SP_W_Tue_Email_for_KYT via EXW_UserSettingsWalletAllowance) |
| 7 | severity | nvarchar(250) | YES | KYT alert severity level from the provider. Values: SEVERE, MEDIUM. Indicates the risk level of the flagged transaction. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 8 | category | nvarchar(250) | YES | KYT alert category describing the type of suspicious activity. Values: darknet market, fraud shop, drug vendor, child abuse material, no kyc exchange, sanctions, ransomware, scam, etc. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 9 | alert_created_at | nvarchar(250) | YES | Timestamp when the KYT alert was created by the provider. Stored as string with inconsistent formats (DD/MM/YYYY HH:MM or YYYY-MM-DD HH:MM:SS). (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 10 | transfer_at | nvarchar(250) | YES | Timestamp when the blockchain transfer occurred. Stored as string with inconsistent date formats. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 11 | status | nvarchar(250) | YES | Review status of the alert. Values: Unreviewed, Reviewed, Dismissed. Indicates compliance team action state. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 12 | service_name | nvarchar(250) | YES | Name of the counterparty service identified by the KYT provider. Examples: YoBit.net, Hydra. NULL/blank if unknown or indirect exposure. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 13 | exposure | nvarchar(250) | YES | Exposure type to the suspicious entity. Values: DIRECT (transacted directly), INDIRECT (transacted with an intermediary that transacted with the entity). (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 14 | direction | nvarchar(250) | YES | Transaction direction relative to the customer. Values: SENT (outgoing), RECEIVED (incoming). (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 15 | alert_amount | float | YES | Transaction amount in the native cryptocurrency denomination that triggered the alert. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 16 | user_id | nvarchar(max) | YES | KYT provider's Base64-encoded user identifier. Decodes to the numeric GCID. Used for customer resolution via EXW_AMLProviderID. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 17 | asset | nvarchar(250) | YES | Cryptocurrency asset code. Values: BTC, TRX, ETH, etc. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 18 | tx_hash | nvarchar(max) | YES | Blockchain transaction hash — unique identifier for the on-chain transaction. Used for fallback customer resolution via EXW_FactTransactions. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 19 | tx_index | int | YES | Output index within the blockchain transaction. Identifies the specific output in multi-output transactions (e.g., UTXO model). (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 20 | output_address | nvarchar(max) | YES | Destination blockchain wallet address for the transaction. Used with tx_hash for fallback customer resolution. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 21 | alert_type | nvarchar(250) | YES | Type of alert. Values: TRANSFER. Indicates the nature of the flagged activity. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 22 | state | nvarchar(250) | YES | Transaction validity state. Values: VALID. Indicates whether the blockchain transaction was confirmed. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 23 | _of_transfer | float | YES | Percentage of the transfer amount associated with the suspicious exposure. Likely "% of transfer" with the percent sign stripped during ingestion. Range 0-100. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 24 | symbol | nvarchar(max) | YES | Cryptocurrency ticker symbol. Same as asset in most cases (BTC, TRX, ETH). (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 25 | network | nvarchar(250) | YES | Blockchain network name. Values: BITCOIN, TRON, ETHEREUM, etc. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 26 | alert_id | nvarchar(max) | YES | Unique identifier for the KYT alert in UUID format. Primary key from the KYT provider system. (Tier 4 — External_Fivetran_google_sheets_kyt_alerts) |
| 27 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, GCID | EXW_AMLProviderID / EXW_FactTransactions | RealCID, GCID | Dual-path ISNULL resolution |
| Country | Dictionary.Country | Name | Via Dim_Country dim lookup |
| Regulation | Dictionary.Regulation | Name | Via Dim_Regulation dim lookup |
| PlayerStatus | Dictionary.PlayerStatus | Name | Via Dim_PlayerStatus dim lookup |
| UserWalletAllowance | EXW_UserSettingsWalletAllowance | UserWalletAllowance | Passthrough |
| 16 alert columns | External KYT provider (Google Sheets via Fivetran) | Various | Passthrough |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
External KYT Provider → Google Sheets → Fivetran
  v
External_Fivetran_google_sheets_kyt_alerts (external table, BI_DB_dbo)
  + EXW_dbo.EXW_AMLProviderID (LEFT JOIN user_id → RealCID/GCID, primary path)
  + EXW_dbo.EXW_FactTransactions (LEFT JOIN tx_hash+output_address → RealCID/GCID, fallback)
  + EXW_dbo.EXW_UserSettingsWalletAllowance (LEFT JOIN GCID → wallet allowance)
  + DWH_dbo.Dim_Customer (x2, LEFT JOIN → CountryID, PlayerStatusID, RegulationID)
  + DWH_dbo.Dim_Country (x2), Dim_PlayerStatus (x2), Dim_Regulation (x2)
    |-- #final (HASH(CID)) ---|
    v
  TRUNCATE TABLE BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT
  INSERT INTO BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| GCID | DWH_dbo.Dim_Customer.GCID | Group customer identity |
| tx_hash | EXW_dbo.EXW_FactTransactions.BlockchainTransactionId | Blockchain transaction |
| user_id | EXW_dbo.EXW_AMLProviderID.ProviderUserIDNormalized | AML provider mapping |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none identified) | — | Terminal compliance email report |

---

## 7. Sample Queries

### 7.1 Severe Alerts by Category

```sql
SELECT category, COUNT(*) AS alert_count,
       SUM(alert_amount) AS total_amount
FROM BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT
WHERE severity = 'SEVERE'
GROUP BY category
ORDER BY alert_count DESC
```

### 7.2 Unreviewed Alerts with Customer Details

```sql
SELECT CID, Country, Regulation, RTRIM(PlayerStatus) AS PlayerStatus,
       severity, category, asset, alert_amount, alert_created_at
FROM BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT
WHERE status = 'Unreviewed'
ORDER BY CASE WHEN severity = 'SEVERE' THEN 1 ELSE 2 END, alert_amount DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 3 T1, 3 T2, 0 T3, 20 T4, 1 T5 | Elements: 27/27, Logic: 7/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT | Type: Table | Production Source: External_Fivetran_google_sheets_kyt_alerts via SP_W_Tue_Email_for_KYT*
