# BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level

> 1,052,545-row customer-level appropriateness test (AT) popup interaction summary, tracking how many times each customer was shown the AT popup, whether they completed the FTP (First Time Pass) process, and their overall appropriateness status. Sourced from ComplianceStateDB (Compliance.CustomerInteractionActionCounts + CustomerInteractions + UserInteractionDetails, UserInteractionTypeId=4/UserInteractionId=22) and SettingsDB (FTP completion, ResourceId=5907/SelectedValue='2'). Refreshed daily via TRUNCATE+INSERT. Date range: FirstInteractionDate 2022-04-03 to 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ComplianceStateDB.Compliance.CustomerInteractionActionCounts + CustomerInteractions + UserInteractionDetails; SettingsDB.Settings.CustomerData (FTP gate); BI_DB_Scored_Appropriateness_Negative_Market (AT_Date, ApproprietnessScore_Status) via SP_BI_DB_ApproperiatenessTest_FTP_CID_Level |
| **Refresh** | Daily TRUNCATE+INSERT (SB_Daily, Priority 0) |
| **Author** | Yarden Sabadra (2024-01-31) |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

Customer-level appropriateness test popup interaction summary for MiFID II compliance. Under EU/FCA regulation, eToro is required to assess whether customers understand that the products they wish to trade may be inappropriate for them (appropriateness test per MiFID II Art. 25). When a customer triggers the negative-market appropriateness flag, they are shown a popup (UserInteractionTypeId=4, UserInteractionId=22) requiring acknowledgement.

This table records, for each customer who has ever seen the AT popup:
- How many times they saw it (PopUpsCount)
- When they first and last interacted with it (FirstInteractionDate, LastInteractionDate)
- Whether they completed the FTP (First Time Pass — the formal completion record in SettingsDB, ResourceId=5907, SelectedValue='2')
- Their overall appropriateness test result (ApproprietnessScore_Status from BI_DB_Scored_Appropriateness_Negative_Market)

**Population**: 1,052,545 customers who have seen the AT popup. HasCompletedFTP=1 for 74.9% (787,902 customers); HasCompletedFTP=0 for 25.1% (264,643 customers). ApproprietnessScore_Status distribution: Failed 61.5% (647K), Passed 35.5% (373K), NULL 3.0% (31K), Borderline Pass <0.01% (25 customers).

Note: The table name contains a typo — "Approperiateness" (should be "Appropriateness") — inherited from the original DDL and must be used as-is in queries.

---

## 2. Business Logic

### 2.1 Appropriateness Test Popup Filtering

**What**: The SP filters ComplianceStateDB interactions to only the AT popup type (UserInteractionTypeId=4, UserInteractionId=22) and the specific action (UserInteractionActionId=2 — popup was shown/dismissed).
**Columns Involved**: GCID, PopUpsCount, FirstInteractionDate, LastInteractionDate
**Rules**:
- Source: ComplianceStateDB.Compliance.CustomerInteractionActionCounts filtered WHERE UserInteractionActionId=2
- INNER JOIN with CustomerInteractions (maps GCID) and UserInteractionDetails (filters TypeId=4, Id=22)
- Multiple popup events per customer are aggregated; Count = total times the popup was triggered

### 2.2 FTP Completion Gate

**What**: HasCompletedFTP indicates whether the customer has a SettingsDB record marking FTP completion. CompletionFTPDate is the BeginDate of that record.
**Columns Involved**: HasCompletedFTP, CompletionFTPDate
**Rules**:
- Source: SettingsDB.Settings.CustomerData WHERE ResourceId=5907 AND SelectedValue='2'
- LEFT JOIN: customers without this record get HasCompletedFTP=0 and CompletionFTPDate=NULL
- CompletionFTPDate NULLs: exactly 264,643 rows (the 25.1% where HasCompletedFTP=0)
- HasCompletedFTP=1 does NOT imply Passed status — customers can complete FTP with a Failed score

### 2.3 AT Status Relay from BI_DB_Scored_Appropriateness_Negative_Market

