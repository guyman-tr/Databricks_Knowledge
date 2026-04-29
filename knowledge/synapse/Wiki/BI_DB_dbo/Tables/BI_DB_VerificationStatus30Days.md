# BI_DB_dbo.BI_DB_VerificationStatus30Days

> 34K-row daily KYC verification monitoring snapshot for customers who first deposited in the last 30 days or registered in the last 15 days without depositing. Tracks verification level, document uploads, electronic verification status, realized equity at FTD+14, deposits within 14 days, and assigns a 5-tier verification urgency priority. TRUNCATE+INSERT daily via SP_H_VerificationStatus30Days.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_etoro_BackOffice_Customer + DWH_dbo.Dim_Customer + Dim_Country + BI_DB_AllDeposits + V_Liabilities + Fact_CustomerAction + BackOffice_CustomerDocument via `SP_H_VerificationStatus30Days` |
| **Refresh** | Daily (TRUNCATE + INSERT — full rebuild) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Guy Manova (2017-12-25), last updated Pavlina Masoura (2023-09-07) |
| **Row Count** | ~34,389 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_VerificationStatus30Days` is a daily point-in-time snapshot monitoring the KYC (Know Your Customer) verification status of recently onboarded customers. The population includes:

- Customers whose first deposit was within the last 30 days
- Customers who registered in the last 15 days without any deposit yet

The table excludes: PlayerLevelID=4 (test accounts), CountryID=250 (specific country exclusion), and LabelID=30 (specific label exclusion).

For each customer, the SP collects:
- **Verification state**: Current verification level (2 or 3), electronic verification match status (Onfido/Au10tix), document upload flags (POA/POI)
- **Financial profile**: Total approved deposits, realized equity at FTD+14 days, deposits within first 14 days
- **Account state**: Player status, pending closure status, cashout history (DidCO)
- **Urgency scoring**: A 5-tier Priority calculated from verification level, realized equity, and days remaining until the 15-day verification deadline

Priority scoring algorithm:
- **5**: Already VL3 (fully verified) — 95% of population
- **1** (urgent): High RE or approaching deadline fast
- **2** (medium-high): Moderate RE or mid-deadline
- **3** (medium): Lower RE or more time remaining
- **4** (low): Below all urgency thresholds

The priority tiers use a matrix of `14_Days_RE` amount ranges (≤200, 200-1000, 1000-2300, ≥2300) crossed with days remaining until FTD+15, with tighter deadlines triggering higher urgency for larger account balances.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Identifies recently onboarded customers for verification monitoring.
**Columns Involved**: `RealCID`, `FirstDepositDate`
**Rules**:
- FTD within last 30 days: cc.FirstDepositDate >= DATEADD(DAY, -30, GETDATE())
- OR registered within last 15 days without FTD: cc.RegisteredReal > GETDATE()-15 AND cc.FirstDepositDate IS NULL
- Excludes: PlayerLevelID=4, CountryID=250, LabelID=30

### 2.2 Electronic Verification

**What**: Identity verification status from automated vendors.
**Columns Involved**: `EvMatchStatus`, `EvVerified`, `NewUpload`
**Rules**:
- EvMatchStatus from BackOffice.Customer (Onfido/Au10tix results)
- EvVerified = 1 when EvMatchStatus=2 (verified), 0 otherwise
- NewUpload = 1 when DocumentStatusID=1 (new document uploaded), 0 otherwise

### 2.3 Document Upload Status

**What**: Whether customer has uploaded required documents (POA/POI).
**Columns Involved**: `UploadDocs`, `SuggestedPOA`, `SuggestedPOI`
**Rules**:
- UploadDocs: 1 if any CustomerDocument exists for this CID
- SuggestedPOA: 1 if SuggestedDocumentTypeID=1 (Proof of Address)
- SuggestedPOI: 1 if SuggestedDocumentTypeID=2 (Proof of Identity)

### 2.4 14-Day Financial Metrics

**What**: Realized equity and deposit total within 14 days of first deposit.
**Columns Involved**: `FTD_Plus_14`, `14_Days_RE`, `14_Days_Deposits`
**Rules**:
- FTD_Plus_14 = DATEADD(day, 14, FirstDepositDate)
- 14_Days_RE: RealizedEquity from V_Liabilities at FTD+14 date; if FTD+14 is in the future, uses yesterday's value
- 14_Days_Deposits: SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=7 (deposits) within 14 days of FTD

### 2.5 Account Closure Detection

**What**: Flags customers who cashed out and closed before completing verification.
**Columns Involved**: `Closed`, `DidCO`
**Rules**:
- DidCO: 1 if any approved cashout (Billing.Withdraw WHERE Approved <> 0)
- Closed: 1 if VL < 3 AND DidCO=1 AND PendingClosureStatusID=3 AND PlayerStatusID=13 AND PlayerStatusReasonID=1

### 2.6 Priority Scoring (5-Tier Urgency)

**What**: Assigns urgency priority based on verification level, realized equity, and time pressure.
**Columns Involved**: `Priority`
**Rules**:
- **5** = VL3 (fully verified, no action needed)
- **1** = Highest urgency: large RE (≥$2,300 with ≤10 days), medium RE ($1K-$2.3K with ≤4 days), small RE ($200-$1K with ≤3 days), or minimal RE (≤$200 with ≤2 days)
- **2** = Medium-high: same RE tiers but wider day windows (≤13, ≤11, ≤7, ≤4)
- **3** = Medium: same RE tiers but widest windows (≤13, ≤12, ≤8, ≤0)
- **4** = Low: does not meet any urgency threshold

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no index optimizations. For CID lookups, add WHERE clause on RealCID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| High-priority unverified customers | `WHERE Priority = 1 AND CurrentVerificationLevel < 3` |
| Verified vs unverified breakdown | `SELECT CurrentVerificationLevel, COUNT(*) GROUP BY CurrentVerificationLevel` |
| Customers with documents uploaded | `WHERE UploadDocs = 1 AND CurrentVerificationLevel < 3` |
| Closed before verification | `WHERE Closed = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| DWH_dbo.Dim_Regulation | `RegulationID = ID` | Regulation name |

