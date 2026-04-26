# BI_DB_DepositUsersFirstTouchPoints

> Customer onboarding funnel tracker. Records each milestone event (install, registration, verification steps, first deposit, first trade, first asset-class cross) as a dated row per customer. The grain is (Date, CID) where Date is the date of a specific milestone — one customer can have multiple rows, each on a different milestone date. Covers customers with any milestone in the rolling 2-year lookback from the last @date run. Used for funnel conversion analysis and activation reporting.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED INDEX (Date ASC) |
| **Row Count** | ~14M rows (rolling 2-year window) |
| **Distinct CIDs** | ~11.2M |
| **Date Range** | 2024-04-01 to 2026-04-12 (2-year lookback from latest run) |
| **Writer SP** | SP_DepositUsersFirstTouchPoints |
| **Write Pattern** | TRUNCATE + INSERT (full refresh per @date run) |
| **UC Status** | Not Migrated |
| **Disabled Columns** | EmailVerification, DepositView, DepositSubmits, DepositSubmitClick, PhoneVerification, KYCFlow, FirstDemoTrade — all NULL/0 |

---

## Business Context

`BI_DB_DepositUsersFirstTouchPoints` is a customer funnel event table. Each row represents one milestone event date for one customer. A customer who registered on day 1, deposited on day 5, and first traded on day 10 would have 3 rows (one per date) — each row carrying all their demographic attributes and a 0/1 flag showing which milestone(s) occurred on that specific date.

The **rolling 2-year window** is controlled by `@CalcDate = first day of month 2 years prior to @date`. Only milestones that occurred on or after @CalcDate are included. The TRUNCATE+INSERT approach rebuilds the entire table each run.

**Milestone flags (0/1 per row)**:
| Flag Column | Event | Source Date |
|---|---|---|
| Install | First app/web install | CIDFirstDates.FirstInstallDate |
| Registration | Account registration | CIDFirstDates.registered |
| VerificationLevel1 | First ID verification step | CIDFirstDates.VerificationLevel1Date |
| VerificationLevel2 | Second verification step | CIDFirstDates.VerificationLevel2Date |
| VerificationLevel3 | Full verification | CIDFirstDates.VerificationLevel3Date |
| EvMatchStatus | Identity match status achieved | CIDFirstDates.EvMatchStatusDate |
| DepositAttDB | First deposit attempt | CIDFirstDates.FirstDepositAttempt |
| FTD | First successful deposit | CIDFirstDates.FirstDepositDate |
| OpenTrade | First position opened | CIDFirstDates.FirstPosOpenDate |
| FirstNewFunded | First new funding event | CIDFirstDates.FirstNewFundedDate |
| FirstAction | First trading action date | BI_DB_First5Actions.FirstActionDate |
| SecondAction | Second trading action | BI_DB_First5Actions.SecondActionDate |
| FirstCross | First asset class cross | BI_DB_First5Actions.FirstCrossDate |
| FirstDemoTrade | **DISABLED** — hardcoded '19000101' sentinel | Demo table disconnected |

---

## Column Elements

### Key & Acquisition

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 3 | CID | int | NO | Tier 1 | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | AffiliateID | int | YES | Tier 1 | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 6 | SubAffiliateID | nvarchar(1024) | YES | Tier 1 | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic, originally Dim_Customer.SubSerialID) |
| 4 | Channel | nvarchar(500) | NO | Tier 2 | Marketing acquisition channel. From BI_DB_CIDFirstDates.Channel. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. |
| 5 | SubChannel | nvarchar(500) | NO | Tier 2 | Marketing sub-channel. From BI_DB_CIDFirstDates.SubChannel. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. |

### Geography & Desk

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 8 | Region | nvarchar(500) | NO | Tier 2 | Marketing region at registration. From BI_DB_CIDFirstDates.Region (Dim_Country.Region). Values: North Europe, French, Eastern Europe, LATAM, etc. |
| 9 | Country | varchar(500) | YES | Tier 2 | Country of residence name in English. From BI_DB_CIDFirstDates.Country (Dim_Country.Name). |
| 10 | State | varchar(500) | YES | Tier 2 | US state or province name. From BI_DB_CIDFirstDates.State (Dim_State_and_Province.Name for US customers). NULL for non-US. |
| 7 | Desk | nvarchar(50) | YES | Tier 3 | Sales/support desk assignment. From Dim_Country.Desk (joined via Country=Name). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no mapping. |

