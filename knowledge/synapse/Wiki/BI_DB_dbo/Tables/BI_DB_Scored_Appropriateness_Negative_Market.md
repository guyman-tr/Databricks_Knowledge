# BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market

| Property | Value |
|----------|-------|
| **Object Type** | TABLE |
| **Schema** | BI_DB_dbo |
| **Row Count** | ~17,860,000 |
| **Synapse Distribution** | HASH ( [GCID] ) |
| **Synapse Index** | CLUSTERED INDEX ( [GCID] ASC ) |
| **Source System** | ComplianceStateDB (production) via external tables |
| **Writer SP** | `SP_BI_DB_Scored_Appropriateness_Negative_Market` |
| **ETL Pattern** | TRUNCATE-INSERT (daily full reload) |
| **Refresh** | Daily (SB_Daily, Priority 20) |

## 1. Business Meaning

`BI_DB_Scored_Appropriateness_Negative_Market` is a compliance analytics table that tracks whether eToro customers have passed or failed the **Appropriateness Test** for leveraged trading products (CFDs), and whether their CFD trading has been blocked or allowed as a result. The term "Negative Market" refers to users who fail the appropriateness assessment — they are classified as negative-market participants and restricted from CFD leverage trading per regulatory requirements.

Under CySEC, FCA, and ASIC/GAML regulations, users who fail the appropriateness test are blocked from CFD trading. The table records the block and release lifecycle: when a customer was blocked, why, when they were released, and the duration of the restriction. It covers all customers who have undergone the appropriateness test since February 2020, currently ~17.86 million rows.

**Key business use cases:**
- Compliance reporting: population of blocked vs. allowed customers per regulation
- Operational monitoring: block/release event tracking with reason codes
- FTD (First Time Deposit) cohort analysis by week/month for negative-market populations
- Regional and regulatory segmentation of appropriateness outcomes

**Important caveat:** Six KYC scoring columns (`IsKYC_NM_Trading_Experience`, `IsKYC_NM_Risk_Factor`, `IsKYC_NM`, `AT_Total_Score_KYC`, `AT_Total_Max_Potential_Score`, `IsKYC_AT_Passed`) are **vestigial** — the scoring logic in the SP was commented out and all values are hardcoded to `-1`. Scoring is now handled by the Compliance service (KYC Analyzer) in production, not replicated into this DWH table.

## 2. Business Logic

### 2.1 Population

The table is populated by `SP_BI_DB_Scored_Appropriateness_Negative_Market` via a 5-step ETL:

1. **#pop_AT** — Builds the appropriateness-test population by unioning:
   - `ComplianceStateDB.Compliance.CustomerRestrictions` (filtered to `RestrictionStatusReasonID = 14` — the appropriateness test reason)
   - `ComplianceStateDB.Compliance.UserTradingData`
   Both are joined to `Dictionary.RestrictionStatus` and `Dictionary.RestrictionStatusReason` to decode status/reason names.

2. **#pop_NM_Current** — Extracts the current CFD restriction status from `UserTradingData`, joining back to `#pop_AT` to tie each customer's current block/allow state.

3. **#pop_NM_History + #blockingdata** — Pulls historical CFD restriction events from `ComplianceStateDB.History.UserTradingData`, selects the latest history record per GCID (via `ROW_NUMBER()`), and merges current + historical to determine:
   - **BlockDate / BlockReasonID / BlockReasonDesc**: When and why CFD was blocked
   - **ReleaseDate / ReleaseReasonID / ReleaseReasonDesc**: When and why the block was lifted
   - Logic: `CFDRestrictionStatusID = 1` → currently blocked (block info from current, release from history); `= 2` → currently allowed (block info from history, release from current)

4. **#finaltable** — Final assembly joins `#pop_AT` with `Dim_Customer`, `Dim_Regulation` (×2: current + designated), `Dim_Country`, and `#blockingdata`. Computes FTD time bucketing (EOW_FTD, EOM_FTD, FTDDateID). KYC scoring columns are all set to `-1`.

5. **TRUNCATE + INSERT** — Full daily reload into the target table.

### 2.2 Hardcoded Filter

