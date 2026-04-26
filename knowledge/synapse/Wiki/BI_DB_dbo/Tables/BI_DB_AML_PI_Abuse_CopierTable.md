# BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable

## 1. Summary

Daily full-refresh snapshot of all active copy relationships where the **copied party (parent)** is a qualifying Popular Investor (PI). Each row represents one copier-PI pair as of the most recent SP run date. The table is the copier-detail component of the `SP_AML_PI_Abuse` suite and supports AML detection of coordinated copy patterns: shared devices, funding IDs, IPs, and identity clusters among a PI's copier base.

- **Row count**: 449,326 (as of 2026-04-11 — single-day full refresh, only most recent run's data present)
- **Distinct PIs (ParentCID)**: 3,855
- **Distinct copiers (CID)**: 215,768
- **Average copiers per PI**: ~117 (median far lower; highly skewed — largest PI has 33,467 copiers)
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: DELETE ALL + INSERT (daily full refresh — delete condition `WHERE @DateID > @Past6MonthsINT` is always TRUE for any current run date, making this effectively a TRUNCATE+INSERT)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: HIGH — contains full PII: FirstName, LastName, Address, Email, Phone, BirthDate, UserName

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | Date | date | T2 | `general.etoroGeneral_History_GuruCopiers.Timestamp` (CAST AS DATE) | Run date — the snapshot date for this copy relationship record. All rows share the same Date value per run. |
| 2 | ParentCID | int | T2 | `general.etoroGeneral_History_GuruCopiers.ParentCID` | The Popular Investor's customer ID. This is the entity being copied — must meet PI qualification criteria in `#pis` (GuruStatusID≥2, IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1). |
| 3 | ParentUserName | nvarchar(500) | T2 | `general.etoroGeneral_History_GuruCopiers.ParentUserName` | The PI's username at the time of the snapshot. |
| 4 | CID | int | T1 | `DWH_dbo.Dim_Customer.RealCID` | The copier's real customer ID. Joins to Dim_Customer on RealCID. |
| 5 | GCID | int | T1 | `DWH_dbo.Dim_Customer.GCID` | The copier's global customer ID. Stable across cross-regulation moves. |
| 6 | BirthDate | datetime | T1 | `DWH_dbo.Dim_Customer.BirthDate` | Copier's date of birth. Used for age computation and identity clustering. |
| 7 | UserName | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.UserName` | Copier's platform username. |
| 8 | GuruStatusName | nvarchar(500) | T2 | `DWH_dbo.Dim_GuruStatus.Name` (LEFT JOIN on copier's GuruStatusID) | Copier's PI program status. Predominantly 'No' (not a PI) — copiers are rarely themselves PIs. |
| 9 | City | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.City` | Copier's city of residence. Used for geographic clustering in abuse detection. |
| 10 | Zip | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.Zip` | Copier's postal code. Used for geographic clustering. |
| 11 | Country | nvarchar(500) | T1 | `DWH_dbo.Dim_Country.Name` | Copier's country of residence (full name in English). |
| 12 | PlayerStatus | nvarchar(500) | T1 | `DWH_dbo.Dim_PlayerStatus.Name` | Copier's account restriction state (e.g., Normal, Blocked, BUR). |
| 13 | Club | nvarchar(500) | T1 | `DWH_dbo.Dim_PlayerLevel.Name` | Copier's experience tier (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond). |
| 14 | Age | int | T2 | Computed: `DATEDIFF(YEAR, BirthDate, GETDATE())` | Copier's age in years at SP run time. Note: can be off by 1 year for customers whose birthday has not yet occurred in the current calendar year (~50% of population at any given point). Use BirthDate directly for precise age queries. |
| 15 | Gender | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.Gender` | Copier's self-declared gender. |
| 16 | AUC | money | T2 | Computed from `general.etoroGeneral_History_GuruCopiers`: `ISNULL(Cash,0) + ISNULL(Investment,0) + ISNULL(PnL,0) + ISNULL(DetachedPosInvestment,0) + ISNULL(Dit_PnL,0)` | Assets Under Copy — total funds the copier has allocated to copying this PI (open position value + unrealized PnL + detached position investment + detached unrealized PnL). Represents the copier's financial exposure to this PI. |
| 17 | StartCopy | datetime | T2 | `general.etoroGeneral_History_GuruCopiers.StartCopy` | Timestamp when this copier began copying the PI. |
| 18 | TotalEquity | money | T2 | `DWH_dbo.V_Liabilities.Liabilities + ActualNWA` (WHERE DateID = @DateID) | Copier's total net equity at run date. Pulled from V_Liabilities snapshot. |
| 19 | NumberOfSessionID | int | T4 | — | **NEVER POPULATED** — column exists in DDL but is absent from the SP INSERT statement. Always NULL. Orphaned DDL artifact. |
| 20 | HasActiveCopy | int | T4 | — | **NEVER POPULATED** — column exists in DDL but is absent from the SP INSERT statement. Always NULL. Orphaned DDL artifact. |
| 21 | NumOfCountry | int | T4 | — | **NEVER POPULATED** — column exists in DDL but is absent from the SP INSERT statement. Always NULL. Orphaned DDL artifact. |
| 22 | NumOfCity | int | T4 | — | **NEVER POPULATED** — column exists in DDL but is absent from the SP INSERT statement. Always NULL. Orphaned DDL artifact. |
| 23 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp. Set to GETDATE() at INSERT time. Not a business date — do not use for data filtering. |
| 24 | FirstName | varchar(250) | T1 | `DWH_dbo.Dim_Customer.FirstName` | Copier's first name. PII — handle with care. |
| 25 | LastName | varchar(250) | T1 | `DWH_dbo.Dim_Customer.LastName` | Copier's last name. PII — handle with care. |
| 26 | Address | nvarchar(max) | T1 | `DWH_dbo.Dim_Customer.Address` | Copier's physical address. PII — handle with care. |
| 27 | Email | varchar(250) | T1 | `DWH_dbo.Dim_Customer.Email` | Copier's email address. PII — handle with care. |
| 28 | Phone | varchar(250) | T1 | `DWH_dbo.Dim_Customer.Phone` | Copier's phone number. PII — handle with care. |

**Tier summary**: 15 T1 | 8 T2 | 4 T4 (never populated) | 1 Propagation

---

## 3. Business Context

This table is the **copier detail layer** of the AML PI Abuse suite. The SP_AML_PI_Abuse framework detects Popular Investors who may be gaming the program by creating or coordinating a network of artificial copiers — accounts that share devices, funding instruments, IP addresses, or biometric/identity signals with the PI.

### Popular Investor Qualification Criteria

The `#pis` population gate filters `Fact_SnapshotCustomer` at @DateID:

| Criterion | Value | Meaning |
|-----------|-------|---------|
| GuruStatusID | ≥ 2 | Cadet and above (enrolled in PI program) |
| IsValidCustomer | 1 | Active, non-demo account |
| VerificationLevelID | 3 | Fully verified (KYC complete) |
| IsDepositor | 1 | Has made at least one deposit |

### AUC (Assets Under Copy) Definition

`AUC = ISNULL(Cash,0) + ISNULL(Investment,0) + ISNULL(PnL,0) + ISNULL(DetachedPosInvestment,0) + ISNULL(Dit_PnL,0)`

All five components from `general.etoroGeneral_History_GuruCopiers`. Represents the copier's total financial stake in copying this specific PI. A very high AUC for a new account, or many copiers with identical AUC values, can signal coordinated activity.

### ETL Pattern: Effectively Daily Full Refresh

The SP uses DELETE + INSERT with condition `WHERE @DateID > @Past6MonthsINT`. This condition is always TRUE for any current run date. As a result, ALL rows are deleted before each run and only the most recent day's data is present. As of 2026-04-11: min_date = max_date = 2026-04-11.

### Relationship to Sibling Tables

This table provides the **copier-level detail** for manual investigation. The other tables in the `SP_AML_PI_Abuse` suite (all using TRUNCATE+INSERT) provide:
- `BI_DB_AML_PI_Abuse` — PI-level abuse signals (shared device/IP/FID counts)
- `BI_DB_AML_PI_Abuse_SameIP` — copiers sharing an IP with the PI
- `BI_DB_AML_PI_Abuse_DeviceID_*` — device ID overlap tables (PI-side, copier-side, as-PI)
- `BI_DB_AML_PI_Abuse_FID_*` — funding ID overlap tables

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 449,326 |
| Distinct PIs (ParentCID) | 3,855 |
| Distinct copiers (CID) | 215,768 |
| Snapshot date | 2026-04-11 (single date — daily full refresh) |
| Largest PI | ParentCID=12569157 — 33,467 copiers, ~$305M total AUC |
| Median copiers per PI | ~10 (distribution heavily right-skewed) |

### GuruStatusName Distribution (copiers)

Almost all copiers are non-PIs. The vast majority show GuruStatusName = 'No' with varying Club/PlayerStatus combinations. A small subset of rows represent copiers who are also PIs themselves (GuruStatusID > 1) — these are higher-risk signals for coordinated abuse.

### PII Coverage

All PII columns (FirstName, LastName, Address, Email, Phone, BirthDate) are sourced directly from Dim_Customer and are populated for all valid customers. NULL values indicate data gaps in the upstream customer record.

---

## 5. Usage Notes

### AML Abuse Detection Queries

When joining this table to the sibling abuse signal tables, join on `ParentCID` (the PI being investigated):

```sql
-- Copiers of a specific PI who also share a device ID with the PI
SELECT ct.*
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable ct
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers dc
    ON ct.ParentCID = dc.ParentCID AND ct.CID = dc.CID
WHERE ct.ParentCID = @TargetPI
```

### Orphaned Columns

`NumberOfSessionID`, `HasActiveCopy`, `NumOfCountry`, `NumOfCity` are **always NULL**. Do not reference these columns in analysis or downstream transformations until the SP owner confirms whether they will be populated.

### AUC Aggregation

To get total AUC under a PI: `SUM(AUC)` over all rows WHERE ParentCID = target. This is valid since the table is a single-day snapshot and each row is a distinct copier-PI pair.

### Age Column Caveat

`Age = DATEDIFF(YEAR, BirthDate, GETDATE())` — uses GETDATE() at SP execution time, not at snapshot date. Age can be off by ±1 for customers near their birthday. For age-based compliance thresholds (e.g., under-18 detection), always filter on `BirthDate` directly.

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Active copy relationships; provides copier-PI pairs, AUC components, StartCopy |
| 2 | `DWH_dbo.Fact_SnapshotCustomer` | Fact | PI population gate (GuruStatusID≥2, IsValidCustomer=1, VL3, Depositor) |
| 3 | `DWH_dbo.Dim_Customer` | Dim | Copier identity and full PII (CID/GCID/BirthDate/UserName/FirstName/LastName/Address/Email/Phone/City/Zip/Gender) |
| 4 | `DWH_dbo.Dim_PlayerStatus` | Dim | Copier account restriction label |
| 5 | `DWH_dbo.Dim_PlayerLevel` | Dim | Copier tier label (Club) |
| 6 | `DWH_dbo.Dim_Country` | Dim | Copier country name |
| 7 | `DWH_dbo.Dim_GuruStatus` | Dim | Copier's PI program status label |
| 8 | `DWH_dbo.V_Liabilities` | View | Copier net equity snapshot at run date |

---

## 7. Known Issues

1. **4 never-populated DDL columns**: `NumberOfSessionID`, `HasActiveCopy`, `NumOfCountry`, `NumOfCity` exist in the DDL but are absent from the SP INSERT statement. Always NULL. May represent a planned but unimplemented enhancement to the abuse detection logic (session count, active copy flag, distinct country count per copier-PI pair, distinct city count).

2. **Age computed with GETDATE() not @Date**: `Age = DATEDIFF(YEAR, BirthDate, GETDATE())` uses wall-clock time, not the SP's @Date parameter. For historical runs or replays, the age column does not reflect age as of @Date. Use BirthDate for precise calculations.

3. **DELETE condition is always TRUE**: `WHERE @DateID > @Past6MonthsINT` evaluates to TRUE for any run within the last 6 months (i.e., always). The effect is the same as TRUNCATE — no historical data is retained. The table only ever holds one day's snapshot.

4. **WITH(NOLOCK) on Synapse tables**: SP_AML_PI_Abuse uses `WITH(NOLOCK)` hints on Synapse SQL Pool tables. Synapse uses snapshot isolation by default — NOLOCK is not applicable and is a code smell. No correctness impact.

5. **V_Liabilities wiki not available**: TotalEquity sources from `DWH_dbo.V_Liabilities` but no wiki exists for this view. Known formula: `Liabilities + ActualNWA` at @DateID.

---

## 8. Metadata

| Field | Value |
|-------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_AML_PI_Abuse |
| ETL Pattern | DELETE ALL + INSERT (effectively daily full refresh) |
| OpsDB Priority | 0 |
| UC Status | Not Migrated |
| Columns | 28 (15 T1, 8 T2, 4 T4, 1 Propagation) |
| Rows | 449,326 (2026-04-11) |
| PII | HIGH (FirstName, LastName, Address, Email, Phone, BirthDate) |
| Batch | 46 |
| Generated | 2026-04-22 |
