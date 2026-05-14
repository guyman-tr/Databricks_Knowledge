# BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications

> **STALE** -- 810,829-row KYC verification tracking dataset (registered 2017-06 -- 2025-07), measuring time from registration to verification levels, verification method (EV/Docs/NA), and first-touch SLA. Writer SP code was removed from SP_Operations_Monthly_KPIs_FullData on 2025-04-14; data frozen since 2025-07-28.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.SP_Operations_Monthly_KPIs_FullData (REMOVED 2025-04-14) |
| **Refresh** | **STALE** -- last updated 2025-07-28; writer SP removed; replacement SP not in SSDT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CI(RealCID) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Operations_Monthly_KPIs_Verifications` is an Operations KPI table that tracked customer KYC (Know Your Customer) verification lifecycle metrics. Each row represents one customer, recording the time and method of their verification journey from registration through VL0, VL1, VL2, and VL3, along with first-touch SLA compliance and verification method classification.

- **Row count**: 810,829 rows
- **Date range**: Registered dates 2017-06 to 2025-07; UpdateDate all 2025-07-28
- **Writer SP**: Was part of `SP_Operations_Monthly_KPIs_FullData`. The KYC verification section was removed on 2025-04-14 with commit message: "remove kyc verification part completely - created new SP for that". The replacement SP is NOT in the SSDT repository.
- **Load pattern (historical)**: Daily incremental -- `DELETE WHERE updatedate = @date OR firstdepositdate = @date`, then INSERT new/changed customers
- **Population**: Customers with verification activity; VerificationMethod distribution: EV (443K), Docs (252K), NA (115K)

**STALENESS WARNING**: This table has not been refreshed since 2025-07-28 (approximately 9 months stale as of 2026-04-26). The writer SP code was removed and the replacement SP is not tracked in source control. Any analysis using this table should note the data cutoff date and consider querying upstream Dim_Customer + History_BackOfficeCustomer directly for current verification data.

---

## 2. Business Logic

### 2.1 Verification Method Classification

**What**: Classifies how each customer was verified.
**Columns Involved**: VerificationMethod, EvMatchStatus
**Rules**:
- `EV` (Electronic Verification): Customer verified via automated electronic identity check (Onfido, Au10tix). Indicated by EvMatchStatus values signaling a successful match.
- `Docs` (Document Upload): Customer verified by uploading identity documents manually reviewed by back-office.
- `NA` (Not Applicable): Customer not yet verified or verification method indeterminate.
- Distribution: EV (443K, 54.6%), Docs (252K, 31.1%), NA (115K, 14.2%)

### 2.2 Verification Timeline Tracking

**What**: Measures elapsed time from registration/FTD to each verification level.
**Columns Involved**: DaysToVerify, WorkingDaysToVerify, HoursToVerify, MinutesToVerify, VerificationDate, VerificationLevel1Date, VerificationLevel2Date
**Rules**:
- `DaysToVerify` = calendar days from registration (or first deposit) to full verification (VL3)
- `WorkingDaysToVerify` = business days (weekday-adjusted) for same interval
- `HoursToVerify` / `MinutesToVerify` = granular time intervals
- Verification level dates sourced from History_BackOfficeCustomer change tracking

### 2.3 First Touch SLA

**What**: Measures back-office responsiveness to new verification requests.
**Columns Involved**: FirstTouch, FirstTouchSLA, FirstTouchHour, FirstTouchMinute, FirstReviewed
**Rules**:
- `FirstTouch` = days from registration to first back-office interaction
- `FirstTouchSLA` = binary compliance flag (1 = within SLA, 0 = exceeded)
- `FirstTouchHour` / `FirstTouchMinute` = granular first-touch intervals
- `FirstReviewed` = timestamp of first back-office review

### 2.4 Verification Before Deposit

**What**: Tracks whether the customer completed KYC before making their first deposit.
**Columns Involved**: IsVerifyB4Deposit, FirstDepositDate, VerificationDate
**Rules**:
- `IsVerifyB4Deposit = 1` when VerificationDate < FirstDepositDate
- Important for regulatory compliance -- some jurisdictions require verification before deposit

### 2.5 Document/POA/POI Flags

**What**: Tracks suggested document requirements and upload status.
**Columns Involved**: SuggestedPOA, SuggestedPOI, "Uploaded 2 Docs (not EV)"
**Rules**:
- `SuggestedPOA` = 1 if Proof of Address was suggested/required
- `SuggestedPOI` = 1 if Proof of Identity was suggested/required
- `"Uploaded 2 Docs (not EV)"` = 1 if customer uploaded 2+ documents without using electronic verification

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with clustered index on RealCID. One row per customer, so RealCID is effectively a unique key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Verification rate by method | `GROUP BY VerificationMethod` |
| Average time to verify by region | `AVG(DaysToVerify) GROUP BY Region` |
| First touch SLA compliance | `SUM(FirstTouchSLA) / COUNT(*) GROUP BY Regulation` |
| Verified before deposit rate | `SUM(IsVerifyB4Deposit) / COUNT(*)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Current customer attributes |
| DWH_dbo.Dim_Country | ON (via Dim_Customer) | Country-level grouping |

