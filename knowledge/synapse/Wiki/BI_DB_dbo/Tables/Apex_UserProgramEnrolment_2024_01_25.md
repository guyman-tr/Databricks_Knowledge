# BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25

> Point-in-time snapshot (2024-01-25) of the live Apex Clearing user program enrollment data for US customers. Contains 13,649 rows representing the enrollment state of US eToro accounts in the Apex staking program (UserProgramID=2) as of January 25, 2024. The table is **frozen** — active SPs use the live `External_USABroker_Apex_UserProgramEnrolment` external table instead. This snapshot was likely created for audit, reconciliation, or debugging purposes.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — point-in-time snapshot |
| **Production Source** | USABroker / Apex Clearing → `Bronze/USABroker/apex/UserProgramEnrolment` (parquet) via Generic Pipeline |
| **Live Source** | BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment |
| **Refresh** | None — frozen snapshot as of 2024-01-25 |
| **Snapshot Date** | 2024-01-25 (baked into table name) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 13,649 (frozen) |
| **BeginTime Range** | 2021-04-20 to 2024-01-25 |

---

## 1. Business Meaning

`Apex_UserProgramEnrolment_2024_01_25` is a frozen point-in-time snapshot of the Apex Clearing user program enrollment records for eToro US (NYDFS) customers, captured on 2024-01-25. All 13,649 rows correspond to a single program — `UserProgramID=2` (the Apex Staking/Money Market program for US clients).

At the snapshot date, 11,783 customers (86.3%) were actively enrolled (`UserProgramEnrolmentStatusID=2`), while 1,866 (13.7%) were in an inactive/pending state (`UserProgramEnrolmentStatusID=1`). All records show `EndTime=9999-12-31` (SCD2 open-ended sentinel for active records at snapshot time — no closed enrollments in this extract).

The live `External_USABroker_Apex_UserProgramEnrolment` external table (Bronze parquet) is what active ETL SPs use for staking NOP calculations (`SP_Crypto_NOP`, `SP_CMR_Automation_RealCrypto_Main_CryptoNOP_ALLRegs_USA_Staking`). This snapshot is a companion read-only reference, likely used for:
- Historical audit comparison
- Debugging staking discrepancies as of Jan 2024
- Cross-check during a migration or system change

A predecessor table `USABroker_Apex_UserProgramEnrolment_old` with the same schema exists and represents an earlier version of this snapshot pattern.

---

## 2. Business Logic

### 2.1 Enrollment Status Model

**What**: Two active enrollment states track whether a US customer is enrolled in the Apex staking/money market program.

**Columns Involved**: `UserProgramEnrolmentStatusID`

**Rules**:
- `UserProgramEnrolmentStatusID = 2` → Active enrollment (86.3% of rows at snapshot date)
- `UserProgramEnrolmentStatusID = 1` → Inactive/pending enrollment (13.7%)
- Values confirmed from SP_Crypto_NOP: status=2 is the active staking population, status=1 is pending
- Live SPs filter `UserProgramEnrolmentStatusID = 2` when counting active staking participants

### 2.2 SCD2 Open-Ended Sentinel

**What**: The `EndTime` column uses the far-future sentinel `9999-12-31 23:59:59` for all active enrollments.

**Columns Involved**: `EndTime`

**Rules**:
- All rows in this snapshot have `EndTime = 9999-12-31 23:59:59` — all enrollments were "open" at the time of the snapshot
- This is a standard SCD2 active-record pattern from the Apex upstream system
- No closed/expired enrollment records are present in this particular snapshot

### 2.3 Program Scope

**What**: This snapshot covers a single program only.

**Columns Involved**: `UserProgramID`

**Rules**:
- All 13,649 rows have `UserProgramID = 2`
- UserProgramID=2 is the Apex staking/money market enrollment program for US accounts
- Multiple programs may exist in the live external table; this snapshot captured only program 2

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no optimization for any join pattern. For joins on GCID, expect a shuffle. Given the small row count (13,649), this is acceptable — the cost of distribution overhead would outweigh the benefit.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active stakers as of Jan 2024 | `WHERE UserProgramEnrolmentStatusID = 2 AND UserProgramID = 2` |
| Enrollment date distribution | `GROUP BY CAST(BeginTime AS DATE)` |
| Join to customer data | `JOIN Dim_Customer ON GCID = Dim_Customer.GCID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON a.GCID = c.GCID` | Enrich with CID, regulation, country |
| External_USABroker_Apex_UserProgramEnrolment | `ON a.GCID = b.GCID` | Compare snapshot vs current state |

### 3.4 Gotchas