**What**: ApproprietnessScore_Status and AT_Date are pulled from the BI_DB_Scored_Appropriateness_Negative_Market table via INNER JOIN on GCID.
**Columns Involved**: ApproprietnessScore_Status, AT_Date, RealCID
**Rules**:
- Only GCIDs present in BI_DB_Scored_Appropriateness_Negative_Market are included (INNER JOIN)
- RealCID also comes from that table (GCIDs in ComplianceStateDB map to RealCIDs through this join)
- Note: AT_Date may be NULL for 31,542 customers (~3%) — inherited NULLs from BI_DB_Scored_Appropriateness_Negative_Market

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distributed on `HASH(RealCID)`. Joining this table to Dim_Customer or other RealCID-distributed tables benefits from data locality. The CLUSTERED COLUMNSTORE INDEX supports both range scans and aggregations efficiently.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers who have NOT completed FTP | `WHERE HasCompletedFTP = 0` (264,643 rows) |
| Customers with failed AT who completed FTP | `WHERE HasCompletedFTP = 1 AND ApproprietnessScore_Status = 'Failed'` |
| First popup date by customer | `SELECT RealCID, FirstInteractionDate` — already at CID level |
| Average popup count for failed customers | `SELECT AVG(CAST(PopUpsCount AS float)) WHERE ApproprietnessScore_Status = 'Failed'` |
| Recently active popup customers | `WHERE FirstInteractionDate >= '2026-01-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON t.RealCID = dc.RealCID` | Add customer demographics, regulation, country |
| BI_DB_Scored_Appropriateness_Negative_Market | `ON t.RealCID = atnm.RealCID` | Full AT scoring details |

### 3.4 Gotchas