### 3.4 Gotchas

- **TABLE IS STALE**: Data frozen since 2025-07-28. Do not use for current verification status analysis.
- **Column name with space**: `"Uploaded 2 Docs (not EV)"` must be quoted with square brackets or double quotes in queries: `[Uploaded 2 Docs (not EV)]`
- **UpdateDate is uniform**: All rows show UpdateDate = 2025-07-28, indicating a full reload on that date (the last refresh).
- **No writer SP in SSDT**: The replacement SP is not source-controlled. Future maintenance requires locating the SP on the Synapse server directly.

---

## 4. Elements

### Confidence Tier Legend
| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (verbatim) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 3 | Inferred from data | Medium |
| Tier 4 | Best guess / Confluence | Lower |

> Note: Because the writer SP code was removed from the SSDT repo, many columns cannot be verified against SP code. Columns sourced from Dim_Customer are Tier 1 (upstream wiki available). ETL-computed columns that rely on the removed SP code are Tier 3 (inferred from column names and data patterns).

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Clustered index column. (Tier 1 — Dim_Customer.RealCID) |
| 2 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 1 — Dim_Customer.FirstDepositDate) |
| 3 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — Dim_Customer.VerificationLevelID) |
| 4 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Dim_Customer.PlayerStatusID) |
| 5 | PendingClosureStatusID | int | YES | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Dim_Customer.PendingClosureStatusID) |
| 6 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Dim_Customer.PlayerStatusReasonID) |
| 7 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — Dim_Customer.EvMatchStatus) |
| 8 | Region | nvarchar(1000) | YES | Marketing region label from Dim_Country, resolved via customer CountryID. Oversize type (nvarchar 1000) relative to source varchar(50). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Country.Region) |
| 9 | Regulation | nvarchar(1000) | YES | Regulation name from Dim_Regulation, resolved via customer RegulationID. Oversize type (nvarchar 1000) relative to source varchar(50). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Regulation.Name) |
| 10 | VerificationDate | datetime | YES | Date when customer reached full verification (VerificationLevelID >= 3). Derived from History_BackOfficeCustomer change tracking. (Tier 3 — inferred from column name and data pattern) |
| 11 | DaysToVerify | int | YES | Calendar days from registration or first deposit to full verification date. (Tier 3 — inferred from column name) |
| 12 | Uploaded 2 Docs (not EV) | int | YES | Flag indicating customer uploaded 2+ documents without using electronic verification. **Column name contains spaces and parentheses -- must be quoted in queries**: `[Uploaded 2 Docs (not EV)]`. (Tier 3 — inferred from column name and data) |
| 13 | IsDepositor | int | YES | Whether the customer has ever deposited. 1=depositor, 0=non-depositor. (Tier 1 — Dim_Customer.IsDepositor, cast from bit to int) |
| 14 | DidCO | int | YES | Flag indicating customer has completed at least one cashout/withdrawal. (Tier 3 — inferred from column name) |
| 15 | Liquidated | bigint | YES | Flag or amount indicating customer account liquidation status. (Tier 3 — inferred from column name) |
| 16 | EffectiveAddDate | datetime | YES | Effective account add/activation date. Likely registration date or account activation timestamp. (Tier 3 — inferred from column name) |
| 17 | FirstReviewed | datetime | YES | Date/time of first back-office review of customer verification documents. (Tier 3 — inferred from column name) |
| 18 | FirstTouch | int | YES | Days from registration to first back-office touch/interaction on the customer record. (Tier 3 — inferred from column name) |
| 19 | VerificationLevel1Date | datetime | YES | Date when customer first reached VerificationLevelID >= 1. Derived from History_BackOfficeCustomer. (Tier 3 — inferred from column name) |
| 20 | VerificationLevel2Date | datetime | YES | Date when customer first reached VerificationLevelID >= 2. Derived from History_BackOfficeCustomer. (Tier 3 — inferred from column name) |
| 21 | EvMatchStatusDate | datetime | YES | Date when EvMatchStatus was first set (electronic verification decision date). Derived from History_BackOfficeCustomer. (Tier 3 — inferred from column name) |
| 22 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. (Tier 1 — Dim_Country.RiskGroupID) |
| 23 | SuggestedPOA | int | YES | Flag: 1 if Proof of Address was suggested/required for this customer. (Tier 3 — inferred from column name) |
| 24 | SuggestedPOI | int | YES | Flag: 1 if Proof of Identity was suggested/required for this customer. (Tier 3 — inferred from column name) |
| 25 | VerificationMethod | nvarchar(1000) | YES | Classification of how the customer was verified: 'EV' (electronic), 'Docs' (document upload), or 'NA' (not applicable/unverified). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 26 | WorkingDaysToVerify | int | YES | Business days (weekday-adjusted) from registration/FTD to full verification. (Tier 3 — inferred from column name) |
| 27 | UnderOneDay | int | YES | 1 if verification was completed within 1 working day, else 0. (Tier 3 — inferred from column name) |
| 28 | OverOneDay | int | YES | 1 if verification took more than 1 working day, else 0. (Tier 3 — inferred from column name) |
| 29 | FirstTouchSLA | int | YES | SLA compliance flag for first back-office touch. 1=within SLA, 0=exceeded. (Tier 3 — inferred from column name) |
| 30 | VerificationSLA | int | YES | SLA compliance flag for full verification completion. 1=within SLA, 0=exceeded. (Tier 3 — inferred from column name) |
| 31 | IsVerifyB4Deposit | int | YES | 1 if customer completed verification before first deposit, 0 otherwise. (Tier 3 — inferred from column name) |
| 32 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution. All rows show 2025-07-28 (last refresh). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 33 | HoursToVerify | bigint | YES | Hours elapsed from registration/FTD start to full verification. DATEDIFF(hh, ...). (Tier 3 — inferred from column name) |
| 34 | MinutesToVerify | bigint | YES | Minutes elapsed from registration/FTD start to full verification. DATEDIFF(mi, ...). (Tier 3 — inferred from column name) |
| 35 | FirstTouchHour | bigint | YES | Hours elapsed from registration to first back-office touch. (Tier 3 — inferred from column name) |
| 36 | FirstTouchMinute | bigint | YES | Minutes elapsed from registration to first back-office touch. (Tier 3 — inferred from column name) |
| 37 | KYCFlow | varchar(225) | YES | KYC workflow classification string. Identifies which verification pipeline the customer went through. (Tier 3 — inferred from column name) |
| 38 | RegisteredDate | datetime | YES | Account registration date. Mapped from Dim_Customer.RegisteredReal (renamed). (Tier 1 — Dim_Customer.RegisteredReal) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Customer | Primary: customer attributes (RealCID, VerificationLevelID, PlayerStatusID, FirstDepositDate, etc.) |
| DWH_dbo.Dim_Country | Region label via customer CountryID; RiskGroupID |
| DWH_dbo.Dim_Regulation | Regulation name via customer RegulationID |
| History_BackOfficeCustomer | Verification level change dates (VL1Date, VL2Date, EvMatchStatusDate) |
| BackOffice document/EV tables | Document upload status, electronic verification results |

