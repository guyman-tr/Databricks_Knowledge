# BI_DB_dbo.BI_DB_CIDFunnelFlow

> 3,970,310-row customer acquisition funnel table (1 row per customer; 3,970,310 distinct RealCIDs) tracking every registration-to-FTD milestone for the rolling 12-month new customer cohort. Refreshed daily by SP_CIDFunnelFlow via TRUNCATE+INSERT. ReportDateID is the customer's REGISTRATION date (YYYYMMDD), not the ETL run date — enabling cohort-based funnel analysis. Covers only IsValidCustomer=1 customers registered within the last 12 months. Last updated 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (primary), Fact_SnapshotCustomer, BI_DB_UsageTracking_SF |
| **Refresh** | Daily (SB_Daily, Priority 20) — TRUNCATE + INSERT (full snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ReportDateID ASC, RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to Unity Catalog |

---

## 1. Business Meaning

`BI_DB_CIDFunnelFlow` is the primary customer acquisition funnel table, providing one row per customer in the rolling 12-month registration cohort. Each row captures the customer's acquisition metadata (channel, funnel, regulation, geography) alongside milestone flags (REG → EmailVerification → V1/V2/V3 → EV → ProofOfAddress/Identity → FTD) and sales contact activity from Salesforce. The table is used by marketing and sales teams to measure conversion rates at each funnel stage, compare channel efficiency, and track compliance verification progress.

`ReportDateID` is the customer's registration date formatted as YYYYMMDD — **not** the date the SP ran. This is a critical design choice: it allows each row to persist with a fixed cohort date even as the customer's milestone flags update daily. The rolling window (`RegisteredReal >= DATEADD(month,-12,@Date)`) means customers drop out of this table after their 12-month anniversary.

Population excludes `IsValidCustomer=0` customers (test accounts, internal accounts, bots), ensuring only genuine onboarded customers appear.

---

## 2. Business Logic

### 2.1 Population and Rolling Window

**What**: The customer base covered by this table is bounded by a 12-month registration lookback from the SP run date.

**Columns Involved**: ReportDateID, Date, RealCID

**Rules**:
- Population: `WHERE RegisteredReal >= DATEADD(month,-12,@Date) AND IsValidCustomer=1`
- ReportDateID = `CONVERT(VARCHAR(8), CAST(RegisteredReal AS date), 112)` — customer's registration date, format YYYYMMDD
- Date = `CAST(RegisteredReal AS date)` — same date as ReportDateID but stored as date type
- Customers registered exactly 12 months ago are included; those 12+ months ago are excluded
- On each daily run, the cohort shrinks by ~12K customers aging out and grows by ~12K new registrations

### 2.2 Milestone Flags (Funnel Stages)

**What**: Binary flags (0/1) representing whether a customer has reached each acquisition funnel milestone. These are MAX() aggregates over the GROUP BY, so they capture the current cumulative state of each customer.

**Columns Involved**: REG, EmailVerification, V1, V2, V3, EV, SendToEV, ProofOfAddress, ProofOfIdentity, PhoneVerified, POA_POI, FTD, DepositAttempt, ConvOver96H, PendingVerification

**Rules**:
- `REG`: Always 1 for all rows in population (sentinel: RegisteredReal > '19000101' — all real customers pass)
- `EmailVerification`: MAX(IsEmailVerified) — 1 if customer verified email address; 59.5% of cohort
- `V1`: VerificationLevelID >= 1 — identity verification initiated; 52.3% of cohort
- `V2`: VerificationLevelID >= 2 — basic verification complete; 45.6% of cohort
- `V3`: VerificationLevelID = 3 — full KYC verification (POA+POI approved); 20.1% of cohort
- `EV`: EvMatchStatus = 2 — electronic verification returned a confirmed match; 17.6% of cohort
- `SendToEV`: EvMatchStatus IN (1,2,3) — sent to electronic verification engine (any result); 17.6% of cohort
- `ProofOfAddress`: IsAddressProof evaluated **at run time** with expiry check (IsAddressProofExpiryDate >= @Date) — may decrease if documents expire; 45.6% baseline
- `ProofOfIdentity`: IsIDProof evaluated **at run time** with expiry check (IsIDProofExpiryDate >= @Date)
- `PhoneVerified`: PhoneVerifiedID IN (1,2) → 1 else 0; evaluated in #POP
- `POA_POI`: IsIDProof > 0 AND IsAddressProof > 0 — both documents present and unexpired
- `DepositAttempt`: LEFT JOIN to Fact_BillingDeposit on PaymentStatusID=2; 9.8% of cohort
- `FTD`: FirstDepositDate > '19000101' — customer has at least one successful deposit; 8.6% of cohort
- `ConvOver96H`: DATEDIFF(hh, RegisteredReal, FirstDepositDate) > 96 — FTD happened more than 4 days after registration (slow conversion)
- `PendingVerification`: PlayerStatusID=13 AND VerificationLevelID != 3 — currently awaiting verification review; 0.2% of cohort

### 2.3 DesignatedRegulation vs Regulation

**What**: Two distinct regulation fields capture different regulation assignments.

**Columns Involved**: DesignatedRegulation, Regulation

**Rules**:
- `Regulation`: The customer's **current** RegulationID at ETL run time, joined directly from Dim_Regulation (DR2.ID = DC.RegulationID). Reflects today's regulation assignment.
- `DesignatedRegulation`: The customer's **earliest assigned** regulation after registration, sourced from Fact_SnapshotCustomer. Resolution:
  1. Find all Fact_SnapshotCustomer rows for the customer with non-null DesignatedRegulationID where the snapshot's FromDateID >= YYYYMMDD(RegisteredReal)
  2. RANK() by DateID ascending — RANK=1 = earliest snapshot post-registration
  3. Join that DesignatedRegulationID to Dim_Regulation DR for the name
- When a customer migrates regulation (e.g., from FCA to BVI), DesignatedRegulation stays as the first assigned, Regulation shows the current one
- 84.0% BVI, 6.2% eToroUS, 5.5% CySEC, 1.7% FCA across the cohort for Regulation

### 2.4 Contact Activity (Salesforce Integration)

**What**: Flags indicating whether and how sales contacted the customer **before their First Time Deposit**.

**Columns Involved**: IsContacted, PhoneContacted, EmailContacted, PhoneContactedSucceed, EmailContactedSucceed

**Rules**:
- Source: `BI_DB_UsageTracking_SF` — Salesforce CRM action events, LEFT JOINed on CID=RealCID
- "Before FTD" condition: `sf.CreatedDate_SF < DC.FirstDepositDate` OR `(FirstDepositDate = '19000101' AND sf.CreatedDate_SF > RegisteredReal)` — the second branch handles non-converters (contacts after registration but no FTD yet)
- `IsContacted`: Any SF action satisfying before-FTD condition
- `PhoneContacted`: ActionName = 'Contacted__c' — phone contact attempt
- `EmailContacted`: ActionName = 'Outbound_Email__c' — outbound email sent
- `PhoneContactedSucceed`: ActionName = 'Phone_Call_Succeed__c' — successful phone call
- `EmailContactedSucceed`: ActionName = 'Completed_Contact_Email__c' — completed email contact
- Only 1.2% of cohort (46,280 customers) were contacted before FTD — contacts focus on high-value prospects

### 2.5 Geography: State Only for USA

**What**: The State column is only populated for US customers.

**Columns Involved**: State, Country

**Rules**:
- #POP build: `CASE WHEN DC.CountryID = 219 THEN RegionID END RegionID` — RegionID only passed through for CountryID=219 (USA)
- Main query: LEFT JOIN Dim_State_and_Province on DC.RegionID = DS.RegionByIP_ID
- All non-US customers: State = NULL
- US customers (CountryID=219): State = state name from Dim_State_and_Province

### 2.6 FunnelFrom vs Funnel (Duplicate Columns)

**What**: Both FunnelFrom and Funnel contain the funnel name from Dim_Funnel, but are resolved at different pipeline stages.

**Columns Involved**: FunnelFrom, Funnel

**Rules**:
- `FunnelFrom`: Resolved in #POP as `e.Name` (LEFT JOIN Dim_Funnel on FunnelFromID); carried into the GROUP BY via `DC.FunnelFrom` alias
- `Funnel`: Resolved in the main query as `DF.Name` (LEFT JOIN Dim_Funnel on FunnelFromID again)
- Both resolve to the same Dim_Funnel.Name for the same FunnelFromID — values are identical in practice
- This duplication appears to be a legacy artifact; the SP joins Dim_Funnel twice

### 2.7 POA_POI_Phone — Orphan Column

**What**: Column 26 in the DDL (POA_POI_Phone) is never populated by SP_CIDFunnelFlow.

**Columns Involved**: POA_POI_Phone

**Rules**:
- Defined in the DDL as `[int] NULL`
- SP INSERT column list skips POA_POI_Phone — no value is inserted
- Always NULL for all rows
- The column likely represents a planned "POA + POI + Phone Verified" triple-flag that was stubbed but never implemented. The commented-out `#POAPOI` block in the SP suggests a broader document verification approach that was abandoned

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX (ReportDateID ASC, RealCID ASC). 3.97M rows. The clustered index enables efficient point lookups by registration cohort date — querying a specific registration month benefits from index seeks. No distribution key means JOINs to large DWH tables (e.g., Dim_Customer) will broadcast; use TOP or date filters to limit scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Funnel conversion rate for a registration cohort | WHERE ReportDateID BETWEEN '20260101' AND '20260131', SUM milestone flags / COUNT(RealCID) |
| Channel efficiency comparison | GROUP BY Channel, compute FTD/REG ratio per channel |
| Regulation breakdown of non-converters | WHERE FTD=0, GROUP BY Regulation |
| Customers still in pending verification | WHERE PendingVerification=1 |
| Slow converters (>96h to FTD) | WHERE ConvOver96H=1 |
| State-level US funnel analysis | WHERE Country='United States' AND State IS NOT NULL |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Get current customer attributes beyond what CIDFunnelFlow captures |
| BI_DB_dbo.BI_DB_Blocked_Customers | (no direct key — use RegulationID/status) | Cross-reference non-Normal status customers |
| BI_DB_dbo.BI_DB_CIDFirstDates | RealCID | Get LastLoggedIn or FirstDeposit dates for enrichment |

### 3.4 Gotchas

- **ReportDateID is registration date, NOT run date**: All rows for a customer registered on 2025-12-01 have ReportDateID='20251201' regardless of when you query — enables cohort analysis but confuses ETL-date assumptions
- **Rolling window drops customers after 12 months**: Customers registered > 12 months ago disappear from this table; historical funnel analysis requires joining to a snapshot or separate history table
- **POA_POI_Phone is always NULL**: Do not include in analyses — the column was never implemented
- **ProofOfAddress and ProofOfIdentity are run-time snapshots**: Expired documents reduce these flags; two queries on different days may return different values for the same customer
- **FunnelFrom = Funnel**: Both columns contain identical values — prefer one (Funnel) for consistency
- **V3 ≠ POA_POI**: V3 means VerificationLevelID=3 (the overall KYC status); POA_POI means both document types are independently present. They are correlated but not identical due to expiry logic differences
- **ConvOver96H requires FTD=1**: ConvOver96H=1 but FTD=0 is logically impossible; FTD=0 means no FirstDepositDate, so DATEDIFF always returns a nonsense value

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code, DDL, or external table definition |
| Tier 3 | Inferred from column name, data patterns, or business context |
| Tier 4 | Best available — limited confidence, needs review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Unique customer identifier — one row per customer. Population covers IsValidCustomer=1 customers registered within the rolling 12-month lookback window (3,970,310 distinct values). (Tier 2 — SP_CIDFunnelFlow/Dim_Customer) |
| 2 | Date | date | YES | Customer's registration date as a date value: CAST(RegisteredReal AS date). Equivalent to ReportDateID but stored as date type. Ranges from 2025-04-12 to 2026-04-12. (Tier 2 — SP_CIDFunnelFlow/Dim_Customer) |
| 3 | Region | varchar(50) | YES | Geographic macro-region of the customer's registered country (e.g., 'Europe', 'Asia', 'Americas'). Resolved from Dim_Country via CountryID. NULL if country not in Dim_Country. (Tier 2 — Dim_Country) |
| 4 | Country | varchar(50) | YES | Customer's registered country name (e.g., 'Germany', 'United States', 'Brazil'). Resolved from Dim_Country.Name via CountryID. (Tier 2 — Dim_Country) |
| 5 | State | varchar(100) | YES | US state/province name from Dim_State_and_Province. Only populated when CountryID=219 (USA); NULL for all other countries. Source: RegionByIP_ID match. (Tier 2 — SP_CIDFunnelFlow/Dim_State_and_Province) |
| 6 | Channel | nvarchar(50) | YES | Acquisition marketing channel (e.g., 'Direct', 'SEM', 'SEO', 'Affiliate', 'Media Performance', 'Friend Referral'). Resolved from Dim_Channel via Dim_Affiliate.SubChannelID. Distribution: Direct 57.0%, SEM 16.2%, SEO 10.8%, Affiliate 7.3%, Media Performance 4.2%, Friend Referral 2.5%. (Tier 2 — Dim_Channel/Dim_Affiliate) |
| 7 | SubChannel | varchar(100) | YES | Acquisition sub-channel granularity below Channel (e.g., specific SEM brand/non-brand split, affiliate tier). Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. (Tier 2 — Dim_Channel/Dim_Affiliate) |
| 8 | Funnel | varchar(50) | YES | Customer acquisition funnel name from Dim_Funnel (e.g., 'eToro Web', 'eToro App'). Resolved in the main INSERT SELECT via LEFT JOIN on FunnelFromID. Identical to FunnelFrom — see Business Logic §2.6. (Tier 2 — Dim_Funnel) |
| 9 | DesignatedRegulation | varchar(50) | YES | The regulation jurisdiction first assigned to the customer after registration, sourced from Fact_SnapshotCustomer RANK=1 (earliest snapshot with non-null DesignatedRegulationID on or after registration date). Resolved to Dim_Regulation.Name. Unlike Regulation, this reflects the original designated jurisdiction and does not change if the customer later migrates. (Tier 2 — Fact_SnapshotCustomer/Dim_Regulation) |
| 10 | Regulation | varchar(50) | YES | The customer's current regulation jurisdiction name at ETL run time. Resolved from Dim_Regulation DR2 on DC.RegulationID = DR2.ID. Note: join uses DR2.ID (not DR2.DWHRegulationID). Distribution: BVI 84.0%, eToroUS 6.2%, CySEC 5.5%, FCA 1.7%. (Tier 2 — Dim_Regulation via RegulationID) |
| 11 | AffiliateID | int | YES | Affiliate partner identifier from Dim_Customer.AffiliateID. GROUP BY key used to link to affiliate program records. NULL if customer was not referred via an affiliate. (Tier 2 — Dim_Customer) |
| 12 | FunnelFrom | varchar(50) | YES | Funnel name pre-resolved in the #POP staging table (e.Name from Dim_Funnel). Identical to Funnel in value — see Business Logic §2.6. Represents the acquisition funnel pathway the customer entered through. (Tier 2 — Dim_Funnel via #POP) |
| 13 | Platform | varchar(50) | YES | Device or platform type through which the customer registered (e.g., 'Web', 'iOS', 'Android'). Resolved from Dim_Platform via Dim_Funnel.PlatformID in the #POP staging table. (Tier 2 — Dim_Platform via #POP) |
| 14 | REG | int | YES | Registration milestone flag. Always 1 for all rows in this table (population is already filtered to RegisteredReal > '19000101' and IsValidCustomer=1). The sentinel date guard confirms a valid registration. (Tier 2 — SP_CIDFunnelFlow) |
| 15 | EmailVerification | int | YES | Email verification flag: 1 if the customer verified their email address (IsEmailVerified=1), 0 otherwise. 59.5% of cohort (2,361,436 customers). (Tier 2 — Dim_Customer.IsEmailVerified) |
| 16 | V1 | int | YES | Verification level 1 flag: 1 if VerificationLevelID >= 1 (identity verification initiated), 0 otherwise. First formal KYC step. 52.3% of cohort (2,076,648 customers). (Tier 2 — Dim_Customer.VerificationLevelID) |
| 17 | V2 | int | YES | Verification level 2 flag: 1 if VerificationLevelID >= 2 (basic verification approved), 0 otherwise. 45.6% of cohort (1,810,046 customers). (Tier 2 — Dim_Customer.VerificationLevelID) |
| 18 | V3 | int | YES | Verification level 3 flag: 1 if VerificationLevelID = 3 (full KYC verification complete — both POA and POI approved to the highest standard), 0 otherwise. 20.1% of cohort (798,751 customers). (Tier 2 — Dim_Customer.VerificationLevelID) |
| 19 | EV | int | YES | Electronic verification match flag: 1 if EvMatchStatus = 2 (confirmed identity match via eVerification provider), 0 otherwise. 17.6% of cohort (697,556 customers). (Tier 2 — Dim_Customer.EvMatchStatus) |
| 20 | SendToEV | int | YES | Sent-to-eVerification flag: 1 if EvMatchStatus IN (1,2,3) — customer was submitted to the electronic verification engine regardless of outcome, 0 otherwise. 17.6% of cohort (approximately same rate as EV). (Tier 2 — Dim_Customer.EvMatchStatus) |
| 21 | PEP | varchar(50) | YES | AML/PEP screening result from Dim_ScreeningStatus.Name (e.g., 'NoMatch', 'PendingInvestigation', 'RiskMatch', 'PEP', 'SanctionsMatch'). NULL (66.9%) means no screening result recorded; 'NoMatch' = 31.6%; flagged statuses < 2%. (Tier 2 — Dim_ScreeningStatus) |
| 22 | ProofOfAddress | int | YES | Proof of address document flag: 1 if IsAddressProof=1 AND IsAddressProofExpiryDate >= @Date (valid, unexpired POA document). Evaluated at run time — may decrease if documents expire. (Tier 2 — Dim_Customer.IsAddressProof + IsAddressProofExpiryDate) |
| 23 | ProofOfIdentity | int | YES | Proof of identity document flag: 1 if IsIDProof=1 AND IsIDProofExpiryDate >= @Date (valid, unexpired POI document). Evaluated at run time — may decrease if documents expire. (Tier 2 — Dim_Customer.IsIDProof + IsIDProofExpiryDate) |
| 24 | PhoneVerified | int | YES | Phone verification flag: 1 if PhoneVerifiedID IN (1,2) (phone verified by SMS or call), 0 otherwise. Evaluated in #POP staging table. (Tier 2 — Dim_Customer.PhoneVerifiedID) |
| 25 | POA_POI | int | YES | Combined document flag: 1 if both IsIDProof > 0 AND IsAddressProof > 0 (both proof of identity and proof of address are present and valid). Requires both documents; more stringent than V3 alone. (Tier 2 — Dim_Customer.IsIDProof + IsAddressProof) |
| 26 | POA_POI_Phone | int | YES | **Always NULL** — column exists in DDL but SP_CIDFunnelFlow never inserts a value. Intended to represent POA+POI+PhoneVerified triple-flag combination; implementation was not completed. Do not use in analysis. (Tier 2 — SP_CIDFunnelFlow stub/orphan) |
| 27 | DepositAttempt | int | YES | Deposit attempt flag: 1 if a Fact_BillingDeposit record with PaymentStatusID=2 exists for the customer, 0 otherwise. Captures whether the customer attempted a deposit regardless of FTD success. 9.8% of cohort (388,791 customers). (Tier 2 — Fact_BillingDeposit) |
| 28 | FTD | int | YES | First Time Deposit flag: 1 if FirstDepositDate > '19000101' (customer has made at least one successful deposit), 0 otherwise. 8.6% of cohort (340,593 customers). Lower than DepositAttempt (9.8%) — reflects deposit attempts that did not result in a confirmed deposit. (Tier 2 — Dim_Customer.FirstDepositDate) |
| 29 | IsContacted | int | YES | Any Salesforce contact flag: 1 if any CRM action occurred before the customer's FTD (or, for non-converters, after registration). 1.2% of cohort (46,280 customers). Source: BI_DB_UsageTracking_SF. (Tier 2 — BI_DB_UsageTracking_SF.CreatedDate_SF) |
| 30 | PhoneContacted | int | YES | Phone contact attempt flag: 1 if a 'Contacted__c' Salesforce action occurred before FTD (or post-registration for non-converters). Subset of IsContacted. (Tier 2 — BI_DB_UsageTracking_SF.ActionName='Contacted__c') |
| 31 | EmailContacted | int | YES | Outbound email flag: 1 if an 'Outbound_Email__c' Salesforce action occurred before FTD (or post-registration for non-converters). Subset of IsContacted. (Tier 2 — BI_DB_UsageTracking_SF.ActionName='Outbound_Email__c') |
| 32 | PhoneContactedSucceed | int | YES | Successful phone call flag: 1 if a 'Phone_Call_Succeed__c' Salesforce action occurred before FTD (or post-registration for non-converters). Subset of PhoneContacted. (Tier 2 — BI_DB_UsageTracking_SF.ActionName='Phone_Call_Succeed__c') |
| 33 | EmailContactedSucceed | int | YES | Completed email contact flag: 1 if a 'Completed_Contact_Email__c' Salesforce action occurred before FTD (or post-registration for non-converters). Subset of EmailContacted. (Tier 2 — BI_DB_UsageTracking_SF.ActionName='Completed_Contact_Email__c') |
| 34 | ConvOver96H | int | YES | Late conversion flag: 1 if DATEDIFF(hour, RegisteredReal, FirstDepositDate) > 96 (FTD occurred more than 4 days after registration). Only meaningful when FTD=1; when FTD=0, FirstDepositDate='19000101' makes DATEDIFF produce a sentinel value. (Tier 2 — SP_CIDFunnelFlow derived from RegisteredReal + FirstDepositDate) |
| 35 | PendingVerification | int | YES | Pending verification flag: 1 if PlayerStatusID=13 AND VerificationLevelID != 3 — customer is in the pending verification account status and has not achieved full KYC. 0.2% of cohort (6,185 customers). (Tier 2 — Dim_Customer.PlayerStatusID + VerificationLevelID) |
| 36 | ReportDateID | varchar(8) | YES | Customer's registration date as YYYYMMDD varchar (e.g., '20260115'). This is the primary cohort key — NOT the ETL run date. All rows for a customer share the same ReportDateID regardless of when the SP executed. Range: 20250412 to 20260412. Clustered index leading key for efficient cohort-date range queries. (Tier 2 — SP_CIDFunnelFlow: CONVERT(VARCHAR(8), CAST(RegisteredReal AS date), 112)) |
| 37 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_CIDFunnelFlow (GETDATE() at SP execution time). All rows in a given load share the same UpdateDate. Last value: 2026-04-13 04:14:00. (Tier 2 — SP_CIDFunnelFlow GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | GROUP BY key |
| Date | DWH_dbo.Dim_Customer | RegisteredReal | CAST(RegisteredReal AS date) |
| Region | DWH_dbo.Dim_Country | Region | LEFT JOIN on CountryID |
| Country | DWH_dbo.Dim_Country | Name | LEFT JOIN on CountryID |
| State | DWH_dbo.Dim_State_and_Province | Name | LEFT JOIN on RegionByIP_ID (USA only) |
| Channel | DWH_dbo.Dim_Channel | Channel | JOIN via Dim_Affiliate.SubChannelID |
| SubChannel | DWH_dbo.Dim_Channel | SubChannel | JOIN via Dim_Affiliate.SubChannelID |
| Funnel | DWH_dbo.Dim_Funnel | Name | LEFT JOIN on FunnelFromID (main query) |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | JOIN via #DesignatedRegulation2 RANK=1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN on DC.RegulationID = DR2.ID |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Passthrough |
| FunnelFrom | DWH_dbo.Dim_Funnel | Name | Resolved in #POP staging table |
| Platform | DWH_dbo.Dim_Platform | Platform | Resolved in #POP via Dim_Funnel.PlatformID |
| REG | DWH_dbo.Dim_Customer | RegisteredReal | CASE > '19000101' → always 1 |
| EmailVerification | DWH_dbo.Dim_Customer | IsEmailVerified | MAX() |
| V1/V2/V3 | DWH_dbo.Dim_Customer | VerificationLevelID | MAX(CASE >= threshold) |
| EV | DWH_dbo.Dim_Customer | EvMatchStatus | MAX(CASE = 2) |
| SendToEV | DWH_dbo.Dim_Customer | EvMatchStatus | MAX(CASE IN (1,2,3)) |
| PEP | DWH_dbo.Dim_ScreeningStatus | Name | LEFT JOIN on ScreeningStatusID |
| ProofOfAddress | DWH_dbo.Dim_Customer | IsAddressProof + IsAddressProofExpiryDate | MAX(ISNULL(IsAddressProof,0)) with expiry check in #POP |
| ProofOfIdentity | DWH_dbo.Dim_Customer | IsIDProof + IsIDProofExpiryDate | MAX(ISNULL(IsIDProof,0)) with expiry check in #POP |
| PhoneVerified | DWH_dbo.Dim_Customer | PhoneVerifiedID | MAX(ISNULL(IsPhoneVerified,0)) via #POP CASE |
| POA_POI | DWH_dbo.Dim_Customer | IsIDProof + IsAddressProof | MAX(CASE both > 0) |
| POA_POI_Phone | — | — | NULL — never inserted by SP |
| DepositAttempt | DWH_dbo.Fact_BillingDeposit | CID | MAX(CASE CID NOT NULL) — PaymentStatusID=2 |
| FTD | DWH_dbo.Dim_Customer | FirstDepositDate | MAX(CASE > '19000101') |
| IsContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CASE before-FTD condition) |
| PhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE = 'Contacted__c' AND before-FTD) |
| EmailContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE = 'Outbound_Email__c' AND before-FTD) |
| PhoneContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE = 'Phone_Call_Succeed__c' AND before-FTD) |
| EmailContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE = 'Completed_Contact_Email__c' AND before-FTD) |
| ConvOver96H | DWH_dbo.Dim_Customer | RegisteredReal + FirstDepositDate | MAX(CASE DATEDIFF(hh,...) > 96) |
| PendingVerification | DWH_dbo.Dim_Customer | PlayerStatusID + VerificationLevelID | MAX(CASE PlayerStatusID=13 AND VerifLevel!=3) |
| ReportDateID | DWH_dbo.Dim_Customer | RegisteredReal | CONVERT(VARCHAR(8), CAST(...AS date), 112) |
| UpdateDate | SP_CIDFunnelFlow | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (WHERE RegisteredReal >= DATEADD(month,-12,@Date) AND IsValidCustomer=1)
  + DWH_dbo.Dim_Funnel, Dim_Platform
  |-- #POP (HEAP ROUND_ROBIN) — pre-resolves FunnelFrom, Platform, USA-only RegionID ---|
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range
  |-- #DesignatedRegulation (earliest DateID per RealCID after registration) ---|
  |-- #DesignatedRegulation2 (RANK() by DateID ascending) ---|
  + DWH_dbo.Dim_Country, Dim_State_and_Province, Dim_Channel, Dim_Affiliate
  + DWH_dbo.Dim_Funnel (re-join), Dim_Regulation DR (DesignatedRegulation name)
  + DWH_dbo.Dim_Regulation DR2 (Regulation name via RegulationID=DR2.ID)
  + DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2 subquery)
  + BI_DB_dbo.BI_DB_UsageTracking_SF (contact events, LEFT JOIN)
  + DWH_dbo.Dim_ScreeningStatus (PEP)
  |-- TRUNCATE TABLE BI_DB_dbo.BI_DB_CIDFunnelFlow ---|
  |-- INSERT: GROUP BY RealCID + all dimension keys ---|
  v
