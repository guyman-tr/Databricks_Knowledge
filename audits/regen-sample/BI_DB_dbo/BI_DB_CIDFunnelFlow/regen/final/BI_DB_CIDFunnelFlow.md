# BI_DB_dbo.BI_DB_CIDFunnelFlow

> 4.24M-row customer registration-to-conversion funnel analysis table tracking every valid customer registered in the last 12 months through verification stages, KYC milestones, deposit attempts, FTD, and Salesforce CRM contact activity. Rebuilt daily via TRUNCATE+INSERT by SP_CIDFunnelFlow.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — funnel snapshot) |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (primary), Dim_Country, Dim_Funnel, Dim_Platform, Dim_Affiliate, Dim_Channel, Dim_State_and_Province, Dim_Regulation, Dim_ScreeningStatus, Fact_SnapshotCustomer + Dim_Range (designated regulation history), Fact_BillingDeposit (deposit attempts), BI_DB_UsageTracking_SF (Salesforce contact activity) |
| **Refresh** | Daily full rebuild (TRUNCATE + INSERT via SP_CIDFunnelFlow @Date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ReportDateID ASC, RealCID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFunnelFlow` is a customer acquisition funnel analysis table that tracks every valid eToro customer registered within the last 12 months through a series of binary conversion milestones. Each row represents one customer and captures their progress through registration (REG), email verification, KYC verification levels (V1/V2/V3), electronic verification (EV), document proofs (POA/POI), deposit attempt, first-time deposit (FTD), and Salesforce CRM contact activity (phone/email contacts and their success).

The table is rebuilt daily by `SP_CIDFunnelFlow(@Date)` using a TRUNCATE+INSERT pattern. The population is filtered to `IsValidCustomer=1` and `RegisteredReal >= DATEADD(month, -12, @Date)`, producing a rolling 12-month window. As of 2026-04-27: 4.24M rows, date range 2025-04-26 to 2026-04-26, all rows share the same UpdateDate (single daily load).

Key data flows:
- **Customer attributes**: Sourced from `DWH_dbo.Dim_Customer` (the primary population driver)
- **Geography**: Country name and marketing region from `Dim_Country`; US state from `Dim_State_and_Province` (only for CountryID=219)
- **Acquisition channel**: Resolved via `Dim_Affiliate → Dim_Channel` chain using the customer's AffiliateID
- **Designated regulation**: First-ever designated regulation resolved from `Fact_SnapshotCustomer` + `Dim_Range` history (earliest FromDateID after registration)
- **Deposit activity**: Approved deposit check against `Fact_BillingDeposit` (PaymentStatusID=2)
- **CRM contacts**: Pre-FTD Salesforce activity from `BI_DB_UsageTracking_SF` (phone calls, emails, and their success outcomes)

The `POA_POI_Phone` column is present in the DDL but is NOT populated by the current SP (always NULL).

---

## 2. Business Logic

### 2.1 Rolling 12-Month Population Filter

**What**: Only valid customers registered in the last 12 months are included.

**Columns Involved**: `RealCID`, `Date`, `REG`

**Rules**:
- Population: `WHERE RegisteredReal >= DATEADD(month, -12, @Date) AND IsValidCustomer = 1`
- IsValidCustomer=1 excludes: PlayerLevelID=4 (Popular Investor), LabelID IN (30,26), CountryID=250
- The @Date parameter is typically yesterday: `DATEADD(DAY, -1, GETDATE())`
- REG is always 1 in practice (the WHERE filter ensures all customers have RegisteredReal > '19000101')

### 2.2 KYC Verification Funnel Stages

**What**: Binary flags converting VerificationLevelID thresholds into funnel stage indicators.

**Columns Involved**: `V1`, `V2`, `V3`, `EmailVerification`, `EV`, `SendToEV`

**Rules**:
- `V1 = 1` when VerificationLevelID >= 1 (partial verification or above)
- `V2 = 1` when VerificationLevelID >= 2 (intermediate verification or above)
- `V3 = 1` when VerificationLevelID = 3 (fully verified)
- `EmailVerification` = MAX(IsEmailVerified) — 1 if email confirmed
- `EV = 1` when EvMatchStatus = 2 (identity verification matched)
- `SendToEV = 1` when EvMatchStatus IN (1,2,3) (sent to electronic verification regardless of outcome)
- Funnel progression: REG → EmailVerification → V1 → V2 → V3 → EV → FTD

### 2.3 Document Proof with Expiry Validation

**What**: Address and ID proof flags that respect document expiry dates.

**Columns Involved**: `ProofOfAddress`, `ProofOfIdentity`, `POA_POI`

**Rules**:
- `ProofOfAddress = 1` when IsAddressProof = 1 AND IsAddressProofExpiryDate >= @Date
- `ProofOfIdentity = 1` when IsIDProof = 1 AND IsIDProofExpiryDate >= @Date
- `POA_POI = 1` when BOTH ProofOfIdentity > 0 AND ProofOfAddress > 0
- Expired documents are treated as not having proof (= 0)

### 2.4 Pre-FTD Contact Tracking

**What**: Salesforce CRM contact activity that occurred BEFORE the customer's first deposit (or after registration if no FTD yet).

**Columns Involved**: `IsContacted`, `PhoneContacted`, `EmailContacted`, `PhoneContactedSucceed`, `EmailContactedSucceed`

**Rules**:
- Contact is "pre-FTD" if: `CreatedDate_SF < FirstDepositDate` (for depositors) OR `CreatedDate_SF > RegisteredReal` (for non-depositors where FirstDepositDate = '19000101')
- `IsContacted = 1` if ANY Salesforce action matches the pre-FTD window
- `PhoneContacted = 1` if ActionName = 'Contacted__c' in the pre-FTD window
- `EmailContacted = 1` if ActionName = 'Outbound_Email__c' in the pre-FTD window
- `PhoneContactedSucceed = 1` if ActionName = 'Phone_Call_Succeed__c' in the pre-FTD window
- `EmailContactedSucceed = 1` if ActionName = 'Completed_Contact_Email__c' in the pre-FTD window

### 2.5 Designated Regulation Resolution

**What**: Resolves the customer's first designated regulation from their snapshot history.

**Columns Involved**: `DesignatedRegulation`

**Rules**:
- Queries `Fact_SnapshotCustomer` joined to `Dim_Range` to find the earliest `FromDateID` where `DesignatedRegulationID IS NOT NULL` and `FromDateID >= registration date`
- RANK() partitioned by RealCID ordered by DateID picks the first occurrence (rn=1)
- The regulation name is resolved via `Dim_Regulation.Name`
- NULL if the customer never had a DesignatedRegulationID assigned

### 2.6 Conversion Latency

**What**: Flags customers whose first deposit took more than 96 hours after registration.

**Columns Involved**: `ConvOver96H`

**Rules**:
- `ConvOver96H = 1` when `DATEDIFF(hh, RegisteredReal, FirstDepositDate) > 96`
- 0 for customers who deposited within 96 hours or never deposited (FirstDepositDate = '19000101')

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with CLUSTERED INDEX on (ReportDateID ASC, RealCID ASC). The clustered index supports date-range + customer queries efficiently. ROUND_ROBIN means no data locality benefit for JOINs on RealCID — consider filtering by ReportDateID first for large analytical queries.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Funnel conversion rates by month | GROUP BY LEFT(ReportDateID, 6), compute SUM(V1)/SUM(REG) etc. |
| Channel effectiveness for FTD | GROUP BY Channel, compute SUM(FTD)/COUNT(*) |
| Pre-FTD contact impact | Compare FTD rate WHERE IsContacted=1 vs IsContacted=0 |
| Regulation-specific funnel | WHERE Regulation = 'CySEC' or WHERE DesignatedRegulation = 'FCA' |
| Country-level verification rates | GROUP BY Country, compute SUM(V3)/SUM(REG) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID | Additional customer attributes not in this table |
| DWH_dbo.Dim_Date | ON ReportDateID = DateID | Time dimension for calendar analytics |

### 3.4 Gotchas

- **POA_POI_Phone is always NULL**: The column exists in DDL but is NOT in the SP's INSERT column list. Do not use it.
- **REG is always 1**: The population WHERE filter ensures all customers have a valid registration date, making REG=1 for every row. It exists as a counting convenience for SUM(REG).
- **State only populated for US (CountryID=219)**: The SP conditionally sets RegionID only when CountryID=219. All non-US customers have NULL State.
- **PEP is a text label, not an ID**: Contains the screening status name (e.g., 'NoMatch', 'PEP', 'RiskMatch'), not a numeric ID. Empty string when ScreeningStatusID has no match in Dim_ScreeningStatus.
- **Pre-FTD contact logic has two branches**: For depositors, contact must precede FirstDepositDate. For non-depositors (FirstDepositDate='19000101'), any contact after registration counts.
- **Full TRUNCATE daily**: No incremental logic — the entire 4.24M-row table is rebuilt each run.
- **ConvOver96H = 0 for non-depositors**: Customers who never deposited get ConvOver96H=0 because DATEDIFF on '19000101' produces a negative or very large value that doesn't match > 96.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 — upstream wiki verbatim | `(Tier 1 — upstream wiki, source)` |
| ★★★☆☆ | Tier 2 — SP code / DDL | `(Tier 2 — SP_CIDFunnelFlow)` |
| ★★☆☆☆ | Tier 3 — DDL structure | `(Tier 3 — DDL only)` |

### 4.1 Customer Identity & Geography

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Date | date | YES | Customer registration date (RegisteredReal from Dim_Customer cast to date, losing time component). Used as the funnel entry date. (Tier 2 — SP_CIDFunnelFlow) |
| 3 | Region | varchar(50) | YES | Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Used for marketing campaign grouping. Passthrough from Dim_Country. (Tier 1 — Dictionary.MarketingRegion) |
| 4 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 5 | State | varchar(100) | YES | Full human-readable geographic name of the region — state, province, or territory. Sourced from Dictionary.RegionName.Name. Only populated when CountryID=219 (United States); NULL for all other countries. Passthrough from Dim_State_and_Province. (Tier 2 — SP_CIDFunnelFlow) |
| 6 | Channel | nvarchar(50) | YES | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' to 'Affiliate'. Common values: Direct, SEM, SEO, Affiliate, Media Performance, Friend Referral. Resolved via Dim_Customer.AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel.Channel. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 7 | SubChannel | varchar(100) | YES | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Direct', 'Direct Mobile'. Resolved via Dim_Customer.AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel.SubChannel. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |

### 4.2 Acquisition & Funnel

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 8 | Funnel | varchar(50) | YES | Unique human-readable label for the registration funnel. Describes the campaign/channel/product that drove registration. Passthrough from Dim_Funnel.Name via FunnelFromID. (Tier 1 — Dictionary.Funnel) |
| 9 | DesignatedRegulation | varchar(50) | YES | Short code for the customer's first designated regulatory jurisdiction, resolved from the earliest Fact_SnapshotCustomer record after registration where DesignatedRegulationID is not null. Passthrough from Dim_Regulation.Name. NULL if never assigned. (Tier 1 — Dictionary.Regulation) |
| 10 | Regulation | varchar(50) | YES | Short code for the customer's current regulatory jurisdiction. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 11 | AffiliateID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 12 | FunnelFrom | varchar(50) | YES | Unique human-readable label for the source funnel variant. Describes the funnel the customer came from. Passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID. (Tier 1 — Dictionary.Funnel) |
| 13 | Platform | varchar(50) | YES | Platform name label: "Undefined", "Web", "IOS", "Android". Resolved via Dim_Customer.FunnelFromID → Dim_Funnel.PlatformID → Dim_Platform.Platform. (Tier 1 — Dictionary.Platform) |

### 4.3 Funnel Conversion Flags

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 14 | REG | int | YES | Registration flag. 1 if the customer has a valid registration date (RegisteredReal > '19000101'). Always 1 in practice because the population WHERE filter ensures valid registrations only. Used as a counting column for SUM(REG). (Tier 2 — SP_CIDFunnelFlow) |
| 15 | EmailVerification | int | YES | 1 if the customer has verified their email address (IsEmailVerified=1 from Dim_Customer). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 16 | V1 | int | YES | KYC verification level 1+ flag. 1 when VerificationLevelID >= 1 (partial verification or above). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 17 | V2 | int | YES | KYC verification level 2+ flag. 1 when VerificationLevelID >= 2 (intermediate verification or above). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 18 | V3 | int | YES | KYC verification level 3 flag. 1 when VerificationLevelID = 3 (fully verified). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 19 | EV | int | YES | Electronic verification matched flag. 1 when EvMatchStatus = 2 (identity verification matched by automated vendors such as Onfido, Au10tix). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 20 | SendToEV | int | YES | Sent to electronic verification flag. 1 when EvMatchStatus IN (1,2,3) — customer was submitted for identity verification regardless of outcome. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 21 | PEP | varchar(50) | YES | AML/compliance screening outcome name. Values: 'NoMatch' (clean), 'PendingInvestigation', 'PEP' (Politically Exposed Person), 'RiskMatch', 'SanctionsMatch', 'Unknown', 'Technical', 'MultipleMatch'. Empty string when ScreeningStatusID has no match. Passthrough from Dim_ScreeningStatus.Name. (Tier 1 — ScreeningService.Dictionary.ScreeningStatus) |

### 4.4 Document Proofs & Phone

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 22 | ProofOfAddress | int | YES | 1 if the customer has a valid (non-expired) address proof document on file. Computed: IsAddressProof=1 AND IsAddressProofExpiryDate >= @Date. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 23 | ProofOfIdentity | int | YES | 1 if the customer has a valid (non-expired) ID proof document on file. Computed: IsIDProof=1 AND IsIDProofExpiryDate >= @Date. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 24 | PhoneVerified | int | YES | 1 if the customer's phone number is verified (PhoneVerifiedID IN (1,2) from Dim_Customer). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 25 | POA_POI | int | YES | Combined document proof flag. 1 when BOTH ProofOfIdentity > 0 AND ProofOfAddress > 0. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 26 | POA_POI_Phone | int | YES | NOT POPULATED by the current SP_CIDFunnelFlow — column exists in DDL but is absent from the INSERT column list. Always NULL. Likely intended to combine POA+POI+Phone verification but never implemented. (Tier 3 — DDL only, not populated) |

### 4.5 Deposit & Conversion

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 27 | DepositAttempt | int | YES | 1 if the customer has at least one approved deposit (PaymentStatusID=2) in Fact_BillingDeposit. 0 otherwise. Note: checks only approved deposits, not all attempts. (Tier 2 — SP_CIDFunnelFlow) |
| 28 | FTD | int | YES | First Time Deposit flag. 1 if the customer has ever deposited (FirstDepositDate > '19000101' from Dim_Customer). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |

### 4.6 CRM Contact Activity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | IsContacted | int | YES | 1 if any Salesforce CRM action occurred before the customer's first deposit (or after registration if no FTD). Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 30 | PhoneContacted | int | YES | 1 if a phone contact action (ActionName='Contacted__c') occurred before FTD. Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 31 | EmailContacted | int | YES | 1 if an outbound email action (ActionName='Outbound_Email__c') occurred before FTD. Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 32 | PhoneContactedSucceed | int | YES | 1 if a successful phone call (ActionName='Phone_Call_Succeed__c') occurred before FTD. Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 33 | EmailContactedSucceed | int | YES | 1 if a completed contact email (ActionName='Completed_Contact_Email__c') occurred before FTD. Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |

### 4.7 Conversion Timing & Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | ConvOver96H | int | YES | Late conversion flag. 1 if the time between registration and first deposit exceeds 96 hours (DATEDIFF(hh, RegisteredReal, FirstDepositDate) > 96). 0 for customers who deposited within 96 hours or never deposited. (Tier 2 — SP_CIDFunnelFlow) |
| 35 | PendingVerification | int | YES | 1 if the customer is in pending verification status (PlayerStatusID=13) AND is not fully verified (VerificationLevelID != 3). 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| 36 | ReportDateID | varchar(8) | YES | Registration date as YYYYMMDD string. Derived from CONVERT(VARCHAR(8), CAST(RegisteredReal AS date), 112). Used as the clustered index leading key for date-range queries. (Tier 2 — SP_CIDFunnelFlow) |
| 37 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at SP_CIDFunnelFlow execution time. All rows share the same value per daily load. (Tier 2 — SP_CIDFunnelFlow) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| RealCID | Dim_Customer | RealCID | Passthrough |
| Date | Dim_Customer | RegisteredReal | CAST to date |
| Region | Dim_Country | Region | Dim-lookup via CountryID |
| Country | Dim_Country | Name | Dim-lookup via CountryID |
| State | Dim_State_and_Province | Name | Conditional dim-lookup (CountryID=219 only) |
| Channel | Dim_Channel | Channel | Chain: AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel |
| SubChannel | Dim_Channel | SubChannel | Chain: AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel |
| Funnel | Dim_Funnel | Name | Dim-lookup via FunnelFromID |
| DesignatedRegulation | Dim_Regulation | Name | Via Fact_SnapshotCustomer + Dim_Range (first DesignatedRegulationID) |
| Regulation | Dim_Regulation | Name | Dim-lookup via RegulationID |
| AffiliateID | Dim_Customer | AffiliateID | Passthrough |
| FunnelFrom | Dim_Funnel | Name | Dim-lookup via FunnelFromID |
| Platform | Dim_Platform | Platform | Chain: FunnelFromID → Dim_Funnel.PlatformID → Dim_Platform |
| REG | Dim_Customer | RegisteredReal | CASE > '19000101' |
| EmailVerification | Dim_Customer | IsEmailVerified | MAX aggregation |
| V1-V3 | Dim_Customer | VerificationLevelID | CASE threshold flags |
| EV, SendToEV | Dim_Customer | EvMatchStatus | CASE value matching |
| PEP | Dim_ScreeningStatus | Name | Dim-lookup via ScreeningStatusID |
| ProofOfAddress | Dim_Customer | IsAddressProof, IsAddressProofExpiryDate | CASE with expiry check |
| ProofOfIdentity | Dim_Customer | IsIDProof, IsIDProofExpiryDate | CASE with expiry check |
| PhoneVerified | Dim_Customer | PhoneVerifiedID | CASE IN (1,2) |
| POA_POI | Dim_Customer | IsIDProof, IsAddressProof | Combined AND flag |
| POA_POI_Phone | — | — | Not populated (DDL-only) |
| DepositAttempt | Fact_BillingDeposit | CID, PaymentStatusID | EXISTS check (PaymentStatusID=2) |
| FTD | Dim_Customer | FirstDepositDate | CASE > '19000101' |
| IsContacted..EmailContactedSucceed | BI_DB_UsageTracking_SF | CID, ActionName, CreatedDate_SF | Pre-FTD CASE logic |
| ConvOver96H | Dim_Customer | RegisteredReal, FirstDepositDate | DATEDIFF(hh) > 96 |
| PendingVerification | Dim_Customer | PlayerStatusID, VerificationLevelID | CASE compound condition |
| ReportDateID | Dim_Customer | RegisteredReal | CONVERT to YYYYMMDD string |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (primary population, 12-month rolling, IsValidCustomer=1)
  + DWH_dbo.Dim_Funnel (funnel name lookup)
  + DWH_dbo.Dim_Platform (platform label lookup)
  + DWH_dbo.Dim_Affiliate (affiliate → subchannel mapping)
  + DWH_dbo.Dim_Channel (channel/subchannel labels)
  + DWH_dbo.Dim_Country (country name, region)
  + DWH_dbo.Dim_State_and_Province (US state name)
  + DWH_dbo.Dim_Regulation (regulation name, x2: designated + current)
  + DWH_dbo.Dim_ScreeningStatus (PEP screening label)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range (designated regulation history)
  + DWH_dbo.Fact_BillingDeposit (deposit attempt check, PaymentStatusID=2)
  + BI_DB_dbo.BI_DB_UsageTracking_SF (Salesforce CRM contact activity)
  |
  v [SP_CIDFunnelFlow @Date — TRUNCATE + INSERT]
  |
  v
BI_DB_dbo.BI_DB_CIDFunnelFlow (4.24M rows, ROUND_ROBIN)
```

| Step | Object | Description |
|------|--------|-------------|
| Population | #POP temp table | Dim_Customer filtered to 12-month rolling + IsValidCustomer=1; computes IsPhoneVerified, IsIDProof, IsAddressProof with expiry checks; resolves FunnelFrom and Platform via dim lookups |
| Regulation History | #DesignatedRegulation, #DesignatedRegulation2 | Finds first DesignatedRegulationID per customer from Fact_SnapshotCustomer + Dim_Range; RANK() picks rn=1 |
| Load | TRUNCATE + INSERT | Full rebuild: joins #POP with 9 dim tables + 2 fact tables + 1 BI_DB table; GROUP BY with MAX aggregation on binary flags |
| Target | BI_DB_dbo.BI_DB_CIDFunnelFlow | 4.24M rows daily |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension (primary population source) |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner who referred the customer |

### 6.2 Referenced By (other objects point to this)

No views, stored procedures, or functions in the SSDT repo reference this table. It appears to be a terminal reporting/analytics table consumed directly by BI tools.

---

## 7. Sample Queries

### 7.1 Monthly funnel conversion rates

```sql
SELECT
    LEFT(ReportDateID, 6) AS YearMonth,
    COUNT(*) AS Registrations,
    SUM(EmailVerification) AS EmailVerified,
    SUM(V1) AS V1_Verified,
    SUM(V3) AS FullyVerified,
    SUM(FTD) AS FirstDeposits,
    CAST(SUM(FTD) AS FLOAT) / COUNT(*) AS FTD_Rate
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
GROUP BY LEFT(ReportDateID, 6)
ORDER BY YearMonth DESC;
```

### 7.2 Channel effectiveness for FTD conversion

```sql
SELECT
    Channel,
    COUNT(*) AS Registrations,
    SUM(FTD) AS FTDs,
    CAST(SUM(FTD) AS FLOAT) / COUNT(*) AS ConversionRate,
    SUM(IsContacted) AS Contacted,
    SUM(PhoneContactedSucceed) AS PhoneSuccess
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
WHERE Channel IS NOT NULL AND Channel <> ''
GROUP BY Channel
ORDER BY ConversionRate DESC;
```

### 7.3 Pre-FTD contact impact analysis

```sql
SELECT
    CASE WHEN IsContacted = 1 THEN 'Contacted' ELSE 'Not Contacted' END AS ContactStatus,
    COUNT(*) AS Customers,
    SUM(FTD) AS FTDs,
    CAST(SUM(FTD) AS FLOAT) / COUNT(*) AS FTD_Rate,
    SUM(ConvOver96H) AS LateConversions
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
GROUP BY CASE WHEN IsContacted = 1 THEN 'Contacted' ELSE 'Not Contacted' END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources available for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-27 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14 (P10 Atlassian skipped, P16 deferred)*
*Tiers: 10 T1, 25 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 37/37, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CIDFunnelFlow | Type: Table | Production Source: Multi-source (Dim_Customer primary + 12 dim/fact sources via SP_CIDFunnelFlow)*
