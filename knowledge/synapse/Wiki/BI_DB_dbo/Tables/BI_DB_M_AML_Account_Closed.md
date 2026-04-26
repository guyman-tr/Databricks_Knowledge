# BI_DB_dbo.BI_DB_M_AML_Account_Closed

> 2,060-row monthly AML account closure monitoring table tracking verified, funded customers whose player status changed to Blocked or Blocked Upon Request during each calendar month, from January 2022 to April 2024. Identifies whether the blocking reason is AML-related by correlating Salesforce case data (AML-type cases within 30 days) and enriches with the latest AML comment from BackOffice history. Refreshed monthly via `SP_M_AML_Account_Closed` with delete-insert by EOM.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed from DWH_dbo dimensions/facts + BI_DB_SF_Cases_Panel + general.etoro_History_BackOfficeCustomer via `SP_M_AML_Account_Closed` |
| **Refresh** | Monthly (delete-insert by EOM). Parameter @Date capped to EOMONTH(GETDATE(),-1). OpsDB: SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table monitors AML (Anti-Money Laundering) account closures by tracking customers who were moved to **Blocked** (PlayerStatusID=2) or **Blocked Upon Request** (PlayerStatusID=4) status during a given month. The population is restricted to verified (VerificationLevelID=3), funded (IsDepositor=1), valid customers from `Fact_SnapshotCustomer`.

The SP performs a multi-step analysis:
1. **Current Blocked Population**: Identifies all customers in Blocked/Blocked Upon Request status at end-of-month
2. **Status Change Detection**: Uses `LAG()` window function on `Fact_SnapshotCustomer` to find the most recent status transition into Blocked/Blocked Upon Request within the month
3. **AML Reason Classification**: Checks if the `PlayerStatusReason` is directly AML-related ('AML', 'Account Closed', 'AML Account Closed')
4. **Salesforce Case Correlation**: JOINs to `BI_DB_SF_Cases_Panel` to find AML-type Salesforce cases opened within 30 days before the blocking date
5. **AML Comment Enrichment**: LEFT JOINs to `general.etoro_History_BackOfficeCustomer` to retrieve the latest AML comment with validity dates

The table contains 2,060 rows spanning January 2022 to April 2024 (28 months). Distribution: CySEC 46%, FCA 31%, FinCEN+FINRA 10%. 83% are Blocked (vs 17% Blocked Upon Request). 60% have Is_AML_Reason=1.

**Note**: The column name `Regualtion` is a typo (should be `Regulation`) — preserved as-is from the DDL.

---

## 2. Business Logic

### 2.1 Status Change Detection

**What**: Identifies the most recent status change to Blocked or Blocked Upon Request within the reporting month.
**Columns Involved**: CID, Current_PlayerStatus, Previous_PlayerStatus, Change_Date
**Rules**:
- Uses `LAG(PlayerStatusID, 1, 0)` partitioned by RealCID, ordered by FromDateID ASC
- Only captures transitions WHERE PlayerStatusID changes (current != previous)
- Takes `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Change_Date DESC) = 1` — most recent change in the month
- Filtered to current status IN (2=Blocked, 4=Blocked Upon Request)

### 2.2 AML Reason Classification

**What**: Determines whether the account closure is AML-related based on two criteria.
**Columns Involved**: PlayerStatusReason, Is_AML_Reason
**Rules**:
- `Is_AML_Reason = 1` when PlayerStatusReason IN ('AML', 'Account Closed', 'AML Account Closed')
- Additionally, only rows that ALSO have a matching Salesforce case (ActionType_AtOpen LIKE '%AML%') within 30 days of Change_Date are included in the final output
- This means Is_AML_Reason=0 rows are cases where the reason was NOT AML but the Salesforce case was AML-related

### 2.3 AML Comment Retrieval

