# BI_DB_dbo.BI_DB_Cashout_Performance_Monitoring

> 291,390-row hourly-refreshed cashout operations monitoring table tracking the real-time status of all withdrawal requests modified in the past 15 days — sourced from `Billing.Withdraw` via External tables, refreshed hourly by `SP_H_Cashout_Performance_Monitoring`. Request Time ranges from 2026-03-15; Status Modification Time from 2026-03-29 to 2026-04-13 (rolling 15-day ModificationDate window). Used by BO operations staff to monitor pending, in-process, and canceled cashouts with assigned manager attribution.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Billing.Withdraw` via `SP_H_Cashout_Performance_Monitoring` |
| **Refresh** | Hourly (SB_Hourly, no @date param — TRUNCATE + INSERT, rolling 15-day ModificationDate window) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([WithdrawID] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Cashout_Performance_Monitoring` is an hourly-refreshed operational monitoring table for the eToro back-office cashout (withdrawal) pipeline. It holds 291,390 rows covering withdrawal requests whose `ModificationDate` falls within the past 15 days (relative to each ETL run). Each row represents one withdrawal request from `Billing.Withdraw`, enriched with the human-readable status name (from `Dim_CashoutStatus`) and the BO manager who last processed the request at a Pending or Pending-Review stage.

The table is used by operations staff to monitor cashout performance in near-real-time. Because it is TRUNCATE + INSERT each hour, it reflects current state only — there is no history; rows disappear when their `ModificationDate` drops older than 15 days.

**Status snapshot (2026-04-13):** Processed 97.7% (284,752), InProcess 1.4% (4,215), Canceled 0.8% (2,420), Partially Processed <0.01% (3).

**Prepared By attribution:** "System  " (with trailing space) accounts for 98.2% of rows — this is an automated-processing artifact from `CONCAT(FirstName, ' ', LastName)` where the "System" manager account's LastName is empty. Named BO agents (Christina Bdewi, Donya Fard, Nikos Ioannou, etc.) cover ~1.2% of rows.

The SP filters out Internal players (`Dim_PlayerLevel.Name != 'Internal'`) and requires `Approved = '1'`. Funding types are filtered to 20 known types (excl. internal/test types). CashoutStatusIDs 1–5, 8–15 are included (the filter is permissive but the resulting data shows only 4 distinct statuses — "Partially Processed" ID=5 appears in only 3 rows).

---

## 2. Business Logic

### 2.1 Rolling 15-Day Window

**What**: The table always covers only the most recent 15 days of activity based on modification time.

**Columns Involved**: `[Status Modification Time]`

**Rules**:
- Filter: `BW.ModificationDate >= CONVERT(DATE, GETDATE()-15)` (applied to External_etoro_Billing_Withdraw)
- TRUNCATE before each INSERT — full refresh every hour
- Request Time may be older than 15 days (withdrawals submitted before the window but modified within it)
- On each ETL run, rows older than 15 days from `ModificationDate` disappear silently — no archive

### 2.2 Prepared By Attribution Logic

**What**: Identifies the last BO manager who acted on the withdrawal at Pending (1) or Pending Review (14) status.

**Columns Involved**: `[Prepared By]`

**Rules**:
- Uses `OUTER APPLY TOP 1` on `External_etoro_History_vWithdrawToFundingAction` WHERE `CashoutStatusID IN (1, 14)`, ordered by `ModificationDate DESC`
- If no matching action exists: `[Prepared By]` = NULL → stored as empty string `''` (CONCAT(NULL,' ',NULL) = ' ' in SQL Server, but NULL manager fields produce empty string)
- "System  " with trailing spaces = automated processing by the system account (LastName blank)
- Named agents handle the minority of manually reviewed withdrawals

### 2.3 Status Coverage

**What**: The table contains all CashoutStatusIDs from 1–5 and 8–15 from production, resolved via `Dim_CashoutStatus.Name`. Not all IDs resolve (DWH Dim_CashoutStatus covers only IDs 0–5 and a few others).

**Columns Involved**: `[Withdraw Status]`

