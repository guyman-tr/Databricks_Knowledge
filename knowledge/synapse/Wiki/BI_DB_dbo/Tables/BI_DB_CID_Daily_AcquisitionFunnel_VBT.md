# BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

> 44.5M-row daily customer acquisition funnel table tracking which lifecycle milestones (registration, V2/V3 verification, first deposit, first position open) each valid customer reached on each calendar day, with a VBT (Video-Based Trading) classification flag — spanning 36.2M distinct CIDs from 2019-01-01 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Fact_SnapshotCustomer (customer state), BI_DB_CIDFirstDates (milestone dates), Dim_Regulation (regulation names), Dim_PlayerStatus (status names), ComplianceStateDB KycFlow (VBT flag) via SP_CID_Daily_AcquisitionFunnel_VBT |
| **Refresh** | Daily via DELETE+INSERT for @date (SP_CID_Daily_AcquisitionFunnel_VBT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

BI_DB_CID_Daily_AcquisitionFunnel_VBT is a daily-grain customer acquisition funnel table in the BI layer. For each calendar day, it records one row per valid customer who reached at least one milestone on that day — registration, V2 verification, V3 verification, first deposit (FTD), or first position open. Each milestone is encoded as a binary flag (1 = milestone occurred on that exact date, 0 = did not occur on that date) alongside the original milestone date from BI_DB_CIDFirstDates.

The table additionally classifies each customer as VBT (Video-Based Trading, IsVBT=1) or non-VBT based on whether their GCID appears in ComplianceStateDB KycFlow records with KYCFlowTypeID=2. This enables compliance and product teams to measure funnel conversion rates split by VBT vs. non-VBT onboarding paths.

The SP filters to valid customers only (IsValidCustomer=1) and excludes blocked/closed/pending statuses (PlayerStatusID NOT IN 2,4,13). It joins Fact_SnapshotCustomer (current SCD2 row via Dim_Range date filter) with BI_DB_CIDFirstDates for milestone dates, then enriches with regulation names from Dim_Regulation and player status names from Dim_PlayerStatus.

As of 2026-04-26: 44.5M rows, 36.2M distinct CIDs, 2,666 distinct dates. In 2026 YTD: 1.5M registrations, 698K V2, 320K V3, 155K FTD, 128K first position open. IsVBT distribution (2026): 42% VBT, 58% non-VBT.

---

## 2. Business Logic

### 2.1 Daily Funnel Flag Pattern

**What**: Each milestone is recorded as both a date column (when it first happened) and a binary flag (did it happen on @date?).

**Columns Involved**: `Registration`/`Reg_Date`, `V2`/`V2_Date`, `V3`/`V3_Date`, `FTD`/`FTD_Date`, `FirstPosOpen`/`FirstPosOpen_Date`

**Rules**:
- Flag = 1 if the milestone date (from BI_DB_CIDFirstDates) equals @date; 0 otherwise
- A customer appears in this table for a given @date only if at least one of the five flags = 1
- The WHERE clause enforces: `Registration=1 OR V2=1 OR V3=1 OR FTD=1 OR FirstPosOpen=1`
- FTD_Date = 1900-01-01 is the sentinel for "no deposit yet" (inherited from BI_DB_CIDFirstDates)

### 2.2 VBT Classification

**What**: Identifies customers who went through Video-Based Trading KYC flow.

**Columns Involved**: `IsVBT`

**Rules**:
- A temp table #VBT_CIDs collects distinct GCIDs from two ComplianceStateDB KycFlow tables (current + history) where KYCFlowTypeID = 2
- IsVBT = 1 if the customer's GCID (from Fact_SnapshotCustomer) appears in #VBT_CIDs via LEFT JOIN; 0 otherwise
- This is a GCID-level flag — all CIDs sharing a GCID get the same VBT classification

### 2.3 Valid Customer Filter

**What**: Only valid, non-blocked customers are included.

**Columns Involved**: Fact_SnapshotCustomer.IsValidCustomer, Fact_SnapshotCustomer.PlayerStatusID

**Rules**:
- `IsValidCustomer = 1` (excludes demo, internal labels, blocked countries — see Fact_SnapshotCustomer wiki §2.2)
- `PlayerStatusID NOT IN (2, 4, 13)` — excludes Blocked (2), Blocked Upon Request (4), Pending Verification (13)
- SCD2 date filter: `@DateINT BETWEEN dr.FromDateID AND dr.ToDateID` ensures the customer's state was active on @date

### 2.4 DELETE+INSERT Refresh

**What**: Each daily run replaces all rows for @date.

**Rules**:
- `DELETE FROM BI_DB_CID_Daily_AcquisitionFunnel_VBT WHERE [Date] = @date`
- Then INSERT all qualifying rows for that date
- This makes the table idempotent for reruns on the same date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with CLUSTERED INDEX on Date ASC. Date-filtered queries are efficient. Cross-CID aggregations require full table scans since there is no hash key — always filter by Date range.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily registration count by VBT | `SELECT [Date], IsVBT, SUM(Registration) FROM ... GROUP BY [Date], IsVBT` |
| Funnel conversion rates for a period | `SELECT SUM(Registration), SUM(V2), SUM(V3), SUM(FTD), SUM(FirstPosOpen) WHERE [Date] BETWEEN @start AND @end` |
| VBT vs non-VBT FTD rate by regulation | `SELECT Regulation, IsVBT, SUM(FTD)*1.0/SUM(Registration) WHERE Registration=1 GROUP BY Regulation, IsVBT` |
| Time-to-deposit for a cohort | Join back to BI_DB_CIDFirstDates for `DATEDIFF(DAY, Reg_Date, FTD_Date)` |
| Customers who registered but never deposited | `WHERE Registration=1 AND (FTD_Date IS NULL OR YEAR(FTD_Date)=1900)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID = CID | Full customer milestone detail |
| DWH_dbo.Dim_Country | ON Country name match or via CIDFirstDates.CountryID | Country-level analytics |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | ON CID = CID | Balance/equity for funnel cohorts |

### 3.4 Gotchas

- **FTD_Date sentinel**: `1900-01-01` means "no deposit yet." Filter with `YEAR(FTD_Date) != 1900` or `FTD_Date > '1900-01-02'`.
- **One row per CID per date**: A customer can appear on multiple dates (e.g., registered day 1, deposited day 5). To count unique customers, use `COUNT(DISTINCT CID)`.
- **Only milestone days**: A customer does NOT have a row for every day — only for days when at least one milestone flag = 1. This is NOT a daily snapshot table.
- **Excluded statuses**: Blocked (2), Blocked Upon Request (4), Pending Verification (13) are excluded. If a customer was Normal when they registered but later Blocked, they still appear for their registration date (the status is as-of @date via SCD2).
- **ROUND_ROBIN**: No co-location benefit for CID JOINs. For CID-heavy joins, consider filtering by Date first to reduce scan scope.
- **Regulation and PlayerStatus are resolved names**: These are varchar strings (e.g., "BVI", "Normal"), not IDs. If you need the ID, use PlayerStatusID directly or join to Dim_Regulation.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 — upstream wiki verbatim | `(Tier 1 — source)` |
| ★★★☆☆ | Tier 2 — SP code / ETL-computed | `(Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Real (funded) customer ID. The primary customer identifier in the DWH ecosystem. Passthrough from Fact_SnapshotCustomer.RealCID (renamed). (Tier 1 — Fact_SnapshotCustomer) |
| 2 | Date | date | NO | The calendar date this funnel row represents. Set to the SP's @date input parameter. Each daily run produces rows for exactly one Date value. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 3 | DateID | int | NO | Integer encoding of Date in YYYYMMDD format. ETL-computed: CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 4 | YearMonth | int | NO | Year-month period in YYYYMM format. ETL-computed: YEAR(@date) * 100 + MONTH(@date). (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 5 | Desk | varchar(8000) | YES | Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. Passthrough from BI_DB_CIDFirstDates.PotentialDesk (renamed). (Tier 1 — BI_DB_CIDFirstDates) |
| 6 | Region | nvarchar(500) | YES | Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. Passthrough from BI_DB_CIDFirstDates. (Tier 4 — BI_DB_CIDFirstDates) |
| 7 | Country | varchar(500) | YES | Country of residence name. Resolved from Dim_Country.Name via CountryID. Passthrough from BI_DB_CIDFirstDates. (Tier 1 — BI_DB_CIDFirstDates) |
| 8 | Channel | nvarchar(500) | YES | Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — BI_DB_CIDFirstDates) |
| 9 | SubChannel | nvarchar(500) | YES | Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — BI_DB_CIDFirstDates) |
| 10 | Regulation | varchar(50) | YES | Short code for the regulation. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 11 | DesignatedRegulation | varchar(50) | YES | Short code for the designated (secondary) regulation. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.DesignatedRegulationID. (Tier 1 — Dictionary.Regulation) |
| 12 | Reg_Date | date | YES | Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. CAST to DATE from BI_DB_CIDFirstDates.registered. (Tier 1 — BI_DB_CIDFirstDates) |
| 13 | Registration | int | NO | Binary flag: 1 if the customer registered on this Date, 0 otherwise. ETL-computed: CASE WHEN CAST(fd.registered AS date) = @date THEN 1 ELSE 0 END. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 14 | V2_Date | date | YES | First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel2Date. (Tier 1 — BI_DB_CIDFirstDates) |
| 15 | V2 | int | NO | Binary flag: 1 if the customer reached V2 verification on this Date, 0 otherwise. ETL-computed: CASE WHEN CAST(fd.VerificationLevel2Date AS date) = @date THEN 1 ELSE 0 END. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 16 | V3_Date | date | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel3Date. (Tier 1 — BI_DB_CIDFirstDates) |
| 17 | V3 | int | NO | Binary flag: 1 if the customer reached V3 (full) verification on this Date, 0 otherwise. ETL-computed: CASE WHEN CAST(fd.VerificationLevel3Date AS date) = @date THEN 1 ELSE 0 END. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 18 | FTD_Date | date | YES | First successful deposit date. Read directly from Dim_Customer.FirstDepositDate, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FTD_Date) != 1900`. CAST to DATE from BI_DB_CIDFirstDates.FirstDepositDate. (Tier 1 — BI_DB_CIDFirstDates) |
| 19 | FTD | int | NO | Binary flag: 1 if the customer made their first deposit on this Date, 0 otherwise. ETL-computed: CASE WHEN CAST(fd.FirstDepositDate AS date) = @date THEN 1 ELSE 0 END. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 20 | FTDA | money | YES | Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. Passthrough from BI_DB_CIDFirstDates.FirstDepositAmount (renamed). (Tier 1 — BI_DB_CIDFirstDates) |
| 21 | FirstPosOpen_Date | date | YES | First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. CAST to DATE from BI_DB_CIDFirstDates.FirstPosOpenDate. (Tier 1 — BI_DB_CIDFirstDates) |
| 22 | FirstPosOpen | int | NO | Binary flag: 1 if the customer opened their first position on this Date, 0 otherwise. ETL-computed: CASE WHEN CAST(fd.FirstPosOpenDate AS date) = @date THEN 1 ELSE 0 END. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 23 | IsVBT | int | NO | Video-Based Trading flag. 1 if the customer's GCID appears in ComplianceStateDB KycFlow tables (current or history) with KYCFlowTypeID=2; 0 otherwise. ETL-computed via LEFT JOIN to #VBT_CIDs temp table on GCID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 24 | PlayerStatusID | int | YES | Customer lifecycle status. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer. Note: statuses 2 (Blocked), 4 (Blocked Upon Request), 13 (Pending Verification) are excluded by the SP WHERE clause. (Tier 2 — Fact_SnapshotCustomer) |
| 25 | PlayerStatus | varchar(50) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Dim-lookup from Dim_PlayerStatus.Name. (Tier 1 — Dictionary.PlayerStatus) |
| 26 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at SP execution. Not a business event date. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| CID | Fact_SnapshotCustomer | RealCID | Rename |
| Date | ETL-computed | @date parameter | Passthrough |
| DateID | ETL-computed | @date parameter | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| YearMonth | ETL-computed | @date parameter | YEAR(@date) * 100 + MONTH(@date) |
| Desk | BI_DB_CIDFirstDates | PotentialDesk | Rename |
| Region | BI_DB_CIDFirstDates | Region | Passthrough |
| Country | BI_DB_CIDFirstDates | Country | Passthrough |
| Channel | BI_DB_CIDFirstDates | Channel | Passthrough |
| SubChannel | BI_DB_CIDFirstDates | SubChannel | Passthrough |
| Regulation | Dim_Regulation (dr1) | Name | Dim-lookup via sc.RegulationID = dr1.DWHRegulationID |
| DesignatedRegulation | Dim_Regulation (dr2) | Name | Dim-lookup via sc.DesignatedRegulationID = dr2.DWHRegulationID |
| Reg_Date | BI_DB_CIDFirstDates | registered | CAST(registered AS DATE) |
| Registration | ETL-computed | fd.registered + @date | CASE WHEN date match THEN 1 ELSE 0 |
| V2_Date | BI_DB_CIDFirstDates | VerificationLevel2Date | CAST AS DATE |
| V2 | ETL-computed | fd.VerificationLevel2Date + @date | CASE WHEN date match THEN 1 ELSE 0 |
| V3_Date | BI_DB_CIDFirstDates | VerificationLevel3Date | CAST AS DATE |
| V3 | ETL-computed | fd.VerificationLevel3Date + @date | CASE WHEN date match THEN 1 ELSE 0 |
| FTD_Date | BI_DB_CIDFirstDates | FirstDepositDate | CAST AS DATE |
| FTD | ETL-computed | fd.FirstDepositDate + @date | CASE WHEN date match THEN 1 ELSE 0 |
| FTDA | BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough (renamed) |
| FirstPosOpen_Date | BI_DB_CIDFirstDates | FirstPosOpenDate | CAST AS DATE |
| FirstPosOpen | ETL-computed | fd.FirstPosOpenDate + @date | CASE WHEN date match THEN 1 ELSE 0 |
| IsVBT | ComplianceStateDB KycFlow | GCID + KYCFlowTypeID=2 | CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1 |
| PlayerStatusID | Fact_SnapshotCustomer | PlayerStatusID | Passthrough |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup via sc.PlayerStatusID = ps.PlayerStatusID |
| UpdateDate | ETL-computed | — | GETDATE() |

### 5.2 ETL Pipeline

```
ComplianceStateDB.Compliance.KycFlow (KYCFlowTypeID=2)  ──┐
ComplianceStateDB.History.KycFlow (KYCFlowTypeID=2)     ──┤
                                                           ▼
                                                     #VBT_CIDs (GCID list)
                                                           │