- **Frozen data** — this table will never be updated. For current enrollment state, use `External_USABroker_Apex_UserProgramEnrolment`.
- **All EndTime = 9999-12-31** — there are no closed enrollment records in this snapshot. The upstream may have historical closed records that were not captured.
- **Only UserProgramID = 2** — the live external table may contain other program IDs. This snapshot is not a complete picture of all Apex programs.
- **GCID, not CID** — US Apex customers use GCID as their identifier. Join to `Dim_Customer.GCID` (not `RealCID`) for customer enrichment.
- **Name contains a date** (`_2024_01_25`) — this is NOT an active/refreshing table. The date in the name is a strong signal that the data is frozen.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, external table DDL, and SP code context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID — the eToro US customer's Apex-assigned account identifier. Used for joins to Dim_Customer (GCID column) and Apex external tables. (Tier 3 — External_USABroker_Apex_UserProgramEnrolment) |
| 2 | UserProgramEnrolmentStatusID | int | YES | Enrollment status in the staking program. 1=Inactive/Pending, 2=Active (confirmed from SP_Crypto_NOP: status=2 is the active staking population). (Tier 3 — External_USABroker_Apex_UserProgramEnrolment) |
| 3 | UserProgramID | int | YES | Identifier for the Apex user program. All 13,649 rows in this snapshot have UserProgramID=2 (Apex Staking/Money Market program for US customers). (Tier 3 — External_USABroker_Apex_UserProgramEnrolment) |
| 4 | BeginTime | datetime2(7) | YES | Date and time when the enrollment in this program began. Range in this snapshot: 2021-04-20 to 2024-01-25. (Tier 3 — External_USABroker_Apex_UserProgramEnrolment) |
| 5 | EndTime | datetime2(7) | YES | Date and time when the enrollment ended. All records in this snapshot have sentinel value 9999-12-31 23:59:59 (open-ended, no closed enrollments captured). Standard SCD2 active-record sentinel from Apex. (Tier 3 — External_USABroker_Apex_UserProgramEnrolment) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | USABroker / Apex Clearing | GCID | Passthrough |
| UserProgramEnrolmentStatusID | USABroker / Apex Clearing | UserProgramEnrolmentStatusID | Passthrough |
| UserProgramID | USABroker / Apex Clearing | UserProgramID | Passthrough |
| BeginTime | USABroker / Apex Clearing | BeginTime | Passthrough |
| EndTime | USABroker / Apex Clearing | EndTime | Passthrough |

### 5.2 ETL Pipeline

```
USABroker / Apex Clearing (US broker production — staking program enrollment)
  |-- Generic Pipeline (Bronze parquet export) --|
  v
Bronze/USABroker/apex/UserProgramEnrolment (Data Lake)
  |-- External Table: External_USABroker_Apex_UserProgramEnrolment --|
  v
[LIVE] BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment (current enrollment state)
  |-- Manual one-time snapshot (2024-01-25, no repeating SP) --|
  v
BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25 (13,649 rows — FROZEN)

Predecessor: BI_DB_dbo.USABroker_Apex_UserProgramEnrolment_old (earlier snapshot)

Active SPs use the LIVE external table:
  SP_Crypto_NOP → BI_DB_dbo.BI_DB_Crypto_NOP
  SP_CMR_Automation_RealCrypto_Main_CryptoNOP_ALLRegs_USA_Staking → (CMR output)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | Customer demographics via GCID FK |
| Source | External_USABroker_Apex_UserProgramEnrolment | Live version of this snapshot (current state) |

### 6.2 Referenced By

No active SPs reference this snapshot table directly. The live external table (`External_USABroker_Apex_UserProgramEnrolment`) is used by active SPs instead.

---

## 7. Sample Queries

### Active staking enrollments as of Jan 2024 by enrollment year

```sql
SELECT
    YEAR(BeginTime) AS EnrollmentYear,
    COUNT(*) AS Enrollments
FROM [BI_DB_dbo].[Apex_UserProgramEnrolment_2024_01_25]
WHERE UserProgramEnrolmentStatusID = 2
GROUP BY YEAR(BeginTime)
ORDER BY EnrollmentYear;
```

### Compare snapshot vs current enrollment state

```sql
SELECT
    snap.GCID,
    snap.UserProgramEnrolmentStatusID AS SnapshotStatus,
    live.UserProgramEnrolmentStatusID AS CurrentStatus
FROM [BI_DB_dbo].[Apex_UserProgramEnrolment_2024_01_25] snap
LEFT JOIN [BI_DB_dbo].[External_USABroker_Apex_UserProgramEnrolment] live
    ON snap.GCID = live.GCID
    AND live.UserProgramID = 2
WHERE snap.UserProgramEnrolmentStatusID != ISNULL(live.UserProgramEnrolmentStatusID, 0);
```

### Enrolled customers with customer demographics

```sql
SELECT
    e.GCID,
    c.RealCID,
    c.Country,
    e.BeginTime,
    e.UserProgramEnrolmentStatusID
FROM [BI_DB_dbo].[Apex_UserProgramEnrolment_2024_01_25] e
JOIN [DWH_dbo].[Dim_Customer] c ON e.GCID = c.GCID
WHERE e.UserProgramEnrolmentStatusID = 2;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This is a US-specific operational snapshot table.

---

*Generated: 2026-04-23 | Quality: 8.0/10 | Phases: 8/14 (P3/P6/P7/P9B/P10 skipped — frozen snapshot, no writer SP)*
*Tiers: 0 T1, 0 T2, 5 T3, 0 T4, 0 T5 | Elements: 5/5 | Object: BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25 | Type: Table | Production Source: USABroker/Apex Clearing*
