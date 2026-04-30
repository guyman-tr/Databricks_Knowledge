# BackOffice.GetCustomerByCID

> The master customer profile procedure for BackOffice: returns ~100 columns covering identity, live financial position (equity, unrealized PnL, used margin), lifetime aggregates, verification history, and administrative state for a single customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer lookup; returns TOP 1 with OPTION(Recompile) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a BackOffice agent opens any customer record in the BO application, this procedure fires. It is the single data source for the entire customer dashboard: personal details, live account balance and equity, lifetime deposit/cashout/commission totals, verification level and document status, affiliate relationship, copy-trading master account linkage, and administrative flags (risk classification, EDD, delayed trading).

The procedure has a 13-year change history (2013-2026), making it the most evolved SP in the BackOffice schema. Key architectural decisions embedded in it:
- **Hybrid credit history**: merges disk-based History.Credit with the in-memory History.ActiveCreditRecentMemoryBucket to get the full credit ledger without cold-start performance issues
- **Live equity calculation**: computed inline using scalar UDFs for unrealized PnL and used margin - the equity value is always fresh at time of call
- **InProcessCO tracking**: separately tracks pending cashout amounts vs actually-settled cashout amounts to show accurate net position
- **Last login pre-fetch**: pulled from the denormalized BackOffice.CustomerAllTimeAggregatedData first (fast) rather than scanning History.LoginArch

---

## 2. Business Logic

### 2.1 Hybrid Credit History (Disk + In-Memory Bucket)

**What**: Before the main SELECT, a TVP @ActiveCreditLocal is populated by merging two credit sources to get the complete credit ledger.

**Columns/Parameters Involved**: `History.Credit`, `History.ActiveCreditRecentMemoryBucket`, `@ActiveCreditLocal`

**Rules**:
- Step 1: INSERT from `History.Credit` (disk) WHERE CID = @CID - gets the persisted credit history
- Step 2: INSERT from `History.ActiveCreditRecentMemoryBucket` (in-memory) WHERE CID = @CID AND CreditID NOT IN (@ActiveCreditLocal) - adds only records not already on disk
- The LEFT JOIN anti-pattern (`AND AL.CreditID IS NULL`) ensures no duplicates
- This merged TVP is then used in multiple OUTER APPLY and LEFT JOIN subqueries for cashout fees, in-process cashouts, and credit count
- Added Jan 2021 (Shay Oren) to replace direct History.Credit access with the unified history pattern

### 2.2 Live Equity Calculation

**What**: Equity is computed fresh at call time from Credit (balance), unrealized PnL from open positions, and in-flight cashout adjustments.

**Columns/Parameters Involved**: `Equity`, `Credit`, `BackOffice.GetUnrealizedPnL`, `BackOffice.GetUsedMarginBigInt`, `InProcessCO`, `NetCashouts`

**Formula**:
```
Equity = ((Credit * 100 + GetUnrealizedPnL(CID) + GetUsedMarginBigInt(CID)) / 100.0)
         + (InProcessCO - NetCashouts)
```
- `Credit * 100` converts to integer cents to avoid floating-point rounding with `GetUnrealizedPnL` and `GetUsedMarginBigInt` (which return values in cents/100ths)
- `GetUnrealizedPnL(@CID)`: scalar UDF returning sum of open position PnL in integer cents
- `GetUsedMarginBigInt(@CID)`: scalar UDF returning margin locked by open positions in integer cents
- The division by 100.0 converts the sum back to dollars
- `InProcessCO - NetCashouts`: in-flight cashout adjustment (see 2.3)

### 2.3 InProcess Cashout Tracking

**What**: Three separate subqueries calculate different aspects of the cashout pipeline to correctly represent equity.

**Columns/Parameters Involved**: `InProcessCO`, `NetCashouts`, `InProcessCOwFees`, `TotalCashoutFees`

**Rules**:

