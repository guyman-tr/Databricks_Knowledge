# BI_DB_dbo.BI_DB_AML_Daily_Alerts

> AML daily alert tracking table — each row records one AML alert event for a customer, capturing the alert identifier, type, category, affected customer (CID/Name/Country/AccountType/Regulation), alert date, related accounts, current and prior PlayerStatus, alert investigation status, assigned analyst, and free-text alert details. Currently **empty (0 rows as of 2026-04-23)** but was active through at least November 2024. No SSDT writer SP found; populated via Google Sheet (AML analyst-maintained) → `BI_DB_AML_Daily_Alerts_From_oglesheet` staging → this table. Distribution: ROUND_ROBIN, CLUSTERED on AlertDate. **Note**: CID was `bigint` in Nov 2024 backup; changed to `int` in current DDL.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — AML daily alert log |
| **Production Source** | External AML monitoring system + Google Sheet (AML analyst-maintained) |
| **Refresh** | Unknown — table currently empty; was active through Nov 2024 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (AlertDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23; backup from 2024-11-17 confirms historical data existed) |
| **Related Tables** | BI_DB_AML_Daily_Alerts_From_oglesheet (Google Sheet staging), BI_DB_AML_Daily_Alerts_History (historical archive), DWH_dbo.Dim_PlayerStatus (PlayerStatus lookup) |

---

## 1. Business Meaning

`BI_DB_AML_Daily_Alerts` is an **AML daily alert log** that tracks each AML alert generated for eToro customers. Each row represents one alert event — recording who was alerted, what triggered the alert, the investigation status, and which analyst is responsible.

The table captures:
- **Who**: CID, Name, Country, AccountType, Regulation — full customer context denormalized at alert time
- **What**: AlertID, AlertType, AlertCategory, AlertDetails — the specific alert and its classification
- **When**: AlertDate — the date the alert was generated (cluster key)
- **Status**: AlertStatus, Assigned — current investigation state and responsible analyst
- **Player state**: PlayerStatus, PreviousStatus — customer account standing at time of alert

**"Daily Alerts" context**: AML monitoring systems (e.g., NICE Actimize, Oracle FCCM) generate alerts daily based on transaction pattern rules, sanctions screening, PEP (Politically Exposed Persons) matches, and behavioral analytics. This table is the Synapse landing zone for those alerts, enabling BI reporting on alert volumes, analyst workloads, and alert-to-action conversion rates.

**ETL pipeline**: Google Sheet (AML analysts enter/review alerts) → `BI_DB_AML_Daily_Alerts_From_oglesheet` (staging; confirmed by "oglesheet" naming convention and bounded nvarchar column lengths) → `BI_DB_AML_Daily_Alerts` (main reporting table) → `BI_DB_AML_Daily_Alerts_History` (historical archive).

**Current status**: Empty (0 rows as of 2026-04-23). A backup taken 2024-11-17 confirms the table was active. The table is either decommissioned, migrated to a new system, or temporarily cleared pending a pipeline rebuild.

---

## 2. Business Logic

### 2.1 AML Alert Lifecycle Tracking

**What**: Each row represents one AML alert in its current state.
**Columns Involved**: AlertID, AlertType, AlertCategory, AlertDate, AlertStatus, Assigned, AlertDetails
**Rules**:
- `AlertID` is the unique identifier from the upstream AML system — not a Synapse-generated key
- `AlertDate` is the date the alert was generated (not the date it was investigated or closed)
- `AlertStatus` tracks the investigation lifecycle: expected values include Open, In Review, Closed, Escalated — exact values from AML tool (nvarchar, no FK constraint)
- `Assigned` stores the analyst's name (not an ID) — no FK to a People/HR table
- `AlertCategory` provides high-level grouping (e.g., "Transaction Monitoring", "Sanctions Screening", "PEP") — broader than `AlertType`

### 2.2 Customer Context Denormalization

**What**: Key customer attributes are copied from Dim_Customer at alert population time.
**Columns Involved**: CID, Name, Country, AccountType, Regulation, PlayerStatus, PreviousStatus
**Rules**:
- Name, Country, AccountType, Regulation are denormalized snapshots — may not reflect current customer state if customer details changed after the alert was logged
- `PlayerStatus` is the customer's account status **at alert time** (stored as name string, not integer ID)
- `PreviousStatus` is the player status **before** any action taken as a result of this alert
- Both PlayerStatus columns use name strings (nvarchar(max)) — not the integer IDs from Dim_PlayerStatus

### 2.3 Related Accounts (Multi-Value Field)

