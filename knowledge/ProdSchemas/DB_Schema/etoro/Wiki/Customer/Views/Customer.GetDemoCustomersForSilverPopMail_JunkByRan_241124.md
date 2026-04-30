# Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124

> **DEPRECATED (Junk - marked by Ran, Nov 2024)** - Legacy SilverPop email marketing export view for demo customers; assembles 41 fields per customer including identity, activity flags, championship history, copy-trading indicators, KYC level, and copier counts. SilverPop was migrated to SFMC in July 2021.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID (CID hardcoded to 0) |
| **Partition** | N/A |
| **Indexes** | N/A (view - see base tables) |

---

## 1. Business Meaning

Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 is a wide email marketing export view originally built for the SilverPop email platform to produce per-customer campaign profiles for demo account users. The `_JunkByRan_241124` suffix was added by team member "Ran" in November 2024, marking this view as deprecated/junk. SilverPop itself was migrated to Salesforce Marketing Cloud (SFMC) in July 2021 (per "Email Migration to SFMC 1 July 2021" Confluence page), making this view unused since at least that migration.

The view assembles 41 fields covering: core identity (GCID, name, email, country, language), account attributes (label, affiliate, provider, gender, funnel, age), balance and trading history (balance, championship performance, position activity, PnL), copy-trading activity (DidCopy, LastCopyDate, copier counts and 24h/7d changes), and platform engagement (last login across clients, OpenBook last login, KYC level, avatar URL). All string fields are wrapped in QUOTENAME with double-quote delimiters, producing CSV-quoted output ready for SilverPop import.

The view targets demo customers: DemoAccount is hardcoded to 1 in both SELECT branches. It contains a UNION ALL of two identical SELECT blocks: the first returns all customers that INNER JOIN to BackOffice.CustomerAllTimeAggregatedData; the second's WHERE clause `BOCD.CID IS NULL` contradicts its own INNER JOIN to the same table and therefore always returns 0 rows - this second branch is dead code (likely a bug or copy-paste error from a planned LEFT JOIN variant).

---

## 2. Business Logic

### 2.1 QUOTENAME String Wrapping for SilverPop Import

**What**: All name/text fields are wrapped in QUOTENAME(..., '"') to produce CSV-ready double-quoted strings.

**Columns/Parameters Involved**: `FirstName`, `LastName`, `UserName`, `Email`, `CountryNameByIP`, `Language`, `LabelName`

**Rules**:
- `QUOTENAME(LTRIM(RTRIM(value)), '"')` produces `"value"` with double quotes
- Also applies LTRIM/RTRIM to strip leading and trailing whitespace
- Email additionally uses ISNULL to '' before wrapping
- Result: all string fields arrive at SilverPop pre-quoted for CSV parsing

### 2.2 GCID as Primary Key (CID Always 0)

**What**: This export uses GCID as the customer identifier, not CID. CID is hardcoded to 0 and DemoCID suppresses the actual CID when GCID is populated.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- `CID` = always 0 (hardcoded - never exposes the actual CID)
- `DemoCID` = `CASE WHEN CCST.GCID <> 0 THEN 0 ELSE CCST.CID END` - returns actual CID only for very old accounts without GCID
- GCID (Group Customer ID) is the cross-product identity key used by external systems like SilverPop to avoid provider-specific CID conflicts

### 2.3 Last Open Position Date Logic

