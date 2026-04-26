# BI_DB_dbo.BI_DB_AML_PI_Abuse

## 1. Summary

Daily full-refresh PI-level aggregate table from the `SP_AML_PI_Abuse` suite. Each row represents one **Popular Investor (PI)** with their identity, program status, financial snapshot, copier base metrics, and a battery of abuse-signal indicators — counts of copiers sharing the PI's identity attributes (name, DOB, phone, IP, city+zip), device fingerprints, and funding instruments. This is the primary investigation surface for AML analysts assessing whether a PI has artificially inflated their copier base through coordinated or sockpuppet accounts.

> **⚠️ CRITICAL DATA QUALITY WARNING**: This table contains **multiple rows per PI** due to a fan-out bug in the ETL. As of 2026-04-12: 61,199 rows for 5,131 distinct PIs (~11.9 rows/PI). **Never aggregate directly**. Always filter to a single PI and deduplicate before analysis. See Known Issues §7.

- **Row count**: 61,199 (2026-04-12; ~11.9 rows per PI due to fan-out)
- **Distinct PIs (CID)**: 5,131
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: HIGH — PI full PII: FirstName, LastName, Address, Email, Phone, BirthDate

---

## 2. Column Reference

### PI Identity

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | CID | int | T1 | `DWH_dbo.Fact_SnapshotCustomer.RealCID` | The Popular Investor's customer ID. Platform-internal primary key assigned at registration. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | UserName | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.UserName` | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 3 | RegisteredReal | datetime | T1 | `DWH_dbo.Dim_Customer.RegisteredReal` | Account registration date (renamed from Registered in production). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 4 | FirstDepositDate | datetime | T2 | `DWH_dbo.Dim_Customer.FirstDepositDate` | Date of first deposit. DEFAULT='19000101' for customers who have not yet deposited (sentinel value). Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 5 | PI_Age | int | T2 | Computed: `DATEDIFF(YEAR, dc.BirthDate, GETDATE())` | PI's age in years computed at SP run time (not at @Date parameter). Can be off by ±1 for birthdays not yet reached in the current year. Use BirthDate for precise age calculations. (Tier 2 — SP_AML_PI_Abuse) |
| 6 | Gender | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.Gender` | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |

### PI Program Status

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 7 | GuruStatusID | int | T1 | `DWH_dbo.Fact_SnapshotCustomer.GuruStatusID` | Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Population gate requires GuruStatusID≥2 (Cadet+). (Tier 1 — Dictionary.GuruStatus) |
| 8 | GuruStatusName | nvarchar(500) | T1 | `DWH_dbo.Dim_GuruStatus.GuruStatusName` | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — Dictionary.GuruStatus) |
| 9 | Regulation | nvarchar(500) | T1 | `DWH_dbo.Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID` | Regulatory jurisdiction governing this PI's account. Values observed: CySEC, FCA, ASIC, GAML, FSRA, FSA Seychelles, MAS. Driven by Dim_Regulation (15 jurisdictions). (Tier 1 — Dictionary.Regulation) |
| 10 | PlayerStatus | nvarchar(500) | T1 | `DWH_dbo.Dim_PlayerStatus.Name` via `Fact_SnapshotCustomer.PlayerStatusID` | PI's account restriction state — one of 16 permission states (Normal, Warning, Blocked, Under Investigation, etc.). Gates trading, deposit, and PI program participation. (Tier 1 — Dictionary.PlayerStatus) |
| 11 | Club | nvarchar(500) | T1 | `DWH_dbo.Dim_PlayerLevel.Name` via `Fact_SnapshotCustomer.PlayerLevelID` | PI's eToro Club loyalty tier. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Reflects realized equity tier. (Tier 1 — Dictionary.PlayerLevel) |

### PI Geography

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 12 | Country | nvarchar(500) | T1 | `DWH_dbo.Dim_Country.Name` via `Fact_SnapshotCustomer.CountryID` | PI's country of residence (full English name). Determines regulatory framework and AML risk level. Top PI countries: UK, Spain, Italy, UAE, Australia. (Tier 1 — Dictionary.Country) |
| 13 | Region | nvarchar(500) | T2 | `DWH_dbo.Dim_Country.MarketingRegionManualName` via `Fact_SnapshotCustomer.CountryID` | Marketing region grouping for the PI's country. Manually curated regional segmentation (distinct from the generic Region column in Dim_Country). Used for regional abuse pattern analysis. (Tier 2 — SP_AML_PI_Abuse via Dim_Country.MarketingRegionManualName) |
| 14 | City | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.City` | PI's city of residence in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 15 | Zip | nvarchar(500) | T1 | `DWH_dbo.Dim_Customer.Zip` | PI's postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |

