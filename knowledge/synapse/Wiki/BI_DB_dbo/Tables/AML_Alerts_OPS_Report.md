# BI_DB_dbo.AML_Alerts_OPS_Report

> AML Alerts OPS reporting table tracking alert assignment and handling status per customer. Currently **empty (0 rows as of 2026-04-23)** — historically populated by an external AML OPS tool; a schema backup from 2024-11-17 confirms the table held data. No active writer SP exists in the Synapse SSDT project. Likely legacy or replaced by a newer workflow.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no Generic Pipeline mapping, no writer SP identified in SSDT |
| **Refresh** | Unknown (no active ETL) — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Historical Note** | Backup `AML_Alerts_OPS_Report_Backup_20241117` created 2024-12-01 confirms historical data existed; CID was bigint in backup vs int in current DDL |

---

## 1. Business Meaning

`AML_Alerts_OPS_Report` was an AML operations reporting table that tracked the assignment and handling lifecycle of AML alerts per customer. Each row represented a customer-alert combination with metrics on how the alert was assigned, handled, and its current state (assigned-not-handled, assigned-and-handled, not-assigned counts).

The table is currently **empty** with no active writer SP in the SSDT Dataplatform repo. Based on the schema backup dated 2024-11-17, the table held operational data at some point. It was likely populated by an AML OPS tool (possibly an external application or manual SQL process) outside the standard OpsDB Service Broker pipeline. The `Assigned` column suggests integration with a case management or alert routing system.

The backup table `AML_Alerts_OPS_Report_Backup_20241117` was created on 2024-12-01 with a CID column of type bigint (vs int in the live DDL), indicating a schema change occurred during a migration or cleanup effort.

This table is considered **dormant/legacy** unless a new feed is established.

---

## 2. Business Logic

### 2.1 Alert Assignment Status Model

**What**: The table tracks each AML alert's assignment and handling state using three mutually exclusive/additive integer counters.

**Columns Involved**: `AssignedNotHandled`, `AssignedAndHandled`, `NotAssigned`

**Rules**:
- `AssignedNotHandled`: Count of alerts that have been assigned to an operator but not yet resolved
- `AssignedAndHandled`: Count of alerts that were both assigned and resolved (closed)
- `NotAssigned`: Count of alerts not yet picked up by any operator
- Total alerts = AssignedNotHandled + AssignedAndHandled + NotAssigned (implied structure)

### 2.2 Alert Timeline Columns

**What**: Three date columns capture the key lifecycle timestamps for each alert.

**Columns Involved**: `FirstAlert`, `FirstHandled`, `FirstAssigned`

**Rules**:
- `FirstAlert`: Date when the first alert was triggered for this CID + AlertType combination
- `FirstAssigned`: Date when the alert was first assigned to an operator
- `FirstHandled`: Date when the alert was first worked/resolved
- Typical flow: `FirstAlert` ≤ `FirstAssigned` ≤ `FirstHandled`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — table has no hash key, indicating either: (a) small/infrequent loads, or (b) external tool inserts without awareness of Synapse distribution. CLUSTERED INDEX on CID provides a customer-level scan pattern.

**Warning**: The table is currently empty. Any query returns 0 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find unhandled alerts | `WHERE AssignedNotHandled > 0` |
| SLA breach analysis | `DATEDIFF(day, FirstAlert, FirstHandled)` |
| Unassigned alert queue | `WHERE NotAssigned > 0 AND AssignedNotHandled = 0` |
| Alert aging by regulation | `GROUP BY Regulation, AlertType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON a.CID = c.RealCID` | Enrich with customer demographics |
| BI_DB_dbo.BI_DB_AML_BI_Alerts_New | `ON a.CID = b.CID AND a.AlertType = b.AlertType` | Cross-reference with active alert log |

### 3.4 Gotchas