### 3.4 Gotchas

- **Rolling 30-day snapshot**: The entire table is TRUNCATED and rebuilt daily. No historical data is retained.
- **IsWalletUser always NULL**: Deprecated since 2020 (BI_DEV link removed). Do not use.
- **TotalDeposit**: From BI_DB_AllDeposits (PaymentStatus='Approved'), not from Dim_Customer. May differ from Dim_Customer.TotalDeposit.
- **Priority=5 dominates**: 95% of rows are already VL3 (verified). Priority 1-4 are the actionable subset.
- **Country is varchar(max)**: Unusually wide type for a country name column. Consider filtering carefully.
- **EvMatchStatus from BackOffice.Customer**: Read from the external table (production), NOT from Dim_Customer. Values may be fresher than DWH.
- **OR precedence**: The population filter has mixed AND/OR without parentheses — the actual behavior includes customers with recent FTD AND (recently registered without FTD, excluding certain PlayerLevels/Countries/Labels).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer. Converted to date type. (Tier 2 — SP_Dim_Customer) |
| 3 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 4 | Region | varchar(max) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Passthrough from Dim_Country. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 5 | CurrentVerificationLevel | int | YES | Customer's current KYC verification level from BackOffice.Customer.VerificationLevelID. 2=partially verified, 3=fully verified. Renamed VerificationLevelID → CurrentVerificationLevel. (Tier 2 — SP_H_VerificationStatus30Days) |
| 6 | PendingClosureStatusID | int | YES | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 7 | CurrentPlayerStatus | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. Renamed PlayerStatusID → CurrentPlayerStatus. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 8 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 9 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. Changes trigger RegulationChangeDate update. Passthrough from BackOffice.Customer. (Tier 1 — BackOffice.Customer) |
| 10 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. Passthrough from BackOffice.Customer. (Tier 1 — BackOffice.Customer) |
| 11 | EvVerified | int | YES | Binary flag derived from EvMatchStatus. 1 if EvMatchStatus=2 (verified), 0 otherwise. (Tier 2 — SP_H_VerificationStatus30Days) |
| 12 | NewUpload | int | YES | Binary flag indicating new document upload. 1 if DocumentStatusID=1 in BackOffice.Customer, 0 otherwise. (Tier 2 — SP_H_VerificationStatus30Days) |
| 13 | TotalDeposit | money | YES | Total approved deposit amount from BI_DB_AllDeposits. SUM of [Amount in $] WHERE PaymentStatus='Approved'. May be NULL if no approved deposits. (Tier 2 — SP_H_VerificationStatus30Days) |
| 14 | IsDepositor | int | YES | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 15 | DidCO | int | YES | Binary flag: 1 if customer has any approved cashout (Billing.Withdraw WHERE Approved <> 0), 0 otherwise. (Tier 2 — SP_H_VerificationStatus30Days) |
| 16 | FTD_Plus_14 | date | YES | Date 14 days after first deposit. DATEADD(day, 14, FirstDepositDate). Used as the reference point for 14-day financial metrics and priority scoring. (Tier 2 — SP_H_VerificationStatus30Days) |
| 17 | 14_Days_RE | money | YES | Realized equity at FTD+14 from V_Liabilities. If FTD+14 is in the future, uses yesterday's RealizedEquity. Key input to priority scoring algorithm. (Tier 2 — SP_H_VerificationStatus30Days) |
| 18 | 14_Days_Deposits | money | YES | Total deposits within 14 days of first deposit. SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=7 AND DateID <= FTD+14. (Tier 2 — SP_H_VerificationStatus30Days) |
| 19 | UploadDocs | int | YES | Binary flag: 1 if any document exists in BackOffice.CustomerDocument for this CID, 0 otherwise. (Tier 2 — SP_H_VerificationStatus30Days) |
| 20 | SuggestedPOA | int | YES | Binary flag: 1 if a Proof of Address document (SuggestedDocumentTypeID=1) exists in CustomerDocument. (Tier 2 — SP_H_VerificationStatus30Days) |
| 21 | SuggestedPOI | int | YES | Binary flag: 1 if a Proof of Identity document (SuggestedDocumentTypeID=2) exists in CustomerDocument. (Tier 2 — SP_H_VerificationStatus30Days) |
| 22 | Closed | int | YES | Binary flag: 1 if customer closed account before completing verification. Criteria: CurrentVerificationLevel < 3 AND DidCO=1 AND PendingClosureStatusID=3 AND CurrentPlayerStatus=13 AND PlayerStatusReasonID=1. (Tier 2 — SP_H_VerificationStatus30Days) |
| 23 | Priority | int | YES | 5-tier verification urgency score. 5=already VL3 (no action). 1=highest urgency (large RE + approaching deadline). 2-4=graduated urgency based on RE amount ranges (≤200/200-1K/1K-2.3K/≥2.3K) crossed with days remaining until FTD+15. (Tier 2 — SP_H_VerificationStatus30Days) |
| 24 | IsWalletUser | int | YES | Deprecated — always NULL. Was from BI_DEV/EXW wallet login data (removed 2020-01-16). Do not use. (Tier 2 — SP_H_VerificationStatus30Days) |
| 25 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | etoro.BackOffice.Customer | CID | Rename (CID → RealCID) |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CONVERT(date) |
| Country | etoro.Dictionary.Country | Name | Dim-lookup via CountryID |
| Region | etoro.Dictionary.MarketingRegion | Name | Dim-lookup via Dim_Country.Region |
| CurrentVerificationLevel | etoro.BackOffice.Customer | VerificationLevelID | Rename |
| PendingClosureStatusID | DWH_dbo.Dim_Customer | PendingClosureStatusID | Passthrough |
| CurrentPlayerStatus | DWH_dbo.Dim_Customer | PlayerStatusID | Rename |
| PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough |
| RegulationID | etoro.BackOffice.Customer | RegulationID | Passthrough |
| EvMatchStatus | etoro.BackOffice.Customer | EvMatchStatus | Passthrough |
| EvVerified | etoro.BackOffice.Customer | EvMatchStatus | CASE WHEN = 2 THEN 1 ELSE 0 |
| NewUpload | etoro.BackOffice.Customer | DocumentStatusID | CASE WHEN = 1 THEN 1 ELSE 0 |
| TotalDeposit | BI_DB_AllDeposits | Amount in $ | SUM WHERE Approved |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough |
| DidCO | etoro.Billing.Withdraw | Approved | MAX(CASE <> 0) |
| FTD_Plus_14 | — | — | DATEADD(day, 14, FirstDepositDate) |
| 14_Days_RE | DWH_dbo.V_Liabilities | RealizedEquity | At FTD+14 or yesterday |
| 14_Days_Deposits | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| UploadDocs | etoro.BackOffice.CustomerDocument | — | EXISTS flag |
| SuggestedPOA | etoro.BackOffice.CustomerDocument | SuggestedDocumentTypeID | CASE = 1 |
| SuggestedPOI | etoro.BackOffice.CustomerDocument | SuggestedDocumentTypeID | CASE = 2 |
| Closed | Multiple | Multiple | Complex CASE (VL + status + closure) |
| Priority | Multiple | Multiple | 5-tier CASE (VL + RE + days) |
| IsWalletUser | — | — | Hardcoded NULL |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
External_etoro_BackOffice_Customer (VerificationLevelID, EvMatchStatus, RegulationID)
  + DWH_dbo.Dim_Customer (RealCID, FTD, PlayerStatus, PendingClosure, IsDepositor)
  + DWH_dbo.Dim_Country (Country name, Region)
  + BI_DB_AllDeposits (approved deposit totals)
  |
  → #pop (FTD last 30 days OR registered last 15 days without FTD)
  |
  + External_etoro_Billing_Withdraw → DidCO flag
  + V_Liabilities → 14_Days_RE (RealizedEquity at FTD+14)
  + Fact_CustomerAction → 14_Days_Deposits (ActionTypeID=7)
  + BackOffice_CustomerDocument → UploadDocs, SuggestedPOA, SuggestedPOI
  |
  → Priority scoring (5-tier urgency based on VL, RE, days remaining)
  → Closed flag (VL<3 + cashout + closure status)
  |
  |-- SP_H_VerificationStatus30Days (TRUNCATE + INSERT) ---|
  v
