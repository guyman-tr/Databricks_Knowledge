# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData

> 2.5M-row AML detection table providing per-customer context for every customer who shares a device ID with at least one other eToro customer (since January 2023). One row per (ClientDeviceId, CID) pair, enriched with the customer's latest Alert Service record. The "detail" companion to BI_DB_AML_Multiple_Accounts_DeviceID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.STS_User_Operations_Data_History` (login sessions) + `External_AlertServiceDB_*` (alert data) |
| **Refresh** | On-demand — SP_AML_Multiple_Accounts is not in the standard OpsDB SB_Daily schedule |
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

`BI_DB_AML_Multiple_Accounts_DeviceID_FullData` is the **customer-level expansion** of the device-sharing AML detection. Where `BI_DB_AML_Multiple_Accounts_DeviceID` provides one row per shared device, this table provides one row per *customer per device* — enabling AML analysts to see the alert status and history for every account that used a flagged shared device.

With 2,485,792 rows, this is the largest table in the Multiple Accounts suite, reflecting that device sharing is more prevalent than payment or IP sharing. Each row links a CID to the ClientDeviceId they shared, plus the customer's most recent alert from the Alert Service (one alert per CID, selected by most-recent ModificationDate).

**Key characteristics**:
- 62% of rows have no recorded alert (AlertType/StatusType/CategoryName = NULL) — most device-sharing customers have no active AML flag
- 38% have at least one alert; most common: AccountStatusChange (27% of all rows), HighRiskLogin (3%), KycRelations (1.6%)
- Alert categories: eToroMoney (27%), KYC (5%), Risk (5%), AML (<1%), Cashouts (<1%)
- Alert status: Active (32%), Clear (6.4%), Follow Up (<0.1%), NULL (62%)

This table is the primary investigation tool for the device-sharing workflow: start from a high-risk device in `_DeviceID`, then pull the customer list from `_DeviceID_FullData` to triage by alert status and investigate individuals.

---

## 2. Business Logic

### 2.1 Population: All CIDs Using Shared Devices

**What**: Any customer who logged in from a device shared with at least one other customer (since 2023) is included.

**Columns Involved**: `CID`, `ClientDeviceId`

**Rules**:
- Driving set: BI_DB_AML_Multiple_Accounts_DeviceID (all shared DeviceIDs)
- Join back to STS_User_Operations_Data_History ON ClientDeviceId to get all CIDs per device
- No VerificationLevelID filter (unlike the Dep tables) — unverified customers are included
- Same DateID >= 20230101 cutoff applies

### 2.2 Latest Alert Enrichment (Per CID)

**What**: Each CID in the population is enriched with its most recent alert.

**Columns Involved**: `AlertID`, `CreationDate`, `ModificationDate`, `AlertType`, `AlertTypeDescription`, `CategoryName`, `TriggerType`, `StatusType`, `StatusReason`

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ModificationDate DESC) = 1` selects the single most-recent alert per CID
- If a CID has multiple devices (appears multiple times in this table), the SAME latest alert is repeated for each device row
- NULL alert = no alert recorded for this CID in the Alert Service
- `StatusType` interpretation: Active (still under review), Clear (resolved, no action needed), Follow Up (requires additional attention)

### 2.3 Alert Category Semantics

**What**: CategoryName classifies the domain that triggered the alert.

**Columns Involved**: `CategoryName`, `AlertType`

**Rules**:
- `eToroMoney` (27% of rows): Alert triggered by wallet-related activity
- `KYC` (5%): Alert triggered by verification status change
- `Risk` (5%): Alert triggered by risk-scoring system
- `AML` (<1%): Direct AML team-generated alert
- `Cashouts` (<1%): Alert triggered by withdrawal-related activity
- `Trading` (<0.1%): Alert triggered by trading activity
- `Deposits` (<0.1%): Alert triggered by deposit activity
- NULL (62%): No alert on record

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 2.5M rows. Full scans are manageable but JOIN heavy queries should filter first. For joining with DWH fact tables, use a CID-filtered subquery or CTAS to a HASH-distributed temp table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers with active alerts on shared devices | `WHERE StatusType = 'Active'` |
| High-risk device investigation | JOIN _DeviceID ON ClientDeviceId, filter `WHERE did.NumOfClientsSameDeviceID > 10` |
| AML-category alerts on shared devices | `WHERE CategoryName = 'AML' AND StatusType = 'Active'` |
| Count distinct CIDs per shared device | `GROUP BY ClientDeviceId, COUNT(DISTINCT CID)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID | ON ClientDeviceId | Get device-level summary (NumOfClientsSameDeviceID) |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile |
| DWH_dbo.STS_User_Operations_Data_History | ON CID=RealCid AND ClientDeviceId | Specific login events |

### 3.4 Gotchas

