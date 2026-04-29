# BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

> 44M-row daily acquisition funnel tracker (2019-01-01 to 2026-04-12) recording one row per customer per date when any funnel milestone occurred — registration, V2/V3 KYC verification, first deposit, or first position open — with VBT (Verified-by-eToro KYC flow) flag and current regulation/desk/channel segmentation. Feeds acquisition funnel dashboards and VBT-cohort analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_CIDFirstDates (milestone dates) + Fact_SnapshotCustomer (daily snapshot) + External_ComplianceStateDB_KycFlow (VBT flag) via SP_CID_Daily_AcquisitionFunnel_VBT |
| **Refresh** | Daily (SB_Daily, Priority 20) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_Daily_AcquisitionFunnel_VBT` is a daily acquisition funnel event table for BI reporting. For each calendar date, it contains one row per customer who experienced at least one funnel milestone on that date — new registration, V2 identity verification, V3 full KYC, first deposit (FTD), or first position open. The table spans 2019-01-01 to 2026-04-12 with approximately 44 million rows.

The **VBT** (Verified-by-eToro) flag distinguishes customers who completed the VBT KYC flow (KYCFlowTypeID=2 in ComplianceStateDB). VBT is an alternative KYC pathway that affects compliance treatment and is tracked separately from standard verification levels. Roughly 49% of funnel events in recent data involve VBT customers.

The ETL pattern is date-level idempotent: `SP_CID_Daily_AcquisitionFunnel_VBT @date` deletes all rows for that date and reinserts them from the current snapshot. The SP filters to `IsValidCustomer=1` and excludes internally blocked statuses (PlayerStatusID NOT IN 2,4,13), so the table reflects only valid customer records. It depends on `BI_DB_CIDFirstDates` (Priority 90 — runs before all Priority 20 SPs) for milestone date inputs.

Each row's milestone flags (Registration, V2, V3, FTD, FirstPosOpen) are binary (1=event happened on this date, 0=not on this date). The corresponding `_Date` columns always equal `[Date]` when the flag is 1, and contain the actual milestone date otherwise (enabling date-of-milestone lookups across the table's full history).

---

## 2. Business Logic

### 2.1 Funnel Milestone Flags

**What**: Five binary flags record which funnel event(s) occurred on the row's Date for that customer.

**Columns Involved**: `Registration`, `V2`, `V3`, `FTD`, `FirstPosOpen` (0/1 INT), `Reg_Date`, `V2_Date`, `V3_Date`, `FTD_Date`, `FirstPosOpen_Date`

**Rules**:
- `Registration=1` → `CAST(fd.registered AS DATE) = [Date]` — the customer registered on this date
- `V2=1` → `CAST(fd.VerificationLevel2Date AS DATE) = [Date]` — customer first reached V2 on this date
- `V3=1` → `CAST(fd.VerificationLevel3Date AS DATE) = [Date]` — customer first reached full KYC on this date
- `FTD=1` → `CAST(fd.FirstDepositDate AS DATE) = [Date]` — customer's first deposit was on this date
- `FirstPosOpen=1` → `CAST(fd.FirstPosOpenDate AS DATE) = [Date]` — first position opened on this date
- At least one flag must be 1 per row (the WHERE clause requires at least one milestone = @date)
- Multiple flags can be 1 on the same row (e.g., same-day registration + V2 + FTD)
- 2026 YTD distribution: Registration=82%, V2=45%, FTD=10%, FirstPosOpen not queried separately

### 2.2 VBT (Verified-by-eToro) Flag

**What**: Identifies customers who completed the alternative VBT KYC pathway (KYCFlowTypeID=2 in ComplianceStateDB).

**Columns Involved**: `IsVBT`

**Rules**:
- `IsVBT=1` → customer GCID appears in External_ComplianceStateDB_Compliance_KycFlow or _History_KycFlow with KYCFlowTypeID=2
- `IsVBT=0` → standard KYC pathway or GCID not in VBT flow
- Recent split: ~49% VBT (670K out of 1.37M events in 2026)
- VBT customers may have different compliance treatment and SLA thresholds

### 2.3 Customer Segmentation Snapshot

**What**: Each row carries the customer's current regulation and desk assignment at the time of the ETL run (from Fact_SnapshotCustomer), providing segmentation context for funnel metrics.

**Columns Involved**: `Desk`, `Region`, `Country`, `Channel`, `SubChannel`, `Regulation`, `DesignatedRegulation`, `PlayerStatusID`, `PlayerStatus`

**Rules**:
- `Regulation`/`DesignatedRegulation` resolved from `Dim_Regulation.Name` via `DWHRegulationID` — they reflect the customer's current regulatory entity, NOT the regulation at the time of the milestone
- `Desk`/`Region`/`Country`/`Channel`/`SubChannel` come from `BI_DB_CIDFirstDates` (acquisition-time segmentation)
- `PlayerStatusID NOT IN (2,4,13)` is applied: 2=Blocked, 4=Fraudster, 13=AML Limited; five statuses remain: 1=Normal (98.7%), 15=BlockDeposit&Trading, 9=Trade&MIMO Blocked, 10=DepositBlocked, 5=Warning

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means joins to this table on any column will cause data movement. The CLUSTERED INDEX on `Date ASC` makes date-range filters fast. For best performance: always filter by `Date` range first, then add secondary filters.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily registration count by desk | `WHERE Date=X AND Registration=1 GROUP BY Desk` — uses clustered index |
| Funnel conversion rates for a week | `WHERE Date BETWEEN x AND y` — pull all flags, aggregate per-CID |
| VBT vs non-VBT FTD rates | `WHERE FTD=1 GROUP BY IsVBT` — compare first deposit rates by VBT flag |
| Registration-to-FTD same-day | `WHERE Registration=1 AND FTD=1` — both flags on same row |
| Cumulative FTDs by regulation | `WHERE FTD=1 GROUP BY Regulation, Date` — sum over time |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_CIDFirstDates | ON CID = CID | Enrich with full customer lifecycle (email, last deposit, funded status) |
| DWH_dbo.Fact_SnapshotCustomer | ON CID=RealCID AND DateID BETWEEN FromDateID AND ToDateID | Current player snapshot |
| DWH_dbo.Dim_Regulation | ON Regulation = Name | Get regulation metadata |

### 3.4 Gotchas

- **Regulation is current, not historical**: Regulation/DesignatedRegulation reflect the snapshot at ETL run time, not the customer's regulation at the time of the milestone. For historical regulation tracking, join to Fact_SnapshotCustomer on DateID.
- **One row per CID per date**: A customer can have multiple funnel events on the same date (e.g., register AND deposit AND trade) — this appears as a SINGLE row with multiple flags=1. Do NOT SUM flags across CIDs without checking for multi-flag rows.
- **_Date columns**: When a flag is 1, the _Date column = [Date]. When flag is 0, the _Date contains the actual historical milestone date (useful for "when did this customer first deposit"). Never assume _Date = Date unless the flag is 1.
- **VBT scope**: IsVBT is based on GCID in ComplianceStateDB — older accounts without GCID will always be IsVBT=0.
- **FTDA = 0 when FTD = 0**: FirstDepositAmount is always populated (passthrough from CIDFirstDates), regardless of whether FTD=1 on this date. When FTD=0, FTDA still shows the customer's historical first deposit amount.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` |
| 1 star | Tier 4 (inferred) | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key for the customer. Sourced from Fact_SnapshotCustomer.RealCID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 2 | Date | date | NO | Calendar date on which at least one funnel milestone occurred for this customer. The SP is parameterized by @date — this always equals the ETL run date for each inserted row. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 3 | DateID | int | NO | Integer date key (YYYYMMDD format). CONVERT(VARCHAR(8), @date, 112) cast to INT. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 4 | YearMonth | int | NO | Year-month key (YYYYMM format). YEAR(@date)*100+MONTH(@date). (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 5 | Desk | varchar(8000) | YES | Sales desk assignment for the customer. Resolved from Dim_Country.Desk via CountryID in BI_DB_CIDFirstDates. Reflects acquisition-time desk, not necessarily current. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 6 | Region | nvarchar(500) | YES | Geographic region name. Resolved from Dim_Country.Region via CountryID in BI_DB_CIDFirstDates. Values: North Europe, French, Eastern Europe, Other EU, LATAM, USA, UK, German, Italian, Asia, ROW, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 7 | Country | varchar(500) | YES | Country of residence name. Resolved from Dim_Country.Name via CountryID in BI_DB_CIDFirstDates. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 8 | Channel | nvarchar(500) | YES | Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID in BI_DB_CIDFirstDates. Values: Direct, Affiliate, SEM, SEO, Media Performance, Friend Referral, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 9 | SubChannel | nvarchar(500) | YES | Marketing sub-channel detail. Resolved from Dim_Channel.SubChannel in BI_DB_CIDFirstDates. Values: Direct, Direct Mobile, Google Brand, Affiliate, YT, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 10 | Regulation | varchar(50) | YES | Current regulatory entity governing this customer's account. Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID (DWHRegulationID). Top values 2026: BVI (81%), CySEC (7.4%), eToroUS (4.7%), FCA (2.9%), FSA Seychelles (1.0%), FSRA (0.9%), ASIC & GAML (0.9%), FinCEN+FINRA (0.7%), FINRAONLY (0.5%), MAS (0.08%). (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_Regulation) |
| 11 | DesignatedRegulation | varchar(50) | YES | Designated regulatory entity (can differ from Regulation for cross-border accounts). Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.DesignatedRegulationID. Same value set as Regulation. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_Regulation) |
| 12 | Reg_Date | date | YES | Customer registration date (CAST of BI_DB_CIDFirstDates.registered AS DATE). NULL if not yet registered. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 13 | Registration | int | NO | Flag: 1 if customer registered on this Date, 0 otherwise. CASE WHEN CAST(fd.registered AS date)=[Date] THEN 1 ELSE 0. 2026 YTD: 1=82%, 0=18%. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 14 | V2_Date | date | YES | Date customer first reached verification level 2 (partial KYC). CAST of BI_DB_CIDFirstDates.VerificationLevel2Date AS DATE. NULL if not yet V2. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 15 | V2 | int | NO | Flag: 1 if customer first reached V2 verification on this Date, 0 otherwise. 2026 YTD: 0=55%, 1=45%. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 16 | V3_Date | date | YES | Date customer first reached verification level 3 (full KYC). CAST of BI_DB_CIDFirstDates.VerificationLevel3Date AS DATE. NULL if not yet fully verified. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 17 | V3 | int | NO | Flag: 1 if customer first reached V3 (full KYC) on this Date, 0 otherwise. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 18 | FTD_Date | date | YES | Customer's first deposit date. CAST of BI_DB_CIDFirstDates.FirstDepositDate AS DATE. NULL if no deposit yet. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 19 | FTD | int | NO | Flag: 1 if customer's first deposit occurred on this Date, 0 otherwise. 2026 YTD: 0=90%, 1=10%. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 20 | FTDA | money | YES | Customer's first deposit amount in USD. Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount. Populated for all rows (including FTD=0 rows) showing the historical FTD amount. 0.0 if no deposit. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 21 | FirstPosOpen_Date | date | YES | Customer's first position open date (manual or copy). CAST of BI_DB_CIDFirstDates.FirstPosOpenDate AS DATE. NULL if no position opened. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates) |
| 22 | FirstPosOpen | int | NO | Flag: 1 if customer first opened a position on this Date, 0 otherwise. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |
| 23 | IsVBT | int | NO | VBT (Verified-by-eToro) KYC flow flag. 1 if customer GCID appears in External_ComplianceStateDB_KycFlow or _History_KycFlow with KYCFlowTypeID=2, 0 otherwise. VBT is an alternative KYC pathway with its own compliance SLAs. 2026 YTD: 0=51%, 1=49%. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via External_ComplianceStateDB) |
| 24 | PlayerStatusID | int | YES | Customer account status ID at time of ETL run. From Fact_SnapshotCustomer. Excludes 2=Blocked/4=Fraudster/13=AML Limited. Present values: 1=Normal (98.7%), 9=Trade&MIMO Blocked, 10=Deposit Blocked, 15=Block Deposit & Trading, 5=Warning. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Fact_SnapshotCustomer) |
| 25 | PlayerStatus | varchar(50) | YES | Customer account status name. Resolved from Dim_PlayerStatus.Name via PlayerStatusID. Values mirror PlayerStatusID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_PlayerStatus) |
| 26 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each INSERT. Not updatable after insert. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column | Production Source | Source Column | Transform |
|-----------|-----------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough |
| Date | SP parameter @date | — | ETL run date |
| Desk/Region/Country/Channel/SubChannel | BI_DB_CIDFirstDates | PotentialDesk/Region/Country/Channel/SubChannel | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Resolved via sc.RegulationID=DWHRegulationID |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Resolved via sc.DesignatedRegulationID=DWHRegulationID |
| Reg_Date/V2_Date/V3_Date/FTD_Date/FirstPosOpen_Date | BI_DB_CIDFirstDates | registered/VerificationLevel2Date/3Date/FirstDepositDate/FirstPosOpenDate | CAST AS DATE |
| Registration/V2/V3/FTD/FirstPosOpen | BI_DB_CIDFirstDates | (same date columns) | CASE WHEN date=@date THEN 1 ELSE 0 |
| FTDA | BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough |
| IsVBT | External_ComplianceStateDB | GCID (KYCFlowTypeID=2) | CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1 |
| PlayerStatusID/PlayerStatus | Fact_SnapshotCustomer + Dim_PlayerStatus | PlayerStatusID / Name | Passthrough + join resolve |
| UpdateDate | SP metadata | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
External_ComplianceStateDB_Compliance_KycFlow (KYCFlowTypeID=2)
External_ComplianceStateDB_History_KycFlow (KYCFlowTypeID=2)
  └── #VBT_CIDs temp (GCID set)
                          |