**What**: LastOpenPositionDateDemo resolves the most recent open-position event by comparing Trade.Position (live open positions) vs History.Position.OpenOccurred (closed positions' open timestamps).

**Columns/Parameters Involved**: `LastOpenPositionDateDemo`

**Rules**:
- OpenPositions CTE: `MAX(Occurred)` from Trade.Position (most recent active position open)
- ClosePositions CTE: `MAX(OpenOccurred)` from History.Position (latest closed position's open date)
- CASE logic: returns the LATER of the two dates, or NULL if both are 1900-01-01 (sentinel for no data)
- This gives the true "when did the customer last open a position?" regardless of whether that position is still open or has since been closed
- When neither date exists (no position history), result is NULL

**Diagram**:
```
OP.Occurred == CP.OpenOccurred (both sentinel 1900-01-01) -> NULL
OP.Occurred > CP.OpenOccurred -> OP.Occurred (live position date is newer)
OP.Occurred < CP.OpenOccurred -> CP.OpenOccurred (last closed position opened later)
```

### 2.4 DidCopy - CopyTrader Activity Detection

**What**: Binary YES/NO flag indicating whether the customer has ever copied another trader.

**Columns/Parameters Involved**: `DidCopy`, `LastCopyDate`

**Rules**:
- Combines Trade.Mirror (active copy relationships) and History.Mirror (closed copy relationships) via UNION
- `MAX(Occurred)` from the combined set -> `LastCopyDate`
- `DidCopy` = 'YES' if any copy event found, 'NO' otherwise
- Used to target "has copied" vs "never copied" segments for copy-trading engagement emails

### 2.5 Copier Count Change Metrics (etoroGeneral.dbo.Copiers_DATA)

**What**: Three snapshots of copier count are computed by cross-referencing etoroGeneral.dbo.Copiers_DATA at different DateModified ranges.

**Columns/Parameters Involved**: `Current_Number_of_copiers`, `ChangeInNumberOfCopiersInPast24Hours`, `ChangeInNumberOfCopiersInPast7Days`

**Rules**:
- `Current_Number_of_copiers`: NumOfCopiers from Copiers_DATA WHERE DateModified BETWEEN DATEADD(d,-1,GETDATE()) AND GETDATE()
- `B4_24_hoursNumOfCopiers`: 24-48 hours ago snapshot
- `B4_7_DaysNumOfCopiers`: 7-8 days ago snapshot
- `ChangeInPast24Hours` = Current - 24h-prior (ISNULL 0 for both)
- `ChangeInPast7Days` = Current - 7d-prior (ISNULL 0 for both)
- These volatility metrics were used by SilverPop to identify Popular Investors with rapidly growing or shrinking follower counts for targeted campaigns

### 2.6 Dead Code - Second UNION ALL Branch

**What**: The second SELECT in the UNION ALL is dead code that always returns 0 rows.

**Columns/Parameters Involved**: All 41 output columns (second branch)

**Rules**:
- BOCD is defined as `INNER JOIN BackOffice.CustomerAllTimeAggregatedData BOCD`
- The WHERE clause has `WHERE BOCD.CID IS NULL`
- A successful INNER JOIN guarantees BOCD.CID is never NULL
- Therefore this entire branch always produces 0 rows
- Likely a bug: the intent was probably a LEFT JOIN to BackOffice.CustomerAllTimeAggregatedData to capture customers without BO records, combined with `LOB.LoggedIn IS NOT NULL` (OpenBook login required)

---

## 3. Data Overview

Full view not queryable in this environment (requires EtoroArchive access for History.* tables). Partial sample from accessible base tables only:

| GCID | DemoCID | FirstName | BalanceDemo | DemoAccount | KYC_Level | Age | Meaning |
|------|---------|-----------|-------------|-------------|-----------|-----|---------|
| 1983587 | 0 | "assia556" | 0.00 | 1 | 1 (basic) | 45 | Early demo account with no balance. KYC_Level=1 (basic). GCID populated so DemoCID=0. Placeholder email (no real email). |
| 1983588 | 0 | "UltraTrader" | 108864.01 | 1 | 3 (advanced) | 34 | Active demo trader with significant play-money balance. KYC_Level=3 indicates higher verification. Likely a test/seed account. |
| 1983589 | 0 | "adi1" | 0.00 | 1 | 1 (basic) | 21 | Young demo account with no balance. Basic KYC level. Early sequential GCID indicating early platform registration. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier in this export. Used by SilverPop to match customers across demo and real databases. NULL for very old accounts predating GCID. |
| 2 | CID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). The actual platform CID is intentionally suppressed. DemoCID (column 3) exposes the CID only for accounts without a GCID. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns the actual CID only for very old accounts that were never assigned a GCID. For all modern accounts (GCID populated), this is 0. |
| 4 | FirstName | nvarchar | YES | - | VERIFIED | Legal first name, QUOTENAME-wrapped in double quotes (e.g., "John"). LTRIM/RTRIM applied. From Customer.Customer (CustomerStatic). Dynamic Data Masking on base table. |
| 5 | LastName | nvarchar | YES | - | VERIFIED | Legal last name, QUOTENAME-wrapped in double quotes. LTRIM/RTRIM applied. From Customer.Customer (CustomerStatic). Dynamic Data Masking on base table. |
| 6 | UserName | varchar | NO | - | VERIFIED | Login username, QUOTENAME-wrapped in double quotes. LTRIM/RTRIM applied. From Customer.Customer (CustomerStatic). Used as fallback display name in email templates. |
| 7 | Email | varchar | NO | - | VERIFIED | Email address, QUOTENAME-wrapped. ISNULL to '' before wrapping. From Customer.Customer (CustomerStatic). Primary SilverPop delivery address. Dynamic Data Masking on base table. |
| 8 | CountryNameByIP | nvarchar | YES | - | CODE-BACKED | Country name QUOTENAME-wrapped. From Dictionary.Country joined on Customer.CountryID (NOTE: despite the alias "ByIP", this uses CountryID, not CountryIDByIP - the alias is misleading). |
| 9 | Language | nvarchar | YES | - | VERIFIED | Language name QUOTENAME-wrapped. From Dictionary.Language on LanguageID. Used to dispatch localized email content. |
| 10 | BirthDate | varchar(50) | YES | - | VERIFIED | Birthdate formatted as MM/DD/YYYY string (style 101). LTRIM applied. From Customer.Customer (CustomerStatic). Dynamic Data Masking on base table. Used for age-based campaign eligibility. |
| 11 | RegistrationDate | varchar(50) | NO | - | VERIFIED | Registration date as MM/DD/YYYY string (style 101). From Customer.Customer.Registered. Used for anniversary and cohort campaigns. |
| 12 | LabelID | int | NO | - | VERIFIED | Internal segment label ID. From Customer.Customer (CustomerStatic). FK to Dictionary.Label. LabelID=26=BonusOnly. Used alongside LabelName for offer eligibility filtering. |
| 13 | LabelName | nvarchar | YES | - | CODE-BACKED | Label name QUOTENAME-wrapped. From Dictionary.Label.Name. Human-readable label for SilverPop campaign segmentation (e.g., "Standard", "BonusOnly"). |
| 14 | AffiliateID | int | YES | - | VERIFIED | Affiliate/introducing broker ID. Customer.Customer.SerialID aliased as AffiliateID. NULL for direct/organic registrations. Used to co-brand emails with affiliate partner. |
| 15 | OriginalCID | int | NO | - | CODE-BACKED | Original CID before any migration. From Customer.Customer. Default=0 for non-migrated accounts. Tracing field for legacy data reconciliation. |
| 16 | RealProviderID | int | YES | - | CODE-BACKED | Underlying real provider ID when different from ProviderID. From Customer.Customer. Nullable. |
| 17 | ProviderID | int | NO | - | VERIFIED | Current active provider/broker ID. From Customer.Customer. FK to Trade.Provider. Provider routing identifier. |
| 18 | OriginalProviderID | int | NO | - | CODE-BACKED | Original provider at migration time. From Customer.Customer. For migration history tracking. |
| 19 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', or 'U'. From Customer.Customer (CustomerStatic). CHECK constraint on base table. Used for gender-personalized email copy. |
| 20 | FunnelID | int | YES | - | VERIFIED | Registration funnel ID. From Customer.Customer (CustomerStatic). FK to Dictionary.Funnel. Tracks which acquisition journey variant the customer used. |
| 21 | Age | int | YES | - | CODE-BACKED | Computed: DATEDIFF(yy, BirthDate, GETDATE()). Age in years as of query execution date. NULL if BirthDate is NULL. Used for age-segmented campaign targeting. |
| 22 | BalanceDemo | decimal(25,2) | YES | - | VERIFIED | Demo account trading balance in USD. CONVERT(decimal(25,2), Credit) from Customer.Customer (CustomerMoney). Used to segment by demo balance size in email campaigns. |
| 23 | ChampPrizeDemo | money | NO | - | CODE-BACKED | Total lifetime championship prize winnings. ISNULL(BOCD.TotalChampWin, 0) from BackOffice.CustomerAllTimeAggregatedData. 0 for non-participants. |
| 24 | ChampRankDemo | int | NO | - | CODE-BACKED | Ranking position in the customer's most recent championship. ISNULL(CMPD.WinPos, 0) from History.ChampionshipPlayer (RowNum=1 = latest championship). 0 if never participated. |
| 25 | ChampProfitDemo | money | NO | - | CODE-BACKED | Current championship profit. ISNULL(CCPL.ChampProfit, 0) from Championship.ChampionshipPlayer. 0 if not in an active championship. |
| 26 | DemoAccount | int | NO | - | CODE-BACKED | Always 1 (hardcoded). This view is specifically for demo customer exports. Unlike Customer.GetCustomerListForStrongMail which uses DB_NAME(), this view always marks every row as demo. |
| 27 | HasOpenedPositionDemo | int | NO | - | CODE-BACKED | 1 if customer has any row in Trade.Position (has an active/live position), 0 otherwise. Checks LIVE positions only (not History). Note: HasOpenedPosition in GetCustomerListForStrongMail uses History.Position; this uses Trade.Position. |
| 28 | LastLoginDemo | varchar(50) | YES | - | CODE-BACKED | Most recent login date as MM/DD/YYYY string. Derived from MAX(LoggedIn) across Customer.Login (active) UNION History.Login (archived). NULL if customer has never logged in. |
| 29 | LastOpenPositionDateDemo | varchar(50) | YES | - | CODE-BACKED | Most recent position open date as MM/DD/YYYY string. Computed from the LATER of Trade.Position.Occurred and History.Position.OpenOccurred. NULL if customer has never opened a position. See Section 2.3 for CASE logic. |
| 30 | LastClosedPositionDateDemo | varchar(50) | YES | - | CODE-BACKED | Most recent position close date as MM/DD/YYYY string. MAX(CloseOccurred) from History.Position. NULL if customer has no closed positions. |
| 31 | TotalCommissionDemo | decimal(25,2) | YES | - | CODE-BACKED | Lifetime total commission earned. CONVERT(decimal(25,2), BOCD.TotalCommission) from BackOffice.CustomerAllTimeAggregatedData. |
| 32 | PLDemo | decimal(25,2) | YES | - | CODE-BACKED | Lifetime total profit/loss. CONVERT(decimal(25,2), BOCD.TotalProfit) from BackOffice.CustomerAllTimeAggregatedData. Labeled [PLDemo] with brackets. |
| 33 | WonChallengeDemo | int | NO | - | CODE-BACKED | 1 if customer has ever won a championship (WinPos=1 in History.ChampionshipPlayer), 0 otherwise. ChallangesWon CTE counts rows WHERE WinPos=1. Note: "Challanges" typo in CTE name. |
| 34 | DidCopy | varchar(3) | NO | - | CODE-BACKED | 'YES' if customer has ever copied another trader (any row in Trade.Mirror OR History.Mirror), 'NO' otherwise. Key CopyTrader segmentation flag. |
| 35 | LastCopyDate | varchar(50) | YES | - | CODE-BACKED | Date of most recent copy event as MM/DD/YYYY string. MAX(Occurred) from Trade.Mirror UNION History.Mirror. NULL if DidCopy='NO'. |
| 36 | OpenBookLastLogInDate | varchar(50) | YES | - | CODE-BACKED | Most recent OpenBook social feed login date as MM/DD/YYYY string. From History.LoginOpenBook.LoggedIn. NULL if customer never logged in to OpenBook. |
| 37 | Current_Number_of_copiers | int | YES | - | CODE-BACKED | Number of active copiers as of approximately now (last 24h snapshot from etoroGeneral.dbo.Copiers_DATA). NULL if no entry in the last 24h window. Popular Investor engagement metric. |
| 38 | KYC_Level | int | YES | - | CODE-BACKED | Customer's KYC (Know Your Customer) verification level. From BackOffice.Customer.VerificationLevelID. Used to target customers based on verification status for compliance-related or privileged campaigns. |
| 39 | UserAvatarURL | varchar | NO | - | CODE-BACKED | Computed: hardcoded S3 URL pattern 'https://openbook-static-files-prod.s3.amazonaws.com/images/users-avatars/150X150/{CID}.jpg'. Pre-built avatar image URL for use in personalized HTML emails. |
| 40 | ChangeInNumberOfCopiersInPast24Hours | int | NO | - | CODE-BACKED | Computed: current copier count minus the count 24-48 hours ago. Both sourced from etoroGeneral.dbo.Copiers_DATA. ISNULL 0 for missing snapshots. Positive=growing, negative=losing copiers. |
| 41 | ChangeInNumberOfCopiersInPast7Days | int | NO | - | CODE-BACKED | Computed: current copier count minus the count 7-8 days ago. Same source as #40. Week-over-week growth/decline for Popular Investors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Most identity/balance columns | Customer.Customer | FROM (CCST alias) | Core customer record |
| ChampPrizeDemo, TotalCommissionDemo, PLDemo | BackOffice.CustomerAllTimeAggregatedData | INNER JOIN on CID | Lifetime aggregated stats; also qualification gate |
| ChampRankDemo | History.ChampionshipPlayer | LEFT JOIN (RowNum=1 per CID) | Most recent championship rank |
| ChampProfitDemo | Championship.ChampionshipPlayer | LEFT JOIN on CID | Current championship profit |
| CountryNameByIP | Dictionary.Country | INNER JOIN on CountryID | Country name lookup |
| Language | Dictionary.Language | INNER JOIN on LanguageID | Language name lookup |
| LabelName | Dictionary.Label | INNER JOIN on LabelID | Label name lookup |
| KYC_Level | BackOffice.Customer | INNER JOIN on CID | Verification level |
| (historical player level) | History.Customer | LEFT JOIN (RowNum=1 per CID) | Previous player level (unused - HCST joined but no columns selected from it) |
| HasOpenedPositionDemo | Trade.Position | LEFT JOIN subquery (MAX Occurred) | Active position existence |
| LastOpenPositionDateDemo | Trade.Position + History.Position | LEFT JOIN subqueries combined | Open position date resolution |
| LastClosedPositionDateDemo | History.Position | LEFT JOIN subquery (MAX CloseOccurred) | Closed position date |
| LastLoginDemo | Customer.Login + History.Login | LEFT JOIN (UNION subquery) | Last login across active and archived |
| WonChallengeDemo | History.ChampionshipPlayer (WinPos=1) | LEFT JOIN subquery | Championship win flag |
| HasDeposited (FTDData CTE) | Billing.Deposit (PaymentStatusID=2) | LEFT JOIN subquery | FTD data (CTE built but no column selected from FD) |
| DidCopy, LastCopyDate | Trade.Mirror + History.Mirror | LEFT JOIN (UNION subquery) | Copy activity |
| OpenBookLastLogInDate | History.LoginOpenBook | LEFT JOIN subquery | OpenBook engagement |
| Current_Number_of_copiers etc. | etoroGeneral.dbo.Copiers_DATA | LEFT JOIN (x3 time windows) | Copier count snapshots |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository. Deprecated terminal export view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Dictionary.Country (table) [cross-schema]
├── Dictionary.Language (table) [cross-schema]
├── Dictionary.Label (table) [cross-schema]
├── BackOffice.Customer (table) [cross-schema]
├── BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema]
├── History.ChampionshipPlayer (table) [cross-schema, CTE: ChampinshipDetails]
├── Championship.ChampionshipPlayer (table) [cross-schema]
├── History.Customer (table) [cross-schema, CTE: CustomerHistory]
├── Trade.Position (table) [cross-schema, CTE: OpenPositions]
├── Customer.Login (table) [CTE: LoggedinData]
├── History.Login (table) [cross-schema, CTE: LoggedinData UNION]
├── History.Position (table) [cross-schema, CTE: ClosePositions]
├── History.ChampionshipPlayer (table) [cross-schema, CTE: ChallangesWon WinPos=1]
├── Billing.Deposit (table) [cross-schema, CTE: FTDData - built but unused]
├── Trade.Mirror (table) [cross-schema]
├── History.Mirror (table) [cross-schema]
├── History.LoginOpenBook (table) [cross-schema]
└── etoroGeneral.dbo.Copiers_DATA (table) [external DB, x3 time windows]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view, CCST alias) |
| Dictionary.Country | Table (cross-schema) | INNER JOIN - country name |
| Dictionary.Language | Table (cross-schema) | INNER JOIN - language name |
| Dictionary.Label | Table (cross-schema) | INNER JOIN - label name |
| BackOffice.Customer | Table (cross-schema) | INNER JOIN - KYC verification level |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | INNER JOIN - aggregated stats + qualification gate |
| History.ChampionshipPlayer | Table (cross-schema) | LEFT JOIN x2: RowNum=1 (rank), WinPos=1 (wins) |
| Championship.ChampionshipPlayer | Table (cross-schema) | LEFT JOIN - current championship profit |
| History.Customer | Table (cross-schema) | LEFT JOIN subquery - prior player level (joined but no output column) |
| Trade.Position | Table (cross-schema) | LEFT JOIN subquery - max open position date |
| Customer.Login | Table | LEFT JOIN subquery (UNION) - last login |
| History.Login | Table (cross-schema) | LEFT JOIN subquery (UNION) - archived login |
| History.Position | Table (cross-schema) | LEFT JOIN subquery x2 - close/open dates |
| Billing.Deposit | Table (cross-schema) | LEFT JOIN subquery (FTDData CTE) - FTD data built but no column selected |
| Trade.Mirror | Table (cross-schema) | LEFT JOIN (UNION) - copy activity |
| History.Mirror | Table (cross-schema) | LEFT JOIN (UNION) - archived copy activity |
| History.LoginOpenBook | Table (cross-schema) | LEFT JOIN subquery - OpenBook last login |
| etoroGeneral.dbo.Copiers_DATA | Table (external DB) | LEFT JOIN x3 - copier count snapshots |

