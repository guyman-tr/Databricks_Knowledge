# Billing.iDEALDepositApproveRatioWithoutBankLevel

> Analytics report that returns daily iDEAL deposit approval rates and transaction volumes broken down by channel (Web, Mobile, iOS, Android) and FTD status, without decomposing by individual bank.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set grouped by PaymentDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.iDEALDepositApproveRatioWithoutBankLevel` is a reporting procedure that calculates daily iDEAL payment approval metrics over a user-specified date range. iDEAL is the Netherlands-based bank-redirect payment method (FundingTypeID=34). For each calendar day in the range, the procedure returns the total volume and count of approved and declined iDEAL transactions, decomposed by originating channel (Web browser, Mobile app, iOS, Android), along with first-time deposit (FTD) amounts and an overall approval ratio per channel.

The procedure exists to support payment operations monitoring and business intelligence for iDEAL payment performance. Risk, finance, and product teams use this data to measure acceptance rates by channel, detect degradation events, and track iDEAL FTD contributions. The "WithoutBankLevel" suffix distinguishes it from a sibling procedure (`Billing.iDEALDepositApproveRatio`) that additionally breaks results down by individual bank - this version aggregates all iDEAL banks together for a higher-level view.

Data flows: the procedure reads `Billing.Deposit` (the deposit ledger, filtered to iDEAL via `Billing.Funding.FundingTypeID=34`) joined to `Customer.CustomerStatic` (to exclude internal employee accounts via `PlayerLevelID<>4`), then enriches each deposit with its originating application/platform by joining `STS_AuditLoginHistoryActive` (session log), `Dictionary.ApplicationIdentifier`, and `Dictionary.Platform`. The result is aggregated and returned as a date-ordered result set - no rows are written to any table. This is a pure read/analytics procedure.

---

## 2. Business Logic

### 2.1 iDEAL Channel Decomposition

**What**: Each deposit is classified into one of four mutually-overlapping channel dimensions (Web, Mobile, iOS, Android), using the application identifier string and platform ID derived from the customer's session at the time of deposit.

**Columns/Parameters Involved**: `ApplicationIdentifierFrom`, `PlatformID`

**Rules**:
- Web: `ApplicationIdentifierFrom = 'retoro'` (the eToro web application)
- Mobile: `ApplicationIdentifierFrom IN ('retoroios', 'retoroandroid')` (combined mobile)
- iOS: `PlatformID = 2` (via Dictionary.Platform join)
- Android: `PlatformID = 3` (via Dictionary.Platform join)
- Session identifier is matched via `OUTER APPLY ... TOP 1` on `STS_AuditLoginHistoryActive`; if no session is found (NULL ApplicationIdentifierFrom), the deposit counts only in `Total` figures, not in channel-specific ones
- Web and Mobile/iOS/Android are alternative representations of the same decomposition - total counts reconcile via AllTransactionsCountTotal

**Diagram**:
```
Deposit Session
    |
    +--[STS_AuditLoginHistoryActive]-> ApplicationIdentifierFrom
    |         |
    |         +--[Dictionary.ApplicationIdentifier]-> PlatformID
    |
    v
Channel Classification:
  ApplicationIdentifierFrom = 'retoro'          -> Web
  ApplicationIdentifierFrom IN ('retoroios',
                                'retoroandroid') -> Mobile
  PlatformID = 2                                -> iOS
  PlatformID = 3                                -> Android
  NULL ApplicationIdentifierFrom               -> Total only