- **Alert deduplication**: One alert per CID (most recent). A CID with 3 different shared devices appears 3 times in this table — all 3 rows show the same latest alert (risk of overcounting alerts in aggregations).
- **NULL majority**: 62% of rows have no alert. Filter `WHERE AlertType IS NOT NULL` to focus on flagged customers.
- **Not in daily ETL**: Data may be stale — check UpdateDate.
- **Large table**: 2.5M rows — apply WHERE filters before aggregating or joining to large DWH tables.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| CID | int | eToro customer Real account ID | DWH_dbo.STS_User_Operations_Data_History (RealCid) | Part of composite key with ClientDeviceId |
| ClientDeviceId | nvarchar(250) | Device identifier shared by this and at least one other customer — links to BI_DB_AML_Multiple_Accounts_DeviceID | DWH_dbo.STS_User_Operations_Data_History | Part of composite key with CID |
| AlertID | nvarchar | Latest Alert Service alert identifier for this CID | External_AlertServiceDB | NULL for 62% of rows (no alert on record) |
| CreationDate | datetime | When the latest alert was first created | External_AlertServiceDB | NULL if no alert |
| ModificationDate | datetime | When the latest alert was last modified (used for recency selection) | External_AlertServiceDB | NULL if no alert |
| AlertType | nvarchar(250) | Alert classification type: AccountStatusChange (27%), HighRiskLogin (3%), KycRelations (1.6%), PossibleCompromisedAccount (0.9%), etc. | External_AlertServiceDB | NULL for 62% of rows |
| AlertTypeDescription | nvarchar(250) | Human-readable description of AlertType | External_AlertServiceDB | NULL if no alert |
| CategoryName | nvarchar(250) | Alert category domain: eToroMoney (27%), KYC (5%), Risk (5%), AML (<1%), Cashouts (<1%), Trading (<0.1%), Deposits (<0.1%) | External_AlertServiceDB | NULL for 62% of rows |
| TriggerType | nvarchar(250) | What event triggered the alert | External_AlertServiceDB | NULL if no alert |
| StatusType | nvarchar(250) | Alert resolution status: Active (32%), Clear (6.4%), Follow Up (<0.1%) | External_AlertServiceDB | NULL for 62% of rows |
| StatusReason | nvarchar(250) | Reason for current alert status | External_AlertServiceDB | NULL if no alert or no reason set |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() at SP execution time |

---

## 5. Lineage

```
BI_DB_AML_Multiple_Accounts_DeviceID (shared ClientDeviceId population)
    → STS_User_Operations_Data_History JOIN on ClientDeviceId → all CIDs per device
    → External_AlertServiceDB_* (ROW_NUMBER latest per CID) → alert data
    └─ SP_AML_Multiple_Accounts (Step 16) → BI_DB_AML_Multiple_Accounts_DeviceID_FullData
```

See full column lineage: `BI_DB_AML_Multiple_Accounts_DeviceID_FullData.lineage.md`

**UC**: Not_Migrated.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID | ON ClientDeviceId | Parent device summary table |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer profile enrichment |
| DWH_dbo.STS_User_Operations_Data_History | ON CID=RealCid AND ClientDeviceId | Raw session/login events |

---

## 7. Sample Queries

```sql
-- Customers with active AML or KYC alerts on shared devices
SELECT full.CID, full.ClientDeviceId, full.AlertType,
       full.CategoryName, full.StatusType, full.ModificationDate
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID_FullData] full
WHERE full.StatusType = 'Active'
  AND full.CategoryName IN ('AML', 'KYC', 'Risk')
ORDER BY full.ModificationDate DESC

-- Most-shared devices with at least one active alert customer
SELECT did.ClientDeviceId, did.NumOfClientsSameDeviceID,
       COUNT(DISTINCT CASE WHEN full.StatusType = 'Active' THEN full.CID END) AS active_alert_customers
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID] did
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID_FullData] full
  ON did.ClientDeviceId = full.ClientDeviceId
GROUP BY did.ClientDeviceId, did.NumOfClientsSameDeviceID
HAVING COUNT(DISTINCT CASE WHEN full.StatusType = 'Active' THEN full.CID END) > 0
ORDER BY did.NumOfClientsSameDeviceID DESC

-- Alert type breakdown for shared-device customers
SELECT AlertType, CategoryName, COUNT(*) AS cnt,
       COUNT(CASE WHEN StatusType = 'Active' THEN 1 END) AS active
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID_FullData]
WHERE AlertType IS NOT NULL
GROUP BY AlertType, CategoryName
ORDER BY cnt DESC
```

---

## 8. Atlassian

No Confluence pages found specifically for this table. Part of the AML Multiple Accounts detection suite. SP authored by Lior Ben Dor (2023-11-13). Contact the AML Analytics team for process documentation.
