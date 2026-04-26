# BI_DB_dbo.BI_DB_Affiliates_VerificationSLA

> 571-row affiliate KYC verification SLA tracking table monitoring the time taken for affiliate accounts (Private and Corporate) to progress from KYC Level 2 (identity verified) to Level 3 (fully verified) within a rolling 4-month window. Data spans December 2025 to April 2026 (last run: 2026-04-13). Populated daily by SP_Affiliates_VerificationSLA via TRUNCATE+INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + [general].[etoro_History_BackOfficeCustomer] + DWH_dbo dimensions (Dim_Country, Dim_Regulation, Dim_AccountType, Dim_PlayerStatus) via SP_Affiliates_VerificationSLA |
| **Refresh** | Daily (SB_Daily, Priority 20, TRUNCATE+INSERT, 4-month rolling window) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Affiliates_VerificationSLA` is a daily-refreshed compliance monitoring table that tracks whether eToro affiliate accounts (Affiliate Private Account and Affiliate Corporate Account) complete the KYC Level 2 → Level 3 verification process within the defined SLA window. Each row represents one affiliate customer whose Level 2 verification date (identity document submission accepted) falls within the last 4 months.

The table covers 571 affiliate accounts across 7 regulatory frameworks (CySEC 447, ASIC 98, FinCEN 13, FCA 6, FSA Seychelles 3, ASIC & GAML 2, FSRA 2). AccountType breakdown: 445 Affiliate Private Accounts, 126 Affiliate Corporate Accounts. SLA compliance: 457 accounts (80%) met SLA, 114 (20%) missed or are still pending Level 3.

The SLA window differs by account type:
- **Affiliate Private Account**: ≤ 48 business hours from Level 2 to Level 3 (weekday-aware: Friday verification gets 3-day offset to Monday 5am before counting starts; Saturday gets 2-day offset; Sunday gets 1-day offset).
- **Affiliate Corporate Account**: ≤ 5 business days (calendar-based, excluding weekends).

SP author: Pavlina Masoura, created 2021-10-19. Updated 2023-11-03 to use [general].[etoro_History_BackOfficeCustomer] instead of the old BackOffice history source. SLA thresholds last updated 2022-08-04 to accommodate weekends.

---

## 2. Business Logic

### 2.1 SLA Computation — Business-Hours-Aware (Private Accounts)

**What**: For Affiliate Private Accounts, the 48-hour SLA is adjusted to exclude weekends, with different offset rules based on which day of the week Level 2 verification occurred.

**Columns Involved**: `SLA`, `VerificationLevel2Date`, `VerificationLevel3Date`, `AccountType`

**Rules**:
- **Same-day Level 2+3**: WHEN VerificationLevel2Date::date = VerificationLevel3Date::date → SLA=1 (instant verification)
- **Friday**: Reference window starts Monday at 05:00 (3-day offset); SLA met if VerificationLevel3Date ≤ that Monday + 48h
- **Saturday**: Reference window starts Monday at 05:00 (2-day offset); same threshold
- **Sunday**: Reference window starts Monday at 05:00 (1-day offset); same threshold
- **Mon–Thu**: Straight DATEDIFF(HOUR, Level2Date, Level3Date) ≤ 48 → SLA=1
- **VerificationLevel3Date IS NULL**: Falls into ELSE 0 → SLA=0 (pending, not necessarily missed)

### 2.2 SLA Computation — Business Days (Corporate Accounts)

**What**: For Affiliate Corporate Accounts, SLA is calculated in business days, excluding weekend days from the count.

**Columns Involved**: `SLA`, `VerificationLevel2Date`, `VerificationLevel3Date`, `AccountType`

**Rules**:
- Business days = (calendar days + 1) − (weeks × 2) − Saturday offset − Sunday offset
- SLA met if business days between Level2Date and Level3Date ≤ 5
- Same ELSE 0 applies when Level3Date IS NULL

### 2.3 SLA=0 Ambiguity — Missed vs. Pending

**What**: SLA=0 encodes two different states that cannot be distinguished from the column value alone.

**Columns Involved**: `SLA`, `VerificationLevel3Date`

**Rules**:
- `SLA=0 AND VerificationLevel3Date IS NOT NULL`: Customer went beyond the SLA window — genuinely missed SLA
- `SLA=0 AND VerificationLevel3Date IS NULL`: Customer has not yet reached Level 3 (still pending) — SLA outcome unknown
- In the current batch: 83 customers are at Level 2 (pending Level 3); 488 are at Level 3 (outcome determined). 114 total SLA=0 includes both categories.

### 2.4 Scope — Rolling 4-Month Window

**What**: The SP only includes customers whose VerificationLevel2Date falls within the rolling 4-month window (from the 1st of the month 4 months ago to yesterday).

**Columns Involved**: `VerificationLevel2Date`

**Rules**:
- @StartDate = first day of month 4 months before run date (e.g., 2025-12-01 for a 2026-04-21 run)
- @EndDate = GETDATE() − 1
- Customers verified before the window (Level 2 date > 4 months ago) are excluded, even if they missed SLA
- Only IsValidCustomer=1 from Dim_Customer are included

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN, HEAP. No distribution key — data is spread evenly across nodes without regard for column values. Appropriate for small tables (571 rows). HEAP means no sorted order; all scans are full-table. For analytical queries, full scans are instantaneous at this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| SLA pass rate by AccountType | `GROUP BY AccountType, SLA` — use `WHERE VerificationLevel3Date IS NOT NULL` to exclude pending accounts |
| Average verification time | `AVG(HourDifference)` or `AVG(DayDifference)` — filter to `VerificationLevel3Date IS NOT NULL` |
| SLA breach by region | `GROUP BY Region, SLA` |
| Pending Level 3 affiliates | `WHERE VerificationLevel3Date IS NULL` |
| Distribution by regulation | `GROUP BY Regulation, SLA` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = Dim_Customer.RealCID | Enrich with full customer profile |
| DWH_dbo.Dim_PlayerStatus | ON PlayerStatus = Dim_PlayerStatus.Name | Decode permission flags from status name |

### 3.4 Gotchas

- **SLA=0 is ambiguous**: Cannot distinguish "missed SLA" from "still awaiting Level 3" without also checking `VerificationLevel3Date IS NULL`. Always use both columns together.
- **ROUND_ROBIN distribution**: No JOIN co-location benefit regardless of join key. Acceptable for 571-row table.
- **4-month rolling window**: Old affiliate verifications fall off the table on the next daily refresh. Historical SLA data is not persisted — this is a snapshot of the last 4 months only.
- **VerificationLevel3Date NULL**: 83 customers currently at Level 2. Their SLA outcome is undetermined — they may still complete within SLA.
- **Weekend SLA adjustment for Private accounts**: The 48-hour SLA is NOT a straight calendar calculation for Friday/Saturday/Sunday Level 2 dates. The reference window shifts to Monday 05:00. Replicating the SP CASE logic exactly is required for accurate compliance reporting.
- **No historical tracking**: TRUNCATE+INSERT on every refresh means yesterday's state is lost. For point-in-time SLA analysis, use a snapshot table or archive.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Meaning |
|------|--------|---------|
| Tier 1 | Upstream wiki verbatim | Description copied from DB_Schema or DWH_dbo wiki, stripped of snapshot stats |
| Tier 2 | SP code / DDL | Derived from SP_Affiliates_VerificationSLA logic or DWH dimension JOIN |
| Tier 3 | Live data sampling | Inferred from Phase 2/3 query results |
| Tier 4 | Inferred [UNVERIFIED] | Best-effort from column name and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered here to affiliate accounts (AccountTypeID 6 or 15) with VerificationLevel2Date in the last 4 months. (Tier 1 — Customer.CustomerStatic) |
| 2 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 3 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. DWH note: In this table, only levels 2 and 3 appear — the SP filters on VerificationLevel2Date so only accounts that reached Level 2 within the 4-month window are included. (Tier 1 — BackOffice.Customer) |
| 4 | VerificationLevel2Date | datetime | YES | Date and time when the affiliate customer first reached KYC Level 2 (identity documents accepted). Computed as MIN(ValidFrom WHERE VerificationLevelID=2) from [general].[etoro_History_BackOfficeCustomer]. Anchors the SLA calculation — used as the start of the SLA clock. (Tier 2 — SP_Affiliates_VerificationSLA) |
| 5 | VerificationLevel3Date | datetime | YES | Date and time when the affiliate customer first reached KYC Level 3 (fully verified). Computed as MIN(ValidFrom WHERE VerificationLevelID=3) from [general].[etoro_History_BackOfficeCustomer]. NULL if the customer has not yet reached Level 3. Used as the end of the SLA clock. (Tier 2 — SP_Affiliates_VerificationSLA) |
| 6 | PlayerStatus | varchar(50) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus.Name. (Tier 1 — Dictionary.PlayerStatus) |
| 7 | Region | varchar(50) | YES | Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via Dim_Country JOIN on CountryID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via JOIN on CountryID. (Tier 1 — Dictionary.Country) |
| 9 | Regulation | varchar(50) | YES | Regulatory entity name governing the customer (e.g., CySEC, ASIC, FCA, FinCEN). Resolved from Dim_Customer.DesignatedRegulationID → Dim_Regulation.Name. Distribution: CySEC 447, ASIC 98, FinCEN 13, FCA 6, FSA Seychelles 3, ASIC & GAML 2, FSRA 2. (Tier 2 — SP_Affiliates_VerificationSLA via Dim_Regulation JOIN) |
| 10 | AccountType | varchar(50) | YES | Affiliate account type name. Values: "Affiliate Private Account" (445 rows, 78%) or "Affiliate Corporate Account" (126 rows, 22%). Resolved from Dim_Customer.AccountTypeID → Dim_AccountType.Name. Determines the SLA threshold (48h for Private, 5 business days for Corporate). (Tier 2 — SP_Affiliates_VerificationSLA via Dim_AccountType JOIN) |
| 11 | SLA | int | YES | SLA compliance flag. 1=met the SLA time window (fully verified within the allowed period); 0=either missed SLA OR VerificationLevel3Date is NULL (pending Level 3, outcome unknown). Business-hour-aware for Private accounts (weekday offsets for Fri/Sat/Sun Level 2 dates); calendar-based for Corporate (≤5 business days). 457 met (80%), 114 missed/pending (20%). (Tier 2 — SP_Affiliates_VerificationSLA) |
| 12 | HourDifference | int | YES | Number of hours between VerificationLevel2Date and VerificationLevel3Date. NULL when VerificationLevel3Date IS NULL (customer has not yet completed Level 3 verification). Used to assess Private Account SLA compliance (threshold: 48 business hours). (Tier 2 — SP_Affiliates_VerificationSLA) |
| 13 | DayDifference | int | YES | Number of calendar days between VerificationLevel2Date and VerificationLevel3Date. NULL when VerificationLevel3Date IS NULL. Used to assess Corporate Account SLA compliance (threshold: 5 business days). (Tier 2 — SP_Affiliates_VerificationSLA) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 2 — SP_Affiliates_VerificationSLA) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough (current level) |
| VerificationLevel2Date | [general].[etoro_History_BackOfficeCustomer] | ValidFrom | MIN(ValidFrom) WHERE VerificationLevelID=2 |
| VerificationLevel3Date | [general].[etoro_History_BackOfficeCustomer] | ValidFrom | MIN(ValidFrom) WHERE VerificationLevelID=3; NULL if not reached |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN: Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name |
| Region | DWH_dbo.Dim_Country | Region | JOIN: Dim_Customer.CountryID → Dim_Country.Region |
| Country | DWH_dbo.Dim_Country | Name | JOIN: Dim_Customer.CountryID → Dim_Country.Name |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN: Dim_Customer.DesignatedRegulationID → Dim_Regulation.Name |
| AccountType | DWH_dbo.Dim_AccountType | Name | JOIN: Dim_Customer.AccountTypeID → Dim_AccountType.Name |
| SLA | Computed | N/A | CASE: Private ≤48h business-hour-aware; Corporate ≤5 business days; ELSE 0 |
| HourDifference | Computed | N/A | DATEDIFF(HOUR, VerificationLevel2Date, VerificationLevel3Date) |
| DayDifference | Computed | N/A | DATEDIFF(day, VerificationLevel2Date, VerificationLevel3Date) |
| UpdateDate | ETL | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
eToro Production (etoroDB-REAL)
  BackOffice.Customer (AccountTypeID 6/15 — Affiliate Private/Corporate)
  BackOffice.VerificationHistory (ValidFrom per VerificationLevelID)
    |
    v
BI_DB_dbo.External_etoro_BackOffice_Customer  (External Table gateway)
[general].[etoro_History_BackOfficeCustomer]  (shared history view)
DWH_dbo.Dim_Customer                          (customer attributes)
DWH_dbo.Dim_Country                           (Region, Country Name)
DWH_dbo.Dim_Regulation                        (Regulation Name)
DWH_dbo.Dim_AccountType                       (AccountType Name)
DWH_dbo.Dim_PlayerStatus                      (PlayerStatus Name)
    |-- SP_Affiliates_VerificationSLA ---------|
    |   Author: Pavlina Masoura, 2021-10-19    |
    |   Schedule: Daily, SB_Daily, Priority 20 |
    |   Window: 4-month rolling (Level2Date)   |
    |   Load: TRUNCATE + INSERT                |
    v
BI_DB_dbo.BI_DB_Affiliates_VerificationSLA
  571 rows | 445 Private + 126 Corporate
  457 SLA met (80%) | 114 missed/pending (20%)
    |-- Not yet migrated to UC ---|
    v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer master — JOIN source for all customer attributes |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status name resolved from Dim_Customer.PlayerStatusID |
| Region, Country | DWH_dbo.Dim_Country | Region and country name resolved from Dim_Customer.CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name resolved from Dim_Customer.DesignatedRegulationID |
| AccountType | DWH_dbo.Dim_AccountType | Account type name resolved from Dim_Customer.AccountTypeID (6=Private, 15=Corporate affiliate) |

### 6.2 Referenced By (other objects point to this)

No BI_DB_dbo views or other documented tables reference this table. It is a standalone compliance monitoring snapshot consumed directly by Compliance/KYC analysts.

---

## 7. Sample Queries

### 7.1 SLA Pass Rate by Account Type (Excluding Pending)

```sql
SELECT
    AccountType,
    COUNT(*) AS total_verified,
    SUM(SLA) AS met_sla,
    COUNT(*) - SUM(SLA) AS missed_sla,
    CAST(SUM(SLA) * 100.0 / COUNT(*) AS decimal(5,1)) AS pct_met
