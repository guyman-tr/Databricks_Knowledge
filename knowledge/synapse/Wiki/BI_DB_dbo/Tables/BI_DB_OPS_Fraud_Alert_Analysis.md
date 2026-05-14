# BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis

> 1.47M-row fraud detection scoring table covering customers registered in the last 3 months (2026-01-01 to 2026-04-11). Computes 15+ suspicious-registration signals (fake names, disposable emails, IP clustering, geographic mismatches, fast verification speed) and a weighted composite score per customer. Sourced from DWH_dbo.Dim_Customer + 9 dimension JOINs + BackOffice documents + History verification dates + billing deposits. Daily TRUNCATE+INSERT via SP_OPS_Fraud_Alert_Analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Key Identifier** | RealCID (not enforced — no PK in DDL) |
| **Production Source** | SP_OPS_Fraud_Alert_Analysis (Michail Vryoni, 2025-06-25) |
| **Refresh** | Daily (1440 min), TRUNCATE+INSERT, 3-month rolling window |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~1.47M |
| **Date Range** | Rolling 3 months from run date (RegisteredReal >= DATEADD(MONTH, -3, first-of-month(@Date))) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis` |
| **UC Format** | parquet |
| **UC Copy Strategy** | Override |

---

## 1. Business Meaning

`BI_DB_OPS_Fraud_Alert_Analysis` is a daily fraud-detection scoring table that evaluates every customer registered in the last 3 months for signs of suspicious or fraudulent activity. Each row represents one customer and carries 15+ binary fraud signal flags plus a composite weighted suspicious score (0--15 scale).

The SP builds a `#SuspiciousRegistrations` temp table from `Dim_Customer` joined to 7 dimension tables, applying pattern-matching CASE expressions to detect:
- **Fake name patterns**: 50+ LIKE checks for gibberish, keyboard walks (qwert, asdf), repeating characters (aaa, bbb), sequential letters (abc, bcd), digits, and test/demo/fake/sample words
- **Disposable email detection**: 25+ disposable email domain patterns (mailinator, tempmail, yopmail, guerrillamail, sharklasers) plus keyboard walk local parts and short/numeric-prefix email addresses
- **Geographic mismatches**: Country vs CountryByIP comparison, and a 18-country language-expectation matrix checking LanguageID/CommunicationLanguageID against expected values for Germany, France, Spain, Italy, UK, Russia, Turkey, Ukraine, Poland, Brazil, Mexico, China, India, Pakistan, Iran, Egypt, US, Vietnam
- **Verification speed anomalies**: Time gaps between VL0->VL1->VL2->VL3 transitions from History.BackOfficeCustomer; flags registrations that complete verification levels in under 1 minute
- **IP clustering**: Flags IPs with 20+ distinct registrations (RepeatedIPAddressFlag) and IPs with 20+ same-minute registrations (ClusteredIP_RegistrationFlag)
- **Country-time clustering**: Flags Country+CountryByIP+Minute combinations with >10 registrations

The weighted suspicious score sums individual signals plus 5 combo flags (e.g., fast registration + fake email, IP repeat + fake email). Additional context columns include POI/POA document upload status from BackOffice.CustomerDocument, total approved deposits from Fact_BillingDeposit, player status/reason/sub-reason, and club (loyalty tier).

Distribution: 50% score=0 (clean), 28% score=1 (single flag), 20% score=2, 1.5% score=3, 0.2% score=4, <0.1% score>=5. Blocked customers = 38% of population. Top countries: UK (29%), France (10%), Germany (8%).

---

## 2. Business Logic

### 2.1 Fake Name Detection

**What**: Identifies customers with gibberish or suspicious first/last names.
**Columns Involved**: FakeFirstNameFlag, FakeLastNameFlag, FirstName, LastName
**Rules**:
- Length < 2 characters
- Contains triple-letter sequences (aaa through zzz — all 26 checked)
- Contains keyboard walk sequences (qwert, asdf, bvbv, zxzx)
- Contains sequential letter pairs (abc, bcd, cde ... xyz — all 23 checked)
- Contains digits or non-alphabetic characters
- Contains test/fake/demo/sample keywords
- FirstName = LastName (exact match)
- Contains double-letter sequences (xx, yy, zz)

### 2.2 Fake Email Pattern Detection