### PI PII

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 16 | BirthDate | datetime | T1 | `DWH_dbo.Dim_Customer.BirthDate` | PI's date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 17 | Address | nvarchar(max) | T1 | `DWH_dbo.Dim_Customer.Address` | PI's street address in Unicode. PII — handle with care. (Tier 1 — Customer.CustomerStatic) |
| 18 | FirstName | varchar(250) | T1 | `DWH_dbo.Dim_Customer.FirstName` | PI's legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. PII — handle with care. (Tier 1 — Customer.CustomerStatic) |
| 19 | LastName | varchar(250) | T1 | `DWH_dbo.Dim_Customer.LastName` | PI's legal last name in Unicode. Used in LinkedAccountHash1. PII — handle with care. (Tier 1 — Customer.CustomerStatic) |
| 20 | Email | varchar(250) | T1 | `DWH_dbo.Dim_Customer.Email` | PI's email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. PII — handle with care. (Tier 1 — Customer.CustomerStatic) |
| 21 | Phone | varchar(250) | T1 | `DWH_dbo.Dim_Customer.Phone` | PI's phone number from production Customer.CustomerStatic. PII — handle with care. (Tier 1 — Customer.CustomerStatic) |

### PI Financial Snapshot

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 22 | TotalEquity | money | T2 | `DWH_dbo.V_Liabilities` at @DateID | PI's total net equity: `ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)`. Represents the PI's own account value independent of their copier base. ISNULL→0 when no liability record. (Tier 2 — SP_AML_PI_Abuse via V_Liabilities) |
| 23 | RealizedEquity | money | T2 | `DWH_dbo.V_Liabilities` at @DateID | PI's realized equity component. Passthrough from V_Liabilities, ISNULL→0. (Tier 2 — V_Liabilities) |
| 24 | PositionPnL | money | T2 | `DWH_dbo.V_Liabilities` at @DateID | PI's unrealized position profit/loss. Passthrough from V_Liabilities, ISNULL→0. (Tier 2 — V_Liabilities) |
| 25 | Liabilities | money | T2 | `DWH_dbo.V_Liabilities` at @DateID | PI's total liabilities (open position investment value). Passthrough from V_Liabilities, ISNULL→0. (Tier 2 — V_Liabilities) |
| 26 | Credit | money | T2 | `DWH_dbo.V_Liabilities` at @DateID | PI's credit balance. Passthrough from V_Liabilities, ISNULL→0. (Tier 2 — V_Liabilities) |
| 27 | NumOfPositions | int | T2 | `DWH_dbo.Dim_Position` at @DateID | Count of PI's open trading positions: `COUNT(DISTINCT PositionID)` WHERE CloseDateID=0 AND OpenDateID≤@DateID AND IsPartialCloseChild=0. (Tier 2 — SP_AML_PI_Abuse via Dim_Position) |
| 28 | NumOfInstruments | int | T2 | `DWH_dbo.Dim_Position` at @DateID | Count of distinct trading instruments in PI's open portfolio: `COUNT(DISTINCT InstrumentID)` same WHERE clause. (Tier 2 — SP_AML_PI_Abuse via Dim_Position) |

