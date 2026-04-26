# BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes

> **PII-SENSITIVE** — Full AML audit trail of every player status change (including initial status assignments) for verified customers (VerificationLevelID ≥ 2), including customer PII at the time of ETL rebuild. 27.2M rows spanning 2011 to present. Full TRUNCATE+INSERT daily rebuild from Fact_SnapshotCustomer. 72% of rows are first-ever status assignments (Previous='N/A').

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Sources** | DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.Dim_Customer, DWH_dbo.Dim_PlayerStatus (×2), DWH_dbo.Dim_PlayerStatusReasons (×2), DWH_dbo.Dim_PlayerStatusSubReasons (×2), DWH_dbo.Dim_Country, DWH_dbo.Dim_Regulation, DWH_dbo.Dim_PlayerLevel, DWH_dbo.Dim_Range |
| **Writer SP** | `BI_DB_dbo.SP_AML_PlayerStatus_Changes` |
| **Schedule** | Daily (no @Date parameter — always full rebuild) |
| **Row Count** | ~27.2M (as of 2026-04-12) |
| **Distinct CIDs** | ~19.6M |
| **Change Date Range** | 2011-06-07 to 2026-04-12 |
| **PII Sensitivity** | HIGH — FirstName, LastName, MiddleName, Email, BirthDate, Phone, IP, UserName |
| | |
| **Synapse Distribution** | `ROUND_ROBIN` |
| **Synapse Index** | `HEAP` |
| | |
| **UC Target** | `_Not_Migrated` |

---

## 1. Business Meaning

`BI_DB_AML_PlayerStatus_Changes` is the AML compliance team's audit trail for account restriction events. Each row represents a player status transition for a verified customer — capturing what status changed, when, why (reason + sub-reason), and the customer's profile at the time of the daily rebuild. The table enables compliance analysts to reconstruct the restriction history of any customer, track escalation patterns, and report on AML-driven account actions (restrictions, blocks, investigation flags).

**PII content**: The table stores eight PII fields from Dim_Customer as they exist at the time of the daily ETL rebuild (not at the time of the status change). This means name, email, and phone reflect current values — not historical values at the change date.

**Scope**: All verified customers (VerificationLevelID ≥ 2) with any detectable player status change since 2011. "Change" is detected by comparing the current day's PlayerStatusID to the previous day's via `LAG()` over Fact_SnapshotCustomer. The first-ever recorded status for a customer (no prior row) also qualifies, producing `Previous_PlayerStatus = 'N/A'` — this accounts for 72.1% of all rows.

**Ghost column**: `PlayerStatusSubReasonName` exists in the DDL but is never populated by the SP (0 rows have a value). Always NULL. Do not rely on it.

---

## 2. Business Logic

### 2.1 Change Detection via LAG()

**What**: Status changes are identified by comparing each snapshot row's PlayerStatusID to the preceding snapshot row's for the same customer.

**Columns Involved**: `Previous_ID`, `Current_ID`, `Previous_PlayerStatus`, `Current_PlayerStatus`

**Rules**:
- Source: `Fact_SnapshotCustomer` ordered by `Dim_Range.FromDateID ASC` per `RealCID`
- LAG default: `LAG(PlayerStatusID, 1, **0**)` — default=0 means "no prior row" returns ID=0 (N/A in Dim_PlayerStatus)
- Filter: `WHERE a.PlayerStatusID <> a.Previous_PlayerStatusID` — includes rows where ID=0 ≠ current ID (i.e., first-ever status assignments appear as transitions from N/A)
- **72.1% of rows** (19.6M) have `Previous_PlayerStatus = 'N/A'` — these are first-time status settings, not actual status changes between two real statuses

### 2.2 Reason and Sub-Reason Capture

**What**: Each status change event is annotated with the reason and sub-reason codes in effect at the time of the snapshot.

**Columns Involved**: `PlayerStatusReason`, `Current_Reason_ID`, `PlayerStatusSubReason`, `Current_Sub_Reason_ID`, and their Previous counterparts

**Rules**:
- Reason and sub-reason come from `Fact_SnapshotCustomer.PlayerStatusReasonID` and `PlayerStatusSubReasonID` — the values recorded on the snapshot date
- Both current and previous reason/sub-reason are captured using the same LAG() pattern as for status IDs
- LEFT JOINs (not INNER) — NULL reason/sub-reason is valid when no explicit reason was recorded (ID=0 = 'None')
- `PlayerStatusSubReason` = `Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName` (column rename in Dim_PlayerStatusSubReasons)

### 2.3 PII Snapshot at ETL Time (Not at Change Time)

