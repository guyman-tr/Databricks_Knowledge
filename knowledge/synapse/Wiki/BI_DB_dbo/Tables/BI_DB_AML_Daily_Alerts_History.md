# BI_DB_dbo.BI_DB_AML_Daily_Alerts_History

> Historical archive of AML daily alert records — same 16-column schema as `BI_DB_AML_Daily_Alerts`, storing the long-term history of AML alerts that were active through at least November 2024. Currently **empty (0 rows as of 2026-04-23)**. No active writer SP in the SSDT repo. Population origin: Google Sheet (AML analyst-maintained) → `BI_DB_AML_Daily_Alerts_From_oglesheet` (staging) → `BI_DB_AML_Daily_Alerts` (main) → this History archive. ROUND_ROBIN, CLUSTERED on AlertDate. **Key difference from sibling**: `AlertDetails` is `nvarchar(2048)` (bounded) here vs `nvarchar(max)` in the main table, suggesting History was created from the staging table DDL or an older schema version.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — AML daily alert historical archive |
| **Production Source** | External AML monitoring system + Google Sheet (AML analyst-maintained); archived from `BI_DB_AML_Daily_Alerts` |
| **Refresh** | Inactive — table currently empty; no SSDT writer SP found; was active through Nov 2024 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (AlertDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23; backup from 2024-11-17 confirms historical data existed with CID as bigint) |
| **Sibling Table** | BI_DB_AML_Daily_Alerts (main reporting table), BI_DB_AML_Daily_Alerts_From_oglesheet (Google Sheet staging) |

---

## 1. Business Meaning

`BI_DB_AML_Daily_Alerts_History` is the **long-term historical archive** of AML daily alert records. It stores the same 16-column AML alert structure as `BI_DB_AML_Daily_Alerts` — the active reporting table — but accumulates rows across time rather than reflecting the current active state.

Each row represents one AML alert event, capturing:
- **Who**: CID, Name, Country, AccountType, Regulation — customer context at time of archival
- **What**: AlertID, AlertType, AlertCategory, AlertDetails — the specific alert and classification
- **When**: AlertDate — the date the alert was generated (cluster key)
- **Status**: AlertStatus, Assigned — investigation state and responsible analyst
- **Player state**: PlayerStatus, PreviousStatus — account standing at time of alert

**Pipeline context**: The AML daily alerts system flows as:
1. Google Sheet (AML analysts enter/review alerts) → `BI_DB_AML_Daily_Alerts_From_oglesheet` (staging, bounded nvarchar)
2. Staging → `BI_DB_AML_Daily_Alerts` (main reporting table, nvarchar(max))
3. Main table → `BI_DB_AML_Daily_Alerts_History` (historical archive — this table)

No SSDT stored procedure writes to this table — the archival process was either manual, ad-hoc scripted, or maintained outside the SSDT project. The pipeline is currently inactive (all three tables in the cluster are empty as of 2026-04-23).

**AlertDetails size**: This table has `AlertDetails nvarchar(2048)` — the same bounded size as the From_oglesheet staging table — rather than `nvarchar(max)` from the main AML_Daily_Alerts table. This indicates the History table was likely populated from the staging-side data or predates the unbounded DDL change in the main table.

**Backup evidence**: A Nov 2024 backup (`2024_12_01_21_07_42_BI_DB_dbo.BI_DB_AML_Daily_Alerts_History_Backup_20241117.sql`) confirms the table existed with data and CID as `bigint` at that time. The current DDL shows CID as `int` — the same type change applied to the sibling table in the decommissioning cleanup.

---

## 2. Business Logic

### 2.1 Archive Relationship to Main Table

**What**: History stores the accumulative record of alerts that have passed through the active AML_Daily_Alerts table.

**Columns Involved**: All 16 columns (same schema as sibling)

**Rules**:
- Rows are archived from `BI_DB_AML_Daily_Alerts` (main) into this History table — no separate ETL populates History directly
- The CLUSTERED INDEX on AlertDate (same as main table) enables efficient date-range scans for historical trend analysis
- No HARD deletion of rows expected — History is an append-only archive by design

### 2.2 Schema Differences from AML_Daily_Alerts (Main Table)

**What**: AlertDetails is bounded in History but unbounded in the main table.

**Columns Involved**: `AlertDetails`

**Rules**:
- `AlertDetails [nvarchar](2048)` in this table vs `[nvarchar](max)` in `BI_DB_AML_Daily_Alerts`
- `AlertDetails [nvarchar](2048)` in `BI_DB_AML_Daily_Alerts_From_oglesheet` (staging) — matches History
- Data archived to History may have `AlertDetails` truncated at 2,048 characters if the main table had longer values

### 2.3 CID Type Change

**What**: CID changed from bigint (historical) to int (current DDL).