**What**: Enriches each record with the most recent AML comment from BackOffice history.
**Columns Involved**: AMLComment, ValidFrom, ValidTo
**Rules**:
- Source: `general.etoro_History_BackOfficeCustomer` (staging table)
- Takes the most recent non-NULL AMLComment per CID (`ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ValidFrom DESC) = 1`)
- LEFT JOIN — AMLComment may be NULL if no BackOffice AML record exists

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index — no distribution key optimization. Table is small (2,060 rows), so distribution strategy is irrelevant for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many AML closures per month? | `SELECT EOM, COUNT(*) FROM ... WHERE Is_AML_Reason = 1 GROUP BY EOM` |
| AML closures by regulation? | `SELECT Regualtion, COUNT(*) FROM ... WHERE Is_AML_Reason = 1 GROUP BY Regualtion` |
| What was the reason for blocking CID X? | `SELECT * FROM ... WHERE CID = X ORDER BY EOM DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID = RealCID | Enrich with customer demographics |
| BI_DB_dbo.BI_DB_SF_Cases_Panel | CID | Cross-reference Salesforce case details |

### 3.4 Gotchas

- **Column typo**: `Regualtion` is misspelled (should be `Regulation`). Use the typo in queries: `WHERE Regualtion = 'CySEC'`
- **Salesforce filter**: Only rows with a matching SF AML case (within 30 days) are included. Not all blocked customers appear — only those with an AML-related SF case
- **ValidFrom/ValidTo are varchar(250)**: Despite representing dates, these columns store formatted datetime strings (e.g., "May 9 2022 7:58AM") as varchar. Use CAST/CONVERT for date operations
- **Data range**: Last EOM is April 2024 — the SP may have stopped running or been replaced. Verify with the data engineering team before using for current reporting
- **Is_AML_Reason=0 does NOT mean non-AML**: It means the PlayerStatusReason was not explicitly AML, but the row still has an AML-related Salesforce case (that's how it passed the SF case filter)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB docs) | Highest — verified against source system documentation |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |
| Tier 4 | Contextual inference | Lower — best available knowledge |
| Tier 5 | Standard ETL column | Canonical — well-known ETL metadata pattern |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Sourced from Fact_SnapshotCustomer.RealCID. Identifies the verified, funded customer whose account was blocked. (Tier 2 — SP_M_AML_Account_Closed) |
| 2 | Regualtion | varchar(250) | YES | Regulation name resolved from Dim_Regulation.Name via JOIN on DWHRegulationID. Values: CySEC, FCA, FinCEN+FINRA, ASIC & GAML, FSA Seychelles, FinCEN, ASIC, FSRA. Note: column name is a typo (should be "Regulation"). (Tier 2 — SP_M_AML_Account_Closed) |
| 3 | Country | varchar(250) | YES | Country name resolved from Dim_Country.Name via JOIN on DWHCountryID. Country of the customer at the end-of-month snapshot. (Tier 2 — SP_M_AML_Account_Closed) |
| 4 | Club | varchar(250) | YES | Player level (club tier) resolved from Dim_PlayerLevel.Name via JOIN on PlayerLevelID. Values include Bronze, Silver, Gold, etc. (Tier 2 — SP_M_AML_Account_Closed) |
| 5 | EOM | date | YES | End-of-month date for the reporting period. Computed from SP parameter @Date, capped to EOMONTH(GETDATE(),-1). Each row represents the month when the blocking event was detected. (Tier 2 — SP_M_AML_Account_Closed) |
| 6 | Current_PlayerStatus | varchar(250) | YES | Current player status at time of blocking. Always one of: Blocked (PlayerStatusID=2) or Blocked Upon Request (PlayerStatusID=4). Resolved from Dim_PlayerStatus.Name. 83% Blocked, 17% Blocked Upon Request. (Tier 2 — SP_M_AML_Account_Closed) |
| 7 | Previous_PlayerStatus | varchar(250) | YES | Player status immediately before the blocking event, detected via LAG() window function on Fact_SnapshotCustomer. Common transitions: Normal→Blocked, Trade & MIMO Blocked→Blocked, Block Deposit & Trading→Blocked. (Tier 2 — SP_M_AML_Account_Closed) |
| 8 | Change_Date | date | YES | Date when the player status changed to Blocked or Blocked Upon Request within the reporting month. Computed from Dim_Range.FromDateID converted to DATE. Always within the [StartDate, EOM] range for the row. (Tier 2 — SP_M_AML_Account_Closed) |
| 9 | PlayerStatusReason | varchar(250) | YES | Reason for the status change, from Dim_PlayerStatusReasons.Name. Common values: AML, Account Closed, AML Account Closed, CloseAccountByUser. LEFT JOIN — may be NULL if no reason recorded. (Tier 2 — SP_M_AML_Account_Closed) |
| 10 | AMLComment | varchar(max) | YES | Latest AML comment from general.etoro_History_BackOfficeCustomer. Retrieved via ROW_NUMBER=1 on ValidFrom DESC where AMLComment IS NOT NULL. Contains free-text compliance notes including case references, investigation details, and risk assessments. LEFT JOIN — NULL if no BackOffice AML record exists. (Tier 2 — SP_M_AML_Account_Closed) |
| 11 | ValidFrom | varchar(250) | YES | Start date of the AML comment validity period from general.etoro_History_BackOfficeCustomer. Stored as varchar containing formatted datetime strings (e.g., "May 9 2022 7:58AM"). NULL when no AMLComment record exists. (Tier 2 — SP_M_AML_Account_Closed) |
| 12 | ValidTo | varchar(250) | YES | End date of the AML comment validity period from general.etoro_History_BackOfficeCustomer. Typically "Jan 1 3000 12:00AM" for currently active records. Stored as varchar containing formatted datetime strings. NULL when no AMLComment record exists. (Tier 2 — SP_M_AML_Account_Closed) |
| 13 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — SP_M_AML_Account_Closed) |
| 14 | Is_AML_Reason | int | YES | AML reason flag. 1=PlayerStatusReason IN ('AML','Account Closed','AML Account Closed'), 0=other reason but with a matching AML-related Salesforce case within 30 days. Note: all rows in this table passed the SF case AML filter, so Is_AML_Reason=0 means non-AML reason text but still AML-correlated via SF. 60% are 1, 40% are 0. (Tier 2 — SP_M_AML_Account_Closed) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Alias rename |
| Regualtion | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID |
| Country | DWH_dbo.Dim_Country | Name | JOIN on DWHCountryID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| EOM | (computed) | @EndOfMonth | SP parameter |
| Current_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN, filtered to ID 2,4 |
| Previous_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | LAG() + JOIN |
| Change_Date | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE) |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN |
| AMLComment | general.etoro_History_BackOfficeCustomer | AMLComment | ROW_NUMBER=1 DESC |
| ValidFrom | general.etoro_History_BackOfficeCustomer | ValidFrom | ROW_NUMBER=1 DESC |
| ValidTo | general.etoro_History_BackOfficeCustomer | ValidTo | ROW_NUMBER=1 DESC |
| UpdateDate | (computed) | GETDATE() | ETL timestamp |
| Is_AML_Reason | (computed) | CASE logic | PlayerStatusReason IN (...) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_PlayerStatus + Dim_Regulation
+ Dim_Country + Dim_PlayerLevel + Dim_PlayerStatusReasons
  |-- Step 02: #Current_Blocked (EOM blocked pop, IsDepositor=1, Verified, Valid)
  |-- Step 03: #first (LAG status changes) → #final_change (ROW_NUMBER=1 most recent)
  |-- Step 04: #join (blocked pop × status changes)
  v
BI_DB_dbo.BI_DB_SF_Cases_Panel (ActionType LIKE '%AML%', within 30 days)
  |-- Step 05: #AML_Reason (Is_AML_Reason flag)
  |-- Step 06: #cases (filtered to matching SF AML cases)
  v
general.etoro_History_BackOfficeCustomer (latest AMLComment per CID)
  |-- LEFT JOIN #amlcomment
  |-- Step 06: #final
  v
BI_DB_dbo.BI_DB_M_AML_Account_Closed (DELETE by EOM + INSERT, 2,060 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | Customer snapshot — source of customer status data |
| CID | DWH_dbo.Dim_Customer | Customer dimension — can be used for demographic enrichment |
| Regualtion | DWH_dbo.Dim_Regulation | Regulation dimension — resolved from DWHRegulationID |
| Country | DWH_dbo.Dim_Country | Country dimension — resolved from DWHCountryID |
| Club | DWH_dbo.Dim_PlayerLevel | Player level dimension — resolved from PlayerLevelID |
| Current_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status dimension (2=Blocked, 4=Blocked Upon Request) |
| CID | BI_DB_dbo.BI_DB_SF_Cases_Panel | Salesforce cases — AML case correlation |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo schema.

---

## 7. Sample Queries

### 7.1 Monthly AML Closure Trend by Regulation

```sql
SELECT EOM,
       Regualtion,
       COUNT(*) AS total_closures,
       SUM(Is_AML_Reason) AS aml_reason_closures,
       COUNT(*) - SUM(Is_AML_Reason) AS non_aml_reason_closures
FROM BI_DB_dbo.BI_DB_M_AML_Account_Closed
GROUP BY EOM, Regualtion
ORDER BY EOM DESC, total_closures DESC
```

### 7.2 Find AML Comments for a Specific Customer

```sql
SELECT CID, EOM, Current_PlayerStatus, Previous_PlayerStatus,
       Change_Date, PlayerStatusReason, Is_AML_Reason,
       AMLComment, ValidFrom, ValidTo
FROM BI_DB_dbo.BI_DB_M_AML_Account_Closed
WHERE CID = 12345678
ORDER BY EOM DESC
```

### 7.3 Status Transition Analysis

```sql
SELECT Previous_PlayerStatus,
       Current_PlayerStatus,
       COUNT(*) AS transitions,
       AVG(CAST(Is_AML_Reason AS FLOAT)) AS pct_aml_reason
FROM BI_DB_dbo.BI_DB_M_AML_Account_Closed
GROUP BY Previous_PlayerStatus, Current_PlayerStatus
ORDER BY transitions DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_M_AML_Account_Closed | Type: Table | Production Source: SP_M_AML_Account_Closed*