**What**: Customer PII fields reflect the current state at the daily ETL rebuild, not the state at the time of the status change.

**Columns Involved**: `FirstName`, `LastName`, `MiddleName`, `Email`, `BirthDate`, `Phone`, `IP`, `UserName`

**Rules**:
- PII is pulled from `Dim_Customer` on the ETL run date — if a customer changed their email since their 2015 status restriction, the table will show their current email next to the 2015 event
- This is a known limitation; for historical PII, BackOffice history tables must be consulted
- Phone from `Dim_Customer.Phone` (CustomerStatic) — not the verified phone from PhoneNumber/ContactVerification

### 2.4 Load Pattern (TRUNCATE + Full Rebuild)

**What**: The entire table is rebuilt every daily ETL run.

**Rules**:
- `TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes`
- `INSERT FROM #final` — full history of all status changes for all qualifying customers
- No date window — all history from Fact_SnapshotCustomer is included (2011 to present)
- No @Date parameter — SP is parameterless; calling it always rebuilds everything

### 2.5 Is_FTD Column Semantics

**What**: `Is_FTD` does not mean "first-time depositor event" — it reflects depositor status on the snapshot day.

**Columns Involved**: `Is_FTD`

**Rule**: `CASE WHEN fsc.IsDepositor = 1 THEN 1 ELSE 0 END` — 1 if the customer had ever deposited as of the snapshot date; 0 if not yet a depositor. The name "Is_FTD" is misleading; this is a depositor flag, not a first-deposit event flag.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: `ROUND_ROBIN` — data is spread evenly across distributions. CID-based queries do not benefit from co-location; expect data movement on JOINs.

