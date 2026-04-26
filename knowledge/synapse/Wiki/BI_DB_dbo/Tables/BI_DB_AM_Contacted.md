# BI_DB_dbo.BI_DB_AM_Contacted

> 296.6M-row rolling daily snapshot table tracking Account Manager (AM) contact activity for all managed customers over a 120-day window (2025-12-14 to 2026-04-13). Each row represents one CID on one UpdateDate and records whether the account manager contacted, called, or attempted contact within the last 30 and 60 days — sourced from Salesforce action logs in BI_DB_UsageTracking_SF. Phone contact columns are Dynamic Data Masked for unauthorized users. Populated daily by SP_AM_Contacted via DELETE+INSERT rolling pattern.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_UsageTracking_SF (Salesforce actions) + DWH_dbo.Dim_Customer + DWH_dbo.V_Liabilities via SP_AM_Contacted |
| **Refresh** | Daily (SB_Daily, Priority 20; depends on BI_DB_UsageTracking_SF at Priority 70) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (UpdateDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AM_Contacted` is a daily-refreshed Account Manager (AM) performance and contact-tracking table used by Account Management and Sales teams to monitor customer engagement. For each managed customer (those with an assigned AccountManagerID in Dim_Customer), it records whether the AM successfully contacted the customer (by phone or email) or made a contact attempt within the last 30 and 60 days.

The table holds 296.6M rows across 2.5M distinct CIDs, representing up to 120 days of daily snapshots per customer (one row per CID per UpdateDate). The 120-day window is enforced by the SP's DELETE logic: rows older than 120 days are purged daily, and today's snapshot is always re-inserted fresh.

Key business metrics per row:
- **Contact flags**: Was the customer contacted (email or phone) in the last 30/60 days?
- **Phone-specific flags**: Was the customer reached by phone specifically?
- **Attempt flag**: Was contact attempted (including failed calls logged as Contacted__c)?
- **Financial snapshot**: Yesterday's Equity (Liabilities + ActualNWA) and RealizedEquity from V_Liabilities
- **Manager context**: ManagerID, AccountManager full name, Club level, Region, Desk

Contact rate on 2026-04-13: 16,143 of 2,434,892 customers (0.7%) contacted in last 30 days.

Club distribution (all dates): Bronze 70.7%, Silver 10.9%, Gold 9.9%, Platinum 4.5%, Platinum Plus 3.4%, Diamond 0.4%, Internal 0.1%.

SP author note: Special handling for ManagerIDs 1151–1154 (hardcoded in filter) — these managers' customers are always included in phone attempt tracking regardless of IsActive status.

---

## 2. Business Logic

### 2.1 30-Day vs. 60-Day Contact Windows

**What**: Two sets of contact flags capture both short-term (monthly) and medium-term (bi-monthly) engagement.

**Columns Involved**: `Last30DaysContacted`, `Last60DaysContacted`, `Last30DaysPhoneContacted`, `Last60DaysPhoneContacted`

**Rules**:
- **30-day contacted**: CASE WHEN customer CID exists in BI_DB_UsageTracking_SF with ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') AND CreatedDate_SF within last 30 days THEN 1 ELSE 0
- **60-day contacted**: Same logic, 60-day window
- **Phone-contacted**: Requires ActionName = 'Phone_Call_Succeed__c' specifically (successful call)
- **Contacted vs. PhoneContacted**: A customer can be 30-day-contacted (=1) but not 30-day-phone-contacted (=0) if only email contact occurred
- DDM applied to phone columns — unauthorized users see NULL

### 2.2 Contact Attempt Flag (Attempted but Not Necessarily Successful)

**What**: `Last30DaysContactedAttempt` is broader than `Last30DaysContacted` — it counts any phone call (successful or failed) or contact action.

**Columns Involved**: `Last30DaysContactedAttempt`, `Last30DaysPhoneContactedAttempt`

**Rules**:
- Attempt includes: 'Phone_Call_Succeed__c' (successful) AND 'Contacted__c' (attempted/logged)
- Successful contact ('Completed_Contact_Email__c') is NOT in the attempt filter — email confirmations are not phone attempts
- `Last30DaysPhoneContactedAttempt` = 1 if PhoneCallAttempt flag was set for the customer (sf3.PhoneCallAttempt=1); DDM MASKED
- An attempt may exist even when Last30DaysPhoneContacted=0 (called but not answered)

### 2.3 Rolling 120-Day Snapshot Pattern

**What**: The table accumulates daily snapshots rather than being overwritten. Each day adds a new row per CID while pruning rows older than 120 days.

**Columns Involved**: `UpdateDate`, all flag and financial columns

**Rules**:
- SP DELETE 1: `DELETE WHERE UpdateDate = CAST(GETDATE() AS DATE)` — clear today's stale rows before re-inserting
- SP DELETE 2: `DELETE WHERE UpdateDate < DATEADD(day,-120,GETDATE())` — purge history beyond 120 days
- SP INSERT: fresh computation for all managed customers with yesterday's V_Liabilities data
- Historical rows retain the contact flags and financial values as computed on that specific UpdateDate
- Cross-date analysis: to trend contact rates over time, GROUP BY UpdateDate

### 2.4 Equity Calculation

**What**: Equity is a computed combination of two V_Liabilities components.

**Columns Involved**: `Equity`, `RealizedEquity`

**Rules**:
- `Equity` = `V_Liabilities.Liabilities + V_Liabilities.ActualNWA` (filtered to DateID = yesterday's YYYYMMDD int)
- `RealizedEquity` = `V_Liabilities.RealizedEquity` (passthrough)
- Both reflect the customer's financial position as of the previous business day

### 2.5 Dynamic Data Masking on Phone Columns

**What**: Phone contact columns contain PII-sensitive data (phone call records) and are masked for non-privileged database users.

**Columns Involved**: `Last30DaysPhoneContacted`, `Last60DaysPhoneContacted`, `Last30DaysPhoneContactedAttempt`

**Rules**:
- Masking function: `default()` — unauthorized users see 0 (int) instead of actual value
- Privileged Synapse users with UNMASK permission see actual values
- Masking applies at the query layer — data is stored unmasked in the table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on UpdateDate ASC. This layout is optimized for daily-partition scans — queries filtering on UpdateDate will scan a contiguous data range. ROUND_ROBIN distributes rows evenly across nodes regardless of CID, so CID-based JOINs to Dim_Customer will involve data movement. For large JOINs, consider CTAS to redistribute by CID first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's contact status per customer | `WHERE UpdateDate = MAX(UpdateDate)` — use subquery or variable for max date |
| Monthly contact rate trend | `GROUP BY UpdateDate, Last30DaysContacted` — use latest date per month |
| Customers never contacted in 60 days | `WHERE Last60DaysContacted = 0 AND UpdateDate = (latest date)` |
| AM performance by manager | `GROUP BY ManagerID, AccountManager, SUM(Last30DaysContacted)` |
| High-equity customers not reached | `WHERE Equity > 10000 AND Last30DaysContacted = 0 AND UpdateDate = (latest)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = Dim_Customer.RealCID | Enrich with full customer profile |
| DWH_dbo.Dim_Manager | ON ManagerID = Dim_Manager.ManagerID | Resolve manager attributes beyond name |
| BI_DB_dbo.BI_DB_UsageTracking_SF | ON CID | Trace raw Salesforce events behind the contact flags |

### 3.4 Gotchas

- **ROUND_ROBIN + 296M rows**: Full-table scans are expensive. Always filter on UpdateDate first; CLUSTERED INDEX makes date-range scans efficient.
- **DDM on phone columns**: `Last30DaysPhoneContacted`, `Last60DaysPhoneContacted`, `Last30DaysPhoneContactedAttempt` return 0 for unauthorized users — cannot distinguish "not called" from "masked". Request UNMASK permission for legitimate AM reporting.
- **One row per CID per date**: Joining to another table without a date filter will cause a 120x row explosion. Always add `WHERE UpdateDate = (latest)` or use a specific date.
- **ManagerIDs 1151–1154 hardcoded**: These managers have special handling in the SP (sf3 temp table always includes them). If these managers are deactivated in Dim_Manager, their customers still appear here.
- **Equity = Liabilities + ActualNWA**: This is not total account equity in the usual sense. Check V_Liabilities definition for the exact formula components.
- **Priority 20 depends on Priority 70 (BI_DB_UsageTracking_SF)**: If UsageTracking_SF hasn't been refreshed, contact flags will reflect stale Salesforce data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Meaning |
|------|--------|---------|
| Tier 1 | Upstream wiki verbatim | Description copied from DWH_dbo or DB_Schema wiki, stripped of snapshot stats |
| Tier 2 | SP code / DWH dimension | Derived from SP_AM_Contacted logic or DWH JOIN resolution |
| Tier 3 | Live data / external source | Inferred from Ext_Dim_Country_Region_Desk or live query |
| Tier 4 | Inferred [UNVERIFIED] | Best-effort from column name and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID (renamed from RealCID to CID in this table). (Tier 1 — Customer.CustomerStatic) |
| 2 | Last30DaysContacted | int | YES | Account Manager contact flag — 30-day window. 1=customer was reached by phone (Phone_Call_Succeed__c) or email (Completed_Contact_Email__c) in the last 30 days per Salesforce; 0=no successful contact recorded. Includes both phone and email contact types. (Tier 2 — SP_AM_Contacted) |
| 3 | Last30DaysPhoneContacted | int | YES | Successful phone contact flag — 30-day window. 1=customer was reached by phone (Phone_Call_Succeed__c) in the last 30 days; 0=no successful phone contact. DDM MASKED with default() — unauthorized users see 0; requires UNMASK permission for actual values. (Tier 2 — SP_AM_Contacted) |
| 4 | Last60DaysContacted | int | YES | Account Manager contact flag — 60-day window. Same logic as Last30DaysContacted but over the last 60 days. 1=contacted, 0=not contacted. (Tier 2 — SP_AM_Contacted) |
| 5 | Last60DaysPhoneContacted | int | YES | Successful phone contact flag — 60-day window. Same logic as Last30DaysPhoneContacted but over the last 60 days. DDM MASKED with default(). (Tier 2 — SP_AM_Contacted) |
| 6 | Last30DaysContactedAttempt | int | YES | Contact attempt flag — 30-day window (broader than Last30DaysContacted). 1=any phone call (successful or failed, Phone_Call_Succeed__c or Contacted__c) was logged for this customer in the last 30 days; 0=no contact attempt recorded. Does not include email-only contacts. (Tier 2 — SP_AM_Contacted) |
| 7 | ManagerID | int | YES | Internal eToro Account Manager ID. FK to DWH_dbo.Dim_Manager. Sourced from Dim_Customer.AccountManagerID. Only customers with a non-null, active AccountManagerID are included (excludes IDs 0, 342, 787, 283, 887). (Tier 2 — SP_AM_Contacted) |
| 8 | Region | varchar(50) | YES | Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via Dim_Country JOIN on CountryID. NOT the geographic region. Examples: UK, French, Arabic GCC, Other Asia, German. Used for AM territory grouping. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | AccountManager | varchar(100) | YES | Full name of the assigned Account Manager. Computed as `Dim_Manager.FirstName + ' ' + Dim_Manager.LastName`. Derived from Dim_Customer.AccountManagerID → Dim_Manager JOIN. (Tier 2 — SP_AM_Contacted) |
| 10 | Club | varchar(20) | YES | Customer's current eToro Club tier. Resolved from Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name. Values (7 distinct): Bronze=70.7%, Silver=10.9%, Gold=9.9%, Platinum=4.5%, Platinum Plus=3.4%, Diamond=0.4%, Internal=0.1%. Determines AM engagement priorities. (Tier 2 — SP_AM_Contacted) |
| 11 | UpdateDate | date | YES | ETL metadata: date when this row was inserted by the ETL pipeline. Each day adds one row per CID; rows older than 120 days are pruned. Use as the daily snapshot partition key. (Tier 2 — SP_AM_Contacted) |
| 12 | Last30DaysPhoneContactedAttempt | int | YES | Phone contact attempt flag — 30-day window. 1=a phone call (successful or attempted) was logged in the last 30 days per Salesforce; 0=no phone attempt. DDM MASKED with default(). Note: sf3 temp table includes all customers plus hardcoded ManagerIDs 1151–1154 regardless of active status. (Tier 2 — SP_AM_Contacted) |
| 13 | Equity | int | YES | Customer equity in USD as of yesterday. Computed as `DWH_dbo.V_Liabilities.Liabilities + DWH_dbo.V_Liabilities.ActualNWA` for DateID = yesterday's YYYYMMDD integer. Reflects the customer's net financial exposure in the DWH model. (Tier 2 — SP_AM_Contacted) |
| 14 | RealizedEquity | int | YES | Customer realized equity in USD as of yesterday. Passthrough from `DWH_dbo.V_Liabilities.RealizedEquity` for DateID = yesterday. Represents equity excluding unrealized position gains/losses. (Tier 2 — SP_AM_Contacted) |
| 15 | Desk | varchar(100) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 — Ext_Dim_Country_Region_Desk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Renamed passthrough (RealCID AS CID) |
| Last30DaysContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CID | CASE: 1 if ActionName IN Phone/Email within 30d, else 0 |
| Last30DaysPhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | CASE: 1 if Phone_Call_Succeed__c within 30d, else 0 |
| Last60DaysContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CID | Same as 30d variant; 60-day window |
| Last60DaysPhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | Same as 30d phone; 60-day window |
| Last30DaysContactedAttempt | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CID | CASE: 1 if Phone_Call_Succeed__c OR Contacted__c within 30d |
| ManagerID | DWH_dbo.Dim_Customer | AccountManagerID | Passthrough via Dim_Manager JOIN |
| Region | DWH_dbo.Dim_Country | Region | JOIN: Dim_Customer.CountryID → Dim_Country.Region |
| AccountManager | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenated: FirstName + ' ' + LastName |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN: Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name |
| UpdateDate | ETL | N/A | CAST(GETDATE() AS DATE) |
| Last30DaysPhoneContactedAttempt | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | CASE: 1 if PhoneCallAttempt flag in sf3 |
| Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | Liabilities + ActualNWA for yesterday's DateID |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough for yesterday's DateID |
| Desk | DWH_dbo.Dim_Country | Desk | JOIN: Dim_Customer.CountryID → Dim_Country.Desk |

### 5.2 ETL Pipeline

```
eToro Salesforce CRM
  Contact events (phone, email, attempts)
    |-- BI_DB_dbo.BI_DB_UsageTracking_SF (Priority 70, daily) ---|
    v
  3 temp tables: #SF1 (30d), #SF2 (60d), #SF3 (30d attempts + ManagerID 1151-1154)

DWH_dbo.Dim_Customer   [RealCID, AccountManagerID, PlayerLevelID, CountryID, FirstDepositDate]
DWH_dbo.Dim_Manager    [ManagerID, FirstName, LastName, IsActive]
DWH_dbo.Dim_Country    [Region, Desk]
DWH_dbo.Dim_PlayerLevel [Name -> Club]
DWH_dbo.V_Liabilities  [RealizedEquity, Liabilities, ActualNWA | DateID=yesterday]
    |-- SP_AM_Contacted -------------------------------------|
    |   Schedule: Daily, SB_Daily, Priority 20              |
    |   Load: DELETE today + DELETE >120d + INSERT today    |
    v
BI_DB_dbo.BI_DB_AM_Contacted
  296.6M rows | 2.5M distinct CIDs
  Rolling 120-day window (2025-12-14 to 2026-04-13)
  Contact rate 0.7% per latest date
    |-- Not yet migrated to UC ---|
    v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer master — the primary driver; only managed customers (AccountManagerID IS NOT NULL) appear |
| ManagerID | DWH_dbo.Dim_Manager | Account manager details (name, active status) |
| Region, Desk | DWH_dbo.Dim_Country | Country-level marketing segmentation |
| Club | DWH_dbo.Dim_PlayerLevel | Customer loyalty tier |
| Contact flags | BI_DB_dbo.BI_DB_UsageTracking_SF | Source Salesforce action log |
| Equity, RealizedEquity | DWH_dbo.V_Liabilities | Yesterday's financial position |

### 6.2 Referenced By (other objects point to this)

No BI_DB_dbo views or documented tables reference this table. It is consumed directly by Account Management reporting tools and CRM dashboards.

---

## 7. Sample Queries

### 7.1 Latest Contact Status for All Managed Customers

```sql
SELECT
    CID,
    AccountManager,
    Region,
    Club,
    Equity,
    Last30DaysContacted,
    Last30DaysPhoneContacted,
    Last30DaysContactedAttempt,
    UpdateDate
FROM [BI_DB_dbo].[BI_DB_AM_Contacted]
WHERE UpdateDate = (SELECT MAX(UpdateDate) FROM [BI_DB_dbo].[BI_DB_AM_Contacted])
ORDER BY Equity DESC;
```

### 7.2 High-Value Customers Not Contacted in 60 Days (AM Prioritization)

```sql
SELECT
    CID,
    AccountManager,
    Desk,
    Club,
    Equity,
    Last60DaysContacted
FROM [BI_DB_dbo].[BI_DB_AM_Contacted]
WHERE UpdateDate = (SELECT MAX(UpdateDate) FROM [BI_DB_dbo].[BI_DB_AM_Contacted])
  AND Last60DaysContacted = 0
  AND Equity > 5000
  AND Club IN ('Diamond', 'Platinum Plus', 'Platinum')
ORDER BY Equity DESC;
```

### 7.3 Daily Contact Rate Trend by Desk (Last 30 Days)

```sql
SELECT
    UpdateDate,
    Desk,
    COUNT(*) AS total_customers,
    SUM(Last30DaysContacted) AS contacted,
    CAST(SUM(Last30DaysContacted) * 100.0 / COUNT(*) AS decimal(5,2)) AS contact_pct
FROM [BI_DB_dbo].[BI_DB_AM_Contacted]
WHERE UpdateDate >= DATEADD(day, -30, CAST(GETDATE() AS DATE))
GROUP BY UpdateDate, Desk
ORDER BY UpdateDate DESC, contact_pct DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available in this session. DATA Confluence space may contain Account Management SLA and contact policy documentation. BI_DB_UsageTracking_SF (Batch 7 #3) documents the underlying Salesforce action log source.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 13/14 (P10 Jira skipped — no MCP)*
*Tiers: 1 T1, 13 T2, 1 T3, 0 T4 | Elements: 15/15, Logic: 9/10, ETL: 9/10, Upstream: 8/10*
*Object: BI_DB_dbo.BI_DB_AM_Contacted | Type: Table | Production Source: BI_DB_UsageTracking_SF + DWH_dbo.Dim_Customer + DWH_dbo.V_Liabilities*