DWH_dbo.Fact_SnapshotCustomer ── daily snapshot ─┐
  JOIN DWH_dbo.Dim_Range          (date window)  │
  JOIN BI_DB_CIDFirstDates (fd)   (milestones)  ─┤
  LEFT JOIN Dim_PlayerStatus       (status name) ─┤── SP_CID_Daily_AcquisitionFunnel_VBT
  LEFT JOIN Dim_Regulation (dr1/dr2) (reg name)  ─┤      DELETE WHERE Date=@date
  LEFT JOIN #VBT_CIDs               (VBT flag)   ─┘      INSERT filtered rows
  WHERE IsValidCustomer=1, PlayerStatusID NOT IN(2,4,13)
  AND any milestone = @date
        |
        v
BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT
(~44M rows, 2019-01-01 to 2026-04-12, ROUND_ROBIN CLUSTERED(Date))
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Fact_SnapshotCustomer | Source of RealCID and daily player status |
| CID | BI_DB_dbo.BI_DB_CIDFirstDates | Primary milestone date source |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Status name resolution |
| Regulation/DesignatedRegulation | DWH_dbo.Dim_Regulation | Regulation name resolution |
| IsVBT | BI_DB_dbo.External_ComplianceStateDB_Compliance_KycFlow | VBT KYC flow source |