### 6.2 Objects That Depend On This

No dependents found. Deprecated terminal export view.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance governed by indexes on 18+ underlying tables across multiple schemas and databases.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN to BackOffice.CustomerAllTimeAggregatedData | Implicit filter | Only customers processed by BackOffice aggregation appear |
| INNER JOIN to BackOffice.Customer | Implicit filter | Only customers with a BackOffice record appear |
| INNER JOIN to Dictionary.Country/Language/Label | Implicit filter | Customers with unresolved LabelID/LanguageID/CountryID excluded |
| Dead code UNION ALL branch | Bug | Second SELECT WHERE BOCD.CID IS NULL contradicts INNER JOIN - always returns 0 rows |
| etoroGeneral cross-DB dependency | External DB | Requires cross-database access to etoroGeneral |

---

## 8. Sample Queries

### 8.1 Active demo Popular Investors with growing copier counts
```sql
SELECT
    GCID,
    FirstName,
    Email,
    Language,
    BalanceDemo,
    Current_Number_of_copiers,
    ChangeInNumberOfCopiersInPast24Hours,
    ChangeInNumberOfCopiersInPast7Days,
    DidCopy,
    KYC_Level
FROM Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 WITH (NOLOCK)
WHERE Current_Number_of_copiers > 0
  AND ChangeInNumberOfCopiersInPast7Days > 0
ORDER BY Current_Number_of_copiers DESC;
```

### 8.2 Demo customers who have deposited but never traded (FTD no-trade segment)
```sql
SELECT
    GCID,
    FirstName,
    Email,
    Language,
    BalanceDemo,
    HasOpenedPositionDemo,
    LastLoginDemo,
    RegistrationDate
FROM Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 WITH (NOLOCK)
WHERE HasOpenedPositionDemo = 0
  AND BalanceDemo > 0
ORDER BY RegistrationDate DESC;
```

### 8.3 Championship winners for prize notification emails
```sql
SELECT
    GCID,
    FirstName,
    Email,
    Language,
    ChampRankDemo,
    ChampPrizeDemo,
    ChampProfitDemo,
    WonChallengeDemo
FROM Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 WITH (NOLOCK)
WHERE WonChallengeDemo = 1
   OR ChampPrizeDemo > 0
ORDER BY ChampPrizeDemo DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Email Migration to SFMC 1 July 2021](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/4468047939) | Confluence | SilverPop was migrated to Salesforce Marketing Cloud (SFMC) in July 2021, confirming this view has been unused since the migration |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.8/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed (view, no consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124 | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetDemoCustomersForSilverPopMail_JunkByRan_241124.sql*