### Copier Base Metrics

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 29 | NumOfCopiers | int | T2 | `general.etoroGeneral_History_GuruCopiers` | Count of active copiers: `COUNT(DISTINCT CID)` among qualified copiers (IsValidCustomer=1, IsDepositor=1, VerificationLevelID>1) at @DateTime. (Tier 2 — SP_AML_PI_Abuse via etoroGeneral_History_GuruCopiers) |
| 30 | Num_of_Blocked_copiers | int | T2 | `DWH_dbo.Dim_Customer` (copier) via `Dim_Customer.PlayerStatusID` | Count of copiers with any non-Normal/non-Warning account status: `SUM(CASE WHEN PlayerStatusID NOT IN (1,5) THEN 1 ELSE 0 END)`. A high proportion of restricted copiers is an abuse signal. (Tier 2 — SP_AML_PI_Abuse) |
| 31 | AUC | money | T2 | `general.etoroGeneral_History_GuruCopiers` | Total Assets Under Copy for this PI: `SUM(ISNULL(Cash,0)+ISNULL(Investment,0)+ISNULL(PnL,0)+ISNULL(DetachedPosInvestment,0)+ISNULL(Dit_PnL,0))` across all qualified copiers. Represents total funds allocated to copying this PI. (Tier 2 — SP_AML_PI_Abuse via etoroGeneral_History_GuruCopiers) |
| 32 | AUC_TopCopier | money | T2 | Derived from `#copy` (ranked copiers) | AUC of the **single** largest copier (rank=1 by AUC DESC). Not cumulative — the individual top copier's stake. (Tier 2 — SP_AML_PI_Abuse) |
| 33 | AUC_Top2Copier | money | T2 | Derived from `#copy` | **Cumulative** AUC of the top 2 copiers combined (`SUM(AUC) WHERE rn < 3`). NOT the 2nd copier alone — includes #1 and #2. (Tier 2 — SP_AML_PI_Abuse) |
| 34 | AUC_Top3Copier | money | T2 | Derived from `#copy` | **Cumulative** AUC of the top 3 copiers combined (`SUM(AUC) WHERE rn < 4`). (Tier 2 — SP_AML_PI_Abuse) |
| 35 | AUC_Top4Copier | money | T2 | Derived from `#copy` | **Cumulative** AUC of the top 4 copiers combined (`SUM(AUC) WHERE rn < 5`). (Tier 2 — SP_AML_PI_Abuse) |
| 36 | AUC_Top5Copier | money | T2 | Derived from `#copy` | **Cumulative** AUC of the top 5 copiers combined (`SUM(AUC) WHERE rn < 6`). (Tier 2 — SP_AML_PI_Abuse) |
| 37 | %TopCopier | decimal(18,0) | T2 | Computed: `(AUC_TopCopier / NULLIF(AUC, 0)) * 100` | AUC concentration ratio — percentage of the PI's total AUC held by their single largest copier. High values (>50%) indicate AUC dependency on one account, a potential coordinated-account signal. NULL if AUC=0. (Tier 2 — SP_AML_PI_Abuse) |

### Identity Overlap: Copier vs PI

Counts of copiers who share specific identity attributes with the PI. All computed over the PI's active copier population via `#sameIndications` (LEFT JOIN Dim_Customer for copier, Dim_Customer for PI; WHERE PI is IsValidCustomer=1, IsDepositor=1, VerificationLevelID>1).

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 38 | Same_City_and_Zip_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers with identical City AND Zip as the PI: `SUM(CASE WHEN dc.City=dc2.City AND dc.Zip=dc2.Zip THEN 1 ELSE 0 END)`. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 39 | Same_DOB_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers with identical date of birth as the PI (date-part match). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 40 | Same_Phone_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers sharing the PI's phone number (LIKE match, effectively equality since no wildcards). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 41 | Same_IP_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers sharing the PI's registration IP address (LIKE match on dc.IP). Distinct from the SameIP satellite table which uses copier registration IPs at snapshot time. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 42 | Same_First_Name_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers sharing the PI's first name (case-insensitive UPPER() match). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 43 | Same_Last_Name_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers sharing the PI's last name (case-insensitive). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 44 | Same_Middle_Name_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers sharing the PI's middle name (case-insensitive). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 45 | Same_Name_AS_PI | int | T2 | `Dim_Customer` (copier + PI) | Count of copiers with any cross-name match with the PI: MiddleName=PI.FirstName, MiddleName=PI.LastName, FirstName=PI.LastName, OR LastName=PI.FirstName (all case-insensitive). Catches name transpositions and alias use. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |

### Identity Overlap: Among Copiers