| Subquery | Source | Filter | Meaning |
|----------|--------|--------|---------|
| `InProcessCO` | Billing.Withdraw | CashoutStatusID NOT IN (4) | All pending withdrawals (exclude Reversed=4) |
| `NetCashouts` | Billing.WithdrawToFunding | CashoutStatusID IN (3,16,17) | Actually settled: Processed=3, Partially Reversed=16, Reversed=17 |
| `InProcessCOwFees` (output) | InProcessCO - NetCashouts | - | Net in-flight amount reducing equity |
| `CashoutFees` | @ActiveCreditLocal | CreditTypeID=15, CashoutStatusID<>4 | Cashout fee credits charged to customer |
| `inProcessCOwFeesForEquity` | @ActiveCreditLocal | CreditTypeID IN (15,9), StatusID IN (1,2,7) | In-process fees for equity (computed but commented out) |

Note: The `InProcessCOwFees` column exposed in the output shows the difference between gross pending cashouts and settled cashouts - a positive value means money still in transit that reduces equity.

### 2.4 Age Calculation (Bug-Fixed)

**What**: Age is computed correctly handling the case where the customer's birthday has not yet occurred this calendar year.

**Columns/Parameters Involved**: `Age`, `OA1` (OUTER APPLY), `CCST.BirthDate`

**Formula**: `OA1.Age + IIF(DateAdd(Year, OA1.Age, BirthDate) > GetUTCDate(), -1, 0)`

**Rules**:
- `DateDiff(Year, BirthDate, GetUTCDate())` gives the simple year difference
- If adding that many years to the birthdate gives a future date, the birthday hasn't happened yet this year - subtract 1
- Fixed in March 2019 (RD-2585, 4787) after BO was showing ages 1 year too high for customers whose birthday is later in the year

### 2.5 Last Login Pre-Fetch Pattern

**What**: Last login time and IP are fetched from a fast denormalized store before the main query rather than joining History.LoginArch inline.

**Columns/Parameters Involved**: `@LastLoginTime`, `@LastLoginIP`, `BackOffice.CustomerAllTimeAggregatedData`

**Rules**:
- `SELECT TOP 1 @LastLoginTime=LastLoggedInOn, @LastLoginIP=LastClientIp FROM BackOffice.CustomerAllTimeAggregatedData WHERE CID=@CID` runs first
- Then the variables are used directly in the main SELECT
- The History.LoginArch LEFT JOIN (alias CGCI) still appears in the FROM clause but its columns are commented out - it exists as a legacy remnant
- `CountryIDByLastLoginIP` still queries History.LoginArch inline via a subquery (not via CGCI)
- Prior to Nov 2018, a linked-server view `Customer.GetCustomerCurrentInfo` was used; replaced due to 12-second performance impact

### 2.6 Verification Change History

**What**: `LastVerifiedDate` shows when the customer's VerificationLevelID last increased (upgraded).

**Columns/Parameters Involved**: `LastVerifiedDate`, `History.BackOfficeCustomer`

**Rules**:
- Self-joins History.BackOfficeCustomer (HBOC, HBOC2) where HBOC2.ValidTo = HBOC.ValidFrom (consecutive records)
- Computes `ChangeInVerified = Cast(Verified_new As SmallInt) - Cast(Verified_old As SmallInt)`
- Filters ChangeInVerified = 1 (verification went up) and takes the most recent (Rank=1)
- This specifically tracks verification upgrades (e.g., unverified -> basic -> full), not downgrades

### 2.7 Delayed Trading Flag

**What**: `Delayed` flag indicates whether the customer's account is in a delayed-trading list.

**Columns/Parameters Involved**: `Delayed`, `Maintenance.Feature` (FeatureID=10)

**Rules**:
- `Maintenance.Feature` FeatureID=10 stores a XML document listing delayed CIDs in the format `/ListCID/CIDToDelayMapping/CID`
- The LEFT JOIN checks if `@CID` appears in the XML for FeatureID=10
- Result cast to BIT: 1 = customer is delayed, 0 = normal
- Delayed customers experience price quote delays in their trading platform

### 2.8 Hardcoded TradingStatus

**What**: `TradingStatus` is always returned as the literal string 'No Entry'.