FROM [BI_DB_dbo].[BI_DB_Affiliates_VerificationSLA]
WHERE VerificationLevel3Date IS NOT NULL    -- exclude still-pending accounts
GROUP BY AccountType
ORDER BY AccountType;
```

### 7.2 Pending Level 3 — Affiliate Customers Awaiting Full Verification

```sql
SELECT
    RealCID,
    AccountType,
    Country,
    Regulation,
    VerificationLevel2Date,
    DATEDIFF(HOUR, VerificationLevel2Date, GETDATE()) AS hours_since_level2
FROM [BI_DB_dbo].[BI_DB_Affiliates_VerificationSLA]
WHERE VerificationLevel3Date IS NULL
ORDER BY VerificationLevel2Date;
```

### 7.3 Average Verification Time by Region and Regulation

```sql
SELECT
    Region,
    Regulation,
    AccountType,
    COUNT(*) AS total,
    AVG(HourDifference) AS avg_hours_to_level3,
    AVG(DayDifference) AS avg_days_to_level3,
    SUM(SLA) AS sla_met
FROM [BI_DB_dbo].[BI_DB_Affiliates_VerificationSLA]
WHERE VerificationLevel3Date IS NOT NULL
GROUP BY Region, Regulation, AccountType
ORDER BY avg_hours_to_level3 DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available in this session. General DATA Confluence space may contain SLA policy documentation for Affiliate KYC processes. SP header comment: "SLA Verification analysis for Affiliates" by Pavlina Masoura (2021-10-19).

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 13/14 (P10 Jira skipped — no MCP)*
*Tiers: 5 T1, 8 T2, 0 T3, 0 T4 | Elements: 14/14, Logic: 8/10, ETL: 9/10, Upstream: 9/10*
*Object: BI_DB_dbo.BI_DB_Affiliates_VerificationSLA | Type: Table | Production Source: DWH_dbo.Dim_Customer + [general].[etoro_History_BackOfficeCustomer]*