**What**: `RelatedAccounts` stores other customer IDs linked to the same AML alert.
**Columns Involved**: RelatedAccounts
**Rules**:
- Stored as nvarchar(max) — not normalized
- Likely contains comma-separated or pipe-separated CID values (e.g., `"12345, 67890"`)
- Represents network-linked accounts flagged by the AML system as connected to the primary alerted customer
- Cannot be directly joined — requires string parsing to extract individual CIDs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on AlertDate. Efficient for date-range scans on AlertDate; per-customer lookups require full table scan (CID not indexed).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Alert volume by day? | `SELECT AlertDate, COUNT(*) AS AlertCount FROM ... GROUP BY AlertDate ORDER BY AlertDate` |
| Alert breakdown by type and category? | `SELECT AlertCategory, AlertType, COUNT(*) FROM ... GROUP BY AlertCategory, AlertType ORDER BY 3 DESC` |
| Open alerts by assigned analyst? | `SELECT Assigned, COUNT(*) FROM ... WHERE AlertStatus = 'Open' GROUP BY Assigned ORDER BY 2 DESC` |
| Alerts for a specific customer? | `SELECT * FROM ... WHERE CID = 12345 ORDER BY AlertDate DESC` |
| Alerts that resulted in player status change? | `SELECT * FROM ... WHERE PlayerStatus <> PreviousStatus` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Get current customer profile (note: Name/Country in this table are historical snapshots) |
| BI_DB_AML_Daily_Alerts_History | `ON AlertID = h.AlertID` | Access historical/archived alert records |
| BI_DB_AML_Benchmarks_AML_Alerts | `ON CID = b.CID` | Cross-reference with AML-driven PlayerStatus change events |
| BI_DB_AML_Benchmarks_Risk_Classification | `ON CID = r.CID` | Cross-reference with AML-driven risk classification changes |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-23 — no current data available. Historical data existed through Nov 2024.
- **CID type change**: CID was `bigint` in the Nov 2024 backup and is `int` in the current DDL. Any restore or migration from backup will hit a type mismatch.
- **RelatedAccounts is a multi-value string**: Cannot be joined directly. Parse with `STRING_SPLIT()` if you need individual related CIDs.
- **PlayerStatus stored as string**: Not an integer ID — cannot join to `Dim_PlayerStatus.PlayerStatusID` directly. Use name matching or a lookup/CASE expression.
- **All columns nullable**: No mandatory fields — rows from Google Sheet imports may have partial data.
- **Denormalized customer attributes**: Name, Country, AccountType, Regulation reflect the customer's state **at alert time** — they may differ from current `Dim_Customer` values.
- **AlertDetails is nvarchar(max)**: Can contain lengthy free-text. Avoid `SELECT *` or `SELECT AlertDetails` on large result sets.

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
| 1 | AlertID | nvarchar(max) | NULL | Unique identifier for the AML alert — sourced from the upstream AML monitoring system. Not a Synapse-generated key. (Tier 4 — external AML tool) |
| 2 | AlertType | nvarchar(max) | NULL | Type of AML alert — specific rule or mechanism that triggered the alert (e.g., 'Transaction Monitoring', 'PEP Match', 'Sanctions Hit'). Narrower than AlertCategory. (Tier 4 — external AML tool) |
| 3 | CID | int | NULL | Customer ID of the alerted customer. FK to DWH_dbo.Dim_Customer.RealCID. **Note**: was `bigint` in Nov 2024 backup — schema changed to `int`. (Tier 4 — external AML tool) |
| 4 | Name | nvarchar(max) | NULL | Customer's full name — denormalized snapshot from DWH_dbo.Dim_Customer at alert population time. May not reflect current customer name. (Tier 3 — Dim_Customer) |
| 5 | Country | nvarchar(max) | NULL | Customer's country — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 6 | AccountType | nvarchar(max) | NULL | Customer account type (e.g., 'Retail', 'Corporate') — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 7 | AlertDate | datetime | NULL | Date and time the AML alert was generated. Cluster key — primary access dimension for date-range scans. (Tier 4 — external AML tool) |
| 8 | Regulation | nvarchar(max) | NULL | Regulatory jurisdiction applicable to the customer (e.g., 'FCA', 'CySEC', 'ASIC') — denormalized snapshot at alert population time. (Tier 3 — Dim_Customer) |
| 9 | RelatedAccounts | nvarchar(max) | NULL | Other CIDs related to this AML alert (network-linked accounts). Stored as free-text — likely comma-separated CID values. Not normalized; requires string parsing. (Tier 4 — external AML tool) |
| 10 | PlayerStatus | nvarchar(max) | NULL | Customer's PlayerStatus account standing at time of the alert, stored as name string (e.g., 'Normal', 'Blocked', 'Warning'). See DWH_dbo.Dim_PlayerStatus for full value list. Not an integer ID. (Tier 3 — Dim_PlayerStatus) |
| 11 | AlertStatus | nvarchar(max) | NULL | Current investigation status of the AML alert (e.g., 'Open', 'In Review', 'Closed', 'Escalated'). Maintained by the AML analyst during case investigation. (Tier 4 — external AML tool / Google Sheet) |
| 12 | Assigned | nvarchar(max) | NULL | Name of the AML analyst assigned to investigate this alert. Free-text name string — no FK to a personnel table. (Tier 4 — Google Sheet / AML tool) |
| 13 | AlertDetails | nvarchar(max) | NULL | Free-text description of why the AML alert was triggered. Can contain lengthy narrative. Avoid in SELECT * on large result sets. (Tier 4 — external AML tool / Google Sheet) |
| 14 | PreviousStatus | nvarchar(max) | NULL | Customer's PlayerStatus before any action taken as a result of this alert — stored as name string. Enables before/after comparison within a single row. (Tier 3 — Dim_PlayerStatus) |
| 15 | UpdateDate | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — ETL metadata) |
| 16 | AlertCategory | nvarchar(max) | NULL | Higher-level category grouping for the alert type (e.g., 'Screening', 'Transaction Monitoring', 'Regulatory'). Broader than AlertType; may be used for dashboard-level reporting. (Tier 4 — external AML tool) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AlertID, AlertType, AlertCategory | External AML monitoring tool | alert_id, alert_type, alert_category | Passthrough from AML system |
| CID, AlertDate, RelatedAccounts | External AML monitoring tool | customer_id, alert_date, related_accounts | Passthrough; CID type changed bigint→int |
| Name, Country, AccountType, Regulation | DWH_dbo.Dim_Customer (at load time) | FullName, Country, AccountType, Regulation | Denormalized snapshot at load time |
| PlayerStatus, PreviousStatus | DWH_dbo.Dim_PlayerStatus (at load time) | PlayerStatusName | Denormalized name (not ID) at load time |
| AlertStatus, Assigned, AlertDetails | Google Sheet (AML analyst) | Manual analyst entry | Passthrough from Google Sheet columns |
| UpdateDate | ETL metadata | GETDATE() | Pipeline run timestamp |