**Rules**:
- Prior code used `CGCI.TradingStatus` from the linked-server view (commented out)
- The field was never updated after the view was removed; the hardcoded value is a stub

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. Returns TOP 1 row from Customer.Customer WHERE CID=@CID. |
| **Identity & Registration** | | | | | | |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. PK of Customer.Customer. |
| 3 | GCID | INT | NO | 0 | CODE-BACKED | Global Customer ID. ISNULL(CCST.GCID, 0). Cross-entity identifier used in multi-platform contexts. |
| 4 | UserName | NVARCHAR | NO | - | CODE-BACKED | Customer's eToro login username. |
| 5 | Email | NVARCHAR | NO | - | CODE-BACKED | Customer email address. |
| 6 | FirstName | NVARCHAR | NO | - | CODE-BACKED | Customer first name. |
| 7 | MiddleName | NVARCHAR | YES | - | CODE-BACKED | Customer middle name. |
| 8 | FirstAndMiddleName | NVARCHAR | NO | - | CODE-BACKED | Computed: FirstName + ISNULL(' ' + MiddleName, ''). |
| 9 | LastName | NVARCHAR | NO | - | CODE-BACKED | Customer last name. |
| 10 | Gender | INT | YES | - | CODE-BACKED | Gender code. |
| 11 | BirthDate | DATE | YES | - | CODE-BACKED | Customer date of birth. |
| 12 | Age | INT | NO | - | CODE-BACKED | Computed age in years with birthday-not-yet-occurred correction (see 2.4). |
| 13 | RegistrationDate | DATETIME | NO | - | CODE-BACKED | Date/time customer registered. From Customer.Customer.Registered. |
| 14 | RegistrationIP | VARCHAR | YES | - | CODE-BACKED | IP address at registration time. |
| 15 | CountryID | INT | YES | - | CODE-BACKED | Customer's declared country ID. |
| 16 | CountryIDByIP | INT | YES | - | CODE-BACKED | Country ID resolved from registration IP. |
| 17 | CountryIDByLastLoginIP | INT | NO | 0 | CODE-BACKED | Country ID resolved from the IP of the most recent login. Queried from History.LoginArch via Internal.GetCountryIDByIP. |
| 18 | StateID | INT | YES | - | CODE-BACKED | Customer state/province ID. |
| 19 | City | NVARCHAR | YES | - | CODE-BACKED | Customer city. |
| 20 | Address | NVARCHAR | YES | - | CODE-BACKED | Customer street address. |
| 21 | BuildingNumber | NVARCHAR | YES | - | CODE-BACKED | Customer building number. |
| 22 | Zip | NVARCHAR | YES | - | CODE-BACKED | Postal code. |
| 23 | Phone | NVARCHAR | YES | - | CODE-BACKED | Phone number. |
| 24 | Mobile | NVARCHAR | YES | - | CODE-BACKED | Mobile number. |
| 25 | Fax | NVARCHAR | YES | - | CODE-BACKED | Fax number. |
| **Account & Financial State** | | | | | | |
| 26 | Credit | DECIMAL(16,2) | NO | - | CODE-BACKED | Current account balance in account currency. From Customer.Customer.Credit (cast to decimal). The raw credit value used in equity formula. |
| 27 | Equity | DECIMAL(16,2) | YES | - | CODE-BACKED | Computed live equity: (Credit + UnrealizedPnL + UsedMargin) + (InProcessCO - NetCashouts). See section 2.2. |
| 28 | UnrealizedPnL | DECIMAL(16,2) | YES | - | CODE-BACKED | Live unrealized PnL from open positions. From BackOffice.GetUnrealizedPnL(@CID) / 100.0. |
| 29 | UsedMargin | DECIMAL(16,2) | YES | - | CODE-BACKED | Margin currently locked by open positions. From BackOffice.GetUsedMarginBigInt(@CID) / 100.0. |
| 30 | CurrencyID | INT | YES | - | CODE-BACKED | Account base currency ID. FK to Dictionary.Currency. |
| 31 | BonusCredit | DECIMAL | NO | 0 | CODE-BACKED | Current bonus credit balance. ISNULL(CCST.BonusCredit, 0). |
| 32 | IsReal | BIT | NO | - | CODE-BACKED | 1 = real money account; 0 = demo account. |
| 33 | AccountClosedStatusID | INT | NO | 1 | CODE-BACKED | Account closure status. ISNULL(CCST.AccountStatusID, 1). Default 1 = active/open. |
| 34 | AccountExpirationDate | DATETIME | YES | - | CODE-BACKED | Date the account expires (demo accounts). |
| 35 | PendingClosureStatusID | INT | NO | 1 | CODE-BACKED | Pending closure pipeline status. ISNULL(CCST.PendingClosureStatusID, 1). |
| **Lifetime Financial Aggregates** (from BackOffice.CustomerAllTimeAggregatedData) | | | | | | |
| 36 | TotalDeposit | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total deposits. From BOCA.TotalDeposit. |
| 37 | TotalCashout | DECIMAL(16,2) | YES | - | CODE-BACKED | Total settled cashouts: ABS(ISNULL(NetCashouts.netCashouts, 0)). Derived from Billing.WithdrawToFunding statuses 3/16/17. |
| 38 | TotalCommission | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime commissions earned/paid. From BOCA.TotalCommission. |
| 39 | TotalCompensation | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime compensations received. From BOCA.TotalCompensation. |
| 40 | TotalBonus | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime bonus credits received. From BOCA.TotalBonus. |
| 41 | TotalProfit | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime realized trading profit. From BOCA.TotalProfit. |
| 42 | TotalChampWin | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime championship winnings. From BOCA.TotalChampWin. |
| 43 | TotalCashoutFees | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Total cashout processing fees charged. Sum of credit Payment where CreditTypeID=15 and CashoutStatusID<>4, from @ActiveCreditLocal. |
| 44 | TotalOverWeekendFees | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime overnight/weekend holding fees. ABS(ISNULL(BOCA.TotalEndOfWeekFee, 0)). |
| 45 | InProcessCOwFees | DECIMAL(16,2) | YES | - | CODE-BACKED | Net in-flight cashout amount: InProcessCO - NetCashouts. Positive = money still in transit reducing equity. See section 2.3. |
| 46 | Volume | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime trading volume. From BOCA.TotalVolume. |
| 47 | GamesPlayed | INT | YES | - | CODE-BACKED | Total championship games participated in. From BOCA.TotalGameCount. |
| 48 | LotCount | DECIMAL | YES | - | CODE-BACKED | Total lot count across all trades. From BOCA.TotalLot. |
| 49 | PositionsOpened | INT | YES | - | CODE-BACKED | Total positions opened lifetime. From BOCA.TotalPositionCount. |
| 50 | NumberOfCreditActions | INT | NO | 0 | CODE-BACKED | Count of credit ledger entries since registration. Computed from @ActiveCreditLocal WHERE Occurred >= Registered. |
| **BackOffice Administrative State** | | | | | | |
| 51 | AccountTypeID | INT | YES | - | CODE-BACKED | Account type (individual, corporate, etc.). From BackOffice.Customer.AccountTypeID. |
| 52 | AcceptanceStatusID | INT | YES | - | CODE-BACKED | Account acceptance/onboarding status. From BackOffice.Customer.AcceptanceStatusID. |
| 53 | VerificationLevelID | INT | YES | - | CODE-BACKED | Current verification level. From BackOffice.Customer.VerificationLevelID. |
| 54 | DocumentStatusID | INT | NO | 0 | CODE-BACKED | Document verification status. ISNULL(BCST.DocumentStatusID, 0). |
| 55 | LastVerifiedDate | DATETIME | YES | - | CODE-BACKED | Date when VerificationLevelID last increased (upgraded). From History.BackOfficeCustomer analysis. See section 2.6. |
| 56 | RiskStatusID | INT | YES | - | CODE-BACKED | AML/risk status of the account. From BackOffice.Customer.RiskStatusID. |
| 57 | RiskClassificationID | INT | NO | -1 | CODE-BACKED | Risk classification. ISNULL(BCST.RiskClassificationID, -1). -1 = not classified. Added Feb 2026. |
| 58 | OnboardingRiskClassificationID | INT | YES | - | CODE-BACKED | Risk classification assigned at onboarding. From BackOffice.Customer.OnboardingRiskClassificationID. |
| 59 | WorldCheckStatusID | INT | YES | - | CODE-BACKED | World-Check (sanctions/PEP screening) result status. From BackOffice.Customer.WorldCheckID. |
| 60 | SalesStatusID | INT | YES | - | CODE-BACKED | Sales pipeline status for this customer. From BackOffice.Customer.SalesStatusID. |
| 61 | GuruStatusID | INT | NO | 0 | CODE-BACKED | Popular Investor (Guru) program status. ISNULL(BCST.GuruStatusID, 0). |
| 62 | Cleared | BIT | YES | - | CODE-BACKED | Account cleared flag. From BackOffice.Customer.Cleared. |
| 63 | IsEDD | BIT | YES | - | CODE-BACKED | Enhanced Due Diligence flag. From BackOffice.Customer.IsEDD. 1 = customer requires enhanced scrutiny. |
| 64 | GDCCheckID | INT | YES | - | CODE-BACKED | Electronic identity check record ID. From BackOffice.ElectronicIdentityCheck.ElectronicIdentityCheckID. Moved from BackOffice.Customer in 2013. |
| 65 | Delayed | BIT | NO | 0 | CODE-BACKED | 1 = customer is on the delayed-trading list (Maintenance.Feature FeatureID=10 XML). See section 2.7. |
| **Manager & Organizational** | | | | | | |
| 66 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager assigned to this customer. From BackOffice.Customer.ManagerID. |
| 67 | ManagerEmailAddress | NVARCHAR | YES | - | CODE-BACKED | Email of the assigned manager. From BackOffice.Manager.Email. |
| 68 | ManagerPermitID | INT | YES | - | CODE-BACKED | Manager permission tier for this account. From BackOffice.Customer.ManagerPermitID. |
| 69 | UserGroupr | NVARCHAR | YES | - | CODE-BACKED | Name of the manager's user group. From Dictionary.UserGroup.Name. Note: alias has a typo ("r" suffix). |
| 70 | PendingManagerID | INT | YES | - | CODE-BACKED | Manager in the FTD (first-time deposit) pool awaiting assignment. From BackOffice.Customer.FTDPoolManagerID. |
| 71 | AffiliateManagerID | INT | YES | - | CODE-BACKED | ID of the affiliate manager. From BackOffice.Customer.AffiliateManagerID. |
| 72 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction ID. From BackOffice.Customer.RegulationID. |
| **Affiliate & Master Account** | | | | | | |
| 73 | IsAffiliate | BIT | YES | - | CODE-BACKED | 1 = customer is an affiliate. From BackOffice.Customer.IsAffiliate. |
| 74 | AffiliateStatusID | INT | YES | - | CODE-BACKED | Affiliate program status. From BackOffice.Affiliate.AffiliateStatusID via CCST.SerialID. NULL if not an affiliate. |
| 75 | MasterAccountCID | INT | YES | - | CODE-BACKED | CID of the master account this customer is linked to (for corporate/sub-accounts). From BackOffice.Customer.MasterAccountCID. |
| 76 | MasterFullName | NVARCHAR | YES | - | CODE-BACKED | Full name of the master account holder. Computed from MasterCCST.FirstName + ' ' + LastName. |
| 77 | MasterAccountTypeID | INT | YES | - | CODE-BACKED | Account type of the master account. From MasterBCST.AccountTypeID. |
| **Trading & Platform** | | | | | | |
| 78 | PlayerLevelID | INT | YES | - | CODE-BACKED | Customer tier level ID. FK to Dictionary.PlayerLevel. |
| 79 | PlayerStatusID | INT | YES | - | CODE-BACKED | Customer trading status ID. FK to Dictionary.PlayerStatus. |
| 80 | TradeLevelID | INT | YES | - | CODE-BACKED | Trading level ID. From Customer.Customer.TradeLevelID. |
| 81 | SpreadGroupID | INT | NO | 0 | CODE-BACKED | Spread group assignment determining trading spreads. ISNULL(CCST.SpreadGroupID, 0). |
| 82 | CashoutFeeGroupID | INT | YES | - | CODE-BACKED | Cashout fee group determining applicable fee schedule. From BackOffice.Customer.CashoutFeeGroupID. |
| 83 | LotCountGroupID | INT | YES | - | CODE-BACKED | Group based on lot count for tiered benefits. From Customer.Customer.LotCountGroupID. |
| 84 | FXEligibilityDate | DATETIME | YES | - | CODE-BACKED | Date from which the customer became eligible to trade FX. From BackOffice.Customer.FXEligibilityDate. |
| 85 | IsOverWeekendFeeExepmt | INT | NO | 100 | CODE-BACKED | Overnight fee exemption level. ISNULL(WeekendFeePrecentage, 100). 100 = full fee applies; lower values = partial/full exemption. Note: alias has a typo ("Exepmt"). |
| 86 | TradingStatus | VARCHAR(8) | NO | - | CODE-BACKED | Hardcoded to 'No Entry'. Legacy stub - previously from Customer.GetCustomerCurrentInfo linked server view. |
| **Lookup / Cross-Reference IDs** | | | | | | |
| 87 | OriginalCID | INT | YES | - | CODE-BACKED | The original CID before any account migration/merge. |
| 88 | OriginalProviderID | INT | YES | - | CODE-BACKED | Original provider that brought the customer in. |
| 89 | ProviderID | INT | YES | - | CODE-BACKED | Current provider ID. |
| 90 | SerialID | INT | YES | - | CODE-BACKED | Affiliate serial number. Used to look up BackOffice.Affiliate. |
| 91 | SubSerial | INT | YES | - | CODE-BACKED | Sub-serial for tiered affiliate programs. |
| 92 | ReferralID | INT | YES | - | CODE-BACKED | Referral tracking ID. |
| 93 | WhiteLabelID | INT | YES | - | CODE-BACKED | White-label partner ID. From Customer.Customer.LabelID. |
| 94 | DownloadID | INT | YES | - | CODE-BACKED | Trading platform download/installer version ID. |
| **Login & Session** | | | | | | |
| 95 | LastLoginDate | DATETIME | YES | - | CODE-BACKED | Most recent login timestamp. From BackOffice.CustomerAllTimeAggregatedData.LastLoggedInOn (pre-fetched). |
| 96 | LastLoginIP | VARCHAR(15) | YES | - | CODE-BACKED | IP address of most recent login. From BackOffice.CustomerAllTimeAggregatedData.LastClientIp (pre-fetched). |
| 97 | PhoneVerificationID | INT | NO | 0 | CODE-BACKED | Phone verification status. ISNULL(BCST.PhoneVerifiedID, 0). |
| **Platform / Localization** | | | | | | |
| 98 | LanguageID | INT | YES | - | CODE-BACKED | UI language preference. |
| 99 | CommunicationLanguageID | INT | YES | - | CODE-BACKED | Preferred language for communications. |
| 100 | TimeZoneID | INT | YES | - | CODE-BACKED | Customer timezone preference. |
| 101 | ClientVersion | NVARCHAR | YES | - | CODE-BACKED | Last seen trading client version. |
| **Miscellaneous** | | | | | | |
| 102 | Comment | NVARCHAR | YES | - | CODE-BACKED | Internal BO comments field. From Customer.Customer.Comments. |
| 103 | ThirdPartyManagerComment | NVARCHAR | YES | - | CODE-BACKED | Comment from a third-party manager. From BackOffice.Customer.ThirdPartyManagerComment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Primary Source | Core customer identity, registration, and platform fields |
| @CID | BackOffice.Customer | Primary Source | BO-specific administrative state, risk, verification, manager assignment |
| SerialID | BackOffice.Affiliate | Lookup / LEFT JOIN | Affiliate status |
| CID | History.LoginArch | LEFT JOIN (legacy) | Remnant join; columns commented out. Used in CountryIDByLastLoginIP subquery |
| ManagerID | BackOffice.Manager | Lookup / LEFT JOIN | Resolves manager ID to email |
| UserGroupID | Dictionary.UserGroup | Lookup / LEFT JOIN | Resolves manager's user group to name |
| MasterAccountCID | Customer.Customer | Self-JOIN | Master account name |
| MasterAccountCID | BackOffice.Customer | Self-JOIN | Master account type |
| CID | BackOffice.CustomerAllTimeAggregatedData | Lookup | Pre-fetch last login; also aggregated totals (BOCA) |
| CID | @ActiveCreditLocal | In-memory TVP | Merged credit history for fee and count subqueries |
| CID | Billing.Withdraw | Subquery | InProcessCO calculation |
| CID | Billing.WithdrawToFunding | Subquery | NetCashouts calculation |
| FeatureID=10 | Maintenance.Feature | Lookup / LEFT JOIN | Delayed trading XML flag |
| CID | History.BackOfficeCustomer | Self-JOIN subquery | Verification level upgrade history |
| CID | BackOffice.ElectronicIdentityCheck | Lookup / LEFT JOIN | GDC/electronic identity check ID |
| CID | History.Credit | INSERT into TVP | Disk-based credit history |
| CID | History.ActiveCreditRecentMemoryBucket | INSERT into TVP | In-memory recent credit bucket |
| IP | Internal.GetCountryIDByIP | Scalar function | Resolves IP to country ID |
| @CID | BackOffice.GetUnrealizedPnL | Scalar UDF | Live unrealized PnL for equity |
| @CID | BackOffice.GetUsedMarginBigInt | Scalar UDF | Live used margin for equity |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Primary customer dashboard SP - called when any BO agent opens a customer record |
| BackOffice.GetCustomerByCIDVerification | (related SP) | Parallel implementation | Lighter-weight SP for verification-only use cases; shares the same base tables but ~60 columns fewer |
| BackOffice.GetCustomerByCIDVerificationNotSafe | (wrapper) | EXECUTE AS wrapper | Calls GetCustomerByCIDVerification with elevated dbo permissions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerByCID (procedure)
|- Customer.Customer (identity + platform fields)
|- BackOffice.Customer (BO administrative state)
|- BackOffice.Affiliate (affiliate status)
|- History.LoginArch (legacy left join + CountryIDByIP subquery)
|- BackOffice.Manager (manager email)
|- Dictionary.UserGroup (manager user group)
|- Customer.Customer (self-join - master account)
|- BackOffice.Customer (self-join - master account type)
|- BackOffice.CustomerAllTimeAggregatedData (login pre-fetch + aggregates)
|- History.Credit (credit history -> TVP)
|- History.ActiveCreditRecentMemoryBucket (in-memory credit -> TVP)
|- Billing.Withdraw (InProcessCO subquery)
|- Billing.WithdrawToFunding (NetCashouts subquery)
|- Maintenance.Feature (delayed flag XML)
|- History.BackOfficeCustomer (verification change history)
|- BackOffice.ElectronicIdentityCheck (GDC check ID)
|- BackOffice.GetUnrealizedPnL (scalar UDF - live PnL)
|- BackOffice.GetUsedMarginBigInt (scalar UDF - used margin)
+-- Internal.GetCountryIDByIP (scalar function - IP resolution)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary source for identity, registration, trading, and platform fields |
| BackOffice.Customer | Table | BO administrative state: risk, verification, manager, regulation |
| BackOffice.Affiliate | Table | Affiliate status via SerialID |
| History.LoginArch | Table | CountryIDByLastLoginIP subquery; legacy LEFT JOIN (CGCI) present but unused |
| BackOffice.Manager | Table | Manager email address |
| Dictionary.UserGroup | Table | Manager user group name |
| BackOffice.CustomerAllTimeAggregatedData | Table | Last login fields + lifetime aggregates (TotalDeposit, TotalBonus, etc.) |
| History.Credit | Table | Disk-based credit history fed into @ActiveCreditLocal TVP |
| History.ActiveCreditRecentMemoryBucket | Table (in-memory) | Recent in-memory credit records to supplement disk history |
| Billing.Withdraw | Table | InProcessCO and cashout fee subqueries |
| Billing.WithdrawToFunding | Table | NetCashouts subquery (settled amounts) |
| Maintenance.Feature | Table | Delayed trading flag (FeatureID=10 XML) |
| History.BackOfficeCustomer | Table | Verification level upgrade history |
| BackOffice.ElectronicIdentityCheck | Table | Electronic identity (GDC) check record |
| History.ActiveCreditRecentMemoryBucket_TYPE | User Defined Type | TVP type for @ActiveCreditLocal in-memory bucket |
| BackOffice.GetUnrealizedPnL | Scalar Function | Live unrealized PnL in integer cents |
| BackOffice.GetUsedMarginBigInt | Scalar Function | Live used margin in integer cents |
| Internal.GetCountryIDByIP | Scalar Function | IP address to country ID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Primary customer dashboard query |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `OPTION(Recompile)`: Forces query plan recompilation on every execution. Required because parameter sniffing on a procedure this complex (many subqueries, scalar UDFs, TVP) would produce unstable plans.
- `SELECT TOP 1`: Guards against data anomalies where multiple Customer.Customer rows could match (should not happen, but defensive).
- `WITH(NOLOCK)` on all major tables: Trade-off between read consistency and performance; BackOffice dashboard calls can tolerate slightly stale reads.