Counts of collisions within the PI's copier population (not copier-vs-PI).

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 46 | Same_First_Name | int | T2 | `Dim_Customer` (copiers only) | Duplicate first name count among copiers: `COUNT(FirstName) - COUNT(DISTINCT FirstName)`. Zero = all unique first names. Higher values = more copiers sharing a first name. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 47 | Same_First_Name2 | int | T2 | Derived from `Same_First_Name` | Same_First_Name + 1, then zeroed if result = 1. Effectively: 0 when all first names are unique, otherwise Same_First_Name+1 (total involved in first-name collisions including first occurrence). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 48 | Same_Last_Name | int | T2 | `Dim_Customer` (copiers only) | Duplicate last name count among copiers: `COUNT(LastName) - COUNT(DISTINCT LastName)`. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 49 | Same_Last_Name2 | int | T2 | Derived from `Same_Last_Name` | Same_Last_Name + 1, zeroed if result = 1. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 50 | Same_City | int | T2 | `Dim_Customer` (copiers only) | Duplicate city count among copiers: `COUNT(City) - COUNT(DISTINCT City)`. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 51 | Same_City2 | int | T2 | Derived from `Same_City` | Same_City + 1, zeroed if result = 1. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 52 | Same_Zip | int | T2 | `Dim_Customer` (copiers only) | Duplicate postal code count among copiers: `COUNT(Zip) - COUNT(DISTINCT Zip)`. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 53 | Same_Zip2 | int | T2 | Derived from `Same_Zip` | Same_Zip + 1, zeroed if result = 1. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |

### Financial Instrument Overlap

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 54 | SameFID_AS_PI | int | T2 | `DWH_dbo.Fact_BillingDeposit` (PI + copier) | Count of PI funding instruments also found in copier deposit history: `COUNT(*) - COUNT(DISTINCT FundingID)` from #SameFID_AS_PI. **⚠️ Unreliable due to fan-out bug** — see Known Issues §7. Excludes generic payment types (FundingID IN 1–7). ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 55 | Same_FID_Copier | int | T2 | `DWH_dbo.Fact_BillingDeposit` (copiers only) | Count of funding instruments shared among copiers of this PI: `COUNT(*) - COUNT(DISTINCT FundingID)` per PI from #SameFID_Copier. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |

### Device Fingerprint Overlap

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 56 | SameDeviceID_Users_AS_PI | int | T2 | `DWH_dbo.STS_User_Operations_Data_History` | Count of PI-owned device fingerprints also found in copier device history: `COUNT(*) - COUNT(DISTINCT PI_DeviceID)` from #sameDeviceID_AS_PI. A PI and copier sharing a physical device is a strong abuse signal. Device history filtered ≥2024-01-01. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |
| 57 | SameDeviceID_Copiers | int | T2 | `DWH_dbo.STS_User_Operations_Data_History` | Count of shared device fingerprints among copiers: `COUNT(*) - COUNT(DISTINCT Copy_DeviceID)` from #sameDeviceID_Copiers. ISNULL→0. (Tier 2 — SP_AML_PI_Abuse) |

### Suspicious Timing Signals

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 58 | CIDs_Same_Start_Copy | nvarchar(max) | T2 | `general.etoroGeneral_History_GuruCopiers` | Comma-delimited list (CIDs ordered ASC) of copiers who started copying this PI on the same calendar date as at least one other copier (`HAVING COUNT(CID) > 1`). Coordinated same-day starts across multiple accounts is a strong abuse signal. ISNULL→'0' (sentinel). (Tier 2 — SP_AML_PI_Abuse) |
| 59 | Equity_Start_Copy | money | T2 | `DWH_dbo.V_Liabilities` at StartCopy date | PI's total equity (`Liabilities + ActualNWA`) on the date of the suspicious coordinated start-copy event. Provides context for whether the PI was financially established when the cluster began copying. (Tier 2 — SP_AML_PI_Abuse via V_Liabilities.FullDate=StartCopy) |

### Investigation History

