# BI_DB_dbo.BI_DB_AML_Documents_Request

> Daily AML compliance workbench — a denormalized per-customer snapshot of document status, risk profile, and financial context for all active, KYC-eligible customers (non-blocked, VerificationLevelID ≥ 2), used by the AML team to identify document gaps and review customer risk exposure.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AML_Documents_Request |
| **OpsDB Priority** | 0 (no intra-schema dependencies) |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild) |
| **Author** | Lior Ben Dor (2025-01-08) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Rows** | ~31M total / ~16.4M distinct CIDs (multi-regulation: each customer appears once per regulatory entity) |
| | |
| **UC Target** | Not migrated |

---

## 1. Business Meaning

BI_DB_AML_Documents_Request is the AML team's daily working view of all customers who need document review. Each row represents one customer under one regulatory entity, capturing their complete KYC and AML status in a single denormalized record: who they are (regulation, country, age, account type), how they're classified (AML risk rank, RiskScoreName, screening status, EV status), and exactly what documents they've submitted (type, date, and AI-suggested type for each of 5 document categories).

The table answers two key compliance questions without any JOIN overhead: "Which customers have document gaps?" (Has_POI=0, Has_POA=0, missing document dates) and "Which customers are high-risk and why?" (AML_Rank, Is_HRC, RiskScoreName, ScreeningStatus, PlayerStatus).

Population scope is all active, non-blocked eToro customers who have progressed past basic registration (VerificationLevelID > 1). Blocked (PlayerStatusID=2) and BUR — Blocked Upon Request (PlayerStatusID=4) — customers are explicitly excluded via the INNER JOIN on Dim_PlayerStatus. The ~16.4M distinct CIDs span all eToro regulatory entities (CySEC, FCA, BVI, ASIC, etc.); a customer registered under multiple regulations appears as one row per regulation, sharing the same CID.

The 5 document categories covered are: Proof of Identity (POI), Proof of Address (POA), Proof of Income (POIncome), Selfie/SelfieLiveliness/Selfie Motion (Selfie), and VideoIdent. For each, the table stores the most recent ACCEPTED document (rejected documents are excluded via RejectReasonName IS NULL filter), surfacing the assigned DocumentType, the date added, and the AI-suggested DocumentType.

SP_W_AML_PEP_Customers (weekly PEP report) reads this table as a source, joining on DocumentDateAdded_Selfie and DocumentDateAdded_POIncome to check Selfie and Source of Funds document freshness for PEP customers.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: The table includes only active, partially-or-fully verified, non-blocked customers.

**Columns Involved**: `CID`, `VerificationLevelID`, `PlayerStatus`

**Rules**:
- `IsValidCustomer = 1`: Only valid, non-test accounts from Dim_Customer.
- `VerificationLevelID > 1`: Customers must have advanced past basic registration (level 1 = registered only). Level 2 = partially verified, Level 3 = fully verified.
- `PlayerStatusID NOT IN (2, 4)`: Blocked (2) and BUR — Blocked Upon Request (4) — customers are excluded via the INNER JOIN on Dim_PlayerStatus. These represent the most serious account restrictions where AML document requests are no longer relevant.
- Customers in other PlayerStatus values (Normal, Chat Blocked, Warning, Under Investigation, etc.) are included.

### 2.2 AML Risk Classification

**What**: Three complementary risk dimensions are stored for each customer.

**Columns Involved**: `AML_Rank`, `Is_HRC`, `RiskScoreName`, `ScreeningStatus`

**Rules**:
- **AML_Rank** (from Dim_Country.RiskGroupID): Country-level risk tier. 0=None (not-high-risk), 1=High risk country, 2=High risk new clients, 3=High risk FATF jurisdictions, 4=Verified before deposit (not-high-risk, special compliance requirement).
- **Is_HRC** (computed): Binary flag. 1 if AML_Rank IN (1,2,3) — i.e., the customer's KYC country is a High Risk Country. AML_Rank 0 and 4 produce Is_HRC=0. This is the primary HRC filter for AML workflows.
- **RiskScoreName** (from External_RiskClassification): Named AML risk level from the RiskClassification system (e.g., "Low", "Medium", "High", "Very High"). Independent of country-based AML_Rank — this is a customer-level composite score. NULL if the customer has no RiskClassification record.
- **ScreeningStatus** (from Dim_ScreeningStatus): World-Check screening result. NULL means no screening status assigned. Key value: 'PEP' (Politically Exposed Person) triggers the weekly PEP report (SP_W_AML_PEP_Customers).