BI_DB_dbo.BI_DB_VerificationStatus30Days (~34K rows, daily snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer identifier |
| RegulationID | DWH_dbo.Dim_Regulation.ID | Regulation entity |
| Country | DWH_dbo.Dim_Country.Name | Country name |
| CurrentPlayerStatus | DWH_dbo.Dim_PlayerStatus.PlayerStatusID | Player status lookup |

### 6.2 Referenced By (other objects point to this)

No known consumer tables or views reference this table directly.

---

## 7. Sample Queries

### 7.1 High-Priority Unverified Customers

```sql
SELECT
    RealCID,
    Country,
    CurrentVerificationLevel,
    Priority,
    [14_Days_RE],
    TotalDeposit,
    EvVerified,
    UploadDocs
FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days]
WHERE Priority = 1
  AND CurrentVerificationLevel < 3
ORDER BY [14_Days_RE] DESC
```

### 7.2 Verification Funnel by Regulation

```sql
SELECT
    RegulationID,
    CurrentVerificationLevel,
    COUNT(*) AS customer_count,
    SUM(CASE WHEN EvVerified = 1 THEN 1 ELSE 0 END) AS ev_verified,
    SUM(CASE WHEN UploadDocs = 1 THEN 1 ELSE 0 END) AS docs_uploaded
FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days]
GROUP BY RegulationID, CurrentVerificationLevel
ORDER BY RegulationID, CurrentVerificationLevel
```

### 7.3 Closed Before Verification

```sql
SELECT
    RealCID,
    Country,
    FirstDepositDate,
    TotalDeposit,
    DidCO,
    CurrentVerificationLevel
FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days]
WHERE Closed = 1
ORDER BY TotalDeposit DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 7 T1, 17 T2, 0 T3, 0 T4, 1 T5 | Elements: 25/25, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_VerificationStatus30Days | Type: Table | Production Source: BackOffice.Customer + Dim_Customer via SP_H_VerificationStatus30Days*