- `BeginTime >= '2020-02-20'` — Only customers whose restriction event occurred on or after this date are included.

### 2.3 CFD Status Derivation

```sql
CASE WHEN bd.CFDRestrictionStatusID = 1 THEN 'CFD_Blocked'
     WHEN bd.CFDRestrictionStatusID = 2 THEN 'CFD_Allowed'
     ELSE 'CFD_Allowed' END
```

### 2.4 Downstream Consumer SPs

Referenced by at least 9 other SPs — used as a source for aggregated compliance dashboards and negative-market monthly rollups (including `BI_DB_Negative_Market_Monthly_Aggregated` which is populated from this table on end-of-month runs).

## 3. Query Advisory

### 3.1 Distribution & Index Strategy

- **HASH ( GCID )** — Good for customer-level queries; all rows for a given customer are on the same node.
- **CLUSTERED INDEX ( GCID ASC )** — Supports equality and range lookups on GCID.
- For aggregations by regulation, region, or CFD status, expect data movement (shuffle) since those columns are not the distribution key.

### 3.2 Recommended Patterns

| Use Case | Pattern |
|----------|---------|
| Customer lookup | `WHERE GCID = @gcid` — collocated, no shuffle |
| CFD-blocked population | `WHERE CFD_Status = 'CFD_Blocked'` — ~20% of rows (3.6M) |
| Appropriateness failures | `WHERE ApproprietnessScore_Status = 'Failed'` — ~75% of rows (13.4M) |
| Block duration analysis | `WHERE DateDiffBlockRelease IS NOT NULL` — only released customers |
| FTD cohort by month | `GROUP BY EOM_FTD` — pre-computed end-of-month bucket |

### 3.3 Performance Notes

- **17.86M rows** — large table. Pre-filter on regulation or CFD_Status before aggregating.
- **TRUNCATE-INSERT** — single `UpdateDate` per day; no incremental history. For change tracking, compare daily snapshots externally.
- All KYC scoring columns (`IsKYC_NM_*`, `AT_*`) are `-1`. Exclude from queries — they carry no information.

### 3.4 Data Freshness