**What**: Identifies disposable or bot-generated email addresses.
**Columns Involved**: FakeEmailPatternFlag, Email
**Rules**:
- Contains numeric sequences (1234, 1111, 0000)
- Contains disposable email domain patterns: mailinator, tempmail, yopmail, 10minutemail, guerrillamail, trashmail, sharklasers, tempail, fakeinbox, gustr, inboxsync, imapenko, telcomail, wireinbox
- Contains @hotmail.co (typosquat domain)
- Local part is <= 4 characters
- Local part starts with 3+ digits
- Contains keyboard walk patterns (abc, bcd, cde ... xyz)
- Contains test/autobot/testemail/user123 patterns

### 2.3 Geographic Mismatch Detection

**What**: Detects customers whose registration country, IP country, and language preferences are inconsistent.
**Columns Involved**: CountryMismatchFlag, LanguageCountryMismatchFlag, Country, CountryByIP, ClientLanguage, ClientCommunicationLanguage
**Rules**:
- CountryMismatchFlag: 1 when registered Country != IP-detected CountryByIP
- LanguageCountryMismatchFlag: 18-country matrix checks both LanguageID and CommunicationLanguageID against expected language IDs for that country (e.g., Germany expects LanguageID IN (2,11,1,25))
- 36% of population triggers CountryMismatchFlag (532K out of 1.47M)

### 2.4 Verification Speed Anomalies

**What**: Detects suspiciously fast KYC verification level progression.
**Columns Involved**: Time_L0To_L1_Min, Time_L1To_L2_Min, Time_L2To_L3_Min, FastLOL1Flag, FastL1L2Flag, FastL2L3Flag, FastEVMatchFlag
**Rules**:
- FastL0L1/L1L2/L2L3 Flag = 1 when transition takes < 1 minute
- FastEVMatchFlag = 1 when RegisteredReal to EVMatchStatusDate <= 5 minutes
- Verification dates sourced from History.BackOfficeCustomer via MIN(ValidFrom) per VerificationLevelID

### 2.5 IP Clustering

**What**: Detects mass registration from shared IP addresses.
**Columns Involved**: RepeatedIPAddressFlag, ClusteredIP_RegistrationFlag
**Rules**:
- RepeatedIPAddressFlag: 1 when IP has >= 20 distinct RealCIDs in the 3-month window
- ClusteredIP_RegistrationFlag: 1 when IP has >= 20 registrations within the same rounded-to-second timestamp

### 2.6 Weighted Suspicious Score

**What**: Composite fraud risk score summing 15 individual signals.
**Columns Involved**: WeightedSuspiciousScore
**Rules** (each contributes 0 or 1 to the sum):
1. FakeFirstNameFlag=1 AND FakeLastNameFlag=1 (both names fake)
2. FakeEmailPatternFlag=1 AND PhoneVerifiedName='NotVerified' (fake email + no phone verification)
3. CountryTimeClusters ClusterCount > 10
4. InvalidDOBFlag
5. LanguageCountryMismatchFlag
6. CountryMismatchFlag
7. FastL0L1Flag
8. FastL1L2Flag
9. FastEVMatchFlag
10. RepeatedIPAddressFlag (IP with 20+ users)
11. Combo: FastL0L1 + FakeEmailPatternFlag
12. Combo: CountryMismatch + LanguageMismatch + FastEVMatch (<=1 min)
13. Combo: FakeEmail + (FakeFirstName OR FakeLastName)
14. Combo: IPRepeat + FakeEmail
15. Combo: CountryMismatch + FastL0L1 + FastL1L2

### 2.7 Document Upload Tracking