LEFT JOINed from `BI_DB_dbo.BI_DB_First5Actions` on CID. NULL for PIs with no recorded investigation.

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 60 | FirstAction | varchar(250) | T2 | `BI_DB_dbo.BI_DB_First5Actions.FirstAction` | Label of the first AML investigation action taken on this PI. NULL if no investigation history. (Tier 2 — BI_DB_First5Actions) |
| 61 | FirstActionDate | datetime | T2 | `BI_DB_dbo.BI_DB_First5Actions.FirstActionDate` | Date of the first investigation action. NULL if no history. (Tier 2 — BI_DB_First5Actions) |
| 62 | SecondAction | varchar(250) | T2 | `BI_DB_dbo.BI_DB_First5Actions.SecondAction` | Label of the second investigation action. NULL if fewer than 2 actions recorded. (Tier 2 — BI_DB_First5Actions) |
| 63 | SecondActionDate | datetime | T2 | `BI_DB_dbo.BI_DB_First5Actions.SecondActionDate` | Date of the second investigation action. (Tier 2 — BI_DB_First5Actions) |
| 64 | ThirdAction | varchar(250) | T2 | `BI_DB_dbo.BI_DB_First5Actions.ThirdAction` | Label of the third investigation action. NULL if fewer than 3 actions recorded. (Tier 2 — BI_DB_First5Actions) |
| 65 | ThirdActionDate | datetime | T2 | `BI_DB_dbo.BI_DB_First5Actions.ThirdActionDate` | Date of the third investigation action. (Tier 2 — BI_DB_First5Actions) |

### ETL Metadata

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 66 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp. Set to `GETDATE()` at INSERT time. Not a business date — do not use for data filtering or temporal analysis. (Propagation) |

**Tier summary**: 18 T1 | 47 T2 | 1 Propagation

---

## 3. Business Context

This is the **primary investigation surface** in the SP_AML_PI_Abuse suite. AML analysts use it to identify Popular Investors who may be gaming the program through coordinated or artificial copier networks — accounts that share personal identity, device fingerprints, funding instruments, or registration IPs with the PI or with each other.

### Popular Investor Qualification Criteria

The SP gate filters `Fact_SnapshotCustomer` at @DateID:

| Criterion | Value | Meaning |
|-----------|-------|---------|
| GuruStatusID | ≥ 2 | Cadet and above (actively enrolled in PI program) |
| IsValidCustomer | 1 | Active non-demo account |
| VerificationLevelID | 3 | Fully KYC-verified |
| IsDepositor | 1 | Has made at least one deposit |

### Abuse Signal Categories

The table provides two distinct signal families:

**Category A — Copier-vs-PI overlap** (columns 38–45): Copiers who share the PI's own identity attributes. These are the highest-risk signals because the PI and copier are provably the same person or connected entity.
- `Same_*_AS_PI` columns: DOB, Phone, IP, City+Zip, FirstName, LastName, MiddleName, Name-transpositions

**Category B — Copier-vs-Copier clustering** (columns 46–53, 54–57): Patterns of duplicated attributes within the copier population, indicating the copiers themselves may be coordinated even without direct PI connection.
- Duplicate name/city/zip counts among copiers
- Shared device fingerprints between copiers (`SameDeviceID_Copiers`)
- Shared funding instruments between copiers (`Same_FID_Copier`)

### AUC Concentration Metric

`%TopCopier = (AUC_TopCopier / AUC) * 100`

A PI where >50% of AUC comes from a single copier is highly vulnerable to that copier's actions and warrants scrutiny. When the top copier is also flagged in identity/device overlap signals, this becomes a high-priority investigation case.

### AUC_TopN Semantics

**Critical naming trap**: `AUC_Top2Copier` is NOT the AUC of the second-ranked copier. It is the **cumulative SUM** of the top 2 copiers (`SUM(AUC) WHERE rn < 3`). Similarly, `AUC_Top3/4/5Copier` are cumulative sums. To get the 2nd copier's individual AUC: `AUC_Top2Copier - AUC_TopCopier`.

### Relationship to Satellite Tables

This table provides the **PI-level aggregate view**. For detailed investigation:

| Need | Use Table |
|------|-----------|
| Which specific copiers share an IP with the PI? | `BI_DB_AML_PI_Abuse_SameIP` (by IP, ≥2 copiers sharing it) |
| Which devices has this PI used? | `BI_DB_AML_PI_Abuse_DeviceID_PI_Side` |
| Which device fingerprints are shared among copiers? | `BI_DB_AML_PI_Abuse_DeviceID_Copiers` + `_Copy_Side` |
| Which PI funding instruments overlap with copiers? | `BI_DB_AML_PI_Abuse_FID_PI_Side` + `_Same_as_pi` |
| Full copier roster with PII | `BI_DB_AML_PI_Abuse_CopierTable` |

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 61,199 (2026-04-12; ~11.9 rows/PI due to fan-out) |
| Distinct PIs (CID) | 5,131 |
| Snapshot date (UpdateDate) | 2026-04-12 |