### Regulation & Funnel Source

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 11 | Regulation | varchar(50) | YES | Tier 2 | Regulatory entity governing this customer. From Dim_Regulation.Name via RegulationID. Values: ASIC, CySEC, FCA, FSAS, etc. |
| 12 | DesignatedRegulation | varchar(50) | YES | Tier 2 | Designated (target/assigned) regulatory entity. From Dim_Regulation.Name via DesignatedRegulationID. May differ from Regulation when a customer is being migrated between entities. |
| 13 | FunnelFrom | varchar(50) | YES | Tier 2 | Funnel origin identifier. From BI_DB_CIDFirstDates.FunnelFromName. Indicates which funnel/product brought the customer. |
| 14 | Platform | varchar(50) | YES | Tier 2 | Funnel platform name. From BI_DB_CIDFirstDates.FunnelName. Indicates the product platform the customer entered through. |

### Platform Detection (from Action Events)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 28 | Platform_fromAction_Regs | varchar(50) | YES | Tier 2 | Platform used at the time of registration. Resolved from Fact_CustomerAction WHERE ActionTypeID=41 (Registration), PlatformID mapped: 105=Android_App, 111=iOS_App, 104=Android_Web, 110=iOS_Web, 117=Desktop_Web. NULL if PlatformID not in this set. |
| 29 | Platform_fromAction_FTD | varchar(50) | YES | Tier 2 | Platform used at the time of first deposit. Resolved from Fact_CustomerAction WHERE ActionTypeID=7 AND IsFTD=1, same PlatformID mapping. NULL if not in set. |

### Funnel Milestone Flags (0/1)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 15 | Install | int | YES | Tier 2 | 1 on the row for the customer's first install date. PIVOT count of Action='Install' from CIDFirstDates.FirstInstallDate. |
| 16 | Registration | int | YES | Tier 2 | 1 on the row for the customer's registration date. PIVOT count of Action='Registration'. 9.5M rows with this flag set. |
| 18 | VerificationLevel1 | int | YES | Tier 2 | 1 on the row for the date the customer completed first-level ID verification. |
| 19 | VerificationLevel2 | int | YES | Tier 2 | 1 on the row for second-level verification completion date. |
| 23 | VerificationLevel3 | int | YES | Tier 2 | 1 on the row for third-level (full) verification completion date. |
| 31 | EvMatchStatus | int | YES | Tier 2 | 1 on the row for the date the customer's eV identity match status was achieved (from CIDFirstDates.EvMatchStatusDate). |
| 24 | DepositAttDB | int | YES | Tier 2 | 1 on the row for the customer's first deposit attempt date (from CIDFirstDates.FirstDepositAttempt). |
| 25 | FTD | int | YES | Tier 2 | 1 on the row for the customer's first successful deposit date. 977K rows with this flag set. |
| 26 | OpenTrade | int | YES | Tier 2 | 1 on the row for the customer's first position open date (from CIDFirstDates.FirstPosOpenDate). 1M rows. |
| 33 | FirstNewFunded | int | YES | Tier 2 | 1 on the row for the customer's first new-funded event date (from CIDFirstDates.FirstNewFundedDate). |
| 34 | FirstAction | int | YES | Tier 2 | 1 on the row for the customer's first trading action date (from BI_DB_First5Actions.FirstActionDate). |
| 35 | SecondAction | int | YES | Tier 2 | 1 on the row for the customer's second trading action date (from BI_DB_First5Actions.SecondActionDate). |
| 36 | FirstCross | int | YES | Tier 2 | 1 on the row for the customer's first cross-asset-class trade date (from BI_DB_First5Actions.FirstCrossDate). |
| 37 | FirstDemoTrade | int | YES | Tier 2 | **DISABLED** — hardcoded '19000101' sentinel in SP. Always 0. Demo table (BI_DB_Demo_CID_Panel) disconnected since 2024-01-15. |