**Index**: `HEAP` — no clustered index. Full table scans for all queries. At 27.2M rows this is notable; filter on indexed columns (none exist) or add query hints if performance is critical.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What is the full restriction history of a customer? | `WHERE CID = X ORDER BY Change_Date` |
| Actual status changes (excluding first-time assignments) | `WHERE Previous_PlayerStatus <> 'N/A'` |
| AML-specific restrictions | `WHERE PlayerStatusReason IN ('AML','AML review','AML-Account Closed')` |
| Count of Normal→Blocked escalations | `WHERE Previous_PlayerStatus='Normal' AND Current_PlayerStatus LIKE 'Blocked%'` |
| Days between restriction upgrades | `SELECT DaysBetweenChanges WHERE DaysBetweenChanges IS NOT NULL` |
| Sub-reason breakdown for blocks | `GROUP BY PlayerStatusSubReason WHERE Current_PlayerStatus LIKE 'Block%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON t.CID = dc.RealCID | Refresh PII or add additional customer attributes |
| DWH_dbo.Fact_SnapshotCustomer | ON t.CID = fsc.RealCID | Retrieve daily snapshot context for specific change dates |

### 3.4 Gotchas

- **PlayerStatusSubReasonName always NULL**: This DDL column (col 22) is never populated by the SP. The SP's INSERT omits it entirely. Do not query it expecting data.
- **72% of rows are "first-time" assignments**: `Previous_PlayerStatus = 'N/A'` rows (19.6M) are not actual status changes — they are the first recorded status per customer. Filter `WHERE Previous_PlayerStatus <> 'N/A'` to isolate real transitions.
- **PII reflects ETL rebuild date, not change date**: Customer name, email, phone reflect today's values. Historical PII at the time of status change is not available in this table.
- **Is_FTD is a depositor flag, not FTD event**: Despite the name, Is_FTD = `CASE WHEN IsDepositor=1 THEN 1 ELSE 0 END` — a binary depositor indicator, not a first-deposit signal.
- **PlayerStatus trailing spaces**: Live values for `Warning`, `Blocked Upon Request`, `Blocked - Under Investigation`, etc. have trailing spaces. Always use `RTRIM()` in string comparisons.
- **ROUND_ROBIN + HEAP**: No CID-based co-location, no index. Queries on large CID sets will be slow. Apply TOP/date filters first.
- **FirstDepositDate default '1900-01-01'**: Non-depositor customers inherit this sentinel from Dim_Customer — not a real date.
- **Previous_ChangeDate NULL for first row**: `LAG(Change_Date, 1, NULL)` — the first change_date per customer has NULL Previous_ChangeDate, making DaysBetweenChanges also NULL.
- **TRUNCATE risk**: If SP_AML_PlayerStatus_Changes fails mid-run (after TRUNCATE, before INSERT completes), the table is empty until the next successful run.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — ...)` |
| ★★★ | Tier 2 — SP code / ETL | `(Tier 2 — SP_AML_PlayerStatus_Changes)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Unique real customer identifier. Matches Dim_Customer.RealCID. Excludes test accounts and internal users. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstName | varchar(250) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). NOTE: reflects current value at ETL rebuild date, not the value at the time of the status change. (Tier 1 — Customer.CustomerStatic) |
| 3 | LastName | varchar(250) | YES | Legal last name in Unicode. NOTE: reflects current value at ETL rebuild date. (Tier 1 — Customer.CustomerStatic) |
| 4 | MiddleName | varchar(250) | YES | Middle name in Unicode. Added to Dim_Customer in 2018. Reflects current value at ETL rebuild date. (Tier 1 — Customer.CustomerStatic) |
| 5 | Email | varchar(250) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Reflects current value at ETL rebuild date. (Tier 1 — Customer.CustomerStatic) |
| 6 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 7 | Phone | varchar(250) | YES | Phone number from production Customer.CustomerStatic. Reflects current value at ETL rebuild date. For verified phone, see Dim_Customer.PhoneNumber. (Tier 1 — Customer.CustomerStatic) |
| 8 | IP | varchar(250) | YES | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 9 | Regulation | varchar(250) | YES | Short code for the regulation under which the customer is licensed. Used in V_Dim_Customer and analytics dashboards. (Tier 1 — Dictionary.Regulation) |
| 10 | Country | varchar(250) | YES | Country name derived from Dim_Country.Name via Dim_Customer.CountryID. Represents the customer's country of residence. (Tier 1 — Dictionary.Country) |
| 11 | Club | varchar(250) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Reflects current tier at ETL rebuild date. (Tier 1 — Dictionary.PlayerLevel) |
| 12 | RegisteredReal | date | YES | Account registration date (renamed from Registered in Dim_Customer; source: Customer.CustomerStatic). Default=getdate() in source. Cast to DATE. (Tier 1 — Customer.CustomerStatic) |
| 13 | FirstDepositDate | date | YES | Date of first deposit, cast to DATE. Default='1900-01-01' for customers who have never deposited. (Tier 2 — SP_Dim_Customer) |
| 14 | Previous_ID | int | YES | PlayerStatusID of the customer's status on the preceding snapshot date. Computed via LAG(PlayerStatusID, 1, 0) — default=0 (N/A) for the first row per customer. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 15 | Previous_PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Value='N/A' (72.1% of rows) indicates no prior status record — first-ever status assignment for the customer. (Tier 1 — Dictionary.PlayerStatus) |
| 16 | Current_ID | int | YES | PlayerStatusID of the customer's status on the change date. Passthrough from Fact_SnapshotCustomer.PlayerStatusID. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 17 | Current_PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Top values: Normal (75.8%), Blocked (8.0%), Block Deposit & Trading (5.0%). (Tier 1 — Dictionary.PlayerStatus) |
| 18 | Change_Date | date | YES | Date on which the status change was detected. Derived from Dim_Range.FromDateID → CONVERT(DATE, CONVERT(CHAR(8), FromDateID)). (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 19 | Previous_ChangeDate | date | YES | Date of the preceding status change for the same customer. LAG(Change_Date, 1, NULL). NULL for the customer's first change event. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 20 | DaysBetweenChanges | int | YES | Number of calendar days between the previous status change and this one. DATEDIFF(DAY, Previous_ChangeDate, Change_Date). NULL when Previous_ChangeDate is NULL. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 21 | PlayerStatusReason | varchar(250) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). NULL when no reason was recorded. (Tier 1 — Dictionary.PlayerStatusReasons) |
| 22 | PlayerStatusSubReasonName | varchar(250) | YES | **Always NULL.** Column exists in DDL but is never populated by SP_AML_PlayerStatus_Changes — the SP's INSERT statement omits this column entirely. Do not use. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 23 | Is_FTD | int | YES | Depositor flag at snapshot time. CASE WHEN Fact_SnapshotCustomer.IsDepositor=1 THEN 1 ELSE 0 END. Despite the name, this is not a "first-time depositor event" flag — it is 1 if the customer had ever deposited as of the change snapshot date. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 24 | Current_Reason_ID | int | YES | PlayerStatusReasonID from Fact_SnapshotCustomer for the current status change. FK to Dim_PlayerStatusReasons.PlayerStatusReasonID. 0=None (no reason). (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 25 | Previous_PlayerStatus_Reason_ID | int | YES | PlayerStatusReasonID from the preceding snapshot. LAG(PlayerStatusReasonID, 1, 0). 0 for the first row per customer. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 26 | Previous_PlayerStatus_Reason | varchar(250) | YES | Human-readable reason label for the preceding status. Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18). LEFT JOIN — NULL when no prior reason. (Tier 1 — Dictionary.PlayerStatusReasons) |
| 27 | Current_Sub_Reason_ID | int | YES | PlayerStatusSubReasonID from Fact_SnapshotCustomer for the current status change. FK to Dim_PlayerStatusSubReasons.PlayerStatusSubReasonID. 0=None. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 28 | PlayerStatusSubReason | varchar(250) | YES | Granular sub-reason label for the current status. Resolved from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName (production column `Name` is renamed to `PlayerStatusSubReasonName` in DWH). LEFT JOIN — NULL when no sub-reason recorded. (Tier 1 — Dictionary.PlayerStatusSubReasons) |
| 29 | Previous_PlayerStatus_SubReason_ID | int | YES | PlayerStatusSubReasonID from the preceding snapshot. LAG(PlayerStatusSubReasonID, 1, 0). 0 for the first row per customer. (Tier 2 — SP_AML_PlayerStatus_Changes) |
| 30 | Previous_PlayerStatus_Sub_Reason | varchar(250) | YES | Granular sub-reason label for the preceding status. Resolved from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. LEFT JOIN — NULL when no prior sub-reason. (Tier 1 — Dictionary.PlayerStatusSubReasons) |
| 31 | UserName | varchar(250) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index in Dim_Customer). Reflects current value at ETL rebuild date. (Tier 1 — Customer.CustomerStatic) |
| 32 | UpdateDate | datetime | YES | SP execution timestamp. Set to GETDATE() at time of SP_AML_PlayerStatus_Changes run. Reflects ETL run time, not a business event date. (Tier 2 — SP_AML_PlayerStatus_Changes) |

---

## 5. Lineage

### 5.1 Column-Level Lineage

| Column | Source Object | Source Column | Transform |
|--------|---------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough |
| FirstName–IP, UserName | DWH_dbo.Dim_Customer | Same-named columns | Passthrough (current-state PII) |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN: RegulationID → DWHRegulationID |
| Country | DWH_dbo.Dim_Country | Name | JOIN: CountryID → DWHCountryID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN: PlayerLevelID |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | CAST AS DATE |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST AS DATE |
| Previous_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | LAG(1, 0) OVER(PARTITION BY RealCID ORDER BY FromDateID) |
| Previous_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on Previous_ID |
| Current_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Passthrough |
| Current_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on Current_ID |
| Change_Date | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE, CONVERT(CHAR(8), FromDateID)) |
| Previous_ChangeDate | Computed | Change_Date | LAG(1, NULL) OVER(PARTITION BY CID ORDER BY Change_Date) |
| DaysBetweenChanges | Computed | Previous_ChangeDate, Change_Date | DATEDIFF(DAY, ...) |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN on Current_Reason_ID |
| PlayerStatusSubReasonName | N/A | N/A | Always NULL (DDL ghost column) |
| Is_FTD | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | CASE WHEN IsDepositor=1 THEN 1 ELSE 0 END |
| Current_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Passthrough |
| Previous_PlayerStatus_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | LAG(1, 0) |
| Previous_PlayerStatus_Reason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN on Previous_Reason_ID |
| Current_Sub_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | Passthrough |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | LEFT JOIN on Current_Sub_Reason_ID |
| Previous_PlayerStatus_SubReason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | LAG(1, 0) |
| Previous_PlayerStatus_Sub_Reason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | LEFT JOIN on Previous_SubReason_ID |
| UpdateDate | ETL | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer [IsValidCustomer=1, VerificationLevelID>=2]
  LAG(PlayerStatusID/ReasonID/SubReasonID) OVER(PARTITION BY RealCID ORDER BY FromDateID)
  WHERE PlayerStatusID <> Previous_PlayerStatusID  [change detection + first-time rows]
    |-- Step 1 → #pop: status transitions + dimension JOINs for status/reason/sub-reason names

DWH_dbo.Dim_PlayerStatus (×2)         → Current_PlayerStatus, Previous_PlayerStatus
DWH_dbo.Dim_PlayerStatusReasons (×2)  → PlayerStatusReason, Previous_PlayerStatus_Reason
DWH_dbo.Dim_PlayerStatusSubReasons (×2) → PlayerStatusSubReason, Previous_PlayerStatus_Sub_Reason
DWH_dbo.Dim_Range                     → Change_Date (FromDateID → DATE)
    |-- Step 2 → #days: LAG(Change_Date) + DATEDIFF for Previous_ChangeDate and DaysBetweenChanges

DWH_dbo.Dim_Customer [IsValidCustomer=1, VerificationLevelID>=2]
  → PII (FirstName, LastName, MiddleName, Email, BirthDate, Phone, IP, UserName)
  → Regulation, Country, Club (via Dim_Regulation, Dim_Country, Dim_PlayerLevel)
  → RegisteredReal, FirstDepositDate
    |-- Step 3 → #client: full row with PII and attributes

    |-- Step 4 → #final: column selection for INSERT

    |-- Step 5: SP_AML_PlayerStatus_Changes ---|
    |   TRUNCATE TABLE                         |
    |   INSERT FROM #final (31 columns)        |
    |   PlayerStatusSubReasonName NOT inserted |
    v
BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes
  27.2M rows | 19.6M CIDs | 2011-06-07 to 2026-04-12
  32 DDL columns (1 ghost column: PlayerStatusSubReasonName — always NULL)
  ROUND_ROBIN | HEAP | Daily full rebuild
```