### 5.2 ETL Pipeline

```
AML monitoring system (NICE Actimize / Oracle FCCM / equivalent)
  |-- Alert export → Google Sheet (AML team reviews/augments) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet (Google Sheet staging; 16 cols with bounded nvarchar)
  |-- ETL transfer (external script) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts (main reporting table; nvarchar(max); 0 rows, inactive as of 2026-04-23)
  |-- Archive process ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_History (historical archive; 0 rows, inactive)
  |-- No UC Gold target ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity reference |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status name lookup (stored as string, not ID) |
| PreviousStatus | DWH_dbo.Dim_PlayerStatus | Prior status name lookup (stored as string, not ID) |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_AML_Daily_Alerts_History | Archive target of this table |

---

## 7. Sample Queries

### Alert volume and type breakdown

```sql
SELECT 
    AlertCategory,
    AlertType,
    COUNT(*) AS AlertCount,
    MIN(AlertDate) AS EarliestAlert,
    MAX(AlertDate) AS LatestAlert
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts]
GROUP BY AlertCategory, AlertType
ORDER BY AlertCount DESC;
```

### Open alerts by analyst with customer details

```sql
SELECT 
    Assigned,
    AlertCategory,
    AlertType,
    CID,
    Name,
    Country,
    AlertDate,
    AlertDetails
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts]
WHERE AlertStatus = 'Open'
ORDER BY Assigned, AlertDate;
```

### Alerts where PlayerStatus changed (action was taken)

```sql
SELECT 
    CID,
    Name,
    AlertDate,
    AlertType,
    PreviousStatus,
    PlayerStatus AS NewStatus,
    AlertDetails
FROM [BI_DB_dbo].[BI_DB_AML_Daily_Alerts]
WHERE PlayerStatus <> PreviousStatus
  AND PlayerStatus IS NOT NULL
  AND PreviousStatus IS NOT NULL
ORDER BY AlertDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. AML daily alert documentation, if available, would reside in the AML/Compliance team's operational documentation or the AML monitoring tool's own reporting suite.

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 5 T3, 10 T4, 1 T5 | Elements: 16/16, Logic: 6/10, Data Evidence: 1/10*
*Object: BI_DB_dbo.BI_DB_AML_Daily_Alerts | Type: Table | Production Source: External AML tool + Google Sheet*