| Metric | Value |
|--------|-------|
| Last loaded | 2026-03-11 04:54:07 |
| Refresh frequency | Daily |
| Latency | Data reflects ComplianceStateDB state at ETL run time |

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer Real account ID. Maps to Dim_Customer.RealCID. (Tier 1 — etoro.Account.Customer.RealCID) |
| 2 | GCID | int | NO | Global Customer ID. Distribution key and clustered index column. Maps to Dim_Customer.GCID. (Tier 1 — Account.Customer) |
| 3 | IsDepositor | bit | YES | Whether the customer has ever deposited (1=yes, 0=no). From Dim_Customer.IsDepositor. (Tier 1 — CustomerStatic.IsDepositor) |
| 4 | FTD_Date | datetime | YES | First Time Deposit date. Renamed from Dim_Customer.FirstDepositDate. (Tier 1 — Fact_BillingDeposit.MIN(DateTimeUTC)) |
| 5 | FTDDateID | int | YES | Integer date key for FTD_Date. `CAST(CONVERT(CHAR(8), FirstDepositDate, 112) AS INT)` → YYYYMMDD format. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 6 | EOW_FTD | datetime | YES | End-of-week date containing the FTD. `DATEADD(dd, -(DATEPART(dw, FirstDepositDate) - 7), FirstDepositDate)`. Used for weekly FTD cohort grouping. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 7 | EOM_FTD | datetime | YES | End-of-month date containing the FTD. `EOMONTH(FirstDepositDate)`. Used for monthly FTD cohort grouping. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 8 | FTD_Amount | money | YES | First deposit amount in USD. Renamed from Dim_Customer.FirstDepositAmount. (Tier 2 — Fact_BillingDeposit.Amount) |
| 9 | RegulationID | tinyint | YES | Current regulation ID. From Dim_Customer.RegulationID. JOINs to Dim_Regulation.DWHRegulationID. (Tier 1 — Dictionary.Regulation) |
| 10 | RegulationName | varchar(200) | YES | Current regulation name. Decoded from Dim_Regulation.Name via RegulationID. Example values: CySEC, FCA, ASIC, BVI. (Tier 1 — Dictionary.Regulation, join-enriched via Dim_Customer.RegulationID) |
| 11 | RegionID | int | YES | Marketing region ID. Renamed from Dim_Country.MarketingRegionID via Dim_Customer.CountryID. (Tier 1 — Dictionary.MarketingRegion, join-enriched) |
| 12 | RegionName | varchar(200) | YES | Marketing region name (manual override). Renamed from Dim_Country.MarketingRegionManualName. May differ from standard Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). (Tier 1 — Ext_Dim_Country manual override, join-enriched) |
| 13 | CountryID | int | YES | Country of residence ID. From Dim_Customer.CountryID. JOINs to Dim_Country.CountryID. (Tier 1 — Dictionary.Country) |
| 14 | CountryName | varchar(200) | YES | Country name. Decoded from Dim_Country.Name via CountryID. (Tier 1 — Dictionary.Country, join-enriched) |
| 15 | IsKYC_NM_Trading_Experience | int | YES | **VESTIGIAL** — always `-1`. Originally intended for KYC negative-market trading experience score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 16 | IsKYC_NM_Risk_Factor | int | YES | **VESTIGIAL** — always `-1`. Originally intended for KYC negative-market risk factor score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 17 | IsKYC_NM | int | YES | **VESTIGIAL** — always `-1`. Originally intended for combined KYC negative-market pass/fail flag. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 18 | AT_Total_Score_KYC | int | YES | **VESTIGIAL** — always `-1`. Originally intended for Appropriateness Test total KYC score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 19 | AT_Total_Max_Potential_Score | int | YES | **VESTIGIAL** — always `-1`. Originally intended for maximum possible AT score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 20 | IsKYC_AT_Passed | int | YES | **VESTIGIAL** — always `-1`. Originally intended for whether customer passed KYC-based AT. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 21 | RestrictionStatusDesc | varchar(200) | YES | Current CFD restriction status description. From ComplianceStateDB Dictionary.RestrictionStatus.Name. NULL defaults to "Passed" via `ISNULL`. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 22 | CFD_Status | varchar(20) | YES | Derived CFD trading status. `CASE WHEN CFDRestrictionStatusID=1 THEN 'CFD_Blocked' ELSE 'CFD_Allowed'`. 2-value enum: "CFD_Blocked" (20%, 3.6M), "CFD_Allowed" (80%, 14.3M). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 23 | BlockDate | datetime | YES | Date when CFD trading was blocked. From ComplianceStateDB UserTradingData. NULL if never blocked. Source depends on current status: if currently blocked → current.ReasonDate; if released → history.ReasonDate. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 24 | BlockReasonID | int | YES | Block reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 25 | BlockReasonDesc | varchar(500) | YES | Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 26 | ReleaseDate | datetime | YES | Date when CFD block was released. Only populated when `CFDRestrictionStatusID = 2` (currently allowed after prior block). NULL if still blocked or never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 27 | ReleaseReasonID | int | YES | Release reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if not released. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 28 | ReleaseReasonDesc | varchar(500) | YES | Release reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not released. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 29 | DateDiffBlockRelease | int | YES | Days between block and release. `DATEDIFF(d, BlockDate, ReleaseDate)`. NULL if not yet released or never blocked. Useful for measuring restriction duration. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 30 | AT_Date | datetime | YES | Date the Appropriateness Test was taken. From ComplianceStateDB.Compliance.CustomerRestrictions.BeginTime. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 31 | ApproprietnessScore_Status | varchar(200) | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: "Failed" 75% (13.4M), "Passed" 24% (4.2M), blank 1%, "Borderline Pass" <0.1%. Note: column name contains typo ("Approprietness" vs "Appropriateness"). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 32 | UpdateDate | datetime | YES | ETL execution timestamp. `GETDATE()` — identical across all rows for a given daily load. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 33 | DesignatedRegulationName | varchar(200) | YES | Designated (target) regulation name. Decoded from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. May differ from current RegulationName when a customer is being migrated between regulations. (Tier 1 — Dictionary.Regulation, join-enriched via Dim_Customer.DesignatedRegulationID) |
| 34 | BlockSubReasonID | int | YES | Block sub-reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusSubreason. Provides granular classification of why CFD was blocked. NULL if not blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 35 | BlockSubReasonDesc | varchar(500) | YES | Block sub-reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusSubreason.Name. NULL if not blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |

