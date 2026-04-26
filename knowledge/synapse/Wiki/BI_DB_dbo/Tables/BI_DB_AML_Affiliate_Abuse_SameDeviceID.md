# BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID

> Device-sharing risk table for AML affiliate abuse monitoring — 74 rows of affiliate + device groups where multiple distinct customers share a device ID, written by SP_AML_Affiliate_Abuse (disabled 2024-12-31); data is frozen.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.STS_User_Operations_Data_History + Fact_BillingDeposit (via Dim_Customer + Dim_Affiliate) |
| **Refresh** | DISABLED (SP_AML_Affiliate_Abuse disabled 2024-12-31 per BI team request) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Affiliate_Abuse |
| **UC Target** | Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **OpsDB Priority** | Not in OpsDB |

---

## 1. Business Meaning

`BI_DB_AML_Affiliate_Abuse_SameDeviceID` captures cases where two or more distinct customers — all referred by the same affiliate — registered or transacted using the **same device ID**. Device sharing at scale is a strong indicator of synthetic identity fraud or coordinated money laundering: a single fraudster operating multiple accounts (mule accounts) from one device, all funnelled through an affiliate partner.

The table contains **74 rows** as of 2024-12-31, each representing one affiliate + device combination where `COUNT(DISTINCT RealCID) > 1`. At 74 rows total, this is a highly filtered signal table — only the most concentrated device-sharing cases across the 5 monitored affiliate channels survive the threshold.

The device identification comes from `DWH_dbo.STS_User_Operations_Data_History`, which logs session-level device fingerprints. The SP links sessions to approved deposits via `Fact_BillingDeposit` (PaymentStatusID=2) and restricts to customers in the affiliate abuse monitoring scope (activated affiliates from Jan 2023 registered under SubChannelIDs 20, 31, 39, 40, 41, 42, 44).

**The SP was permanently disabled on 2024-12-31** at the request of Lior Ben Dor from the BI team. The table is a frozen historical snapshot.

The ETL pipeline:

```
DWH_dbo.Dim_Customer (activated affiliate customers, RegisteredReal>=2023)
  |-- JOIN Dim_Affiliate SubChannelID IN (20,31,39,40,41,42,44) ---|
  v
#cidlevel (CID scope)
  |-- JOIN STS_User_Operations_Data_History (DateID>=20220101, SessionId≠0) ---|
  |-- JOIN Fact_BillingDeposit ON SessionId (PaymentStatusID=2) ---|
  |-- GROUP BY AffiliateID, ClientDeviceId HAVING COUNT(DISTINCT RealCid)>1 ---|
  v
  TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID (74 rows, frozen)
```

---

## 2. Business Logic

### 2.1 Device Sharing Detection

**What**: Identifies affiliates whose customers share device fingerprints — a synthetic identity / mule account signal.

**Columns Involved**: AffiliateID, ClientDeviceId, NumOfClientsSameDeviceID

**Rules**:
- Source: `STS_User_Operations_Data_History` (session logs) joined to `Fact_BillingDeposit` on SessionId
- Scope: DateID >= 20220101 and SessionId ≠ 0 (excludes null/missing sessions)
- Null device excluded: ClientDeviceId ≠ '00000000-0000-0000-0000-000000000000' (all-zero GUID = no device fingerprint)
- Threshold: HAVING COUNT(DISTINCT RealCid) > 1 — only device IDs shared by at least 2 customers survive
- Result: one row per AffiliateID + ClientDeviceId pair exceeding the threshold

### 2.2 Affiliate Scope

**What**: Only the 5 affiliate channel types monitored in the AML Affiliate Abuse suite.

**Columns Involved**: AffiliateID

**Rules**:
- Restricted to SubChannelID IN (20, 31, 39, 40, 41, 42, 44) via JOIN to Dim_Affiliate
- Organic, SEM, SEO channels are excluded
- Only customers with AccountActivated=1 and RegisteredReal >= 2023-01-01 are in scope

### 2.3 Grain

**What**: One row per affiliate × device ID pair where multiple customers share that device.

**Columns Involved**: AffiliateID, ClientDeviceId

