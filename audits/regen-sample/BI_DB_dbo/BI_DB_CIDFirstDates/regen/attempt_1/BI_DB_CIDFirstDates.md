# BI_DB_dbo.BI_DB_CIDFirstDates

> 46.7M-row customer lifecycle milestone table tracking every eToro customer's first and last occurrence of key platform events -- registration, deposit, login, trade, copy, contact, verification, and funded status -- serving as the central customer-level dimension for BI reporting, CRM enrichment, and lifecycle segmentation. Updated daily by SP_CIDFirstDates via incremental INSERT (new customers) + UPDATE (changed attributes and new events).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension -- customer lifecycle milestones) |
| **Row Count** | ~46.7M (one row per valid customer) |
| **Date Range** | Registrations from 2007-08-29 to present |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (core), Fact_CustomerAction (events), Fact_BillingDeposit (deposits), V_Liabilities (equity), Dim_Mirror (copy), BI_DB_UsageTracking_SF (CRM contacts), Fact_SnapshotCustomer (verification), Function_Population_Funded/First_Time_Funded (funded status), BI_DB_DDR_Customer_Daily_Status (last funded), BI_DB_AppFlyer_Reports (mobile install) |
| **Refresh** | Daily incremental -- INSERT new valid customers + multi-pass UPDATE for changed attributes and new events (SP_CIDFirstDates) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFirstDates` is the BI layer's master customer lifecycle dimension. It maintains one row per valid customer (IsValidCustomer=1 in Dim_Customer, i.e., not PlayerLevelID=4, not LabelID 26/30, not CountryID=250), capturing:

- **Identity & demographics**: CID, GCID, UserName, Gender, BirthDate, Email, Country, CountryID, State, Language, CommunicationLanguage
- **Acquisition**: Channel, SubChannel, SerialID (AffiliateID), LabelName, FunnelName, FunnelFromName, BannerID, SubAffiliateID, DownloadID, ReferralID
- **Account status**: Club (PlayerLevel name), Blocked flag, Verified (VerificationLevel), RegulationID, DesignatedRegulationID, Manager, PrivacyPolicyID
- **Deposit milestones**: FirstDepositAttempt/Amount/Processor/FundingType, FirstDeposit/LastDeposit dates/amounts/funding types, Credit, RealizedEquity
- **Trading milestones**: FirstPosOpenDate, FirstMenualPosOpenDate, FirstMirrorPosOpenDate, FirstMirrorRegistrationDate, FirstStocksOpenDate, and their Last counterparts
- **Login milestones**: FirstLoggedIn, LastLoggedIn, FirstCashierLogin, LastCashierLogin
- **Social/copy milestones**: FirstTimeBeingCopied, LastTimeBeingCopied
- **Contact milestones**: FirstContactDate, LastContactDate, LastContactDate_ByPhone (from Salesforce CRM)
- **Verification milestones**: VerificationLevel1/2/3Date, EmailVerifiedDate, EvMatchStatusDate, PhoneVerifiedDate
- **Funded status**: IsFundedNew, FirstNewFundedDate, LastNewFundedDate
- **Cashout milestones**: FirstCashoutDate, LastCashoutDate
- **Other**: FirstInstallDate (mobile), FirstCampaignID/Date/Amount, KycModeID, ProfessionalApplicationDate, IsAirDropBefore, FTDIsLessThanAWeek

The table is populated from 15+ sources via SP_CIDFirstDates (Author: Adi Ferber, 2016-03-01). The SP first builds a full valid-customer set from Dim_Customer, inserts new customers with demographic/acquisition attributes, then runs ~20 multi-pass UPDATEs to populate first/last event dates from Fact_CustomerAction, deposit details from Fact_BillingDeposit, equity from V_Liabilities, copy data from Dim_Mirror, CRM contacts from BI_DB_UsageTracking_SF, verification dates from Fact_SnapshotCustomer, and funded status from the Function_Population_Funded/First_Time_Funded TVFs.

**Important**: Many columns are **deprecated** and no longer updated. Columns like KYC, DocsOK, Bankruptcy, PremiumAccount, Evangelist, SuitabilityTestCompletedAt, PassedSuitabilityTest, PEPCreatedTime, PEPStatusUpdatedDate, isPassedPEP, PEPStatusID were explicitly nullified on 2022-02-22. Demo-related columns (FirstDemoLoggedIn, FirstDemoPosOpenDate, etc.) were disabled in 2017. Social/engagement columns were disabled when source tables stopped updating. RiskGroup and DepositGroup were disabled 2023-05-09. These columns remain in the DDL but carry NULL/0 for all rows.

Invalid customers (IsValidCustomer=0) are actively DELETED from this table each run.

---

## 2. Business Logic

### 2.1 Valid Customer Population

**What**: Only valid customers are tracked. Invalid customers are deleted each run.

**Columns Involved**: CID, all columns

**Rules**:
- Valid = IsValidCustomer=1 in Dim_Customer (PlayerLevelID != 4, LabelID NOT IN (26,30), CountryID != 250)
- Invalid customers are identified via `#internal` temp table and DELETEd from BI_DB_CIDFirstDates
- New valid customers not yet in the table are INSERTed with demographic/acquisition attributes
- Changed attributes (Club, Language, Email, Blocked, etc.) trigger UPDATEs via change detection using COLLATE Latin1_General_BIN comparison

