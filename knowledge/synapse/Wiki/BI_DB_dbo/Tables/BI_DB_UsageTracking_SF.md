# BI_DB_dbo.BI_DB_UsageTracking_SF

> Salesforce CRM account activity log — records every account-level action taken by customer service and account management reps, enabling tracking of rep-to-customer contact history and funnel activity analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — event log) |
| **Production Source** | Salesforce CRM → DLT-CRM pipeline → ADLS Gold/CRM/UsageTracking/*.parquet |
| **Refresh** | Full refresh — TRUNCATE + INSERT (SP_UsageTracking_SF, no date param) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CreatedDate_SF ASC, CID ASC) |
| **Synapse NCI** | NCL_IX_BI_DBUsageTrackingSF_CID_ActionName (CID, ActionName) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_UsageTracking_SF` captures every account-level activity event from the Salesforce CRM system. Each row represents an action taken on a customer account — such as a call, email, case update, or ownership change — along with who performed the action and when.

This table is one of the most widely consumed tables in the BI_DB schema, referenced by 17+ SPs across account management, reporting, and compliance workflows. Key use cases:
- **Contact tracking**: Which rep last contacted a customer, and when
- **Funnel analysis**: Tracking customer engagement through conversion stages
- **High-value customer management**: Identifying recent rep activity on high-balance customers before cashout approvals
- **CID first dates**: Determining the first date of various activities per customer

Data originates from Salesforce, flows through the DLT-CRM pipeline to ADLS Gold layer, and is loaded via COPY INTO. Originally populated via SSIS (migrated 2024-04-03 by Katy F).

---

## 2. Business Logic

### 2.1 Deduplication

**What**: Source data is deduplicated during load.

**Rules**:
- GROUP BY all columns except CreatedDate and UpdateDate
- `CreatedDate` = MIN(CreatedDate) from the group — takes the earliest creation timestamp per unique event

### 2.2 Manager Resolution

**What**: Manager context for the rep who performed the action.

**Columns Involved**: `ManagerID`, `CreatedByManagerID`

**Rules**:
- `CreatedByManagerID` = `ManagerID` — they are the same value (duplicated in the INSERT)
- Represents the internal manager ID of the rep who created/performed the action

### 2.3 Full Refresh

**What**: The entire table is rebuilt each load.

**Rules**:
- TRUNCATE TABLE before INSERT — no incremental logic
- Complete historical CRM activity is reloaded from ADLS Gold parquet files each run

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: No distribution key — the table is accessed in diverse patterns.

**CLUSTERED INDEX (CreatedDate_SF ASC, CID ASC)**: Efficient for date-range + customer queries.

**NCI (CID, ActionName)**: Covers the common pattern of filtering by customer + specific action type.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer details |
| BI_DB_dbo.BI_DB_CID_DailyPanel | ON CID | Daily panel enrichment |

### 3.3 Gotchas

- **Full TRUNCATE refresh**: There is no date filter — the entire table is rebuilt every load. Query timing matters for data freshness.
- **ActionName truncation**: Source ActionName is varchar(200) but target is varchar(50). Long action names may be truncated.
- **Salesforce IDs are 18-char nvarchar**: AccountHistoryID, AccountID, CreatedByID, OwnerID are Salesforce record IDs — always 18 characters.
- **CreatedByManagerID = ManagerID**: These are always the same value. The duplication appears intentional for consumer SP compatibility.
- **No ID column in INSERT**: The `ID` column appears to be auto-generated (likely IDENTITY) — not populated by the SP.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_UsageTracking_SF) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NULL | Auto-generated surrogate key. Not populated by the writer SP — likely IDENTITY column. (Tier 4 — [UNVERIFIED]) |
| 2 | AccountHistoryID | nvarchar(18) | NULL | Salesforce Account History record ID (18-char SF ID). Unique per history event. (Tier 2 — SP_UsageTracking_SF) |
| 3 | AccountID | nvarchar(18) | NULL | Salesforce Account record ID. Links to the customer's SF Account object. (Tier 2 — SP_UsageTracking_SF) |
| 4 | ActionName | varchar(50) | NULL | Type of CRM action performed (e.g., call, email, case update, ownership change). Truncated from 200-char source. (Tier 2 — SP_UsageTracking_SF) |
| 5 | CreatedByID | nvarchar(18) | NULL | Salesforce User ID of the rep who performed the action. (Tier 2 — SP_UsageTracking_SF) |
| 6 | CreatedDate_SF | datetime | NULL | Timestamp when the action was recorded in Salesforce. Clustered index key. (Tier 2 — SP_UsageTracking_SF) |
| 7 | OwnerID | nvarchar(18) | NULL | Salesforce User ID of the account owner at the time of the action. (Tier 2 — SP_UsageTracking_SF) |
| 8 | ManagerID | int | NULL | Internal manager ID of the rep who performed the action. Maps to internal HR/management hierarchy. (Tier 4 — [UNVERIFIED]) |
| 9 | CID | int | NULL | Customer ID mapped from the Salesforce Account. FK to Dim_Customer. (Tier 2 — SP_UsageTracking_SF) |
| 10 | CreatedDate | datetime | NULL | Earliest creation timestamp for this event group (MIN after dedup). May differ from CreatedDate_SF. (Tier 2 — SP_UsageTracking_SF) |
| 11 | CreatedByManagerID | int | NULL | Duplicate of ManagerID — the internal manager of the rep who performed the action. Always equals ManagerID. (Tier 2 — SP_UsageTracking_SF) |
| 12 | UpdateDate | datetime | NULL | ETL load timestamp — GETDATE(). (Tier 2 — SP_UsageTracking_SF) |

---

## 5. Lineage

### 5.1 Pipeline

```
Salesforce CRM (Account History)
  → DLT-CRM pipeline (Azure)
    → ADLS Gold: dldataplatformprodwe.dfs.core.windows.net/internal-sources/Gold/CRM/UsageTracking/*.parquet
      │
      └─ SP_UsageTracking_SF
          ├─ COPY INTO #UsageTracking (from ADLS parquet)
          ├─ TRUNCATE TABLE BI_DB_UsageTracking_SF
          └─ INSERT (GROUP BY dedup + MIN(CreatedDate) + GETDATE())
```

### 5.2 Key Source Tables

| Source | Columns Used |
|--------|-------------|
| Gold/CRM/UsageTracking (parquet) | AccountHistoryID, AccountID, ActionName, CreatedByID, CreatedDate_SF, OwnerID, CID, ManagerID, CreatedDate |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | CID | Customer details |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_CIDFirstDates | CID, CreatedDate_SF | First activity dates per customer |
| SP_AM_Contacted | CID, ActionName | Account manager contact tracking |
| SP_AM_Portfolio_Summary | CID | Portfolio summary with SF activity |
| SP_CID_DailyPanel_Club | CID | Daily panel enrichment |
| SP_CIDFunnelFlow | CID, ActionName | Funnel flow analysis |
| SP_NewContactActivityPerRep | CreatedByID, ActionName | Per-rep activity reporting |
| SP_InvestorReportDetails | CID | Investor report enrichment |
| (+ 10 more consumer SPs) | various | Reporting, compliance, management dashboards |

---

## 7. Sample Queries

### 7.1 Recent activity per customer

```sql
SELECT  CID, ActionName, CreatedDate_SF, CreatedByID
FROM    [BI_DB_dbo].[BI_DB_UsageTracking_SF]
WHERE   CID = 12345678
ORDER BY CreatedDate_SF DESC;
```

### 7.2 Activity volume by action type

```sql
SELECT  ActionName,
        COUNT(*) AS ActionCount,
        COUNT(DISTINCT CID) AS UniqueCustomers,
        MIN(CreatedDate_SF) AS FirstSeen,
        MAX(CreatedDate_SF) AS LastSeen
FROM    [BI_DB_dbo].[BI_DB_UsageTracking_SF]
WHERE   CreatedDate_SF >= '2026-01-01'
GROUP BY ActionName
ORDER BY ActionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Salesforce](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/13482328083) | Confluence | Salesforce is eToro's CRM — used for communication with clients and collaboration |
| [Big Data Platform migration](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/1942847659) | Confluence | Documents BI_DB InterestDaily and other external source assignments |

---

*Generated: 2026-03-22 | Quality: 7.5/10 (★★★☆☆) | Phases: 12/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 10 T2, 0 T3, 2 T4 [UNVERIFIED] (ID auto-gen, ManagerID source), 0 T5 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_UsageTracking_SF | Type: Table | Source: Salesforce CRM → DLT-CRM → ADLS Gold/CRM/UsageTracking*