**Rules**:
- An AffiliateID can appear multiple times if its customers share multiple device IDs
- 74 total rows — very sparse; high threshold means only egregious cases are captured

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. 74 rows — negligible in any context. Full scan is instantaneous.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliates with any device sharing | `SELECT DISTINCT AffiliateID FROM BI_DB_AML_Affiliate_Abuse_SameDeviceID` |
| Worst offenders (most shared clients) | `ORDER BY NumOfClientsSameDeviceID DESC` |
| All devices for a specific affiliate | `WHERE AffiliateID = @id` |
| Affiliates with high-count device groups | `WHERE NumOfClientsSameDeviceID >= 5` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Affiliate_Abuse_Users | ON AffiliateID | Get CID-level profile for customers on flagged devices |
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Add affiliate name and contact info |
| DWH_dbo.STS_User_Operations_Data_History | ON ClientDeviceId | Re-expand to full customer list per device |

### 3.4 Gotchas

- **Data is frozen**: All rows reflect state as of 2024-12-31. Do NOT use for current monitoring.
- **74 rows only**: This is a post-threshold signal table, not a complete device log. Absence here does not mean no sharing exists below the threshold.
- **All-zero GUID excluded**: The sentinel device ID '00000000-0000-0000-0000-000000000000' is explicitly filtered — it represents missing/unknown device, not a real device.
- **Session scope starts 2022**: STS_User_Operations_Data_History filter is DateID >= 20220101, broader than the 2023 customer registration window — captures sessions from earlier years for customers registered in 2023+.
- **No %SameDevice metric**: Unlike SameIP, this table does not compute a percentage ratio. It is a raw flag table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL infrastructure — canonical description applies universally |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Unique affiliate partner identifier from AffWizz system. Groups customers who share device IDs under the same affiliate channel. (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via Dim_Customer+Dim_Affiliate) |
| 2 | NumOfClientsSameDeviceID | int | YES | Count of distinct customers (RealCID) who share the same ClientDeviceId within this affiliate. Always ≥ 2 (HAVING filter). Higher values indicate more concentrated device-sharing risk. (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via STS_User_Operations_Data_History) |
| 3 | ClientDeviceId | nvarchar(50) | YES | Device fingerprint identifier from session logs. GUID-format string. Excludes all-zero GUID ('00000000-0000-0000-0000-000000000000'). Groups customers by shared hardware/browser fingerprint. (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via STS_User_Operations_Data_History) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted. All rows show 2024-12-31 — the date the SP was last run before being disabled. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | DWH_dbo.Dim_Customer + Dim_Affiliate | AffiliateID | passthrough via JOIN |
| NumOfClientsSameDeviceID | DWH_dbo.STS_User_Operations_Data_History | RealCid | COUNT DISTINCT per AffiliateID + ClientDeviceId, HAVING > 1 |
| ClientDeviceId | DWH_dbo.STS_User_Operations_Data_History | ClientDeviceId | passthrough; excludes all-zero GUID |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer
  |-- JOIN Dim_Affiliate SubChannelID IN (20,31,39,40,41,42,44) ---|
  v
#cidlevel (activated affiliate customers, RegisteredReal>=2023)
  |-- JOIN STS_User_Operations_Data_History (DateID>=20220101, SessionId≠0) ---|
  |-- JOIN Fact_BillingDeposit ON SessionId (PaymentStatusID=2) ---|
  |-- EXCLUDE ClientDeviceId = '00000000-0000-0000-0000-000000000000' ---|
  |-- GROUP BY AffiliateID, ClientDeviceId ---|
  |-- HAVING COUNT(DISTINCT RealCid) > 1 ---|
  v
TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID (74 rows, frozen)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner master |
| AffiliateID | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users | CID-level companion for flagged affiliates |
| ClientDeviceId | DWH_dbo.STS_User_Operations_Data_History | Source session/device log |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers (SP was disabled; AML monitoring suite decommissioned).

---

## 7. Sample Queries

### Affiliates with highest device-sharing concentration

```sql
SELECT
    AffiliateID,
    COUNT(*) AS distinct_shared_devices,
    SUM(NumOfClientsSameDeviceID) AS total_clients_on_shared_devices,
    MAX(NumOfClientsSameDeviceID) AS max_clients_per_device
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_SameDeviceID]
GROUP BY AffiliateID
ORDER BY max_clients_per_device DESC
```

### Device IDs with most clients (top fraud signals)

```sql
SELECT
    AffiliateID,
    ClientDeviceId,
    NumOfClientsSameDeviceID
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_SameDeviceID]
WHERE NumOfClientsSameDeviceID >= 3
ORDER BY NumOfClientsSameDeviceID DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. The AML Affiliate Abuse suite was internally tracked — refer to BI team communications with Lior Ben Dor (2024-12-31 disable request).

---

*Generated: 2026-04-23 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 4/4*
*Object: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameDeviceID | Type: Table | Production Source: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)*
