# BI_DB_dbo.BI_DB_OPS_KYC_Verification

> 1.76M-row KYC verification SLA tracking table covering customers who reached VerificationLevel >= 2 within the last year. Measures time-to-verify (days, hours, minutes), first-touch SLA (document upload to first review), verification method (EV=50%, Docs=18%, NA=31%), and KYC flow type from ComplianceStateDB. Sourced from DWH_dbo.Dim_Customer + History.BackOfficeCustomer + BackOffice documents + ComplianceStateDB KYC flow. Daily TRUNCATE+INSERT via SP_OPS_KYC_Verification. Only IsValidCustomer=1, RiskGroupID NOT IN (1,2).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Key Identifier** | RealCID (not enforced — no PK in DDL) |
| **Production Source** | SP_OPS_KYC_Verification (Pavlina Masoura, 2025-02-07) |
| **Refresh** | Daily (1440 min), TRUNCATE+INSERT, 1-year rolling window (VL2 date >= Jan 1 of prior year) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~1.76M |
| **Date Range** | Registrations from 2007 to present (VL2 date >= 1 year ago) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification` |
| **UC Format** | delta |
| **UC Copy Strategy** | Override |

---

## 1. Business Meaning

`BI_DB_OPS_KYC_Verification` is a daily KYC verification SLA monitoring table that tracks how long it takes customers to become verified (VerificationLevel=3) and how quickly operations reviews their documents. It covers all valid customers (IsValidCustomer=1) from non-high-risk countries (RiskGroupID NOT IN 1,2) who reached VL2+ in the last year.

Each row represents one customer and captures:
- **Verification timeline**: Registration date, VL1/VL2/VL3 dates from History.BackOfficeCustomer, EV match status date
- **Time-to-verify metrics**: DaysToVerify, HoursToVerify, MinutesToVerify — from an "effective start date" to VerificationLevel3Date
- **First-touch SLA**: FirstTouch (days), FirstTouchHour, FirstTouchMinute — from document upload or effective date to first review (Occurred timestamp)
- **Verification method**: EV (electronic verification via Onfido/Au10tix), Docs (manual document review), or NA (VL2 only, not yet VL3)
- **KYC flow type**: From ComplianceStateDB — current flow, with fallback to latest historical flow when current=0

The "effective start date" (EffectiveAddDate) is determined by a priority waterfall:
1. EVMatchStatusDate — if customer was EV-verified (EvMatchStatus=2)
2. DateAdded (latest document upload) — if customer has no deposit
3. DateAdded — if deposit came before document, but verification came after both
4. FirstDepositDate — otherwise

Distribution: BVI=60%, CySEC=21%, FCA=6%, eToroUS=5%. Verification methods: EV=50%, NA=31%, Docs=18%. Most customers verify in 0 days (same-day EV verification).

---

## 2. Business Logic

### 2.1 Effective Date Calculation (SLA Start Point)

**What**: Determines the starting point for time-to-verify and first-touch SLA calculations.
**Columns Involved**: EffectiveAddDate, FirstDepositDate, DateAdded, EVMatchStatusDate, VerificationDate
**Rules** (priority waterfall):
1. If EVMatchStatusDate exists AND EvMatchStatus=2 → use EVMatchStatusDate (EV-verified customers)
2. If FirstDepositDate is sentinel (year=1900) → use DateAdded (no deposit, document upload is the trigger)
3. If VerificationDate > FirstDepositDate AND FirstDepositDate < DateAdded → use DateAdded (deposited first, then docs, then verified)
4. If DateAdded < VerificationDate AND VerificationDate < FirstDepositDate → use DateAdded (docs first, then verified, then deposited)
5. Otherwise → use FirstDepositDate

### 2.2 Verification Method Classification

**What**: Categorizes how a customer was verified to VL3.
**Columns Involved**: VerificationMethod, VerificationLevelID, EvMatchStatus, DateAdded
**Rules**:
- 'EV': VerificationLevelID=3 AND EvMatchStatus=2 (electronic verification succeeded)
- 'Docs': VerificationLevelID=3 AND (DateAdded IS NOT NULL OR EvMatchStatus<>2) (manual document review)
- 'NA': VerificationLevelID < 3 (not yet fully verified)

### 2.3 Time-to-Verify Metrics

**What**: Measures how long from effective start to full verification.
**Columns Involved**: DaysToVerify, HoursToVerify, MinutesToVerify
**Rules**:
- DATEDIFF(day/hour/minute, EffectiveDate, VerificationDate)
- Set to 0 when EVMatchStatusDate > VerificationDate (EV happened after VL3 — not the verification path)
- Floor at 0 — negative values are corrected via UPDATE after initial calculation

### 2.4 First-Touch SLA

**What**: Measures time from customer action (document upload/deposit) to first operations review.
**Columns Involved**: FirstTouch, FirstTouchHour, FirstTouchMinute, FirstReviewed, EffectiveAddDate
**Rules**:
- When EVMatchStatusDate exists AND VL2Date > EVMatchStatusDate → 0 (EV pre-dated VL2)
- When EVMatchStatusDate exists → DATEDIFF from VL2Date to EVMatchStatusDate
- When FirstReviewed > FirstDepositDate AND EffectiveAddDate < DateAdded → DATEDIFF from DateAdded to Occurred
- When FirstReviewed < EffectiveAddDate AND no EVMatch → DATEDIFF from DateAdded to Occurred
- Otherwise → DATEDIFF from EffectiveAddDate to FirstReviewed

### 2.5 KYC Flow Resolution

**What**: Determines the KYC flow type from ComplianceStateDB.
**Columns Involved**: KYCFlow
**Rules**:
- Current flow from ComplianceStateDB_Compliance_KycFlow (by GCID)
- If current KYCFlowTypeID=0 AND historical exists → use latest historical flow (ROW_NUMBER DESC by BeginTime)
- If current KYCFlowTypeID=0 AND no history → keep 0
- Otherwise → use current flow
- Name resolved from Dictionary_KYCFlowType

### 2.6 Population Filters

**What**: Defines the eligible population.
**Rules**:
- IsValidCustomer=1 (excludes Popular Investors, labels 30/26, CountryID=250)
- RiskGroupID NOT IN (1,2) — excludes high-risk and high-risk-for-new-clients countries
- VerificationLevel2Date >= @6month (VL2 achieved within last year, from Jan 1 of prior year)
- VerificationLevelID > 1 in final output
- Must have either EvMatchStatus NOT NULL or at least one document uploaded (SuggestedDocumentTypeID IN 1,2,13,15,6,18,23)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN HEAP**: No distribution key. For customer-specific lookups, filter on RealCID. For SLA analytics, GROUP BY Region, Regulation, or VerificationMethod.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly verification SLA by regulation | `GROUP BY Regulation, DATEPART(month, VerificationDate)` with `AVG(DaysToVerify)` |
| First-touch SLA by region | `GROUP BY Region` with `AVG(FirstTouch)` WHERE VerificationMethod='Docs' |
| EV vs Docs verification speed | `GROUP BY VerificationMethod` with `AVG(MinutesToVerify)` |
| Customers stuck at VL2 | `WHERE VerificationLevelID = 2 AND VerificationMethod = 'NA'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | dc.RealCID = kyc.RealCID | Full customer profile enrichment |
| DWH_dbo.Dim_PlayerStatus | ps.PlayerStatusID = kyc.PlayerStatusID | Status name resolution |
| DWH_dbo.Dim_EvMatchStatus | ems.EvMatchStatusID = kyc.EvMatchStatus | EV status name |