- Table name typo: "Approperiateness" — use the exact name `BI_DB_ApproperiatenessTest_FTP_CID_Level` in queries
- `DaysFromFirstToLast=0` means the customer interacted only once (same day first and last)
- `CompletionFTPDate` can be earlier OR later than `FirstInteractionDate` — FTP completion is tracked separately from popup display
- AT_Date is NULL for ~3% of customers — these are rows where BI_DB_Scored_Appropriateness_Negative_Market has no AT_Date
- INNER JOIN to BI_DB_Scored_Appropriateness_Negative_Market means only customers scored by that table appear; customers never scored are excluded
- `HasCompletedFTP=1` AND `ApproprietnessScore_Status='Failed'` can co-exist — completing the FTP does not change the score

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code and source table analysis |
| Tier 3 | Inferred from data patterns and naming |
| Tier 4 | Best available knowledge, limited confidence |
| Propagation | Canonical ETL metadata (UpdateDate, InsertDate, etc.) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — the customer identifier used in ComplianceStateDB. Imported from ComplianceStateDB.Compliance.CustomerInteractions. Links to GCID in other compliance system tables. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 2 | RealCID | int | NO | Real Customer ID — the eToro platform customer identifier. Distribution key. Sourced via JOIN to BI_DB_Scored_Appropriateness_Negative_Market on GCID; maps the ComplianceStateDB GCID to the DWH RealCID. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 3 | PopUpsCount | int | YES | Total number of times the appropriateness test popup was displayed to this customer (CustomerInteractionActionCounts.Count). Aggregated across all sessions. Value range from sample: 1–18+ (some customers are shown the popup many times before completing FTP). (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 4 | FirstInteractionDate | datetime2(7) | YES | Timestamp of the customer's first appropriateness test popup interaction, from ComplianceStateDB.Compliance.CustomerInteractionActionCounts.FirstInteractionDate. Range: 2022-04-03 to 2026-04-13. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 5 | LastInteractionDate | datetime2(7) | YES | Timestamp of the customer's most recent appropriateness test popup interaction, from ComplianceStateDB.Compliance.CustomerInteractionActionCounts.LastInteractionDate. Equals FirstInteractionDate when PopUpsCount=1. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 6 | HasCompletedFTP | int | YES | Binary flag indicating whether the customer has completed the First Time Pass (FTP) process: 1=completed (787,902; 74.9%), 0=not completed (264,643; 25.1%). Derived: 1 if customer has a SettingsDB.Settings.CustomerData record with ResourceId=5907 and SelectedValue='2'; 0 if no such record exists (LEFT JOIN NULL check). (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 7 | CompletionFTPDate | datetime2(7) | YES | Date the customer completed the FTP process, from SettingsDB.Settings.CustomerData.BeginDate (ResourceId=5907, SelectedValue='2'). NULL when HasCompletedFTP=0 (264,643 NULLs). (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 8 | DaysFromFirstToLast | int | YES | Number of days between FirstInteractionDate and LastInteractionDate: DATEDIFF(DAY, FirstInteractionDate, LastInteractionDate). Value of 0 means first and last interaction were on the same day. No NULLs observed. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level) |
| 9 | ApproprietnessScore_Status | varchar(30) | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Values: "Failed" (majority), "Passed", "Borderline Pass" (rare), NULL. Note: column name contains typo ("Approprietness" vs "Appropriateness"). Passthrough from BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level, join-enriched via BI_DB_Scored_Appropriateness_Negative_Market) |
| 10 | AT_Date | datetime | YES | Date the Appropriateness Test was taken. From ComplianceStateDB.Compliance.CustomerRestrictions.BeginTime. NULL for ~3% of customers (31,542 NULLs). Passthrough from BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market. (Tier 2 — SP_BI_DB_ApproperiatenessTest_FTP_CID_Level, join-enriched via BI_DB_Scored_Appropriateness_Negative_Market) |
| 11 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time during daily TRUNCATE+INSERT. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | ComplianceStateDB.Compliance.CustomerInteractions | GCID | passthrough |
| RealCID | BI_DB_Scored_Appropriateness_Negative_Market | RealCID | passthrough via JOIN on GCID |
| PopUpsCount | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | Count | passthrough (aliased) |
| FirstInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | FirstInteractionDate | passthrough |
| LastInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | LastInteractionDate | passthrough |
| HasCompletedFTP | SettingsDB.Settings.CustomerData | Gcid | CASE WHEN NULL THEN 0 ELSE 1 |
| CompletionFTPDate | SettingsDB.Settings.CustomerData | BeginDate | passthrough (aliased) |
| DaysFromFirstToLast | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | FirstInteractionDate, LastInteractionDate | DATEDIFF(DAY, First, Last) |
| ApproprietnessScore_Status | BI_DB_Scored_Appropriateness_Negative_Market (← ComplianceStateDB Dictionary) | ApproprietnessScore_Status | passthrough via JOIN |
| AT_Date | BI_DB_Scored_Appropriateness_Negative_Market (← ComplianceStateDB Compliance) | AT_Date | passthrough via JOIN |
| UpdateDate | ETL pipeline | — | GETDATE() |

### 5.2 ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerInteractionActionCounts
  └── Bronze/ComplianceStateDB/Compliance/CustomerInteractionActionCounts
        └── External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts
              |
ComplianceStateDB.Compliance.CustomerInteractions
  └── Bronze/ComplianceStateDB/Compliance/CustomerInteractions
        └── External_ComplianceStateDB_Compliance_CustomerInteractions
              |
ComplianceStateDB.Compliance.UserInteractionDetails (TypeId=4, Id=22)
  └── Bronze/ComplianceStateDB/Compliance/UserInteractionDetails
        └── External_ComplianceStateDB_Compliance_UserInteractionDetails
              |
SettingsDB.Settings.CustomerData (ResourceId=5907, SelectedValue='2')
  └── Bronze/SettingsDB/Settings/CustomerData
        └── External_SettingsDB_Settings_CustomerData
              |
BI_DB_Scored_Appropriateness_Negative_Market (JOIN → RealCID, AT_Date, ApproprietnessScore_Status)
              |
              v
SP_BI_DB_ApproperiatenessTest_FTP_CID_Level (TRUNCATE + INSERT, Daily)
              |
              v
BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level (1,052,545 rows)
  UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| ApproprietnessScore_Status, AT_Date | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Source of AT status and date |

### 6.2 Referenced By

No known downstream consumers identified (no other SPs insert from this table).

---

## 7. Sample Queries

### Active customers who haven't completed FTP (compliance queue)

```sql
SELECT t.RealCID, t.PopUpsCount, t.FirstInteractionDate, t.ApproprietnessScore_Status
FROM [BI_DB_dbo].[BI_DB_ApproperiatenessTest_FTP_CID_Level] t
WHERE t.HasCompletedFTP = 0
  AND t.ApproprietnessScore_Status = 'Failed'
ORDER BY t.FirstInteractionDate DESC
```

### Customers who completed FTP despite failing the AT

```sql
SELECT t.RealCID, t.AT_Date, t.CompletionFTPDate, t.DaysFromFirstToLast,
       dc.RegulationID, dc.CountryID
FROM [BI_DB_dbo].[BI_DB_ApproperiatenessTest_FTP_CID_Level] t
JOIN [DWH_dbo].[Dim_Customer] dc ON t.RealCID = dc.RealCID
WHERE t.HasCompletedFTP = 1
  AND t.ApproprietnessScore_Status = 'Failed'
```

### Distribution of popup counts by AT status

```sql
SELECT t.ApproprietnessScore_Status,
       COUNT(*) AS CustomerCount,
       AVG(CAST(t.PopUpsCount AS float)) AS AvgPopups,
       MAX(t.PopUpsCount) AS MaxPopups
FROM [BI_DB_dbo].[BI_DB_ApproperiatenessTest_FTP_CID_Level] t
GROUP BY t.ApproprietnessScore_Status
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-23 | Quality: 8.7/10 | Phases: 11/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 1 Propagation | Elements: 11/11, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level | Type: Table | Production Source: ComplianceStateDB + SettingsDB (External Tables) + BI_DB_Scored_Appropriateness_Negative_Market*