### Disabled Columns

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 17 | EmailVerification | int | YES | Tier 2 | **DISABLED** — always NULL. Removed from SP logic but DDL column remains. 100% NULL in live data. |
| 20 | DepositView | int | YES | Tier 2 | **DISABLED** — always NULL. Was intended for deposit page view events. 100% NULL. |
| 21 | DepositSubmits | int | YES | Tier 2 | **DISABLED** — always NULL. Was intended for deposit form submit events. 100% NULL. |
| 22 | DepositSubmitClick | int | YES | Tier 2 | **DISABLED** — always NULL. 100% NULL. |
| 30 | PhoneVerification | int | YES | Tier 2 | **DISABLED** — always NULL. Removed 2021-12-27. 100% NULL. |
| 32 | KYCFlow | varchar(50) | YES | Tier 2 | **DISABLED** — always NULL. Removed 2022-07-03 to prevent duplicate records. 100% NULL. |

### First Action Type

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 38 | FirstActionType | varchar(50) | YES | Tier 2 | Detailed asset class of the customer's first trade. From BI_DB_First5Actions.FirstAction_Detailed. Values (among non-NULL): Real Stocks/ETFs (43.8%), Crypto (33.8%), Copy (10.4%), FX/Commodities/Indices (7.7%), CFD Stocks/ETFs (3.2%), Copy Fund (1.2%). NULL for customers who never traded. |

### Grain Date

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | Date | date | YES | Tier 2 | Date of the milestone event for this row. Each customer appears once per distinct milestone date. Multiple milestones on the same date result in one row with multiple flags set. Drives the CLUSTERED INDEX. |

### Metadata

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 27 | UpdateDate | datetime | NO | Tier 2 | Timestamp of SP execution. GETDATE() at INSERT time. |

---

## ETL Pipeline

```
BI_DB_CIDFirstDates (ANY milestone date >= @CalcDate AND IsValidCustomer=1)
  + BI_DB_First5Actions → FirstActionDate, SecondActionDate, FirstCrossDate, FirstAction_Detailed
  + Dim_Regulation (x2) → Regulation, DesignatedRegulation names
  → #tmp: one customer row with all milestone dates

#tmp → #date: UNION explode to (milestone_date, CID, ...) — one row per milestone
  → #pivot: PIVOT count(Action) → (Date, CID, ...) with 0/1 flags per milestone

+ Dim_Country.Desk (via Country=Name JOIN)
+ Fact_CustomerAction → Platform_fromAction_Regs / Platform_fromAction_FTD

|-- SP_DepositUsersFirstTouchPoints @date (TRUNCATE + full INSERT) --|
  v
BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints (14M rows, 2024–2026)
  |-- UC: Not Migrated --|
```

---

## Sample Queries

```sql
-- Weekly funnel conversion rates (Registration → FTD → FirstAction)
SELECT
    DATEPART(WEEK, Date) AS wk,
    YEAR(Date) AS yr,
    SUM(Registration) AS registrations,
    SUM(FTD) AS ftds,
    SUM(FirstAction) AS first_trades,
    CAST(100.0 * SUM(FTD) / NULLIF(SUM(Registration), 0) AS DECIMAL(5,1)) AS reg_to_ftd_pct
FROM BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), DATEPART(WEEK, Date)
ORDER BY yr, wk;
```

```sql
-- FTD breakdown by channel and first action type
SELECT
    Channel,
    FirstActionType,
    COUNT(*) AS ftd_customers
FROM BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints
WHERE FTD > 0
GROUP BY Channel, FirstActionType
ORDER BY ftd_customers DESC;
```

```sql
-- Platform used at registration vs at FTD
SELECT
    Platform_fromAction_Regs AS reg_platform,
    Platform_fromAction_FTD AS ftd_platform,
    COUNT(*) AS customers
FROM BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints
WHERE FTD > 0
  AND Platform_fromAction_Regs IS NOT NULL
  AND Platform_fromAction_FTD IS NOT NULL
GROUP BY Platform_fromAction_Regs, Platform_fromAction_FTD
ORDER BY customers DESC;
```

---

## Relationships

| Related Object | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer attribute enrichment |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID = CID | Demographics and milestone dates source |
| BI_DB_dbo.BI_DB_First5Actions | ON CID = CID | Trading milestone dates and FirstActionType |