---

## 6. Relationships

### 6.1 References To (upstream sources)

| Source Object | Join Condition | Columns Consumed |
|--------------|---------------|-----------------|
| DWH_dbo.Fact_SnapshotCustomer | RealCID | PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID, IsDepositor |
| DWH_dbo.Dim_Range | DateRangeID | FromDateID → Change_Date |
| DWH_dbo.Dim_Customer | RealCID | PII fields, RegisteredReal, FirstDepositDate, CountryID, RegulationID, PlayerLevelID |
| DWH_dbo.Dim_PlayerStatus | PlayerStatusID (×2) | Name → Current/Previous_PlayerStatus |
| DWH_dbo.Dim_PlayerStatusReasons | PlayerStatusReasonID (×2) | Name → PlayerStatusReason, Previous_PlayerStatus_Reason |
| DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonID (×2) | PlayerStatusSubReasonName → PlayerStatusSubReason, Previous_PlayerStatus_Sub_Reason |
| DWH_dbo.Dim_Country | CountryID | Name → Country |
| DWH_dbo.Dim_Regulation | DWHRegulationID | Name → Regulation |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID | Name → Club |

### 6.2 Referenced By (known consumers)

No downstream BI_DB tables or SPs found in the SSDT repo that directly JOIN to this table. Primary consumers are AML compliance reports and dashboards.