**Rules**:
- 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed
- IDs 6, 7, 11–13, 16–17 would return NULL join in Dim_CashoutStatus (none observed in current window)
- Inner join means rows with unresolvable CashoutStatusIDs are silently dropped from the output

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution — data is spread across distributions without a key. This is appropriate for a small operational table (<300K rows). The CLUSTERED INDEX on `[WithdrawID]` supports efficient point-lookups by withdraw ID.

**Column name gotcha**: 4 of 6 columns contain spaces — must bracket-quote in all SQL:
```sql
SELECT [[WithdrawID]], [[Withdraw Status]], [[Request Time]], [[Prepared By]]
FROM [BI_DB_dbo].[BI_DB_Cashout_Performance_Monitoring]
```

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| "Show all InProcess cashouts right now" | `WHERE [Withdraw Status] = 'InProcess'` |
| "Which cashouts have been in process for > 3 days?" | `WHERE [Withdraw Status] = 'InProcess' AND DATEDIFF(day, [Request Time], GETDATE()) > 3` |
| "Find cashouts processed by a specific manager today" | `WHERE [Prepared By] = 'Manager Name' AND CAST([Status Modification Time] AS DATE) = CAST(GETDATE() AS DATE)` |
| "Count cashouts by status" | `GROUP BY [Withdraw Status]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Fact_BillingWithdraw` | `[WithdrawID] = Fact_BillingWithdraw.WithdrawID` | Enrich with full billing detail (CID, Amount, FundingTypeID) |
| `DWH_dbo.Dim_CashoutStatus` | `[Withdraw Status] = Dim_CashoutStatus.Name` | Resolve back to CashoutStatusID (if needed for further joins) |

### 3.4 Gotchas

- **Rolling window only**: This table has no history. Data is gone after 15 days from ModificationDate. For historical analysis use `DWH_dbo.Fact_BillingWithdraw`.
- **"System  " trailing spaces**: The "System" agent name has trailing spaces — use `LTRIM(RTRIM([Prepared By]))` for grouping/comparison.
- **Double-bracket quoting required**: `[[Withdraw Status]]`, `[[Request Time]]`, `[[Status Modification Time]]`, `[[Prepared By]]` — single brackets are insufficient for column names with spaces.
- **Partially Processed (5)**: Only 3 rows observed — effectively rare edge case.
- **UpdateDate is identical for all rows**: Equal to the hourly ETL run time, not a per-row timestamp.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (Billing.Withdraw.md) |
| Tier 2 | Description derived from SP code analysis and live data sampling |
| Propagation | ETL infrastructure column — canonical description from propagation blacklist |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | [Status Modification Time] | datetime | YES | UTC timestamp of the most recent status change or update. Indexed (ix_BillingWithdraw_ModificationDate). Included in covering index. DWH note: renamed from Billing.Withdraw.ModificationDate; used as the rolling 15-day window filter in SP_H_Cashout_Performance_Monitoring. (Tier 1 — Billing.Withdraw) |
| 2 | [Request Time] | datetime | YES | Timestamp when the customer submitted the withdrawal request. Included in covering indexes for date-range queries. DWH note: renamed from Billing.Withdraw.RequestDate; may be older than 15 days since the window is on ModificationDate not RequestDate. (Tier 1 — Billing.Withdraw) |
| 3 | [Withdraw Status] | nvarchar(1000) | YES | Human-readable cashout lifecycle state resolved via INNER JOIN to Dim_CashoutStatus. Observed values: Processed, InProcess, Canceled, Partially Processed. Rows with unresolvable CashoutStatusIDs (outside DWH Dim_CashoutStatus coverage) are silently dropped by the INNER JOIN. (Tier 2 — SP_H_Cashout_Performance_Monitoring) |
| 4 | [WithdrawID] | bigint | YES | Primary key. IDENTITY starting at 1. Both a PK NONCLUSTERED and a separate CLUSTERED index exist on this column (unusual pattern - PK is non-clustered to allow covering indexes to reference the clustered key). NOT FOR REPLICATION. (Tier 1 — Billing.Withdraw) |
| 5 | [Prepared By] | nvarchar(1000) | YES | BO manager who last acted on this withdrawal at CashoutStatusID IN (1=Pending, 14=Pending Review). Computed as CONCAT(FirstName, ' ', LastName) from BackOffice.Manager via OUTER APPLY TOP 1 on History.vWithdrawToFundingAction ordered by ModificationDate DESC. "System  " (with trailing spaces, 98.2%) = automated processing. Empty string = no qualifying action found. Named agents cover ~1.2% of rows. (Tier 2 — SP_H_Cashout_Performance_Monitoring) |
| 6 | [UpdateDate] | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. EXCEPTION: for frozen migration tables (DWH_Migration schema origin), this is the original production timestamp preserved from the legacy system — NOT set by GETDATE(). Run timestamp analysis (Phase 2 Tier A1) to determine which applies before using this description. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| [Status Modification Time] | etoro.Billing.Withdraw | ModificationDate | Rename |
| [Request Time] | etoro.Billing.Withdraw | RequestDate | Rename |
| [Withdraw Status] | etoro.Dictionary.CashoutStatus (via DWH_dbo.Dim_CashoutStatus) | Name | INNER JOIN on CashoutStatusID |
| [WithdrawID] | etoro.Billing.Withdraw | WithdrawID | Passthrough |
| [Prepared By] | etoro.BackOffice.Manager | FirstName, LastName | OUTER APPLY CONCAT(FirstName,' ',LastName) |
| [UpdateDate] | ETL runtime | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (production — ModificationDate >= GETDATE()-15)
  + etoro.Billing.WithdrawToFunding (funding leg)
  + etoro.History.vWithdrawToFundingAction (manager attribution)
  + etoro.BackOffice.Manager (name resolution)
    |-- External Tables (External_etoro_Billing_Withdraw, etc.) ---|
    v