### GuruStatusName Distribution (by row count)

| GuruStatusName | Row Count |
|---------------|-----------|
| Elite | 24,045 |
| Elite Pro | 19,269 |
| Champion | 12,188 |
| Cadet | 5,697 |

### Regulation Distribution (by row count)

| Regulation | Row Count |
|-----------|-----------|
| CySEC | 35,675 |
| FCA | 20,840 |
| ASIC / GAML | 3,800 |
| FSRA | 875 |
| FSA Seychelles | 6 |
| MAS | 3 |

### Top PI Countries

| Country | Row Count |
|---------|-----------|
| United Kingdom | 10,644 |
| Spain | 8,155 |
| Italy | 4,866 |
| UAE | 4,470 |
| Australia | 3,632 |

### Abuse Signal Coverage (% of rows with signal > 0)

| Signal | % of Rows |
|--------|-----------|
| Same_IP_AS_PI | ~9.8% |
| SameDeviceID_Copiers | ~78.2% |
| Same_City_and_Zip_AS_PI | ~21.7% |
| Same_DOB_AS_PI | ~24.2% |
| SameFID_AS_PI | ~10.9% (unreliable — fan-out) |

---

## 5. Usage Notes

### Always Deduplicate Before Aggregation

Due to the fan-out bug (~11.9 rows/PI), never directly SUM or COUNT across the table. Always select one row per PI first:

```sql
-- Safe approach: pick the row with the maximum SameFID_AS_PI per PI
-- (avoids 0-row artifacts from fan-out; acknowledges the FID signal is unreliable)
WITH deduped AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY CID ORDER BY SameFID_AS_PI DESC, UpdateDate DESC) AS rn
    FROM BI_DB_dbo.BI_DB_AML_PI_Abuse
)
SELECT *
FROM deduped
WHERE rn = 1
```

### Interpreting Same_ Counts

`Same_City` (inter-copier) = 0 means all copiers have unique cities. The _2 variant adds 1 and zeros if result=1, making it easier to flag: any non-zero value in `Same_City2` means at least 2 copiers share a city.

### Blocked Copier Threshold

`Num_of_Blocked_copiers > 0` indicates at least one copier in any non-Normal/Warning state. Normal=1, Warning=5. All other PlayerStatusIDs (Blocked, Under Investigation, Chat Blocked, etc.) count as "blocked" in this metric.

### Device Overlap Signal Strength

`SameDeviceID_Users_AS_PI > 0` is one of the strongest individual abuse signals: the PI and at least one copier physically share a device (same ClientDeviceId UUID from STS audit logs). Device data covers activity from 2024-01-01 onward only.

### Joining to Satellite Tables

Join on `CID` (PI's CID in this table = `ParentCID` in satellite tables):

```sql
-- Get same-IP detail for PI CID 12345678
SELECT s.*
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse a
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP s ON a.CID = s.ParentCID
WHERE a.CID = 12345678
```

---

## 6. T1 Verification Log

| Column | Upstream Wiki | Section | Verbatim (truncated to key phrase) |
|--------|--------------|---------|-------------------------------------|
| CID | DWH_dbo/Tables/Dim_Customer.md | §3.1, RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)" |
| UserName | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 7 | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)" |
| RegisteredReal | DWH_dbo/Tables/Dim_Customer.md | §3.4, col 31 | "Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic)" |
| Gender | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 12 | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)" |
| GuruStatusID | DWH_dbo/Tables/Dim_GuruStatus.md | §4 Elements, col 1 | "Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. (Tier 1 — Dictionary.GuruStatus)" |
| GuruStatusName | DWH_dbo/Tables/Dim_GuruStatus.md | §4 Elements, col 2 | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. (Tier 1 — Dictionary.GuruStatus)" |
| Country | DWH_dbo/Tables/Dim_Country.md | §1 Business Meaning | Dim_Country.Name = country's English name; "Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes." (Tier 1 — Dictionary.Country) |
| Regulation | DWH_dbo/Tables/Dim_Regulation.md | §1 Business Meaning | Dim_Regulation.Name = jurisdiction label; "15 regulatory jurisdictions under which eToro operates globally." (Tier 1 — Dictionary.Regulation) |
| PlayerStatus | DWH_dbo/Tables/Dim_PlayerStatus.md | §1 Business Meaning | Dim_PlayerStatus.Name = restriction state label; "16 distinct account restriction states." (Tier 1 — Dictionary.PlayerStatus) |
| Club | DWH_dbo/Tables/Dim_PlayerLevel.md | §1 Business Meaning | Dim_PlayerLevel.Name = tier label; "7 eToro Club loyalty tiers (Bronze through Diamond plus Internal)." (Tier 1 — Dictionary.PlayerLevel) |
| City | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 18 | "City in Unicode. (Tier 1 — Customer.CustomerStatic)" |
| Zip | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 17 | "Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)" |
| BirthDate | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 13 | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic)" |
| Address | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 19 | "Street address in Unicode. (Tier 1 — Customer.CustomerStatic)" |
| FirstName | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 9 | "Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)" |
| LastName | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 10 | "Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)" |
| Email | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 14 | "Customer email address. Unique (case-insensitive via LowerEmail computed column). (Tier 1 — Customer.CustomerStatic)" |
| Phone | DWH_dbo/Tables/Dim_Customer.md | §3.2, col 15 | "Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic)" |