### 2.2 Blocked Flag Derivation

**What**: Binary flag indicating whether the customer account is restricted.

**Columns Involved**: `Blocked`

**Rules**:
- `CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0 END`
- PlayerStatusID values: 2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked

### 2.3 Registration Date Logic

**What**: The `registered` column takes the earlier of demo and real registration dates.

**Columns Involved**: `registered`

**Rules**:
- `CASE WHEN RegisteredDemo < RegisteredReal THEN RegisteredDemo ELSE RegisteredReal END`
- This captures the customer's first interaction with the platform regardless of account type

### 2.4 First/Last Event Pattern

**What**: Most first/last date columns follow a consistent pattern from Fact_CustomerAction.

**Columns Involved**: FirstLoggedIn, LastLoggedIn, FirstPosOpenDate, LastPosOpenDate, FirstCashierLogin, LastCashierLogin, FirstCashoutDate, LastCashoutDate, FirstMirrorRegistrationDate, LastMirrorRegistrationDate, FirstMenualPosOpenDate, LastMenualPosOpenDate, FirstMirrorPosOpenDate, LastMirrorPosOpenDate, FirstStocksOpenDate

**Rules**:
- SP filters Fact_CustomerAction by DateID range (today only) and ActionTypeID
- First dates: UPDATE only WHERE current value IS NULL or > @date (never overwrite an earlier first)
- Last dates: UPDATE with MAX(Occurred) -- always overwrite with latest
- ActionTypeID mapping: 1=ManualPositionOpen, 2=CopyPositionOpen, 7=Deposit, 8=Cashout, 14=Login, 15=AccountToMirror, 17=RegisterMirror, 21=PublishPost, 29=CashierLogin, 34=OpenStockOrder

### 2.5 Deposit Details (First and Last)

**What**: First and last deposit details including processor, funding type, amount, and date.

**Columns Involved**: FirstDepositDate, FirstDepositAmount, FirstDepositProcessor, FirstDepositFundingType, LastDepositDate, LastDepositAmount, LastDepositFundingType

**Rules**:
- FirstDeposit: Sourced via Dim_Customer.FTDTransactionID joined to Fact_BillingDeposit (IsFTD=1), enriched with Dim_FundingType.Name and Dim_BillingDepot.Name
- LastDeposit: From today's Fact_CustomerAction ActionTypeID=7 rows joined back to Fact_BillingDeposit
- FirstDepositAttempt: From Fact_FirstCustomerAction WHERE ActionTypeID=27 (deposit attempt)
- Amount is in USD (Amount * ExchangeRate for last deposit)

### 2.6 Credit and Equity Snapshot

**What**: Daily credit and realized equity from V_Liabilities, updated only for yesterday's date.

**Columns Involved**: `Credit`, `RealizedEquity`

**Rules**:
- Only updated when `@date = @yesterday` (i.e., running for the most recent day)
- `Credit = ISNULL(V_Liabilities.Credit, 0)`
- `RealizedEquity = ISNULL(V_Liabilities.RealizedEquity, 0)`

### 2.7 Funded Status (IsFundedNew)

**What**: Whether the customer meets all four funded criteria today.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- `IsFundedNew`: 1 if customer is in the result set of Function_Population_Funded(@dateINT), else 0. The function requires: (1) past first-funded date, (2) positive combined equity across TP/eMoney/Options
- `FirstNewFundedDate`: From Function_Population_First_Time_Funded(). Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Only set once (WHERE NULL)
- `LastNewFundedDate`: COALESCE of MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1 and current Function_Population_Funded result

### 2.8 FTD Speed Flag

**What**: Whether the customer's first deposit was within 7 days of registration.

**Columns Involved**: `FTDIsLessThanAWeek`

**Rules**:
- `CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0 THEN 1 ELSE 0 END`
- Only computed for customers registered in the last 10 days

### 2.9 Copy Milestones

**What**: First and last time another customer started copying this customer's trades.

**Columns Involved**: `FirstTimeBeingCopied`, `LastTimeBeingCopied`