### 3.4 Gotchas

- **DaysToVerify can be NULL**: VL2-only customers (VerificationMethod='NA') have NULL DaysToVerify/HoursToVerify — they haven't reached VL3 yet.
- **FirstTouch can be NULL or 0**: 0 means EV-verified (instant), NULL means no touch point could be determined.
- **IsDepositor uses date range check**: Not the same as Dim_Customer.IsDepositor — this checks `FirstDepositDate BETWEEN '20000101' AND '20990101'` (treats sentinel 1900-01-01 as non-depositor).
- **Region values are marketing labels**: Not geographic regions. Examples: "UK", "Italian", "French", "Arabic Other", "ROW" (Rest of World). From Dim_Country.Region (marketing region).
- **WITH (NOLOCK) in SP**: The SP uses NOLOCK hints which are unnecessary in Synapse (snapshot isolation by default) but do not cause issues.
- **Occurred sentinel**: When Occurred is NULL in source, it's set to '3000-01-01' — filter with `WHERE Occurred < '3000-01-01'` for real review dates.
- **Document types**: SuggestedDocumentTypeID values: 1=POA, 2=POI, 6/13/15/18/23=other KYC document types.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verbatim from upstream wiki (production source documented) | Upstream dimension/fact wiki |
| Tier 2 | Derived from SP code analysis | SP_OPS_KYC_Verification |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 2 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer) |
| 3 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Filtered to > 1 in output. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer) |
| 4 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal; other values indicate restricted, closed, banned, or special states. Default=0. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 5 | PendingClosureStatusID | int | YES | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 6 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 7 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer) |
| 8 | Region | nvarchar(max) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. Dim-lookup passthrough from Dim_Country.Region via Dim_Customer.CountryID. (Tier 2 -- SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | Regulation | nvarchar(max) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 -- Dictionary.Regulation) |
| 10 | VerificationDate | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=3 (fully verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL3. (Tier 2 -- SP_OPS_KYC_Verification) |
| 11 | DaysToVerify | int | YES | Days from effective start date to VL3 verification. DATEDIFF(day, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0 (negative values corrected). NULL for VL2-only customers. (Tier 2 -- SP_OPS_KYC_Verification) |
| 12 | IsDepositor | int | YES | 1 when FirstDepositDate is between 2000-01-01 and 2099-01-01 (has real deposit). 0 when sentinel (1900-01-01) — no deposit. Not the same as Dim_Customer.IsDepositor. (Tier 2 -- SP_OPS_KYC_Verification) |
| 13 | EffectiveAddDate | datetime | YES | Effective SLA start date. Priority waterfall: EVMatchStatusDate (if EV-verified) → DateAdded (if no deposit or deposit-then-docs) → FirstDepositDate (otherwise). Used as denominator for DaysToVerify and FirstTouch calculations. (Tier 2 -- SP_OPS_KYC_Verification) |
| 14 | EvMatchStatusDate | datetime | YES | Earliest timestamp when the customer reached EvMatchStatus=2 (Verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never EV-verified. (Tier 2 -- SP_OPS_KYC_Verification) |
| 15 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. Dim-lookup passthrough from Dim_Country.RiskGroupID via Dim_Customer.CountryID. (Tier 1 -- Dictionary.Country) |
| 16 | VerificationMethod | nvarchar(max) | YES | How the customer was verified: 'EV' (electronic verification, EvMatchStatus=2 + VL3), 'Docs' (document review, VL3 without EV or with docs), 'NA' (not yet VL3). (Tier 2 -- SP_OPS_KYC_Verification) |
| 17 | HoursToVerify | bigint | YES | Hours from effective start date to VL3 verification. DATEDIFF(hour, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0. NULL for VL2-only. (Tier 2 -- SP_OPS_KYC_Verification) |
| 18 | MinutesToVerify | bigint | YES | Minutes from effective start date to VL3 verification. DATEDIFF(minute, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0. NULL for VL2-only. (Tier 2 -- SP_OPS_KYC_Verification) |
| 19 | KYCFlow | nvarchar(max) | YES | KYC flow type name from ComplianceStateDB. Resolved via GCID: current flow preferred, fallback to latest historical when current KYCFlowTypeID=0. Example: "Verify Before Deposit". NULL when GCID not found in ComplianceStateDB. (Tier 2 -- SP_OPS_KYC_Verification) |
| 20 | RegisteredDate | datetime | YES | Account registration date (renamed from RegisteredReal in Dim_Customer). Default=getdate(). Passthrough from Dim_Customer.RegisteredReal. (Tier 1 -- Customer.CustomerStatic) |
| 21 | UpdateDate | datetime | NO | ETL load timestamp. GETDATE() at SP execution time. Uniform across all rows (TRUNCATE+INSERT). (Tier 2 -- SP_OPS_KYC_Verification) |
| 22 | VerificationLevel1Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=1 (partial). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL1. (Tier 2 -- SP_OPS_KYC_Verification) |
| 23 | VerificationLevel2Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=2 (intermediate). From MIN(ValidFrom) in History.BackOfficeCustomer. Must be >= @6month for inclusion. (Tier 2 -- SP_OPS_KYC_Verification) |
| 24 | DateAdded | datetime | YES | Most recent KYC document upload date for this customer. From External_etoro_BackOffice_CustomerDocument, ROW_NUMBER DESC by DateAdded. Only documents with SuggestedDocumentTypeID IN (1,2,13,15,6,18,23). Excludes documents uploaded after VL3 date. (Tier 2 -- SP_OPS_KYC_Verification) |
| 25 | Occurred | datetime | YES | Document review occurred timestamp from BackOffice.CustomerDocumentToDocumentType. Sentinel '3000-01-01' when NULL in source (no review occurred yet). Used in FirstTouch SLA calculation. (Tier 2 -- SP_OPS_KYC_Verification) |
| 26 | FirstReviewed | datetime | YES | Effective first document review date. EVMatchStatusDate if EV-verified; Occurred if docs; conditional logic based on deposit/document/verification ordering. Used as endpoint for FirstTouch SLA. (Tier 2 -- SP_OPS_KYC_Verification) |
| 27 | FirstTouch | bigint | YES | Days from SLA start to first operations review. Complex CASE logic: 0 for instant EV, DATEDIFF from VL2/DateAdded/EffectiveAddDate to EVMatchStatusDate/Occurred/FirstReviewed depending on verification path. NULL when no touch point exists. (Tier 2 -- SP_OPS_KYC_Verification) |
| 28 | FirstTouchHour | bigint | YES | Hours from SLA start to first operations review. Same logic as FirstTouch but DATEDIFF in hours. (Tier 2 -- SP_OPS_KYC_Verification) |
| 29 | FirstTouchMinute | bigint | YES | Minutes from SLA start to first operations review. Same logic as FirstTouch but DATEDIFF in minutes. (Tier 2 -- SP_OPS_KYC_Verification) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID (via Dim_Customer) | Passthrough (renamed) |
| Region | Dictionary.MarketingRegion | Name (via Dim_Country) | Dim-lookup passthrough |
| Regulation | Dictionary.Regulation | Name (via Dim_Regulation) | Dim-lookup passthrough |
| VerificationDate | History.BackOfficeCustomer | ValidFrom | MIN WHERE VL=3 |
| KYCFlow | ComplianceStateDB.Dictionary.KYCFlowType | Name | Current or latest historical |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1)
  + DWH_dbo.Dim_Country (RiskGroupID NOT IN 1,2)
  + DWH_dbo.Dim_Regulation
  + general.etoro_History_BackOfficeCustomer
  |-- #firstVer (VL1/2/3 dates, EVMatch date, HAVING VL2 >= @6month) ---|
  |
  + External_ComplianceStateDB (KYC flow: current + history)
  |-- #currentvbd (KYC flow name per GCID) ---|
  |
  + External_etoro_BackOffice_CustomerDocument (doc types 1,2,13,15,6,18,23)
  + External_etoro_BackOffice_CustomerDocumentToDocumentType
  |-- #documents → #doc → #maxdateadded (latest doc per CID) ---|
  |
  |-- #pop1 → #pop (population: VL2+, valid, non-high-risk) ---|
  |-- #touch (effective date waterfall) ---|
  |-- #effective1 → #effective (DaysToVerify, HoursToVerify, MinutesToVerify) ---|
  |-- UPDATE: floor negative values to 0 ---|
  |-- #alldates (EffectiveAddDate, FirstReviewed) ---|
  |-- #firstTouch (FirstTouch, FirstTouchHour, FirstTouchMinute) ---|
  |-- #finalRaw (all columns + VerificationMethod CASE + RegisteredDate) ---|
  v
TRUNCATE BI_DB_dbo.BI_DB_OPS_KYC_Verification
INSERT FROM #finalRaw (~1.76M rows, VL > 1 only)
  |
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension master |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account restriction status (ID, not name) |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | EV identity verification status (ID, not name) |
| Region | DWH_dbo.Dim_Country | Marketing region from country |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name |
| RiskGroupID | DWH_dbo.Dim_Country | Country risk classification |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo. Operational reporting endpoint for KYC SLA monitoring.

---

## 7. Sample Queries

### 7.1 Monthly Verification SLA by Regulation

```sql
SELECT
    Regulation,
    DATEPART(month, VerificationDate) AS verify_month,
    DATEPART(year, VerificationDate) AS verify_year,
    COUNT(*) AS customers,
    AVG(CAST(DaysToVerify AS FLOAT)) AS avg_days,
    AVG(CAST(HoursToVerify AS FLOAT)) AS avg_hours
FROM BI_DB_dbo.BI_DB_OPS_KYC_Verification
WHERE VerificationMethod IN ('EV', 'Docs')
  AND VerificationDate IS NOT NULL
GROUP BY Regulation, DATEPART(year, VerificationDate), DATEPART(month, VerificationDate)
ORDER BY verify_year DESC, verify_month DESC, Regulation
```

### 7.2 First-Touch SLA by Verification Method

```sql
SELECT
    VerificationMethod,
    COUNT(*) AS customers,
    AVG(CAST(FirstTouch AS FLOAT)) AS avg_first_touch_days,
    AVG(CAST(FirstTouchMinute AS FLOAT)) AS avg_first_touch_minutes
FROM BI_DB_dbo.BI_DB_OPS_KYC_Verification
WHERE FirstTouch IS NOT NULL
GROUP BY VerificationMethod
```

### 7.3 Customers Stuck at VL2

```sql
SELECT
    RealCID, RegisteredDate, Region, Regulation, KYCFlow,
    VerificationLevel2Date, IsDepositor
FROM BI_DB_dbo.BI_DB_OPS_KYC_Verification
WHERE VerificationLevelID = 2
  AND VerificationMethod = 'NA'
ORDER BY VerificationLevel2Date ASC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable). SP comment mentions: "Need data to report monthly verification SLA based on updated processes and procedures."

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 8 T1, 21 T2, 0 T3, 0 T4, 0 T5 | Elements: 29/29, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_OPS_KYC_Verification | Type: Table | Production Source: SP_OPS_KYC_Verification*