### 2.3 Document Evidence Logic

**What**: For each of 5 document categories, the table captures the most recent accepted document.

**Columns Involved**: `DocumentType_*`, `DocumentDateAdded_*`, `SuggestedDocumentType_*`, `last_document_upload`

**Rules**:
- **Accepted only**: Documents where `RejectReasonName IS NULL` are included. Rejected documents are filtered out.
- **Most recent**: When a customer has multiple documents of the same type, only the most recent (by DateAdded DESC) is retained per category (ROW_NUMBER = 1 per CID).
- **Two-way type matching**: A document qualifies for a category if EITHER the formally assigned type (DocumentType via CustomerDocumentToDocumentType) OR the AI-suggested type (SuggestedDocumentTypeID → DocumentType.Name via SuggestedDocumentTypeID) matches the category name. This means a document pending review (assigned type not yet set) can still appear if its AI suggestion matches.
- **Selfie category** covers three names: `'Selfie'`, `'SelfieLiveliness'`, and `'Selfie Motion'`.
- `last_document_upload` = MAX(DateAdded) across ALL document types — the date of the customer's most recent upload regardless of type.

### 2.4 POI/POA Flags from Dim_Customer

**What**: Has_POI/Has_POA and their expiry dates come from Dim_Customer (SP_Dim_Customer), NOT from the document counts in the CustomerDocument table.

**Columns Involved**: `Has_POI`, `POI_ExpiryDate`, `Has_POA`, `POA_ExpiryDate`

**Rules**:
- `Has_POI = Dim_Customer.IsIDProof`: 1 if the customer has an approved Proof of Identity document on record in the BackOffice system. NULL if not computed for this customer.
- `POI_ExpiryDate = Dim_Customer.IsIDProofExpiryDate`: Expiry date of the current accepted POI document. NULL if no POI or no expiry date recorded.
- `Has_POA = Dim_Customer.IsAddressProof`: Same pattern for Proof of Address.
- `POA_ExpiryDate = Dim_Customer.IsAddressProofExpiryDate`: Expiry date of the current accepted POA document.
- These differ from `DocumentType_POI/DocumentDateAdded_POI` — those fields show the most recent POI document from the CustomerDocument table, while `Has_POI`/`POI_ExpiryDate` reflect the approved verification state stored in Dim_Customer.

### 2.5 ETL Pattern

**What**: Full daily rebuild via TRUNCATE + INSERT.

**Rules**:
- No date parameters — SP always rebuilds the full table from scratch.
- Priority 0 in OpsDB: SP_AML_Documents_Request runs first in the daily SB_Daily batch, before any downstream tables that depend on it.
- `UpdateDate = GETDATE()` at INSERT time — all rows share the same timestamp per daily run.
- Multi-regulation fan-out: a customer with multiple regulatory registrations generates one row per regulation due to the Dim_Customer join on RegulationID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP. No distribution key — queries that filter by CID will require a broadcast. For CID-specific lookups, ensure the query filters early to reduce data movement. For analytical queries on the full population (e.g., COUNT by AML_Rank), the distribution is acceptable.

### 3.2 Multi-Regulation Awareness

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count distinct customers (not rows) | COUNT(DISTINCT CID) — not COUNT(*) |
| Find a specific customer | WHERE CID = @CID (may return multiple rows, one per regulation) |
| Deduplicate to one row per customer | ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Regulation) = 1 or filter by Regulation |
| Find customers with missing POI | WHERE Has_POI = 0 OR Has_POI IS NULL |
| Find HRC customers | WHERE Is_HRC = 1 (AML_Rank IN 1,2,3) |
| Find PEP customers | WHERE ScreeningStatus = 'PEP' |
| Check if documents are fresh | WHERE DocumentDateAdded_POI >= DATEADD(YEAR,-5,GETDATE()) |
| Latest run date | SELECT MAX(UpdateDate) FROM BI_DB_dbo.BI_DB_AML_Documents_Request |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| No joins required for most analytics — this table is pre-denormalized | | |
| DWH_dbo.Dim_Customer | ON dc.RealCID = adr.CID | Extend with raw customer attributes not in this table |
| BI_DB_dbo.BI_DB_W_AML_PEP_Customers | ON wpep.CID = adr.CID | Join weekly PEP report data |
| BI_DB_dbo.BI_DB_AMLPeriodicReview | ON apr.RealCID = adr.CID | Combine with periodic review queue |

### 3.4 Gotchas

