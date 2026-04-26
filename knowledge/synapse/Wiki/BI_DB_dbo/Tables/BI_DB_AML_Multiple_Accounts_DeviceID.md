# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID

> 758K-row AML detection table identifying device identifiers shared by 2 or more distinct eToro customers since January 2023. Each row represents one shared device — a potential AML signal for account farming, shared device fraud, or coordinated multi-account activity. Part of the Multiple Accounts detection suite written by SP_AML_Multiple_Accounts.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.STS_User_Operations_Data_History` (Session Tracking Service login audit log) |
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

`BI_DB_AML_Multiple_Accounts_DeviceID` identifies device IDs (client device fingerprints captured by the Session Tracking Service) that have been associated with 2 or more distinct eToro customers. When multiple people log into different accounts from the same device, it can signal account sharing, multi-account fraud, or a single operator controlling several customer accounts.

Each row represents one shared `ClientDeviceId` and its associated customer count (`NumOfClientsSameDeviceID`). The table covers login activity from January 2023 onwards and excludes the all-zeros null-sentinel GUID (`00000000-0000-0000-0000-000000000000`).

At 758,063 rows, this is the largest of the three "summary-level" Multiple Accounts tables (vs. 116K for Dep and 87K for SameIP). The high row count reflects that device sharing is a more common pattern than shared payment entities — shared devices may include family members, offices, or public computers, which AML analysts must distinguish from intentional fraud.

This table serves as the **input driver** for `BI_DB_AML_Multiple_Accounts_DeviceID_FullData`, which provides per-CID detail for each shared device.

---

## 2. Business Logic

### 2.1 Shared Device Detection

**What**: A device is flagged when 2 or more distinct customers have logged in from it since 2023.

**Columns Involved**: `ClientDeviceId`, `NumOfClientsSameDeviceID`

**Rules**:
- Source: `DWH_dbo.STS_User_Operations_Data_History` (Session Tracking Service login events)
- Filter: `DateID >= 20230101` — only login activity from 2023 onward is considered
- Exclude: `ClientDeviceId <> '00000000-0000-0000-0000-000000000000'` — the all-zeros GUID is a null-sentinel value assigned when the device ID is unavailable; excluded to prevent false positives
- Aggregate: `GROUP BY ClientDeviceId HAVING COUNT(DISTINCT RealCid) > 1`
- `NumOfClientsSameDeviceID` = the number of distinct customer IDs who logged in from this device since 2023

### 2.2 No Customer-Level Filtering

**What**: Unlike the Dep table, this table does NOT filter by VerificationLevelID, IsValidCustomer, or IsDepositor.

**Rules**:
- Any customer who logged in from a shared device appears in the DeviceID_FullData table
- This broader scope captures potential fraud activity even from unverified accounts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 758K rows. Full table scans are reasonably fast. For joining with large tables, consider filtering first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| High-risk devices (many users) | `WHERE NumOfClientsSameDeviceID > 10 ORDER BY NumOfClientsSameDeviceID DESC` |
| Expand to customer detail | JOIN BI_DB_AML_Multiple_Accounts_DeviceID_FullData ON ClientDeviceId |
| Distribution of sharing counts | `GROUP BY NumOfClientsSameDeviceID ORDER BY 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData | ON ClientDeviceId | Expand to per-customer detail rows |
| DWH_dbo.STS_User_Operations_Data_History | ON ClientDeviceId | Raw login events for this device |

### 3.4 Gotchas

- **2023+ only**: Only login activity from DateID >= 20230101. Devices that were only shared before 2023 are not captured.
- **Not in daily ETL**: Data may be stale — check UpdateDate.
- **All-zeros GUID excluded**: The null-sentinel ClientDeviceId is not in this table. Queries that JOIN to STS_User_Operations_Data_History will see rows with the all-zeros GUID — don't join them back.
- **Minimum 2 customers**: Devices used by only 1 customer are excluded.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| NumOfClientsSameDeviceID | int | Number of distinct customers (RealCid) who logged in from this device since 2023 | DWH_dbo.STS_User_Operations_Data_History | COUNT(DISTINCT RealCid); minimum 2 |
| ClientDeviceId | nvarchar(250) | Device identifier from the Session Tracking Service login audit log | DWH_dbo.STS_User_Operations_Data_History | Excludes all-zeros null-sentinel GUID |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() at SP execution time |

---

## 5. Lineage

```
DWH_dbo.STS_User_Operations_Data_History
    WHERE DateID >= 20230101
      AND ClientDeviceId <> '00000000-0000-0000-0000-000000000000'
    GROUP BY ClientDeviceId
    HAVING COUNT(DISTINCT RealCid) > 1
    └─ SP_AML_Multiple_Accounts (Step 15) → BI_DB_AML_Multiple_Accounts_DeviceID
```

See full column lineage: `BI_DB_AML_Multiple_Accounts_DeviceID.lineage.md`

**UC**: Not_Migrated.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData | ON ClientDeviceId | Per-customer detail for each shared device |
| DWH_dbo.STS_User_Operations_Data_History | ON ClientDeviceId | Source login event data |

---

## 7. Sample Queries

```sql
-- Most-shared devices (highest customer counts)
SELECT ClientDeviceId, NumOfClientsSameDeviceID, UpdateDate
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID]
ORDER BY NumOfClientsSameDeviceID DESC

-- Sharing count distribution
SELECT NumOfClientsSameDeviceID, COUNT(*) AS num_devices
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID]
GROUP BY NumOfClientsSameDeviceID
ORDER BY NumOfClientsSameDeviceID

-- Expand specific device to customer list
SELECT did.ClientDeviceId, did.NumOfClientsSameDeviceID,
       full.CID, full.AlertType, full.StatusType, full.CategoryName
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID] did
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_DeviceID_FullData] full
  ON did.ClientDeviceId = full.ClientDeviceId
WHERE did.NumOfClientsSameDeviceID > 10
ORDER BY did.NumOfClientsSameDeviceID DESC, did.ClientDeviceId, full.CID
```

---

## 8. Atlassian

No Confluence pages found specifically for this table. Part of the AML Multiple Accounts detection suite. SP authored by Lior Ben Dor (2023-11-13). Contact the AML Analytics team for process documentation.