DWH_dbo.Fact_SnapshotCustomer ──┐                          │
DWH_dbo.Dim_Range ──────────────┤                          │
BI_DB_dbo.BI_DB_CIDFirstDates ──┤──→ SP_CID_Daily_AcquisitionFunnel_VBT(@date)
DWH_dbo.Dim_PlayerStatus ───────┤      │
DWH_dbo.Dim_Regulation (×2) ───┘      │ DELETE [Date]=@date + INSERT
                                       ▼
                              BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT
```

| Step | Object | Description |
|------|--------|-------------|
| VBT Prep | #VBT_CIDs | UNION of current + history KycFlow WHERE KYCFlowTypeID=2 → distinct GCIDs |
| Main Query | #CIDs | JOIN FSC × Dim_Range × CIDFirstDates × Dim_PlayerStatus × Dim_Regulation (×2) × #VBT_CIDs, filter valid + at least one milestone on @date |
| Delete | BI_DB_CID_Daily_AcquisitionFunnel_VBT | DELETE WHERE [Date] = @date |
| Insert | BI_DB_CID_Daily_AcquisitionFunnel_VBT | INSERT from #CIDs with @date, @DateINT, YearMonth, GETDATE() |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Fact_SnapshotCustomer (RealCID) | Customer state (SCD2) |
| CID | BI_DB_dbo.BI_DB_CIDFirstDates | Customer milestone dates |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account restriction state |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Primary regulatory jurisdiction |
| DesignatedRegulation | DWH_dbo.Dim_Regulation (Name) | Secondary regulatory jurisdiction |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in the SSDT repo. This appears to be a reporting/analytics endpoint table.

---

## 7. Sample Queries

### 7.1 Daily funnel conversion by VBT status (2026)

```sql
SELECT
    [Date],
    IsVBT,
    SUM(Registration) AS registrations,
    SUM(V2) AS v2_verifications,
    SUM(V3) AS v3_verifications,
    SUM(FTD) AS first_deposits,
    SUM(FirstPosOpen) AS first_positions
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE [Date] >= '2026-01-01'
GROUP BY [Date], IsVBT
ORDER BY [Date] DESC, IsVBT;
```

### 7.2 FTD conversion rate by regulation (2026 registrations)

```sql
SELECT
    Regulation,
    COUNT(DISTINCT CID) AS total_registered,
    COUNT(DISTINCT CASE WHEN FTD = 1 THEN CID END) AS ftd_on_reg_day,
    SUM(FTDA) AS total_ftda
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE [Date] >= '2026-01-01'
  AND Registration = 1
GROUP BY Regulation
ORDER BY total_registered DESC;
```

### 7.3 Monthly funnel trend

```sql
SELECT
    YearMonth,
    SUM(Registration) AS registrations,
    SUM(FTD) AS first_deposits,
    CAST(SUM(FTD) AS FLOAT) / NULLIF(SUM(Registration), 0) AS ftd_rate
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE YearMonth >= 202501
GROUP BY YearMonth
ORDER BY YearMonth;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — Atlassian MCP not available in regen harness mode.)

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Phases: 11/14*
*Tiers: 16 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT | Type: Table | Production Source: Multi-source via SP_CID_Daily_AcquisitionFunnel_VBT*