BI_DB_dbo.BI_DB_CIDFunnelFlow (3,970,310 rows — 1 row per customer)
  |-- NOT exported to Unity Catalog (_Not_Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Primary customer dimension |
| AffiliateID | DWH_dbo.Dim_Affiliate.AffiliateID | Affiliate program lookup |
| (contact data) | BI_DB_dbo.BI_DB_UsageTracking_SF.CID | Salesforce CRM contact events |

### 6.2 Referenced By

| Object | Join Column | Description |
|--------|------------|-------------|
| (Downstream reports) | RealCID or ReportDateID | Used by marketing analytics to track cohort funnel performance |

---

## 7. Sample Queries

### Funnel Conversion Rates for a Registration Cohort

```sql
SELECT
    Channel,
    COUNT(*) AS registrations,
    SUM(CAST(EmailVerification AS int)) AS email_verified,
    SUM(CAST(V1 AS int)) AS v1,
    SUM(CAST(V3 AS int)) AS v3,
    SUM(CAST(FTD AS int)) AS ftd,
    CAST(100.0 * SUM(CAST(FTD AS int)) / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS ftd_rate_pct
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
WHERE ReportDateID BETWEEN '20260101' AND '20260131'
GROUP BY Channel
ORDER BY registrations DESC
```

### US State-Level Conversion Analysis

```sql
SELECT
    State,
    COUNT(*) AS customers,
    SUM(CAST(FTD AS int)) AS ftd,
    CAST(100.0 * SUM(CAST(FTD AS int)) / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS ftd_rate_pct
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
WHERE Country = 'United States'
  AND State IS NOT NULL
GROUP BY State
ORDER BY customers DESC
```

### Contact Impact on Conversion

```sql
SELECT
    IsContacted,
    COUNT(*) AS customers,
    SUM(CAST(FTD AS int)) AS ftd,
    CAST(100.0 * SUM(CAST(FTD AS int)) / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS ftd_rate_pct
FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
GROUP BY IsContacted
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specifically for this table. The table is the core funnel tracking artifact for the BI_DB_dbo customer acquisition reporting layer.

---

*Generated: 2026-04-21 | Quality: 9.68/10 | Phases: 16/16*
*Tiers: 0 T1, 37 T2, 0 T3, 0 T4 | Elements: 37/37, Logic: 7/7, ETL: confirmed, Data Evidence: live*
*Object: BI_DB_dbo.BI_DB_CIDFunnelFlow | Type: Table | Production Source: Dim_Customer + Fact_SnapshotCustomer + BI_DB_UsageTracking_SF*