---

## 7. Sample Queries

### 7.1 Full restriction history for a customer (actual changes only)

```sql
SELECT
    CID,
    Change_Date,
    RTRIM(Previous_PlayerStatus)  AS Previous_Status,
    RTRIM(Current_PlayerStatus)   AS Current_Status,
    PlayerStatusReason,
    PlayerStatusSubReason,
    DaysBetweenChanges
FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes]
WHERE CID = 12345678
  AND Previous_PlayerStatus <> 'N/A'  -- exclude first-time assignments
ORDER BY Change_Date;
```

### 7.2 Count AML-driven restrictions by month

```sql
SELECT
    FORMAT(Change_Date, 'yyyy-MM')     AS MonthYear,
    COUNT(*)                           AS RestrictionCount,
    RTRIM(Current_PlayerStatus)        AS NewStatus
FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes]
WHERE PlayerStatusReason IN ('AML', 'AML review', 'AML-Account Closed')
  AND Previous_PlayerStatus <> 'N/A'
GROUP BY FORMAT(Change_Date, 'yyyy-MM'), RTRIM(Current_PlayerStatus)
ORDER BY MonthYear DESC, RestrictionCount DESC;
```

### 7.3 Normal → Blocked escalation events

```sql
SELECT
    CID,
    Change_Date,
    RTRIM(Current_PlayerStatus) AS NewStatus,
    PlayerStatusReason,
    DaysBetweenChanges,
    Regulation
FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes]
WHERE RTRIM(Previous_PlayerStatus) = 'Normal'
  AND RTRIM(Current_PlayerStatus) LIKE 'Block%'
ORDER BY Change_Date DESC;
```

### 7.4 Sub-reason breakdown for current blocks

```sql
SELECT
    PlayerStatusSubReason,
    COUNT(*)              AS BlockCount
FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes]
WHERE RTRIM(Current_PlayerStatus) LIKE 'Block%'
  AND PlayerStatusSubReason IS NOT NULL
GROUP BY PlayerStatusSubReason
ORDER BY BlockCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 8.8/10 (★★★★☆) | Phases: 1–11, 16*
*Tiers: 19 T1, 13 T2, 0 T3, 0 T4 | Elements: 32/32 | UC Target: _Not_Migrated*
*Object: BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Type: Table | Writer: SP_AML_PlayerStatus_Changes*