**Rules**:
- Source: Dim_Mirror WHERE OpenOccurred in today's date range, grouped by ParentCID
- First: MIN(OpenOccurred), only if current value is NULL or > @date
- Last: MAX(OpenOccurred), always updated

### 2.10 Verification Dates

**What**: First date each verification level was reached, plus email and phone verification dates.

**Columns Involved**: `VerificationLevel1Date`, `VerificationLevel2Date`, `VerificationLevel3Date`, `EmailVerifiedDate`, `EvMatchStatusDate`, `PhoneVerifiedDate`

**Rules**:
- Sourced from Fact_SnapshotCustomer joined to Dim_Range (FromDateID)
- VerificationLevelNDate = MIN(FromDateID) WHERE VerificationLevelID = N
- Backfill logic: if Level 3 date is set but Level 2 is NULL, Level 2 is set to Level 3 date (cascade)
- EmailVerifiedDate = MIN(FromDateID) WHERE IsEmailVerified = 1
- EvMatchStatusDate = MIN(FromDateID) WHERE EvMatchStatus = 2
- PhoneVerifiedDate from BackOffice history WHERE PhoneVerifiedID IN (1,2)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) with CLUSTERED INDEX on CID. Single-customer lookups are optimal (data-local). Cross-customer aggregations by Channel, Country, or Region work well with the columnstore segment elimination on the clustered index. 46.7M rows -- manageable for full scans but prefer filtered queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer lifecycle summary | `SELECT * WHERE CID = @cid` |
| FTD funnel (registered → first deposit) | `SELECT Channel, COUNT(*) WHERE FirstDepositDate IS NOT NULL GROUP BY Channel` |
| Time-to-first-deposit | `DATEDIFF(DAY, registered, FirstDepositDate) WHERE FirstDepositDate > '1900-01-01'` |
| Currently funded customers | `WHERE IsFundedNew = 1` |
| Active copiers (Popular Investors) | `WHERE FirstTimeBeingCopied IS NOT NULL` |
| Recently contacted customers | `WHERE LastContactDate >= DATEADD(DAY, -7, GETDATE())` |
| Verification funnel | `COUNT by VerificationLevel3Date IS NOT NULL vs IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Extended customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID | Country details beyond Name/Region |
| DWH_dbo.Dim_Regulation | ON RegulationID | Regulation name |
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | ON CID = RealCID AND DateID | Daily status for a specific date |

### 3.4 Gotchas

- **46.7M rows, NOT all customers**: Only IsValidCustomer=1 customers. Invalid customers (PlayerLevelID=4, LabelID 26/30, CountryID=250) are actively deleted each run
- **~40 deprecated columns**: Many columns carry NULL/0 for all rows. See the Elements table for individual deprecation notes. Do not use deprecated columns for analytics
- **FirstDepositDate sentinel**: `1900-01-01` means no deposit, not a historical deposit. Filter `WHERE FirstDepositDate > '1900-01-01'` for depositors
- **FirstLeadDate sentinel**: Set to `1900-01-01` universally -- deprecated
- **Credit/RealizedEquity**: Only updated when SP runs for yesterday's date. Not a real-time snapshot -- reflects previous day's end-of-day values
- **registered is MIN(demo, real)**: Not the real-account registration date. For real-only registration, use Dim_Customer.RegisteredReal
- **Channel defaults to 'Direct'**: ISNULL(Channel, 'Direct') is applied in the SP. Customers without an affiliate mapping show 'Direct'
- **Manager is concatenated**: `FirstName + ' ' + LastName` from Dim_Manager. NULL if no manager assigned
- **IsFundedNew can toggle**: A customer can be funded one day and not the next (if equity drops to 0). It reflects the CURRENT day's funded status, not a permanent flag
- **FirstNewFundedDate is permanent**: Once set, it is never overwritten (WHERE NULL guard). It represents the graduation date, not a daily status

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 -- upstream wiki verbatim | (Tier 1 -- {source}) |
| Tier 2 -- SP ETL code | (Tier 2 -- SP_CIDFirstDates) |
| Tier 3 -- deprecated/not populated | (Tier 3 -- deprecated) |

### 4.1 Customer Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -- Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -- Customer.CustomerStatic) |
| 3 | OriginalCID | int | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 4 | UserName | varchar(500) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 -- Customer.CustomerStatic) |

### 4.2 Acquisition & Classification

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 5 | Club | varchar(500) | YES | eToro Club loyalty tier name. Values: Bronze (45.97M), Silver (287K), Gold (259K), Platinum (129K), Platinum Plus (92K), Diamond (11K). Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 -- Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Top-level marketing channel category. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.Channel. ISNULL default 'Direct' for customers without affiliate mapping. Common values: Direct, SEM, SEO, Affiliate, Friend Referral. (Tier 1 -- fiktivo_dbo.tblaff_Affiliates via Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Granular sub-channel name within the parent Channel. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.SubChannel. ISNULL default 'Direct'. Examples: 'Google Brand', 'Direct Mobile', 'Friend Referral'. (Tier 1 -- fiktivo_dbo.tblaff_Affiliates via Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | White-label broker brand name. Dim-lookup from Dim_Label.Name via LabelID. Most customers show 'eToro' (LabelID 0/1). (Tier 1 -- Dictionary.Label) |
| 10 | Country | varchar(500) | YES | Full country name in English. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -- Dictionary.Country) |
| 11 | Language | char(500) | YES | Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected. (Tier 1 -- Dictionary.Language) |
| 12 | Region | nvarchar(500) | NO | Marketing region label for this country. From Dim_Country.Region via CountryID. NOT the geographic region -- reflects marketing segmentation. (Tier 2 -- SP_CIDFirstDates via Dim_Country.Region) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping. (Tier 1 -- Ext_Dim_Country_Region_Desk) |
| 14 | Email | varchar(500) | YES | Customer email address. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 15 | FunnelName | varchar(500) | YES | Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through. (Tier 1 -- Dictionary.Funnel) |
| 16 | DownloadID | int | YES | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 -- Customer.CustomerStatic) |
| 17 | FunnelFromName | varchar(500) | YES | Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID. (Tier 1 -- Dictionary.Funnel) |
| 18 | BannerID | int | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 -- Customer.CustomerStatic) |
| 19 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID. (Tier 1 -- Customer.CustomerStatic) |
| 20 | ReferralID | int | YES | Referral CID -- the customer who referred this customer (for RAF program tracking). (Tier 1 -- Customer.CustomerStatic) |

### 4.3 Account Status & Demographics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | Blocked | int | YES | Account block flag. ETL-computed: 1 when PlayerStatusID IN (2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked), else 0. (Tier 2 -- SP_CIDFirstDates) |
| 22 | Verified | int | YES | KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID. (Tier 1 -- Dictionary.VerificationLevel) |
| 23 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only. (Tier 1 -- Customer.CustomerStatic) |
| 24 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 25 | BirthDate | datetime | YES | Customer date of birth. Used in KYC age verification. (Tier 1 -- Customer.CustomerStatic) |
| 26 | CommunicationLanguage | varchar(500) | YES | Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language). (Tier 1 -- Dictionary.Language) |
| 27 | Manager | nvarchar(500) | YES | Assigned account manager full name. ETL-computed: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via AccountManagerID. NULL if no manager assigned. (Tier 2 -- SP_CIDFirstDates) |
| 28 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 -- BackOffice.Customer) |
| 29 | DesignatedRegulationID | int | YES | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 -- BackOffice.Customer) |
| 30 | PrivacyPolicyID | tinyint | YES | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 -- Customer.CustomerStatic) |
| 31 | IP | bigint | YES | Registration IP address as numeric value. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 32 | State | varchar(100) | YES | State or province name from IP-based geolocation. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = RegionByIP_ID. NULL if region not in the 181-row Dim_State_and_Province table. (Tier 2 -- SP_CIDFirstDates via Dim_State_and_Province) |
| 33 | NewMarketingRegion | varchar(100) | YES | Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE). (Tier 1 -- Ext_Dim_Country) |

### 4.4 Registration & Login Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | registered | datetime | NO | Earliest registration date across demo and real accounts. ETL-computed: MIN(RegisteredDemo, RegisteredReal). Not the real-account-only date. (Tier 2 -- SP_CIDFirstDates) |
| 35 | FirstLoggedIn | datetime | YES | First platform login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 36 | LastLoggedIn | datetime | YES | Most recent platform login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 37 | FirstCashierLogin | datetime | YES | First cashier/billing login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |
| 38 | LastCashierLogin | datetime | YES | Most recent cashier login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |

### 4.5 Deposit Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 39 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first deposit attempt (whether successful or not). From Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 -- SP_CIDFirstDates) |
| 40 | FirstDepositAttemptAmount | numeric(36,12) | YES | Amount of the first deposit attempt in USD. (Tier 2 -- SP_CIDFirstDates) |
| 41 | FirstDepositAttemptProcessor | varchar(500) | YES | Payment processor name for the first deposit attempt. Dim-lookup from Dim_BillingDepot.Name via DepotID. (Tier 2 -- SP_CIDFirstDates) |
| 42 | FirstDepositAttemptFundingType | varchar(500) | YES | Payment method name for the first deposit attempt. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 43 | FirstDepositDate | datetime | YES | Date of first successful deposit. From Dim_Customer.FirstDepositDate via FTDTransactionID join to Fact_BillingDeposit. Sentinel 1900-01-01 = no deposit. (Tier 2 -- SP_CIDFirstDates) |
| 44 | FirstDepositProcessor | varchar(500) | YES | Payment processor name for the first successful deposit. Dim-lookup from Dim_BillingDepot.Name. (Tier 2 -- SP_CIDFirstDates) |
| 45 | FirstDepositFundingType | varchar(500) | YES | Payment method name for the first successful deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 46 | FirstDepositAmount | money | YES | Amount of first deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 -- SP_CIDFirstDates) |
| 47 | Credit | money | YES | Customer credit balance (promotional/bonus credit). Daily snapshot from V_Liabilities.Credit. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 48 | RealizedEquity | money | YES | Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 49 | LastDepositDate | datetime | YES | Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. (Tier 2 -- SP_CIDFirstDates) |
| 50 | LastDepositAmount | money | YES | Most recent deposit amount in USD (Amount * ExchangeRate). (Tier 2 -- SP_CIDFirstDates) |
| 51 | LastDepositFundingType | varchar(500) | YES | Payment method name for the most recent deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 52 | FirstDepositAmountExtended | money | YES | Not populated by current SP. Deprecated. (Tier 3 -- deprecated) |

### 4.6 Trading Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | FirstPosOpenDate | datetime | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 54 | LastPosOpenDate | datetime | YES | Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 55 | FirstMenualPosOpenDate | datetime | YES | First manual (non-copy) position open timestamp. MIN(Occurred) WHERE ActionTypeID=1. Note: column name has typo 'Menual' (not 'Manual'). (Tier 2 -- SP_CIDFirstDates) |
| 56 | LastMenualPosOpenDate | datetime | YES | Most recent manual position open timestamp. MAX(Occurred) WHERE ActionTypeID=1. (Tier 2 -- SP_CIDFirstDates) |
| 57 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open timestamp. MIN(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 58 | LastMirrorPosOpenDate | datetime | YES | Most recent copy-trade position open. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 59 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade mirror registration timestamp. MIN(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 60 | LastMirrorRegistrationDate | datetime | YES | Most recent copy-trade mirror registration. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 61 | FirstStocksOpenDate | datetime | YES | First stock order open timestamp. MIN(Occurred) WHERE ActionTypeID=34. (Tier 2 -- SP_CIDFirstDates) |

### 4.7 Cashout Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 62 | FirstCashoutDate | datetime | YES | First withdrawal timestamp. MIN(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |
| 63 | LastCashoutDate | datetime | YES | Most recent withdrawal timestamp. MAX(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |

### 4.8 Copy & Social Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 64 | FirstTimeBeingCopied | datetime | YES | First time another customer started copying this customer's trades. MIN(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |
| 65 | LastTimeBeingCopied | datetime | YES | Most recent time another customer started copying this customer. MAX(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |

### 4.9 Contact Milestones (Salesforce CRM)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | LastContactDate | datetime | YES | Most recent successful contact date. MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 -- SP_CIDFirstDates) |
| 67 | LastContactDate_ByPhone | datetime | YES | Most recent successful phone contact. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. Dynamically masked. (Tier 2 -- SP_CIDFirstDates) |
| 68 | FirstContactDate | datetime | YES | First successful contact date. MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN successful contacts. (Tier 2 -- SP_CIDFirstDates) |
| 69 | FirstContactDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 70 | LastContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 71 | LastContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 72 | FirstContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 73 | FirstContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |

### 4.10 Verification & Compliance Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | VerificationLevel1Date | datetime | YES | Date customer first reached KYC verification level 1 (basic). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=1. Backfilled from Level 2/3 dates if missing. (Tier 2 -- SP_CIDFirstDates) |
| 75 | VerificationLevel2Date | datetime | YES | Date customer first reached KYC verification level 2 (intermediate). MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from Level 3 date if missing. (Tier 2 -- SP_CIDFirstDates) |
| 76 | VerificationLevel3Date | datetime | YES | Date customer first reached KYC verification level 3 (full KYC). MIN(FromDateID) WHERE VerificationLevelID=3. (Tier 2 -- SP_CIDFirstDates) |
| 77 | EmailVerifiedDate | date | YES | Date customer verified their email address. MIN(FromDateID) from Fact_SnapshotCustomer WHERE IsEmailVerified=1. (Tier 2 -- SP_CIDFirstDates) |
| 78 | EvMatchStatusDate | datetime | YES | Date electronic verification matched (EvMatchStatus=2). MIN(FromDateID) from Fact_SnapshotCustomer. (Tier 2 -- SP_CIDFirstDates) |
| 79 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 -- BackOffice.Customer) |
| 80 | PhoneVerifiedDate | datetime | YES | Date phone number was verified. MIN(ValidFrom) from BackOffice history WHERE PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). (Tier 2 -- SP_CIDFirstDates) |
| 81 | KycModeID | int | YES | KYC workflow mode from ComplianceStateDB.Compliance.CustomerKycMode. Updated via GCID join. (Tier 2 -- SP_CIDFirstDates) |
| 82 | ProfessionalApplicationDate | date | YES | Date the customer applied for MiFID II professional categorization. From ComplianceStateDB.Compliance.CustomerProfessionalQuestionnaireResult.ApplicationDate. (Tier 2 -- SP_CIDFirstDates) |

### 4.11 Funded Status

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 83 | IsFundedNew | tinyint | YES | 1 if the customer meets ALL four funded criteria on this date: (1) real deposit per Dim_Customer.IsDepositor=1; (2) KYC verified to level 3; (3) at least one non-airdrop activity completed (TP trade, IOB interest credit, or Options trade); AND (4) positive equity on this date across TP, eMoney, or Options. Can toggle daily as equity changes. Source: Function_Population_Funded. (Tier 1 -- Function_Population_Funded) |
| 84 | FirstNewFundedDate | date | YES | Permanent graduation date -- the LATEST of the three funded milestones. Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Set once (WHERE NULL guard). Source: Function_Population_First_Time_Funded. (Tier 1 -- Function_Population_First_Time_Funded) |
| 85 | LastNewFundedDate | date | YES | Most recent date the customer was funded. COALESCE of MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1 and current Function_Population_Funded result. (Tier 2 -- SP_CIDFirstDates) |

### 4.12 Campaign & Marketing

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | FirstCampaignID | nvarchar(1024) | YES | Campaign ID of the customer's first campaign credit event. From History.Credit WHERE CampaignID IS NOT NULL, first by Occurred. (Tier 2 -- SP_CIDFirstDates) |
| 87 | FirstCampaignDate | datetime | YES | Date of the customer's first campaign credit event. (Tier 2 -- SP_CIDFirstDates) |
| 88 | FirstCampaignAmount | money | YES | Payment amount of the first campaign credit event. (Tier 2 -- SP_CIDFirstDates) |
| 89 | LastCampaignSentDate | datetime | YES | Not actively maintained by current SP. Legacy -- last marketing campaign sent. (Tier 3 -- deprecated) |

### 4.13 Mobile & Install

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 90 | FirstInstallDate | datetime | YES | First mobile app install date. From BI_DB_AppFlyer_Reports WHERE EventName='install', linked via AppsFlyerID through External_MarketPerformance_Tracking_Customer mapping. (Tier 2 -- SP_CIDFirstDates) |

### 4.14 Flags & Indicators

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 91 | FTDIsLessThanAWeek | int | YES | 1 if customer deposited within 7 days of registration AND FirstDepositAmount > 0. ETL-computed: CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 THEN 1 ELSE 0. Only computed for customers registered in last 10 days. (Tier 2 -- SP_CIDFirstDates) |
| 92 | IsAirDropBefore | tinyint | YES | 1 if the customer received a stock airdrop position (IsAirDrop=1, ActionTypeID=1, InstrumentTypeID=5) within the last 30 days and has a deposit. (Tier 2 -- SP_CIDFirstDates) |

### 4.15 Activity Tracking

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 93 | LastPublishedPostDate | date | YES | Date of the customer's most recent social feed post. MAX(Occurred) as DATE from Fact_CustomerAction WHERE ActionTypeID=21. (Tier 2 -- SP_CIDFirstDates) |
| 94 | LastActionDateForLifeStage | date | YES | Date of the customer's most recent life-stage event (manual open, mirror open, or mirror registration). MAX(Occurred) as DATE from Fact_CustomerAction WHERE ActionTypeID IN (1,15,17). (Tier 2 -- SP_CIDFirstDates) |
| 95 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() on each SP run that touches this row. (Tier 2 -- SP_CIDFirstDates) |

### 4.16 Deprecated Columns (Not Populated)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 96 | SocialConnect | int | YES | Not updated since Sep 2018. Source table (Customer.PrivacyUniqueIdentity) stopped updating. (Tier 3 -- deprecated) |
| 97 | KYC | int | YES | Nullified 2022-02-22 by Guy Manova. Superseded by Verified column. (Tier 3 -- deprecated) |
| 98 | DocsOK | int | YES | Nullified 2022-02-22. Document verification status -- superseded by Dim_Customer.DocsOK. (Tier 3 -- deprecated) |
| 99 | IsSales | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 100 | HasPic | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 101 | Bankruptcy | int | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 102 | FirstTimeUser | datetime | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 103 | FirstDemoLoggedIn | datetime | YES | Demo step disabled 2017-01-26 (Katy). (Tier 3 -- deprecated) |
| 104 | FirstDemoPosOpenDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 105 | FirstDemoMirrorRegistrationDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 106 | LastDemoMirrorRegistrationDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 107 | FirstDemoMirrorPosOpenDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 108 | LastDemoLoggedIn | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 109 | LastDemoMirrorPosOpenDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 110 | LastDemoPosOpenDate | datetime | YES | Demo step disabled. (Tier 3 -- deprecated) |
| 111 | FirstEngagementDate | datetime | YES | Engagement section disabled in SP. (Tier 3 -- deprecated) |
| 112 | LastEngagementDate | datetime | YES | Engagement section disabled in SP. (Tier 3 -- deprecated) |
| 113 | FirstLeadDate | datetime | YES | Set to 1900-01-01 sentinel universally. Not populated with real data. (Tier 3 -- deprecated) |
| 114 | CertifiedGuru | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 115 | FirstTimeSocialConnect | datetime | YES | Source table stopped updating. (Tier 3 -- deprecated) |
| 116 | SevenDayRetained | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 117 | FirstToSevenDayRetained | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 118 | FirstDateRetained | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 119 | PremiumAccount | int | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 120 | Evangelist | int | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 121 | FirstToThirtyDayRetained | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 122 | FirstWallEngagement | datetime | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 123 | FeedUnBlocked | tinyint | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 124 | FeedUnlocked | tinyint | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 125 | Follow5UsersDate | datetime | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 126 | NumberOfUsersFollowed | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 127 | PopularInvestor | int | YES | Not populated by current SP. (Tier 3 -- deprecated) |
| 128 | SuitabilityTestCompletedAt | datetime | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 129 | PassedSuitabilityTest | int | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 130 | Model_FTDsOTDs | float | YES | ML model score. Not populated by current SP. (Tier 3 -- deprecated) |
| 131 | Model_Leads | float | YES | ML model score. Not populated by current SP. (Tier 3 -- deprecated) |
| 132 | Model_ReDepositor | money | YES | ML model score. Not populated by current SP. (Tier 3 -- deprecated) |
| 133 | RiskGroup | varchar(500) | YES | Disabled 2023-05-09 (Eti Rozolio). (Tier 3 -- deprecated) |
| 134 | DepositGroup | varchar(500) | YES | Disabled 2023-05-09 (Eti Rozolio). (Tier 3 -- deprecated) |
| 135 | PEPCreatedTime | datetime | YES | Nullified 2022-02-22. PEP screening creation timestamp. (Tier 3 -- deprecated) |
| 136 | PEPStatusUpdatedDate | datetime | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 137 | isPassedPEP | tinyint | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 138 | PEPStatusID | int | YES | Nullified 2022-02-22. (Tier 3 -- deprecated) |
| 139 | SignedW8Date | date | YES | W-8BEN form signing date. Not actively updated by current SP (section disabled by Boris Slutski 2022-02-29). (Tier 3 -- deprecated) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Source | Transform |
|---------------------|--------|-----------|
| Identity (CID, GCID, UserName, etc.) | DWH_dbo.Dim_Customer | Passthrough |
| Acquisition (Channel, SubChannel) | Dim_Customer -> Dim_Affiliate -> Dim_Channel | Dim-lookup chain |
| Classification (Club, Country, Language, etc.) | Dim_Customer -> Dim_PlayerLevel/Country/Language/Label/Funnel/VerificationLevel/Manager | Dim-lookup |
| Deposit milestones | Fact_CustomerAction (ActionTypeID=7) + Fact_FirstCustomerAction (ActionTypeID=27) + Fact_BillingDeposit + Dim_FundingType + Dim_BillingDepot | MIN/MAX aggregation + JOIN enrichment |
| Login milestones | Fact_CustomerAction (ActionTypeID=14, 29) | MIN/MAX(Occurred) |
| Trading milestones | Fact_CustomerAction (ActionTypeID=1, 2, 17, 34) | MIN/MAX(Occurred) |
| Cashout milestones | Fact_CustomerAction (ActionTypeID=8) | MIN/MAX(Occurred) |
| Copy milestones | DWH_dbo.Dim_Mirror (ParentCID) | MIN/MAX(OpenOccurred) |
| Equity snapshot | DWH_dbo.V_Liabilities | Credit, RealizedEquity for yesterday |
| Contact milestones | BI_DB_dbo.BI_DB_UsageTracking_SF | MIN/MAX(CreatedDate_SF) filtered by ActionName |
| Verification dates | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) per verification level |
| Funded status | Function_Population_Funded, Function_Population_First_Time_Funded, DDR_Customer_Daily_Status | TVF result set membership |
| Mobile install | BI_DB_AppFlyer_Reports + tracking mapping | MIN(EventTime) WHERE install |
| Campaign | External History.Credit | First by Occurred WHERE CampaignID IS NOT NULL |
| KYC mode | External ComplianceStateDB.CustomerKycMode | Passthrough via GCID |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (46.4M customers)
  + Dim_State_and_Province, Dim_Funnel, Dim_Label, Dim_Country, Dim_Language,
    Dim_Affiliate, Dim_Channel, Dim_PlayerLevel, Dim_PlayerStatus,
    Dim_VerificationLevel, Dim_Manager
  |
  v [SP_CIDFirstDates — daily incremental]
    Step 1: Build #cust (valid customers only)
    Step 2: DELETE invalid customers from BI_DB_CIDFirstDates
    Step 3: Build #TotalCustomers -> #CustomerData (demographic enrichment)
    Step 4: INSERT new customers + UPDATE changed attributes
    |
    + Fact_CustomerAction (ActionTypeID filter, today's date range)
    + Fact_FirstCustomerAction (ActionTypeID=27, first deposit attempt)
    + Fact_BillingDeposit + Dim_FundingType + Dim_BillingDepot
    |
    v [~20 multi-pass UPDATE statements]
    Step 5: First/last login, position, mirror, cashout, stocks dates
    Step 6: First/last deposit details (processor, funding type, amount)
    Step 7: Credit + RealizedEquity from V_Liabilities (yesterday only)
    Step 8: First/last time being copied from Dim_Mirror
    Step 9: Contact dates from BI_DB_UsageTracking_SF
    Step 10: Verification dates from Fact_SnapshotCustomer + Dim_Range
    Step 11: FirstInstallDate from BI_DB_AppFlyer_Reports
    Step 12: KycModeID, ProfessionalApplicationDate from external compliance
    Step 13: EvMatchStatus, DesignatedRegulationID from Dim_Customer
    Step 14: FTDIsLessThanAWeek computation
    Step 15: IsFundedNew from Function_Population_Funded
    Step 16: FirstNewFundedDate from Function_Population_First_Time_Funded
    Step 17: LastNewFundedDate from DDR_Customer_Daily_Status
    Step 18: IsAirDropBefore from Fact_CustomerAction + Dim_Instrument
    Step 19: LastPublishedPostDate, LastActionDateForLifeStage
    Step 20: FirstCampaignID/Date/Amount from History.Credit
  |
  v
BI_DB_dbo.BI_DB_CIDFirstDates (46.7M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Core customer dimension |
| CountryID | DWH_dbo.Dim_Country | Country lookup |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| DesignatedRegulationID | DWH_dbo.Dim_Regulation | Secondary regulation |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_CID_DailyPanel_FullData | CID | Daily customer panel enrichment |
| BI_DB_dbo.SP_CID_MonthlyPanel_FullData | CID | Monthly customer panel |
| BI_DB_dbo.SP_DDR_Customer_Daily_Status | CID | DDR customer segmentation |
| BI_DB_dbo.SP_AM_Portfolio_Summary | CID | Account management reporting |
| BI_DB_dbo.SP_MarketingCloudDaily | CID | Marketing data feed |
| Multiple BI_DB SPs | CID | Various reporting and analytics |

---

## 7. Sample Queries

### 7.1 Customer lifecycle summary

```sql
SELECT CID, UserName, Country, Channel, Club,
       registered, FirstDepositDate, FirstPosOpenDate,
       FirstNewFundedDate, IsFundedNew,
       Credit, RealizedEquity
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]
WHERE CID = 12345678;
```

### 7.2 FTD conversion funnel by channel

```sql
SELECT Channel,
       COUNT(*) AS TotalCustomers,
       SUM(CASE WHEN FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS Depositors,
       SUM(IsFundedNew) AS CurrentlyFunded,
       CAST(SUM(CASE WHEN FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS DepositRate
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]
GROUP BY Channel
ORDER BY TotalCustomers DESC;
```

### 7.3 Time-to-first-deposit distribution

```sql
SELECT
    CASE
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) = 0 THEN 'Same day'
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) BETWEEN 8 AND 30 THEN '8-30 days'
        ELSE '30+ days'
    END AS TimeToFTD,
    COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]
WHERE FirstDepositDate > '1900-01-01'
GROUP BY
    CASE
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) = 0 THEN 'Same day'
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN DATEDIFF(DAY, registered, FirstDepositDate) BETWEEN 8 AND 30 THEN '8-30 days'
        ELSE '30+ days'
    END
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- regen harness mode.)

---

*Generated: 2026-04-28 | Quality: 8.2/10 | Phases: 12/14*
*Tiers: 27 T1, 68 T2, 44 T3, 0 T4 | Elements: 139/139, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CIDFirstDates | Type: Table | Production Source: SP_CIDFirstDates (15+ sources)*