---

## 8. Sample Queries

### 8.1 Get full customer profile

```sql
EXEC BackOffice.GetCustomerByCID @CID = 12345678;
```

### 8.2 Check equity components directly

```sql
DECLARE @CID INT = 12345678;

SELECT
    CAST(c.Credit AS DECIMAL(16,2)) AS Credit,
    CAST(BackOffice.GetUnrealizedPnL(@CID) / 100.0 AS DECIMAL(16,2)) AS UnrealizedPnL,
    CAST(BackOffice.GetUsedMarginBigInt(@CID) / 100.0 AS DECIMAL(16,2)) AS UsedMargin,
    (SELECT CAST(ABS(ISNULL(SUM(w.Amount),0)) AS DECIMAL(16,2))
     FROM Billing.Withdraw w WITH(NOLOCK)
     WHERE w.CID=@CID AND w.CashoutStatusID NOT IN (4)) AS InProcessCO,
    (SELECT CAST(ABS(ISNULL(SUM(wf.Amount),0)) AS DECIMAL(16,2))
     FROM Billing.WithdrawToFunding wf WITH(NOLOCK)
     JOIN Billing.Withdraw w WITH(NOLOCK) ON wf.WithdrawID=w.WithdrawID
     WHERE w.CID=@CID AND wf.CashoutStatusID IN (3,16,17)) AS NetCashouts
FROM Customer.Customer c WITH(NOLOCK)
WHERE c.CID = @CID;
```

### 8.3 Verification upgrade history for a customer

```sql
SELECT HBOC.CID, HBOC.ValidFrom, HBOC.Verified AS NewVerified, HBOC2.Verified AS OldVerified
FROM History.BackOfficeCustomer HBOC WITH(NOLOCK)
JOIN History.BackOfficeCustomer HBOC2 WITH(NOLOCK)
    ON HBOC.CID = HBOC2.CID
    AND CONVERT(VARCHAR, HBOC2.ValidTo, 20) = CONVERT(VARCHAR, HBOC.ValidFrom, 20)
WHERE HBOC.CID = 12345678
    AND CAST(HBOC.Verified AS SMALLINT) > CAST(HBOC2.Verified AS SMALLINT)
ORDER BY HBOC.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| "HLD: Reverse Partially Processed Withdrawals" (Confluence, MG space) | Confluence | References GetCustomerByCID in the context of cashout status changes. Relevant to the InProcessCO logic and CashoutStatusID exclusion filters. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 103 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerByCID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerByCID.sql*