- **Table is currently empty** — no rows as of 2026-04-23. Queries will return 0 rows.
- **CID type mismatch with backup**: backup had bigint, live table has int — indicates historical migration. Use int-safe joins.
- **No OpsDB registration** — this table is not in the Service Broker pipeline and will not be refreshed automatically.
- **Wide nvarchar columns** (AlertIdentifier, AlertType, Assigned, Regulation are all nvarchar(1000)) — string matching is case-insensitive but may be slow on large datasets.
- **AlertIdentifier** likely contained a UUID or system identifier from the OPS tool — format unknown.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, context, and domain knowledge |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AlertIdentifier | nvarchar(1000) | YES | Unique identifier for the AML alert, likely a system-generated UUID or case reference from the OPS alerting tool. (Tier 4 — unknown source) |
| 2 | AlertType | nvarchar(1000) | YES | Classification of the alert type (e.g., MIMO, OnBoarding, threshold breach). Wide varchar(1000) suggests free-text or multi-value categories from the source system. (Tier 4 — unknown source) |
| 3 | CID | int | YES | Customer ID — the eToro customer account this alert relates to. Links to DWH_dbo.Dim_Customer.RealCID. (Tier 4 — unknown source) |
| 4 | Assigned | nvarchar(1000) | YES | Name or identifier of the AML analyst or team the alert is assigned to. Wide varchar(1000) indicates free-text assignment field. (Tier 4 — unknown source) |
| 5 | Regulation | nvarchar(1000) | YES | Regulatory jurisdiction applicable to the alerted customer (e.g., CySEC, FCA, ASIC). Stored as text, not a foreign key. (Tier 4 — unknown source) |
| 6 | FirstAlert | date | YES | Date when the first occurrence of this alert type was triggered for this customer. (Tier 4 — unknown source) |
| 7 | FirstHandled | date | YES | Date when the alert was first worked/resolved by an operator. NULL if never handled. (Tier 4 — unknown source) |
| 8 | FirstAssigned | date | YES | Date when the alert was first assigned to an operator. NULL if unassigned. (Tier 4 — unknown source) |
| 9 | AssignedNotHandled | int | YES | Count of alerts assigned to an operator but not yet resolved (open workload). (Tier 4 — unknown source) |
| 10 | AssignedAndHandled | int | YES | Count of alerts that were both assigned to an operator and subsequently resolved. (Tier 4 — unknown source) |
| 11 | NotAssigned | int | YES | Count of alerts not yet assigned to any operator (unowned queue). (Tier 4 — unknown source) |
| 12 | UpdateDate | datetime | YES | Timestamp when this row was last updated. ETL metadata column. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns | Unknown — external OPS tool | Unknown | No writer SP in SSDT |

### 5.2 ETL Pipeline

```
Unknown external AML OPS tool (possibly manual SQL inserts or OPS application feed)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.AML_Alerts_OPS_Report (0 rows as of 2026-04-23; historical data per backup)
  |-- No downstream consumers identified --|
  v
(No UC target — Not_Migrated)

Historical state: Backup created 2024-12-01 from data dated 2024-11-17
Schema change: CID bigint (backup) → CID int (current DDL)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer demographics lookup |
| CID | BI_DB_dbo.BI_DB_AML_BI_Alerts_New | Cross-reference with active AML alert log |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views.

---

## 7. Sample Queries

### Alert handling backlog by analyst

```sql
SELECT
    Assigned,
    AlertType,
    SUM(AssignedNotHandled) AS UnhandledAlerts,
    SUM(AssignedAndHandled) AS HandledAlerts,
    MIN(FirstAlert) AS EarliestAlert
FROM [BI_DB_dbo].[AML_Alerts_OPS_Report]
WHERE AssignedNotHandled > 0
GROUP BY Assigned, AlertType
ORDER BY UnhandledAlerts DESC;
```

### Alert SLA: days from first alert to first handling

```sql
SELECT
    AlertType,
    Regulation,
    AVG(DATEDIFF(day, FirstAlert, FirstHandled)) AS AvgDaysToHandle,
    MAX(DATEDIFF(day, FirstAlert, FirstHandled)) AS MaxDaysToHandle,
    COUNT(*) AS AlertCount
FROM [BI_DB_dbo].[AML_Alerts_OPS_Report]
WHERE FirstHandled IS NOT NULL
GROUP BY AlertType, Regulation
ORDER BY AvgDaysToHandle DESC;
```

### Unassigned alerts queue

```sql
SELECT
    AlertType,
    Regulation,
    COUNT(*) AS UnassignedCount,
    MIN(FirstAlert) AS OldestAlert
FROM [BI_DB_dbo].[AML_Alerts_OPS_Report]
WHERE NotAssigned > 0
GROUP BY AlertType, Regulation
ORDER BY OldestAlert ASC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table is not registered in OpsDB and has no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 6/14 (P3/P5/P6/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 0 T3, 11 T4, 1 T5 | Elements: 12/12 | Object: BI_DB_dbo.AML_Alerts_OPS_Report | Type: Table | Production Source: Unknown*
*Note: Table is currently empty (0 rows). Historical data confirmed via backup 2024-11-17. No active writer SP. Quality capped at 7.0 due to unknown source and empty table.*