### 6.2 Referenced By

| Related Object | Reference | Description |
|---------------|-----------|-------------|
| BI_DB_dbo.BI_DB_CIDFunnelFlow | CID/milestone logic | CIDFunnelFlow uses the same funnel logic (rolling 12-month variant); VBT_AcquisitionFunnel is the cumulative daily-grain complement |

---

## 7. Sample Queries

### Daily VBT vs Non-VBT Registration Count by Desk

```sql
SELECT
    Date,
    Desk,
    IsVBT,
    SUM(Registration) AS Registrations,
    SUM(FTD) AS FTDs,
    SUM(FirstPosOpen) AS FirstPositions
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE Date >= '2026-01-01'
    AND Registration = 1
GROUP BY Date, Desk, IsVBT
ORDER BY Date DESC, Desk, IsVBT
```

### Same-Day Registration and FTD (Instant Converters)

```sql
SELECT
    Regulation,
    Country,
    Channel,
    COUNT(1) AS InstantConverters
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE Date BETWEEN '2026-01-01' AND '2026-04-12'
    AND Registration = 1
    AND FTD = 1
GROUP BY Regulation, Country, Channel
ORDER BY InstantConverters DESC
```

### Weekly Funnel Conversion Rates

```sql
SELECT
    DATEADD(WEEK, DATEDIFF(WEEK, 0, Date), 0) AS WeekStart,
    COUNT(DISTINCT CASE WHEN Registration=1 THEN CID END) AS Registrations,
    COUNT(DISTINCT CASE WHEN V2=1 THEN CID END) AS V2Verified,
    COUNT(DISTINCT CASE WHEN FTD=1 THEN CID END) AS FirstDepositors,
    COUNT(DISTINCT CASE WHEN FirstPosOpen=1 THEN CID END) AS FirstTraders
FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE Date >= '2026-01-01'
GROUP BY DATEADD(WEEK, DATEDIFF(WEEK, 0, Date), 0)
ORDER BY WeekStart DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources queried (Atlassian MCP not available in this session). Acquisition funnel KPIs are tracked in the Data Platform DATA Confluence space.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 12/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4 | Elements: 26/26, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT | Type: Table | Production Source: SP_CID_Daily_AcquisitionFunnel_VBT*