---

## 7. Known Issues

1. **CRITICAL — Fan-out bug causes ~11.9 rows per PI**: Root cause: `#SameFID_AS_PI` temp table is grouped by `(pf.ParentCID, cf.CID)` — one row per (PI, copier sharing a FID). But in `#final1`, it is LEFT JOINed on only `ParentCID`, creating a Cartesian product against the `#copy` table (one row per copier per PI). Since `SameFID_AS_PI` is also in the GROUP BY, the GROUP BY cannot collapse the duplicates. The `SELECT DISTINCT` in `#final2` cannot resolve this because `SameFID_AS_PI` differs across rows. **Impact**: All aggregate queries over this table are incorrect without deduplication. Max-affected PI: 5,131 distinct PIs, ~11.9 avg rows each.

2. **`SameFID_AS_PI` is unreliable**: Because of the fan-out bug, this column takes different values for the same PI depending on which (ParentCID, copierCID) row is selected. The column cannot be trusted for FID abuse signal analysis. Use the satellite `BI_DB_AML_PI_Abuse_FID_Same_as_pi` table instead (which has correct 1:1 PI grain from `#SameFID_AS_PI` grouped by ParentCID only).

3. **`AUC_Top2/3/4/5Copier` are cumulative, not individual**: The naming suggests these are the AUC of the 2nd, 3rd, 4th, 5th copiers respectively. They are NOT — they are cumulative sums of the top N copiers. `AUC_Top5Copier - AUC_TopCopier` = AUC of copiers ranked 2 through 5 combined.

4. **`PI_Age` uses GETDATE(), not @Date**: For historical or replay runs, `PI_Age` does not reflect the PI's age on the run date. Use `BirthDate` for precise age calculations.

5. **`Same_IP_AS_PI` uses registration IP, not session IP**: It compares the PI's registration IP (from Dim_Customer) to copier registration IPs. This is a weaker signal than the SameIP satellite table which uses session-level IP data from the active copy snapshot.

6. **Device history limited to 2024-01-01+**: `STS_User_Operations_Data_History` is filtered `WHERE DateID >= 20240101`. Device overlap signals (`SameDeviceID_Copiers`, `SameDeviceID_Users_AS_PI`) cover only device activity from Jan 2024 onward. PIs and copiers who shared devices exclusively before that date will not be flagged.

7. **`WITH(NOLOCK)` on Synapse tables**: SP uses `WITH(NOLOCK)` hints on Synapse SQL Pool tables. Synapse uses snapshot isolation by default — NOLOCK is not applicable and is a code smell. No correctness impact.

---

## 8. Metadata

| Field | Value |
|-------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_AML_PI_Abuse |
| ETL Pattern | TRUNCATE + INSERT (daily full refresh) |
| OpsDB Priority | 0 |
| UC Status | Not Migrated |
| Columns | 66 (18 T1, 47 T2, 1 Propagation) |
| Rows | 61,199 (2026-04-12; ~11.9 rows/PI — fan-out bug) |
| Distinct PIs | 5,131 |
| PII | HIGH (FirstName, LastName, Address, Email, Phone, BirthDate) |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 47 |
| Generated | 2026-04-22 |