**Columns Involved**: `CID`

**Rules**:
- Nov 2024 backup had CID as `bigint`; current DDL has `int`
- Same schema change applied to all three sibling tables in the cluster
- Any restore or migration from the Nov 2024 backup will encounter a type mismatch

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with CLUSTERED INDEX on AlertDate. With 0 current rows, all queries return empty results. When data exists: date-range scans on AlertDate are efficient; per-customer lookups on CID require full table scan (no index on CID).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Historical alert volume by day? | `SELECT AlertDate, COUNT(*) AS AlertCount FROM ... GROUP BY AlertDate ORDER BY AlertDate` |
| Alert breakdown by type over time? | `SELECT AlertCategory, AlertType, COUNT(*) FROM ... GROUP BY AlertCategory, AlertType ORDER BY 3 DESC` |
| Alerts for a specific historical customer? | `SELECT * FROM ... WHERE CID = 12345 ORDER BY AlertDate DESC` |
| Status at time of alert vs current? | Join `CID` to `DWH_dbo.Dim_Customer.RealCID` for current state; use `PlayerStatus` column for historical state |
| Compare with current active alerts? | `UNION ALL` with `BI_DB_AML_Daily_Alerts` on matching columns |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Get current customer profile (historical state is in Name/Country/etc. columns) |
| BI_DB_AML_Daily_Alerts | `ON AlertID = a.AlertID` | Compare historical archive with current active alerts |
| BI_DB_AML_Benchmarks_AML_Alerts | `ON CID = b.CID` | Cross-reference with AML-driven PlayerStatus change events |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-23 — no current data available. Historical data existed through at least Nov 2024.
- **AlertDetails bounded at 2048 chars**: Unlike the main `BI_DB_AML_Daily_Alerts` table (nvarchar(max)), this table truncates AlertDetails at 2,048 characters. Long alert narratives may be cut off.
- **CID type change**: CID was `bigint` in Nov 2024 backup; now `int`. Any restore from backup requires type coercion.
- **RelatedAccounts is multi-value string**: Cannot be joined directly. Parse with `STRING_SPLIT()` if you need individual related CIDs.
- **PlayerStatus stored as string**: Not an integer ID — cannot join to `Dim_PlayerStatus.PlayerStatusID`. Use name matching.
- **All columns nullable**: No mandatory fields — rows may have partial data.
- **No active writer SP**: No stored procedure populates this table in the SSDT repo. The archival mechanism is unknown.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from writer SP code (source-to-target mapping) |
| Tier 3 | Inferred from DDL, column name patterns, live Dim table data, or sibling table docs |
| Tier 4 | Best-guess — no definitive source found |
| Tier 5 | Propagation constant (ETL metadata — UpdateDate) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AlertID | nvarchar(max) | YES | Unique identifier for the AML alert — sourced from the upstream AML monitoring system. Not a Synapse-generated key. (Tier 4 — external AML tool) |
| 2 | AlertType | nvarchar(max) | YES | Type of AML alert — specific rule or mechanism that triggered the alert (e.g., 'Transaction Monitoring', 'PEP Match', 'Sanctions Hit'). Narrower than AlertCategory. (Tier 4 — external AML tool) |
| 3 | CID | int | YES | Customer ID of the alerted customer. FK to DWH_dbo.Dim_Customer.RealCID. **Note**: was `bigint` in Nov 2024 backup — schema changed to `int`. (Tier 4 — external AML tool) |
| 4 | Name | nvarchar(max) | YES | Customer's full name — denormalized snapshot from DWH_dbo.Dim_Customer at alert population time. May not reflect current customer name. (Tier 3 — Dim_Customer) |
| 5 | Country | nvarchar(max) | YES | Customer's country — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 6 | AccountType | nvarchar(max) | YES | Customer account type (e.g., 'Retail', 'Corporate') — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 7 | AlertDate | datetime | YES | Date and time the AML alert was generated. Cluster key — primary access dimension for date-range scans. (Tier 4 — external AML tool) |
| 8 | Regulation | nvarchar(max) | YES | Regulatory jurisdiction applicable to the customer (e.g., 'FCA', 'CySEC', 'ASIC') — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 9 | RelatedAccounts | nvarchar(max) | YES | Other CIDs related to this AML alert (network-linked accounts). Stored as free-text — likely comma-separated CID values. Not normalized; requires string parsing. (Tier 4 — external AML tool) |
| 10 | PlayerStatus | nvarchar(max) | YES | Customer's PlayerStatus account standing at time of the alert, stored as name string (e.g., 'Normal', 'Blocked', 'Warning'). See DWH_dbo.Dim_PlayerStatus for full value list. Not an integer ID. (Tier 3 — Dim_PlayerStatus) |
| 11 | AlertStatus | nvarchar(max) | YES | Current investigation status of the AML alert (e.g., 'Open', 'In Review', 'Closed', 'Escalated'). Maintained by the AML analyst during case investigation. (Tier 4 — external AML tool / Google Sheet) |
| 12 | Assigned | nvarchar(max) | YES | Name of the AML analyst assigned to investigate this alert. Free-text name string — no FK to a personnel table. (Tier 4 — Google Sheet / AML tool) |
| 13 | AlertDetails | nvarchar(2048) | YES | Free-text description of why the AML alert was triggered. **Bounded at 2,048 chars** in this History table (vs nvarchar(max) in the main AML_Daily_Alerts table) — long narratives may be truncated. (Tier 4 — external AML tool / Google Sheet) |
| 14 | PreviousStatus | nvarchar(max) | YES | Customer's PlayerStatus before any action taken as a result of this alert — stored as name string. Enables before/after comparison within a single row. (Tier 3 — Dim_PlayerStatus) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — ETL metadata) |
| 16 | AlertCategory | nvarchar(max) | YES | Higher-level category grouping for the alert type (e.g., 'Screening', 'Transaction Monitoring', 'Regulatory'). Broader than AlertType; may be used for dashboard-level reporting. (Tier 4 — external AML tool) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AlertID, AlertType, AlertCategory | External AML monitoring tool | alert_id, alert_type, alert_category | Passthrough from AML system |
| CID, AlertDate, RelatedAccounts | External AML monitoring tool | customer_id, alert_date, related_accounts | Passthrough; CID type changed bigint→int |
| Name, Country, AccountType, Regulation | DWH_dbo.Dim_Customer (at load time) | FullName, Country, AccountType, Regulation | Denormalized snapshot at load time |
| PlayerStatus, PreviousStatus | DWH_dbo.Dim_PlayerStatus (at load time) | PlayerStatusName | Denormalized name (not ID) at load time |
| AlertStatus, Assigned, AlertDetails | Google Sheet (AML analyst) | Manual analyst entry | Passthrough from Google Sheet; AlertDetails bounded at 2048 |
| UpdateDate | ETL metadata | GETDATE() | Pipeline run timestamp |