**What**: Checks whether proof documents exist in BackOffice.
**Columns Involved**: POIUploaded, POIDefined, POAUploaded, POADefined
**Rules**:
- POIUploaded: SuggestedDocumentTypeID = 2 (Proof of Identity) exists in CustomerDocument
- POIDefined: DocumentTypeID = 2 exists in CustomerDocumentToDocumentType
- POAUploaded: SuggestedDocumentTypeID = 1 (Proof of Address) exists
- POADefined: DocumentTypeID = 1 exists
- Uploaded = AI/user suggested type; Defined = reviewer-confirmed type

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN HEAP**: No distribution key — queries scan all distributions. For customer-specific lookups, filter on RealCID. For score-based analytics, filter on WeightedSuspiciousScore.
- No clustered index — full table scan for all queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find high-risk registrations | `WHERE WeightedSuspiciousScore >= 4` (3.8K rows, 0.26%) |
| Blocked customers with fraud flags | `WHERE PlayerStatus LIKE 'Blocked%' AND WeightedSuspiciousScore >= 2` |
| Country-level fraud rates | `GROUP BY Country` with `AVG(WeightedSuspiciousScore)` |
| Registration velocity anomalies | `WHERE FastLOL1Flag = 1 OR ClusteredIP_RegistrationFlag = 1` |
| Document compliance gaps | `WHERE VerificationLevelID >= 2 AND POIUploaded = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | dc.RealCID = fa.RealCID | Full customer profile enrichment |
| DWH_dbo.Dim_Country | dc.CountryID = fa.CountryID (via Dim_Customer) | Additional country attributes |

### 3.4 Gotchas

- **TotalDeposits is NULL, not 0**: Customers with no approved deposits have NULL TotalDeposits (LEFT JOIN). Use `ISNULL(TotalDeposits, 0)` for aggregations.
- **PlayerStatus has trailing spaces**: Live data shows padding (e.g., 'Blocked                                            '). Use `RTRIM(PlayerStatus)` or `LIKE 'Blocked%'`.
- **3-month rolling window is month-aligned**: The WHERE clause uses `DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1))`, meaning it always starts from the 1st of the month 3 months ago, not exactly 90 days.
- **VerificationLeveL0Date typo**: The 'L' in 'LeveL' is uppercase — match exactly in queries.
- **ClusteredIP_RegistrationFlag is always 0**: In current data, no IP had 20+ registrations within the same second. The threshold may be too strict.
- **DDL has no TotalCommissions column**: The SP computes TotalCommissions from BI_DB_CID_DailyPanel_FullData but the INSERT list does not include it — this data is computed but discarded.
- **UpdateDate is uniform**: All rows share the same GETDATE() timestamp (last run: 2026-04-12 07:03:40) due to TRUNCATE+INSERT pattern.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verbatim from upstream wiki (production source documented) | Upstream dimension/fact wiki |
| Tier 2 | Derived from SP code analysis | SP_OPS_Fraud_Alert_Analysis |
| Tier 3 | Inferred from data patterns and naming | Live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 2 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 3 | FirstName | varchar(max) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 4 | LastName | varchar(max) | YES | Legal last name in Unicode. Used in LinkedAccountHash1. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 5 | Email | varchar(max) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 6 | BirthDate | date | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 7 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer) |
| 8 | ClientLanguage | varchar(max) | YES | Language display name. Used in back-office language selectors and reporting. Dim-lookup passthrough from Dim_Language.Name via Dim_Customer.LanguageID. (Tier 1 -- Dictionary.Language) |
| 9 | ClientCommunicationLanguage | varchar(max) | YES | Language display name. Used in back-office language selectors and reporting. Dim-lookup passthrough from Dim_Language.Name via Dim_Customer.CommunicationLanguageID. (Tier 1 -- Dictionary.Language) |
| 10 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID. (Tier 1 -- Dictionary.Country) |
| 11 | CountryByIP | varchar(max) | YES | Full country name in English. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryIDByIP. Used for geographic mismatch detection. (Tier 1 -- Dictionary.Country) |
| 12 | EvMatchStatusName | varchar(max) | YES | Human-readable label for the EV match status. Values: None, PartiallyVerified, Verified, NotVerified. Dim-lookup passthrough from Dim_EvMatchStatus.EvMatchStatusName via Dim_Customer.EvMatchStatus. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 13 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Dim-lookup passthrough from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. (Tier 1 -- Dictionary.PlayerStatus) |
| 14 | IP | varchar(max) | YES | Registration IP address. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 15 | FakeFirstNameFlag | int | YES | 1 when FirstName matches 50+ suspicious patterns: gibberish (aaa-zzz triple repeats, all 26 letters), keyboard walks (qwert, asdf, bvbv, zxzx), sequential letters (abc-xyz, all 23 pairs), digits, non-alphabetic characters, test/fake/demo/sample keywords, length < 2, or FirstName = LastName. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 16 | FakeLastNameFlag | int | YES | 1 when LastName matches 40+ suspicious patterns: same logic as FakeFirstNameFlag (triple repeats, keyboard walks, digits, non-alpha, test/fake keywords, length < 2). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 17 | FakeEmailPatternFlag | int | YES | 1 when Email matches disposable domain patterns (mailinator, tempmail, yopmail, guerrillamail, sharklasers, etc.), keyboard walks, @hotmail.co typosquat, short local parts (<=4 chars), numeric-prefix local parts, or test/autobot keywords. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 18 | InvalidDOBFlag | int | YES | 1 when customer is under 18 (DATEDIFF(YEAR, BirthDate, GETDATE()) < 18) OR BirthDate equals registration date (CAST(RegisteredReal AS DATE)). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 19 | LanguageCountryMismatchFlag | int | YES | 1 when LanguageID or CommunicationLanguageID does not match the expected language IDs for the customer's country. 18-country matrix: Germany (2,11,1,25), France (7,1,25), Spain (6,1,25), Italy (8,1,25), UK (1,25), Russia (5,1,25), Turkey (1,11,25), Ukraine (5,1,25), Poland (17,1,25), Brazil (10,1,25), Mexico (7,1,25), China (4,1,18,25), India (11,1,25), Pakistan (121,25,1), Iran (13,1,25), Egypt (3,1,25), US (1,6,7,25), Vietnam (1,25,26). 0 for unlisted countries. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 20 | CountryMismatchFlag | int | YES | 1 when Country (registration) differs from CountryByIP (IP-detected). 0 when they match. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 21 | PhoneVerifiedName | varchar(max) | YES | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards. Dim-lookup passthrough from Dim_PhoneVerified.PhoneVerifiedName via Dim_Customer.PhoneVerifiedID. (Tier 1 -- Dictionary.PhoneVerified) |
| 22 | 2FA | int | YES | Two-factor authentication status. 0=disabled, 1=enabled. Derived from STS_Audit_UserOperationsData login type events. Preserves previous value when no new 2FA event exists. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer) |
| 23 | FailedEVMatchFlag | int | YES | 1 when EvMatchStatusName = 'NotVerified'. 0 otherwise. Derived from Dim_EvMatchStatus lookup. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 24 | VerificationLevel3Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=3 (fully verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL3. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 25 | VerificationLevel2Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=2 (intermediate). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL2. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 26 | VerificationLevel1Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=1 (partial). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL1. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 27 | VerificationLeveL0Date | datetime | YES | Earliest timestamp when the customer reached VerificationLevelID=0 (unverified). From MIN(ValidFrom) in History.BackOfficeCustomer. Note: column name has uppercase 'L' typo. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 28 | EVMatchStatusDate | datetime | YES | Earliest timestamp when the customer reached EvMatchStatus=2 (Verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached EV verified status. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 29 | Time_L0To_L1_Min | bigint | YES | Minutes between VL0 and VL1 verification dates. DATEDIFF(MINUTE, VerificationLeveL0Date, VerificationLevel1Date). NULL if either date is missing. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 30 | Time_L1To_L2_Min | bigint | YES | Minutes between VL1 and VL2 verification dates. DATEDIFF(MINUTE, VerificationLevel1Date, VerificationLevel2Date). NULL if either date is missing. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 31 | Time_L2To_L3_Min | bigint | YES | Minutes between VL2 and VL3 verification dates. DATEDIFF(MINUTE, VerificationLevel2Date, VerificationLevel3Date). NULL if either date is missing. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 32 | FastLOL1Flag | int | YES | 1 when VL0-to-VL1 transition took less than 1 minute (Time_L0To_L1_Min < 1). Indicates suspiciously fast initial verification. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 33 | FastL1L2Flag | int | YES | 1 when VL1-to-VL2 transition took less than 1 minute (Time_L1To_L2_Min < 1). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 34 | FastL2L3Flag | int | YES | 1 when VL2-to-VL3 transition took less than 1 minute (Time_L2To_L3_Min < 1). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 35 | FastEVMatchFlag | int | YES | 1 when EV match verification completed within 5 minutes of registration (DATEDIFF(MINUTE, RegisteredReal, EVMatchStatusDate) <= 5). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 36 | RepeatedIPAddressFlag | int | YES | 1 when the customer's registration IP has >= 20 distinct RealCIDs in the 3-month window. Indicates shared VPN/proxy or botnet origin. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 37 | WeightedSuspiciousScore | int | YES | Composite fraud risk score (0--15 scale). Sum of 15 binary signals: both-names-fake, fake-email+unverified-phone, country-time-cluster>10, InvalidDOB, LanguageMismatch, CountryMismatch, FastL0L1, FastL1L2, FastEVMatch, RepeatedIP, plus 5 combo flags. Higher = more suspicious. Distribution: 50% score=0, 28% score=1, 20% score=2, <2% score>=3. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 38 | Combo_FastRegistration_FakeEmail | int | YES | 1 when FastL0L1Flag=1 AND FakeEmailPatternFlag=1. Combined signal: suspiciously fast verification with disposable email. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 39 | Combo_SuspiciousDomain_FakeName | int | YES | 1 when FakeEmailPatternFlag=1 AND (FakeFirstNameFlag=1 OR FakeLastNameFlag=1). Combined signal: disposable email with fake name. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 40 | Combo_IPRepeat_FakeEmail | int | YES | 1 when IP has >= 20 users AND FakeEmailPatternFlag=1. Combined signal: shared IP with disposable email. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 41 | Combo_FastVerification_GeoMismatch | int | YES | 1 when CountryMismatchFlag=1 AND FastL0L1Flag=1 AND FastL1L2Flag=1. Combined signal: geographic mismatch with rapid verification. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 42 | ClusteredIP_RegistrationFlag | int | YES | 1 when the same IP has >= 20 registrations within the same second (DATETIME2(0) rounded). Indicates bot-driven mass registration. Currently all 0 in production (threshold may be too strict). (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 43 | GCID | bigint | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 44 | CountryTimeClustersFlag | int | YES | 1 when the customer's Country + CountryByIP + registration minute combination has > 10 registrations. Detects coordinated geographic registration bursts. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 45 | PlayerStatusReason | varchar(max) | YES | Human-readable reason label. Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Dim-lookup passthrough from Dim_PlayerStatusReasons.Name via Dim_Customer.PlayerStatusReasonID. (Tier 1 -- Dictionary.PlayerStatusReasons) |
| 46 | PlayerStatusSubReason | varchar(max) | YES | Human-readable sub-reason label (renamed from production Name). Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). Dim-lookup passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName via Dim_Customer.PlayerStatusSubReasonID. (Tier 1 -- Dictionary.PlayerStatusSubReasons) |
| 47 | Club | varchar(max) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough from Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) |
| 48 | TotalDeposits | float | YES | Sum of approved deposit amounts in USD (PaymentStatusID=2) from Fact_BillingDeposit. NULL if no approved deposits exist (LEFT JOIN). (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 49 | AffiliateID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 50 | IsDepositor | int | YES | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer) |
| 51 | IsValidCustomer | int | YES | DWH-computed: 1 when not Internal (PlayerLevelID!=4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer) |
| 52 | POIUploaded | int | YES | 1 when at least one document with SuggestedDocumentTypeID=2 (Proof of Identity) exists in BackOffice.CustomerDocument for this customer. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 53 | POIDefined | int | YES | 1 when at least one document with DocumentTypeID=2 (Proof of Identity) exists in BackOffice.CustomerDocumentToDocumentType for this customer. Defined = reviewer-confirmed type (vs Uploaded = AI/user-suggested). 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 54 | POAUploaded | int | YES | 1 when at least one document with SuggestedDocumentTypeID=1 (Proof of Address) exists in BackOffice.CustomerDocument. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 55 | POADefined | int | YES | 1 when at least one document with DocumentTypeID=1 (Proof of Address) exists in BackOffice.CustomerDocumentToDocumentType. 0 otherwise. (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |
| 56 | UpdateDate | datetime | NO | ETL load timestamp. GETDATE() at SP execution time. Uniform across all rows (TRUNCATE+INSERT). (Tier 2 -- SP_OPS_Fraud_Alert_Analysis) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID (via Dim_Customer) | Passthrough (renamed) |
| Country | Dictionary.Country | Name (via Dim_Country) | Dim-lookup passthrough |
| PlayerStatus | Dictionary.PlayerStatus | Name (via Dim_PlayerStatus) | Dim-lookup passthrough |
| FakeFirstNameFlag | Customer.CustomerStatic | FirstName (via Dim_Customer) | 50+ LIKE pattern CASE |
| WeightedSuspiciousScore | Multiple sources | Multiple | Sum of 15 binary flags |
| TotalDeposits | Billing.Deposit | AmountUSD (via Fact_BillingDeposit) | SUM WHERE PaymentStatusID=2 |
| VerificationLevel3Date | History.BackOfficeCustomer | ValidFrom | MIN WHERE VL=3 |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (primary, 3-month filter on RegisteredReal)
  + DWH_dbo.Dim_Country (x2: Country, CountryByIP)
  + DWH_dbo.Dim_Language (x2: ClientLanguage, CommLanguage)
  + DWH_dbo.Dim_EvMatchStatus, Dim_PlayerStatus, Dim_PhoneVerified
  |-- #SuspiciousRegistrations (fraud flags computed via CASE) ---|
  |
  + general.etoro_History_BackOfficeCustomer
  |-- #firstVer (VL dates via MIN) ---|
  |
  + External_etoro_BackOffice_CustomerDocument
  + External_etoro_BackOffice_CustomerDocumentToDocumentType
  |-- #DOCS → #poiuploaded, #poidefined, #poauploaded, #poadefined ---|
  |
  + DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2)
  |-- #deposits (SUM AmountUSD) ---|
  |
  + BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  |-- #commissions (SUM Revenue_Total — NOT inserted, discarded) ---|
  |
  + DWH_dbo.Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons, Dim_PlayerLevel
  + #IPCounts, #IP_Minute_Group, #CountryTimeClusters
  |-- #finaltable (all columns assembled) ---|
  v
TRUNCATE BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis
INSERT FROM #finaltable (~1.47M rows)
  |
  |-- Generic Pipeline (Override, parquet, daily) ---|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension master (RealCID = RealCID) |
| Country | DWH_dbo.Dim_Country | Country name from CountryID |
| CountryByIP | DWH_dbo.Dim_Country | IP-detected country name from CountryIDByIP |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Account restriction status |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EV identity verification status |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | Phone verification state |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Status change reason |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | Status change sub-reason |
| Club | DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| TotalDeposits | DWH_dbo.Fact_BillingDeposit | Aggregated approved deposits |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo. This is an operational reporting endpoint.

---

## 7. Sample Queries

### 7.1 High-Risk Registration Summary by Country

```sql
SELECT
    Country,
    COUNT(*) AS total_registrations,
    SUM(CASE WHEN WeightedSuspiciousScore >= 3 THEN 1 ELSE 0 END) AS high_risk,
    AVG(CAST(WeightedSuspiciousScore AS FLOAT)) AS avg_score