```

### 2.2 Approval Status and Ratio Calculation

**What**: Deposits are classified as Approved (PaymentStatusID=2) or Declined (any other status). Per-channel approval ratios are computed using safe division (NULLIF to avoid divide-by-zero).

**Columns/Parameters Involved**: `PaymentStatusID`, `ApproveRatioTotal`, `ApproveRatioWeb`, `ApproveRatioMobile`, `ApproveRatioIOS`, `ApproveRatioAndroid`

**Rules**:
- PaymentStatusID=2 = Approved (see Billing.Deposit Section 2.1 for full status machine)
- PaymentStatusID<>2 = Declined for this report's purposes (all non-approved statuses count as declined)
- Approval ratio formula: `CONVERT(DECIMAL(10,2), CONVERT(FLOAT, ApprovedCount) / NULLIF(AllCount, 0))`
- Ratio is 0 when no transactions exist for a channel on a day (ISNULL wraps the NULLIF result)
- Amounts are multiplied by ExchangeRate to normalize to USD for TotalApproved aggregates

### 2.3 Employee Exclusion and FTD Scope

**What**: Internal employee accounts are excluded from the dataset. FTD (first-time deposit) metrics are a subset of approved deposits.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `IsFTD`, `PlayerLevelID` (Customer.CustomerStatic)

**Rules**:
- `Customer.CustomerStatic.PlayerLevelID <> 4` excludes employees/internal test accounts from all metrics
- FTD deposits: `IsFTD=1 AND PaymentStatusID=2` - approved iDEAL deposits that were the customer's first ever deposit
- FTD amounts and counts are provided per channel (Web, Mobile, iOS, Android) in addition to total
- Date range uses `PaymentDate >= @StartDate AND PaymentDate <= @EndDate` (inclusive on both ends, DATE type comparison)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | NO | - | CODE-BACKED | Start of the reporting date range (inclusive). Compared against `Billing.Deposit.PaymentDate` cast as DATE. Typically the first day of the period to analyze (e.g., a month or quarter start). |
| 2 | @EndDate | DATE | NO | - | CODE-BACKED | End of the reporting date range (inclusive). Compared against `Billing.Deposit.PaymentDate` cast as DATE. |

### Output Columns (per PaymentDate row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PaymentDate | DATE | NO | - | CODE-BACKED | The calendar date for this aggregated row. One row per distinct PaymentDate within the range. Derived by CAST(Billing.Deposit.PaymentDate AS DATE). |
| 4 | TotalApproved | DECIMAL | NO | - | CODE-BACKED | Total approved iDEAL deposit amount (USD-equivalent) for the day across all channels. SUM of Amount*ExchangeRate where PaymentStatusID=2. Normalized to USD via ExchangeRate. |
| 5 | TotalApprovedFromWeb | DECIMAL | NO | - | CODE-BACKED | Approved iDEAL amount (USD) from the Web channel (ApplicationIdentifierFrom='retoro'). |
| 6 | TotalApprovedFromMobile | DECIMAL | NO | - | CODE-BACKED | Approved iDEAL amount (USD) from combined Mobile channel (retoroios + retoroandroid). |
| 7 | TotalApprovedFromIOS | DECIMAL | NO | - | CODE-BACKED | Approved iDEAL amount (USD) from iOS channel (PlatformID=2). |
| 8 | TotalApprovedFromAndroid | DECIMAL | NO | - | CODE-BACKED | Approved iDEAL amount (USD) from Android channel (PlatformID=3). |
| 9 | AllTransactionsCountTotal | INT | NO | - | CODE-BACKED | Total count of all iDEAL deposit attempts for the day (approved + declined), all channels. Denominator for ApproveRatioTotal. |
| 10 | AllTransactionsCountWeb | INT | NO | - | CODE-BACKED | Count of all iDEAL attempts from the Web channel (retoro). |
| 11 | AllTransactionsCountMobile | INT | NO | - | CODE-BACKED | Count of all iDEAL attempts from Mobile (retoroios + retoroandroid). |
| 12 | AllTransactionsCountIOS | INT | NO | - | CODE-BACKED | Count of all iDEAL attempts from iOS (PlatformID=2). |
| 13 | AllTransactionsCountAndroid | INT | NO | - | CODE-BACKED | Count of all iDEAL attempts from Android (PlatformID=3). |
| 14 | ApprovedTransactionsCountTotal | INT | NO | - | CODE-BACKED | Count of approved (PaymentStatusID=2) iDEAL deposits for the day, all channels. Numerator for ApproveRatioTotal. |
| 15 | ApprovedTransactionsCountWeb | INT | NO | - | CODE-BACKED | Count of approved iDEAL deposits from Web channel. |
| 16 | ApprovedTransactionsCountMobile | INT | NO | - | CODE-BACKED | Count of approved iDEAL deposits from Mobile channel. |
| 17 | ApprovedTransactionsCountIOS | INT | NO | - | CODE-BACKED | Count of approved iDEAL deposits from iOS channel. |
| 18 | ApprovedTransactionsCountAndroid | INT | NO | - | CODE-BACKED | Count of approved iDEAL deposits from Android channel. |
| 19 | DeclinedTransactionsCountTotal | INT | NO | - | CODE-BACKED | Count of declined iDEAL deposits (PaymentStatusID<>2) for the day, all channels. |
| 20 | DeclinedTransactionsCountWeb | INT | NO | - | CODE-BACKED | Count of declined iDEAL deposits from Web channel. |
| 21 | DeclinedTransactionsCountMobile | INT | NO | - | CODE-BACKED | Count of declined iDEAL deposits from Mobile channel. |
| 22 | DeclinedTransactionsCountIOS | INT | NO | - | CODE-BACKED | Count of declined iDEAL deposits from iOS (PlatformID=2). |
| 23 | DeclinedTransactionsCountAndroid | INT | NO | - | CODE-BACKED | Count of declined iDEAL deposits from Android (PlatformID=3). |
| 24 | CountFTD | INT | NO | - | CODE-BACKED | Count of first-time deposits (IsFTD=1 AND PaymentStatusID=2) via iDEAL for the day. |
| 25 | TotalFTD | DECIMAL | NO | - | CODE-BACKED | Total approved FTD amount (USD) via iDEAL for the day. SUM of Amount*ExchangeRate where IsFTD=1 AND PaymentStatusID=2. |
| 26 | ApproveRatioTotal | DECIMAL(10,2) | NO | - | CODE-BACKED | Overall daily approval ratio across all channels: ApprovedTransactionsCountTotal / AllTransactionsCountTotal. Returns 0 when no transactions exist. |
| 27 | ApproveRatioWeb | DECIMAL(10,2) | NO | - | CODE-BACKED | Approval ratio for Web channel: ApprovedTransactionsCountWeb / AllTransactionsCountWeb. 0 when no Web transactions. |
| 28 | ApproveRatioMobile | DECIMAL(10,2) | NO | - | CODE-BACKED | Approval ratio for Mobile channel (iOS + Android combined). |
| 29 | ApproveRatioIOS | DECIMAL(10,2) | NO | - | CODE-BACKED | Approval ratio for iOS channel: ApprovedTransactionsCountIOS / AllTransactionsCountIOS. |
| 30 | ApproveRatioAndroid | DECIMAL(10,2) | NO | - | CODE-BACKED | Approval ratio for Android channel: ApprovedTransactionsCountAndroid / AllTransactionsCountAndroid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BD.FundingID | Billing.Funding | JOIN | Joins to Funding to filter FundingTypeID=34 (iDEAL) - only iDEAL payment instruments are included |
| BD.CID | Customer.CustomerStatic | JOIN | Joins to exclude employees (PlayerLevelID=4) from results |
| BD.SessionID | STS_AuditLoginHistoryActive | OUTER APPLY | Looks up the application identifier from the session active at deposit time; used for channel classification |
| AHA.ApplicationIdentifierFrom | Dictionary.ApplicationIdentifier | LEFT JOIN | Resolves the application identifier string to a PlatformID; case-insensitive match (UPPER applied) |
| DAI.PlatformID | Dictionary.Platform | LEFT JOIN | Resolves PlatformID to platform row (PlatformID=2=iOS, PlatformID=3=Android) |

### 5.2 Referenced By (other objects point to this)

No callers found within the Billing schema stored procedures. This procedure is invoked ad-hoc by operations/analytics teams or BI tools - no automated scheduled callers identified.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.iDEALDepositApproveRatioWithoutBankLevel (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Customer.CustomerStatic (table)
├── STS_AuditLoginHistoryActive (table - cross-schema session log)
├── Dictionary.ApplicationIdentifier (table)
└── Dictionary.Platform (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source - each row is one deposit attempt; filtered by date range and FundingTypeID (via Funding join) |
| Billing.Funding | Table | Joined on FundingID to filter FundingTypeID=34 (iDEAL only) |
| Customer.CustomerStatic | Table | Joined on CID to exclude PlayerLevelID=4 (employee accounts) |
| STS_AuditLoginHistoryActive | Table | OUTER APPLY to resolve SessionID -> ApplicationIdentifierFrom for channel detection |
| Dictionary.ApplicationIdentifier | Table | LEFT JOIN to resolve ApplicationIdentifierFrom string to PlatformID |
| Dictionary.Platform | Table | LEFT JOIN to resolve PlatformID for iOS/Android channel segmentation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Uses three CTEs: `RawData` (row-level join and filter), `AggregatedData` (per-day channel aggregation), `DataAndSumUnsorted` (ratio computation with safe division)
- All source tables read with `WITH (NOLOCK)` on Billing.Deposit; `STS_AuditLoginHistoryActive` is read in OUTER APPLY without NOLOCK hint
- `OUTER APPLY ... TOP 1 ... WHERE ApplicationIdentifierFrom IS NOT NULL` on session history - takes the first non-null application identifier for the session; missing sessions leave ApplicationIdentifierFrom as NULL
- `UPPER()` applied to both sides of the `Dictionary.ApplicationIdentifier` join for case-insensitive matching
- Amounts normalized to USD by multiplying `Amount * ExchangeRate` (ExchangeRate is the USD conversion rate stored on the deposit)
- Result ordered by PaymentDate ascending

---

## 8. Sample Queries

### 8.1 Last 30 days iDEAL approval rate overview
```sql
EXEC Billing.iDEALDepositApproveRatioWithoutBankLevel
    @StartDate = CAST(DATEADD(DAY, -30, GETUTCDATE()) AS DATE),
    @EndDate   = CAST(GETUTCDATE() AS DATE)
```

### 8.2 Compare monthly iDEAL approval rates for a specific period
```sql
EXEC Billing.iDEALDepositApproveRatioWithoutBankLevel
    @StartDate = '2025-01-01',
    @EndDate   = '2025-03-31'
-- Returns 90 rows (one per day) with approval ratios by channel
```

### 8.3 Validate iDEAL FTD contribution vs total approved (ad-hoc check)
```sql
-- Call and inspect FTD columns vs total columns
-- to determine what percentage of approved iDEAL deposits are FTDs
EXEC Billing.iDEALDepositApproveRatioWithoutBankLevel
    @StartDate = '2025-01-01',
    @EndDate   = '2025-01-31'
-- CountFTD / ApprovedTransactionsCountTotal = FTD conversion rate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.iDEALDepositApproveRatioWithoutBankLevel | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.iDEALDepositApproveRatioWithoutBankLevel.sql*