### 5.2 ETL Pipeline (Historical -- no longer active)

```
DWH_dbo.Dim_Customer (dc)
  + JOIN DWH_dbo.Dim_Country (dco) ON dc.CountryID = dco.CountryID
  + JOIN DWH_dbo.Dim_Regulation (dr) ON dc.RegulationID = dr.ID
  + JOIN History_BackOfficeCustomer (hbo) for VL date tracking
  + JOIN BackOffice document tables for POA/POI/EV
  |
  v [SP_Operations_Monthly_KPIs_FullData -- REMOVED 2025-04-14]
    1. DELETE WHERE updatedate = @date OR firstdepositdate = @date
    2. INSERT customer verification records with computed metrics
    3. Classify VerificationMethod (EV/Docs/NA)
    4. Compute SLA flags and time intervals
  |
  v
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications (810K rows -- FROZEN)
```

**NOTE**: A replacement SP was created (per commit message) but is NOT in the SSDT repository. The table data is frozen as of 2025-07-28.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer record |
| VerificationLevelID | Dictionary.VerificationLevel | KYC level |
| PlayerStatusID | Dictionary.PlayerStatus | Account status |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | Electronic verification result |
| RiskGroupID | Dictionary.CountryRiskGroup | Country risk classification |

### 6.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| Operations dashboards | KYC verification SLA monitoring (historical) |

---

## 7. Sample Queries

```sql
-- Verification method distribution (note: data frozen since 2025-07-28)
SELECT VerificationMethod,
       COUNT(*) AS Customers,
       AVG(CAST(DaysToVerify AS FLOAT)) AS AvgDaysToVerify
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications
WHERE VerificationMethod IS NOT NULL
GROUP BY VerificationMethod
ORDER BY Customers DESC;

-- First touch SLA by regulation
SELECT Regulation,
       COUNT(*) AS Customers,
       SUM(FirstTouchSLA) AS SLA_Pass,
       CAST(SUM(FirstTouchSLA) AS FLOAT) / COUNT(*) AS SLA_Rate
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications
GROUP BY Regulation
ORDER BY Customers DESC;

-- Column with space in name requires quoting
SELECT [Uploaded 2 Docs (not EV)],
       COUNT(*) AS Customers
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications
GROUP BY [Uploaded 2 Docs (not EV)];
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources identified for this object during documentation.

---

*Generated: 2026-04-26 | Quality: 5.5/10 | Phases: 14/14*
*Tiers: 9 T1, 4 T2, 25 T3, 0 T4 | Elements: 38/38, All documented*
*Note: Low quality score due to (a) table staleness since 2025-07-28, (b) writer SP removed from SSDT -- 25 of 38 columns are Tier 3 inferred, (c) replacement SP not available for code analysis.*
*Object: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications | Type: Table | Production Source: BI_DB_dbo.SP_Operations_Monthly_KPIs_FullData (REMOVED)*