FROM BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis
GROUP BY Country
HAVING COUNT(*) >= 1000
ORDER BY avg_score DESC
```

### 7.2 Fraud Signal Prevalence Analysis

```sql
SELECT
    SUM(FakeFirstNameFlag) AS fake_first_name,
    SUM(FakeLastNameFlag) AS fake_last_name,
    SUM(FakeEmailPatternFlag) AS fake_email,
    SUM(CountryMismatchFlag) AS country_mismatch,
    SUM(LanguageCountryMismatchFlag) AS language_mismatch,
    SUM(RepeatedIPAddressFlag) AS repeated_ip,
    SUM(CountryTimeClustersFlag) AS country_time_cluster,
    COUNT(*) AS total
FROM BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis
```

### 7.3 Blocked Customers with Document Gaps

```sql
SELECT
    RealCID, RTRIM(PlayerStatus) AS PlayerStatus,
    PlayerStatusReason, PlayerStatusSubReason,
    WeightedSuspiciousScore,
    POIUploaded, POIDefined, POAUploaded, POADefined,
    ISNULL(TotalDeposits, 0) AS TotalDeposits
FROM BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis
WHERE PlayerStatus LIKE 'Blocked%'
  AND WeightedSuspiciousScore >= 3
  AND (POIUploaded = 0 OR POAUploaded = 0)
ORDER BY WeightedSuspiciousScore DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 14 T1, 40 T2, 0 T3, 0 T4, 0 T5 | Elements: 56/56, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis | Type: Table | Production Source: SP_OPS_Fraud_Alert_Analysis*