## 5. Lineage

| Source | Relationship | Objects |
|--------|-------------|---------|
| **ComplianceStateDB** (production) | Primary — appropriateness test and CFD restriction data | `Compliance.CustomerRestrictions`, `Compliance.UserTradingData`, `History.UserTradingData`, `Dictionary.RestrictionStatus`, `Dictionary.RestrictionStatusReason`, `Dictionary.RestrictionStatusSubreason` |
| **DWH_dbo.Dim_Customer** | Customer demographics and FTD data | `RealCID`, `GCID`, `IsDepositor`, `FirstDepositDate`, `FirstDepositAmount`, `RegulationID`, `CountryID`, `DesignatedRegulationID` |
| **DWH_dbo.Dim_Regulation** (×2) | Current regulation + designated regulation decode | `Name` via `RegulationID` and `DesignatedRegulationID` |
| **DWH_dbo.Dim_Country** | Country and marketing region decode | `Name`, `MarketingRegionID`, `MarketingRegionManualName` via `CountryID` |

Full column-level lineage: [BI_DB_Scored_Appropriateness_Negative_Market.lineage.md](BI_DB_Scored_Appropriateness_Negative_Market.lineage.md)

## 6. Relationships

| Related Object | Join Condition | Purpose |
|---------------|----------------|---------|
| DWH_dbo.Dim_Customer | `ON GCID = dc.GCID` | Source: customer demographics |
| DWH_dbo.Dim_Regulation | `ON RegulationID = dr.DWHRegulationID` | Source: regulation name decode |
| DWH_dbo.Dim_Country | `ON CountryID = dc1.CountryID` | Source: country/region decode |
| BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated | _Downstream_ — populated from this table on EOM runs | Monthly rollup of negative-market populations |

## 7. Sample Queries

```sql
-- Count of CFD-blocked vs allowed by regulation
SELECT  RegulationName,
        CFD_Status,
        COUNT(*) AS CustomerCount
FROM    BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
WHERE   ApproprietnessScore_Status = 'Failed'
GROUP BY RegulationName, CFD_Status
ORDER BY RegulationName, CFD_Status;

-- Average block duration for released customers
SELECT  RegulationName,
        AVG(CAST(DateDiffBlockRelease AS FLOAT)) AS AvgDaysBlocked,
        COUNT(*) AS ReleasedCount
FROM    BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
WHERE   DateDiffBlockRelease IS NOT NULL
GROUP BY RegulationName
ORDER BY AvgDaysBlocked DESC;
```

## 8. Atlassian Knowledge Sources

| Source | Key Insight |
|--------|-------------|
| [Experience and Objectives questionnaire](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11543019541) | Negative Market applies to new users in all regulations; CySEC/FCA users who fail are blocked from CFD since July 2023 |
| [Block from CFD](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/12061770175) | CFD Block can result from Negative Market OR failing the Suitability Test; ASIC/GAML can also be blocked |
| [Trading Experience according to Regulation](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12236620146) | FCA clients who fail can't trade CFDs for 60 days and 20 trades (as of June 2024) |
| [Compliance Glossary](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/689799236) | CFD Block = block from leverage trading; Scored Appropriateness = calculated in KYC Analyzer; Negative Market = restricted users |
| [HLD: Appropriateness scoring mechanism](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/897777665) | Scoring mechanism for calculating AT status implemented in Compliance service |
| [HLD - ASIC Appropriateness](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2100199454) | ASIC uses the CySEC/FCA appropriateness test but WITHOUT negative market component |

---

| Metric | Value |
|--------|-------|
| **Quality Score** | 8.5 / 10 |
| **Tier 1 Elements** | 13 / 35 (37%) |
| **Tier 2 Elements** | 22 / 35 (63%) |
| **Tier 4 Elements** | 0 |
| **Confidence** | HIGH — SP code fully analyzed, 6 vestigial columns documented |