### 5.2 ETL Pipeline

```
AML monitoring system (NICE Actimize / Oracle FCCM / equivalent)
  |-- Alert export → Google Sheet (AML analysts review/augment) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet (staging; bounded nvarchar, AlertDetails=2048)
  |-- ETL transfer (external/ad-hoc) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts (main reporting; nvarchar(max); 0 rows, inactive 2026-04-23)
  |-- Archive process (no SSDT SP; ad-hoc or script-based) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_History (historical archive; AlertDetails=nvarchar(2048); 0 rows, inactive)
  |-- No UC Gold target ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity reference via RealCID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status name lookup (stored as string, not ID) |
| PreviousStatus | DWH_dbo.Dim_PlayerStatus | Prior status name lookup (stored as string, not ID) |

### 6.2 Referenced By (other objects read from this)

| Object | Relationship |
|--------|-------------|
| BI_DB_AML_Daily_Alerts | Source table — rows are archived from Daily_Alerts into this History table |

---

## 7. Sample Queries

### 7.1 Historical alert volume by date (when data exists)

```sql
SELECT
    CAST(AlertDate AS DATE) AS AlertDateDay,
    COUNT(*) AS AlertCount,
    COUNT(DISTINCT CID) AS DistinctCustomers
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_History]
GROUP BY CAST(AlertDate AS DATE)
ORDER BY AlertDateDay DESC;
```

### 7.2 Historical alerts with player status changes

```sql
SELECT
    AlertID,
    CID,
    AlertType,
    AlertDate,
    PlayerStatus,
    PreviousStatus,
    AlertStatus
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_History]
WHERE PlayerStatus <> PreviousStatus
  AND PlayerStatus IS NOT NULL
  AND PreviousStatus IS NOT NULL
ORDER BY AlertDate DESC;
```

### 7.3 Combine with current active alerts for full history

```sql
-- Full history including current active alerts
SELECT 'History' AS Source, * FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts_History]
UNION ALL
SELECT 'Active' AS Source, * FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts]
ORDER BY AlertDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. For AML daily alerts context see the parent table wiki (`BI_DB_AML_Daily_Alerts`).

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 11/14 (P10 Atlassian skipped — AML tool external, no Confluence pages; P3 Dist skipped — 0 rows; no SP for P9)*
*Tiers: 0 T1, 0 T2, 5 T3, 10 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Relationships: 7/10, Sources: 5/10*
*Object: BI_DB_dbo.BI_DB_AML_Daily_Alerts_History | Type: Table | Production Source: External AML tool (inactive) | Priority: 0 (not in OpsDB) | Refresh: Inactive*