- **~31M rows**: Use WHERE CID = @CID for customer lookups; do not COUNT(*) or SELECT * without a filter in SSMS.
- **Duplicates per CID by design**: Each regulatory registration generates a row. A CID appearing twice is correct if the customer is registered under 2 regulations.
- **NULL vs 0**: `Has_POI`, `Has_POA`, `VerificationLevelID` can be NULL (not 0) for some customers. Always use `ISNULL(Has_POI, 0)` or `Has_POI IS NULL` in WHERE clauses.
- **ScreeningStatus NULL**: A NULL ScreeningStatus means no screening record, not "No Match". Filter `WHERE ScreeningStatus = 'NoMatch'` to find explicitly cleared customers.
- **Last_Login_Date is INT YYYYMMDD**: Not a date column — cast to DATE with `CAST(CONVERT(VARCHAR(8), Last_Login_Date) AS DATE)` for date math.
- **Selfie category width**: Selfie, SelfieLiveliness, and Selfie Motion are all counted under DocumentType_Selfie / DocumentDateAdded_Selfie.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ***** | Tier 1 - upstream wiki verbatim | varies by source |
| **** | Tier 2 - SP code / DWH wiki | (Tier 2 - SP_AML_Documents_Request) |
| *** | Tier 3 - live data inference | (Tier 3 - live data) |
| — | Propagation blacklist | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer account ID — eToro RealCID. Unique per customer per regulatory entity; a customer registered under multiple regulations appears as one row per regulation. FK to Customer.CustomerStatic. Population limited to IsValidCustomer=1, VerificationLevelID>1, PlayerStatusID NOT IN(2,4). (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 2 | Regulation | nvarchar(250) | YES | Regulatory entity under which this customer row is registered. Values: CySEC (Cyprus), FCA (UK), BVI (British Virgin Islands), ASIC (Australia), FINRA (USA), FSA (Seychelles), etc. One row per CID per Regulation. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | Country | nvarchar(250) | YES | Customer's KYC country of residence — the country used for regulatory classification. Sourced from Dim_Country.Name via Dim_Customer.CountryID. This is the same country used for AML_Rank and Is_HRC classification. (Tier 1 - upstream wiki, Dictionary.Country) |
| 4 | AML_Rank | int | YES | Country-level AML risk tier from Dim_Country.RiskGroupID. Values: 0=None (standard-risk country), 1=High risk country, 2=High risk new clients, 3=High risk FATF jurisdictions (8 countries), 4=Verified before deposit (not high-risk, special compliance requirement, e.g., Israel). Is_HRC flag uses AML_Rank IN(1,2,3). (Tier 1 - upstream wiki, Dim_Country) |
| 5 | Is_HRC | int | YES | Binary High Risk Country flag. 1 if AML_Rank IN(1,2,3); 0 if AML_Rank is 0 or 4. Computed: CASE WHEN AML_Rank IN (1,2,3) THEN 1 ELSE 0 END. Primary HRC filter for AML workflows — use this instead of filtering on AML_Rank directly. (Tier 2 - SP_AML_Documents_Request) |
| 6 | CitizenshipCountry | nvarchar(250) | YES | Customer's country of citizenship from Dim_Customer.CitizenshipCountryID. NULL if not recorded. Used for additional nationality-based AML screening (a customer residing in a low-risk country may hold citizenship from a high-risk country). (Tier 1 - upstream wiki, Dictionary.Country) |
| 7 | POBCountry | nvarchar(250) | YES | Customer's place of birth country from Dim_Customer.POBCountryID. NULL if not recorded. Used in PEP screening and AML questionnaires where birth country is a risk signal independent of residency and citizenship. (Tier 1 - upstream wiki, Dictionary.Country) |
| 8 | PlayerStatus | nvarchar(250) | YES | Customer's current account restriction status name. Values: Normal, Chat Blocked, Warning, Under Investigation, Scalpers Block, PayPal Investigation, Trade & MIMO Blocked, Deposit Blocked, Social Index, Copy Block, Pending Verification, Failed Verification, Block Deposit & Trading. Note: Blocked (2) and BUR (4) are excluded from this table by the INNER JOIN population filter. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 9 | PlayerStatusReason | nvarchar(250) | YES | Broad reason category for the customer's current PlayerStatus change. NULL if no reason was recorded (PlayerStatusReasonID=0). Values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), Abusive Trading (34), Hacked Account (35), Tax (41), etc. (44 total). (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 10 | PlayerStatusSubReasonName | nvarchar(250) | YES | Granular sub-reason for the PlayerStatus change, providing second-level detail beneath PlayerStatusReason. NULL if no sub-reason recorded. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, SAR=Suspicious Activity Report, WCH=World Check, PEP=Politically Exposed Person. 83 values total (IDs 0-82). (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 11 | Club | nvarchar(250) | YES | Customer loyalty tier / club name from Dim_PlayerLevel. Values: Silver, Gold, Platinum, Diamond, etc. Reflects the customer's trading volume-based VIP status. NULL rare (INNER JOIN on Dim_PlayerLevel). (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 12 | RiskScoreName | nvarchar(250) | YES | Named AML risk level from the RiskClassification system — a customer-level composite AML score independent of country risk. Source: RiskClassification.dbo.V_RiskClassificationDataLake via External_RiskClassification_dbo_V_RiskClassificationDataLake. NULL if no RiskClassification record exists for this customer. Values observed: Low, Medium, High, Very High. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake) |
| 13 | ScreeningStatus | nvarchar(250) | YES | World-Check AML screening outcome name. NULL = no screening record. Values: Unknown, NoMatch, PendingInvestigation, PEP (Politically Exposed Person), RiskMatch, Technical, MultipleMatch, SanctionsMatch. PEP triggers the weekly SP_W_AML_PEP_Customers report. (Tier 3 - live data, Dim_ScreeningStatus) |
| 14 | AccountType | nvarchar(250) | YES | Account category name. Values: Private, Corporate, IB Account, Joint Account, White Label, Affiliate Private, Employee, Custodian, Fund, eToro Group, News, White List, Analyst, SMSF, Affiliate Corporate, Administrated, Funded Employee, Trust (18 types). (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 15 | EvMatchStatusName | nvarchar(250) | YES | Electronic Verification (EV) match outcome name. Values: None (0), PartiallyVerified (1), Verified (2), NotVerified (3). Source: Dim_EvMatchStatus via Dim_Customer.EvMatchStatus. NULL if LEFT JOIN finds no record. (Tier 2 - SP_AML_Documents_Request via Dim_EvMatchStatus) |
| 16 | FirstDepositDate | datetime | YES | Date and time of the customer's first deposit. NULL if never deposited (IsDepositor=0). Computed by SP_Dim_Customer. Used in Periodic Review to calculate review due dates (3-year anniversary from FTD). (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 17 | RegisteredReal | datetime | YES | Timestamp when the customer's real (live trading) account was created. Sourced from Customer.CustomerStatic in the production etoro database. Distinct from the demo account creation date. (Tier 1 - Customer.CustomerStatic via Dim_Customer) |
| 18 | HasWallet | int | YES | Flag indicating whether the customer has an eToro Money (crypto wallet) account. 1=yes, 0=no. Sourced from BackOffice.Customer in production. NULL if not computed. (Tier 1 - BackOffice.Customer via Dim_Customer) |
| 19 | IsDepositor | int | YES | Flag indicating whether the customer has ever made a deposit. 1=yes, 0=no. Computed by SP_Dim_Customer from deposit transaction history. Customers with IsDepositor=0 have no deposit history as of the last Dim_Customer refresh. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 20 | VerificationLevelID | int | YES | KYC verification level. Always > 1 due to population filter. Values in this table: 2=partially verified (entered KYC flow), 3=fully verified (all KYC documents approved). Sourced from BackOffice.Customer. (Tier 1 - BackOffice.Customer via Dim_Customer) |
| 21 | Age | int | YES | Customer age in years at the time of the SP run, computed as DATEDIFF(YEAR, Dim_Customer.BirthDate, GETDATE()). Recalculated on every daily refresh — not a stored age. NULL if BirthDate is NULL in Dim_Customer. (Tier 2 - SP_AML_Documents_Request) |
| 22 | Equity | money | YES | Customer's current total equity: Liabilities + ActualNWA from DWH_dbo.V_Liabilities for the prior business day (DateID = yesterday). ISNULL → 0 if the customer has no V_Liabilities record. Represents the customer's net financial exposure in USD. (Tier 2 - SP_AML_Documents_Request via V_Liabilities) |
| 23 | Total_Deposits | money | YES | Lifetime total of all approved deposit transactions in USD. Sum of Fact_CustomerAction.Amount WHERE ActionTypeID=7 (Deposits), all-time (no date filter). ISNULL → 0 if no deposits. Used for AML thresholds and economic profile checks. (Tier 2 - SP_AML_Documents_Request via Fact_CustomerAction) |
| 24 | Last_Login_Date | int | YES | Date of the customer's most recent login, stored as INT in YYYYMMDD format. Derived from MAX(Fact_CustomerAction.DateID) WHERE ActionTypeID=14 (LoggedIn). NULL if the customer has no recorded login actions. Cast to DATE with CAST(CONVERT(VARCHAR(8), Last_Login_Date) AS DATE). (Tier 2 - SP_AML_Documents_Request via Fact_CustomerAction) |
| 25 | Has_Open_position | int | YES | Flag indicating whether the customer had at least one open position as of yesterday. 1=yes (CID found in BI_DB_PositionPnL for yesterday's DateID), 0=no open positions. (Tier 2 - SP_AML_Documents_Request via BI_DB_PositionPnL) |
| 26 | last_document_upload | datetime | YES | Timestamp of the customer's most recent document upload of ANY type. MAX(BackOffice.CustomerDocument.DateAdded) across all documents for this CID. NULL if the customer has never uploaded a document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 27 | Has_POI | int | YES | Flag indicating whether the customer has a currently approved Proof of Identity document. 1=approved POI on file, 0=no approved POI. Sourced from Dim_Customer.IsIDProof (computed by SP_Dim_Customer from the BackOffice document approval workflow). NULL if not computed. Distinct from DocumentDateAdded_POI which shows the most recent upload date regardless of approval state. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 28 | POI_ExpiryDate | datetime | YES | Expiry date of the customer's currently approved Proof of Identity document. NULL if no POI on file or no expiry date recorded. Sourced from Dim_Customer.IsIDProofExpiryDate. Documents past this date may need renewal for ongoing compliance. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 29 | DocumentType_POI | nvarchar(250) | YES | Formally assigned document type name for the most recent accepted Proof of Identity document. Value from Dictionary.DocumentType.Name via External_etoro_BackOffice_CustomerDocumentToDocumentType. Typically 'Proof of Identity'. NULL if no accepted POI document found. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 30 | DocumentDateAdded_POI | datetime | YES | Upload date of the most recent accepted Proof of Identity document (BackOffice.CustomerDocument.DateAdded). Most recent by DateAdded DESC where (assigned type OR suggested type) = 'Proof of Identity' AND reject reason IS NULL. NULL if no accepted POI document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 31 | SuggestedDocumentType_POI | nvarchar(250) | YES | AI-vendor suggested document type name (Au10tix/Onfido) for the most recent accepted POI document, from Dictionary.DocumentType.Name via BackOffice.CustomerDocument.SuggestedDocumentTypeID. May differ from DocumentType_POI if the BackOffice agent overrode the AI suggestion. NULL if no accepted POI document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 32 | Has_POA | int | YES | Flag indicating whether the customer has a currently approved Proof of Address document. 1=approved POA on file, 0=no approved POA. Sourced from Dim_Customer.IsAddressProof. NULL if not computed. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 33 | POA_ExpiryDate | datetime | YES | Expiry date of the customer's currently approved Proof of Address document. NULL if no POA on file or no expiry recorded. Sourced from Dim_Customer.IsAddressProofExpiryDate. POA documents (utility bills, bank statements) typically expire after 3 months under FCA/CySEC requirements. (Tier 2 - SP_Dim_Customer via Dim_Customer) |
| 34 | DocumentType_POA | nvarchar(250) | YES | Formally assigned document type name for the most recent accepted Proof of Address document. Typically 'Proof of address'. NULL if no accepted POA document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 35 | DocumentDateAdded_POA | datetime | YES | Upload date of the most recent accepted Proof of Address document. Most recent by DateAdded DESC where (assigned type OR suggested type) = 'Proof of address' AND reject reason IS NULL. NULL if no accepted POA document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 36 | SuggestedDocumentType_POA | nvarchar(250) | YES | AI-vendor suggested document type name for the most recent accepted POA document. NULL if no accepted POA document. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 37 | DocumentType_POIncome | nvarchar(250) | YES | Formally assigned document type name for the most recent accepted Proof of Income document. Typically 'Proof of Income'. NULL if no accepted Proof of Income document found. Required for HRC (Is_HRC=1) customers and high-deposit customers per AML policy. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 38 | DocumentDateAdded_POIncome | datetime | YES | Upload date of the most recent accepted Proof of Income document. NULL if none. Read by SP_W_AML_PEP_Customers to determine SOF (Source of Funds) document freshness for PEP customers (valid if within last 12 months). (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 39 | SuggestedDocumentType_POIncome | nvarchar(250) | YES | AI-vendor suggested document type name for the most recent accepted Proof of Income document. NULL if none. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 40 | DocumentType_Selfie | nvarchar(250) | YES | Formally assigned document type name for the most recent accepted Selfie document. Covers three type names: 'Selfie', 'SelfieLiveliness', and 'Selfie Motion'. NULL if no accepted Selfie document. Required for PEP customers (SP_W_AML_PEP_Customers checks Has_Selfie from this column). (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 41 | DocumentDateAdded_Selfie | datetime | YES | Upload date of the most recent accepted Selfie document (any of 'Selfie', 'SelfieLiveliness', 'Selfie Motion'). NULL if none. Read by SP_W_AML_PEP_Customers to check Selfie freshness for PEP customers (valid if within last 12 months). (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 42 | SuggestedDocumentType_Selfie | nvarchar(250) | YES | AI-vendor suggested document type name for the most recent accepted Selfie document. NULL if none. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 43 | DocumentType_VideoIdent | nvarchar(250) | YES | Formally assigned document type name for the most recent accepted VideoIdent document. Typically 'VideoIdent'. NULL if no VideoIdent document found. VideoIdent is a video-based identity verification used as an alternative or supplement to static document uploads (e.g., for German AML requirements). (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 44 | DocumentDateAdded_VideoIdent | datetime | YES | Upload date of the most recent accepted VideoIdent document. NULL if none. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 45 | SuggestedDocumentType_VideoIdent | nvarchar(250) | YES | AI-vendor suggested document type name for the most recent accepted VideoIdent document. NULL if none. (Tier 2 - SP_AML_Documents_Request via External_etoro_BackOffice_CustomerDocument) |
| 46 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE() at INSERT time). All rows share the same timestamp per daily run. Not a business date — reflects SP execution time. (Propagation blacklist — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Passthrough via Dim_Customer.RealCID |
| Regulation | etoro.Dictionary.Regulation | Name | Lookup via Dim_Regulation |
| Country | etoro.Dictionary.Country | Name | Lookup via Dim_Country (CountryID) |
| AML_Rank | etoro.Dictionary.Country | RiskGroupID | Lookup via Dim_Country (CountryID) |
| Is_HRC | — | AML_Rank | SP-computed: CASE WHEN AML_Rank IN(1,2,3) THEN 1 ELSE 0 END |
| CitizenshipCountry | etoro.Dictionary.Country | Name | Lookup via Dim_Country (CitizenshipCountryID); LEFT JOIN |
| POBCountry | etoro.Dictionary.Country | Name | Lookup via Dim_Country (POBCountryID); LEFT JOIN |
| PlayerStatus | etoro.Dictionary.PlayerStatus | Name | Lookup via Dim_PlayerStatus (INNER, excludes 2,4) |
| PlayerStatusReason | etoro.Dictionary.PlayerStatusReasons | Name | Lookup via Dim_PlayerStatusReasons; LEFT JOIN |
| PlayerStatusSubReasonName | etoro.Dictionary.PlayerStatusSubReasons | Name | Lookup via Dim_PlayerStatusSubReasons; LEFT JOIN; renamed |
| Club | etoro.Dictionary.PlayerLevel | Name | Lookup via Dim_PlayerLevel |
| RiskScoreName | RiskClassification.dbo.V_RiskClassificationDataLake | RiskScoreName | Passthrough via External_RiskClassification; LEFT JOIN |
| ScreeningStatus | (no upstream wiki) | Name | Lookup via Dim_ScreeningStatus; LEFT JOIN |
| AccountType | etoro.Dictionary.AccountType | Name | Lookup via Dim_AccountType; LEFT JOIN |
| EvMatchStatusName | (UserApiDB.Dictionary.EvMatchStatus — no upstream wiki) | EvMatchStatusName | Lookup via Dim_EvMatchStatus; LEFT JOIN |
| FirstDepositDate | etoro.BackOffice.Customer / Billing | — | SP_Dim_Customer computed; passthrough via Dim_Customer |
| RegisteredReal | etoro.Customer.CustomerStatic | RegisteredReal | Passthrough via Dim_Customer |
| HasWallet | etoro.BackOffice.Customer | HasWallet | Passthrough via Dim_Customer |
| IsDepositor | — | — | SP_Dim_Customer computed; passthrough via Dim_Customer |
| VerificationLevelID | etoro.BackOffice.Customer | VerificationLevelID | Passthrough via Dim_Customer |
| Age | etoro.Customer.CustomerStatic | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | SP aggregate for yesterday's DateID |
| Total_Deposits | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| Last_Login_Date | DWH_dbo.Fact_CustomerAction | DateID | MAX WHERE ActionTypeID=14 |
| Has_Open_position | BI_DB_dbo.BI_DB_PositionPnL | CID | EXISTS check for yesterday |
| last_document_upload | etoro.BackOffice.CustomerDocument | DateAdded | MAX across all doc types per CID |
| Has_POI | etoro.BackOffice.Customer | IsIDProof | SP_Dim_Customer computed; Dim_Customer.IsIDProof |
| POI_ExpiryDate | etoro.BackOffice.Customer | IsIDProofExpiryDate | Dim_Customer.IsIDProofExpiryDate |
| DocumentType_POI | etoro.Dictionary.DocumentType | Name | Most recent accepted POI doc assigned type |
| DocumentDateAdded_POI | etoro.BackOffice.CustomerDocument | DateAdded | Most recent accepted POI doc upload date |
| SuggestedDocumentType_POI | etoro.Dictionary.DocumentType | Name | Most recent accepted POI doc AI-suggested type |
| Has_POA | etoro.BackOffice.Customer | IsAddressProof | Dim_Customer.IsAddressProof |
| POA_ExpiryDate | etoro.BackOffice.Customer | IsAddressProofExpiryDate | Dim_Customer.IsAddressProofExpiryDate |
| DocumentType_POA–SuggestedDocumentType_POA | (same pattern as POI) | — | Most recent accepted POA doc |
| DocumentType_POIncome–SuggestedDocumentType_POIncome | (same pattern as POI) | — | Most recent accepted Proof of Income doc |
| DocumentType_Selfie–SuggestedDocumentType_Selfie | (same pattern as POI) | — | Most recent accepted Selfie/SelfieLiveliness/Selfie Motion doc |
| DocumentType_VideoIdent–SuggestedDocumentType_VideoIdent | (same pattern as POI) | — | Most recent accepted VideoIdent doc |
| UpdateDate | — | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.* (Regulation, Country, PlayerStatus, PlayerStatusReasons,
                    PlayerStatusSubReasons, PlayerLevel, AccountType)
  -> Generic Pipeline (daily)
  -> DWH_dbo.Dim_* (dimension tables)
  -> SP_AML_Documents_Request (#pop step)
  -> BI_DB_dbo.BI_DB_AML_Documents_Request

etoro.BackOffice.CustomerDocument + CustomerDocumentToDocumentType + Dictionary.DocumentType
  -> External_etoro_BackOffice_CustomerDocument / External_etoro_BackOffice_CustomerDocumentToDocumentType
  -> External_etoro_Dictionary_DocumentType
  -> SP_AML_Documents_Request (#Proof_of_Identity/Address/Selfie/Income/VideoIdent steps)
  -> BI_DB_dbo.BI_DB_AML_Documents_Request

RiskClassification.dbo.V_RiskClassificationDataLake
  -> External_RiskClassification_dbo_V_RiskClassificationDataLake
  -> SP_AML_Documents_Request (#pop step, LEFT JOIN)
  -> BI_DB_dbo.BI_DB_AML_Documents_Request

DWH_dbo.V_Liabilities + Fact_CustomerAction + BI_DB_PositionPnL
  -> SP_AML_Documents_Request (#equity, #lastLogin, #open_position, #deposits steps)
  -> BI_DB_dbo.BI_DB_AML_Documents_Request
```

| Step | Object | Description |
|------|--------|-------------|
| Sources | Dim_Customer + 10 dimension tables + External tables | Population build with all dimension lookups |
| ETL | SP_AML_Documents_Request (Priority 0, Daily) | 6-step temp table pipeline then TRUNCATE+INSERT |
| Target | BI_DB_dbo.BI_DB_AML_Documents_Request | ~31M rows, ROUND_ROBIN HEAP |

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | RealCID, RegulationID, CountryID, CitizenshipCountryID, POBCountryID, PlayerStatusID, PlayerLevelID, ScreeningStatusID, AccountTypeID, EvMatchStatus, PlayerStatusReasonID, PlayerStatusSubReasonID, VerificationLevelID, IsDepositor, HasWallet, RegisteredReal, FirstDepositDate, BirthDate, IsIDProof, IsIDProofExpiryDate, IsAddressProof, IsAddressProofExpiryDate | Customer population base and all customer-level attributes |
| DWH_dbo.Dim_Regulation | Name | Regulation label |
| DWH_dbo.Dim_Country | Name, RiskGroupID | Country name (x3: residence, citizenship, POB) and AML_Rank |
| DWH_dbo.Dim_PlayerStatus | Name | Status name (INNER JOIN, excludes Blocked/BUR) |
| DWH_dbo.Dim_PlayerStatusReasons | Name | Status reason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Status sub-reason name |
| DWH_dbo.Dim_PlayerLevel | Name | Club/tier name |
| DWH_dbo.Dim_ScreeningStatus | Name | Screening outcome name |
| DWH_dbo.Dim_AccountType | Name | Account category name |
| DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | EV match status name |
| DWH_dbo.V_Liabilities | Liabilities, ActualNWA | Equity calculation |
| DWH_dbo.Fact_CustomerAction | Amount (ActionTypeID=7), DateID (ActionTypeID=14) | Total deposits and last login date |
| BI_DB_dbo.BI_DB_PositionPnL | CID | Open position existence check |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | AML risk level name |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | CID, DateAdded, SuggestedDocumentTypeID | Document upload metadata |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | DocumentID, DocumentTypeID, RejectReasonID | Formal document type assignments |
| BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Document type name (assigned and suggested) |
| BI_DB_dbo.External_etoro_Dictionary_DocumentRejectReason | RejectReasonName | Reject reason filter (IS NULL = accepted docs only) |

### 6.2 Referenced By (other objects read from this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_W_AML_PEP_Customers | DocumentDateAdded_Selfie, DocumentDateAdded_POIncome | Weekly PEP customer report: reads Selfie/SOF document dates to compute Has_Selfie, Selfie_Date, Has_SOF, SOF_Date, and Selfie_and_SOF_Valid (valid if both within 12 months) |

---

## 7. Sample Queries

### 7.1 Find HRC customers missing Proof of Income

```sql
SELECT CID,
       Country,
       AML_Rank,
       RiskScoreName,
       Total_Deposits,
       last_document_upload,
       DocumentDateAdded_POIncome
FROM   [BI_DB_dbo].[BI_DB_AML_Documents_Request]
WHERE  Is_HRC = 1
AND    DocumentDateAdded_POIncome IS NULL
ORDER  BY Total_Deposits DESC;
```

### 7.2 Find PEP customers with expired or missing Selfie

```sql
SELECT CID,
       Regulation,
       Country,
       RiskScoreName,
       DocumentDateAdded_Selfie,
       DocumentDateAdded_POIncome
FROM   [BI_DB_dbo].[BI_DB_AML_Documents_Request]
WHERE  ScreeningStatus = 'PEP'
AND    (DocumentDateAdded_Selfie IS NULL
        OR DocumentDateAdded_Selfie < DATEADD(MONTH, -12, GETDATE()));
```

### 7.3 Document gap summary by regulation

```sql
SELECT Regulation,
       COUNT(DISTINCT CID)                                         AS Customers,
       SUM(CASE WHEN Has_POI = 0 OR Has_POI IS NULL THEN 1 ELSE 0 END) AS Missing_POI,
       SUM(CASE WHEN Has_POA = 0 OR Has_POA IS NULL THEN 1 ELSE 0 END) AS Missing_POA,
       SUM(CASE WHEN Is_HRC = 1 AND DocumentDateAdded_POIncome IS NULL THEN 1 ELSE 0 END) AS HRC_Missing_SOF
FROM   [BI_DB_dbo].[BI_DB_AML_Documents_Request]
GROUP  BY Regulation
ORDER  BY Customers DESC;
```

### 7.4 High-equity customers with no recent document upload

```sql
SELECT CID,
       Regulation,
       Country,
       Equity,
       Total_Deposits,
       last_document_upload,
       Has_POI,
       Has_POA,
       VerificationLevelID
FROM   [BI_DB_dbo].[BI_DB_AML_Documents_Request]
WHERE  Equity > 50000
AND    (last_document_upload < DATEADD(YEAR, -3, GETDATE())
        OR last_document_upload IS NULL)
ORDER  BY Equity DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-22 | Batch: 45 | Quality: 9.3/10 (Phase 16 adversarial eval PASS) | Schema: BI_DB_dbo*
*Tiers: 15 T1, 29 T2, 1 T3, 0 T4, 1 BL | Elements: 46/46, Logic: 9.0/10, Relationships: 9.0/10, Sources: 9.0/10*
*Object: BI_DB_dbo.BI_DB_AML_Documents_Request | Type: Table | Writer: SP_AML_Documents_Request | Priority: 0 | Refresh: Daily*