[BI_DB_dbo staging layer — direct External table reads, no staging SP]
    |-- SP_H_Cashout_Performance_Monitoring (TRUNCATE + INSERT, Hourly) ---|
    v
BI_DB_dbo.BI_DB_Cashout_Performance_Monitoring (~291K rows, 15-day window)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers identified)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| [WithdrawID] | DWH_dbo.Fact_BillingWithdraw | Logical FK — enriches with full billing details, CID, Amount, FundingTypeID |
| [Withdraw Status] | DWH_dbo.Dim_CashoutStatus | Resolved from CashoutStatusID; reverse-join if CashoutStatusID needed |

### 6.2 Referenced By (other objects point to this)

No downstream SPs or views identified in the BI_DB_dbo schema.

---

## 7. Sample Queries

### Current InProcess Cashouts Older Than 2 Days

```sql
SELECT
    [WithdrawID],
    [Request Time],
    [Status Modification Time],
    DATEDIFF(hour, [Status Modification Time], GETDATE()) AS hours_in_status,
    [Prepared By]
FROM [BI_DB_dbo].[BI_DB_Cashout_Performance_Monitoring]
WHERE [Withdraw Status] = 'InProcess'
  AND DATEDIFF(day, [Status Modification Time], GETDATE()) > 2
ORDER BY [Status Modification Time] ASC
```

### Cashout Volume by Status and Day

```sql
SELECT
    CAST([Status Modification Time] AS DATE) AS modification_day,
    [Withdraw Status],
    COUNT(*) AS cashout_count
FROM [BI_DB_dbo].[BI_DB_Cashout_Performance_Monitoring]
GROUP BY CAST([Status Modification Time] AS DATE), [Withdraw Status]
ORDER BY modification_day DESC, cashout_count DESC
```

### Manager Workload Distribution

```sql
SELECT
    LTRIM(RTRIM([Prepared By])) AS prepared_by,
    COUNT(*) AS cashout_count,
    SUM(CASE WHEN [Withdraw Status] = 'InProcess' THEN 1 ELSE 0 END) AS in_process
FROM [BI_DB_dbo].[BI_DB_Cashout_Performance_Monitoring]
WHERE [Prepared By] NOT IN ('System', 'System  ', '')
GROUP BY LTRIM(RTRIM([Prepared By]))
ORDER BY cashout_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this operational monitoring table.

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 3 T1, 2 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 6/6, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Cashout_Performance_Monitoring | Type: Table | Production Source: etoro.Billing.Withdraw*
