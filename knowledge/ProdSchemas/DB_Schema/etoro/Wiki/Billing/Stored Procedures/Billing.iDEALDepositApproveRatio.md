# Billing.iDEALDepositApproveRatio

> Analytical report procedure for iDEAL deposit (FundingTypeID=34) approval rates over a date range: returns per-bank per-day breakdowns of approved/declined counts and USD-equivalent amounts, segmented by channel (Web/Mobile/iOS/Android), with approve ratio calculations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate; returns one row per bank per payment date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.iDEALDepositApproveRatio is a reporting procedure that calculates the approval rate and volume statistics for iDEAL deposits (FundingTypeID=34, the Dutch online banking payment method) over a specified date range. It is used by operations and payments teams to monitor iDEAL bank performance.

Results are grouped by PaymentDate and BankName (extracted from the deposit's PaymentData XML), providing per-bank daily metrics. Each row includes:
- USD-equivalent approved amounts (total, web, mobile, iOS, Android)
- Transaction counts (all, approved, declined) by channel
- FTD (First Time Deposit) statistics
- Approval ratios by channel (ApproveRatioTotal, ApproveRatioWeb, ApproveRatioMobile, ApproveRatioIOS, ApproveRatioAndroid)

**FundingTypeID=34** = iDEAL (the Dutch Tikkie/Ideal bank transfer system). **PlayerLevelID<>4** excludes test/internal accounts. Session-based application identifier resolution maps sessions to platform (Web='retoro', iOS='retoroios', Android='retoroandroid') via STS_AuditLoginHistoryActive.

Note: The UNION for a 'SUM FOR ALL BANKS:' summary row is present but disabled by `WHERE 1=0` - the totals row is never returned.

---

## 2. Business Logic

### 2.1 Three-CTE Pipeline

**What**: RawData -> AggregatedData -> DataAndSumUnsorted -> final SELECT.

**CTE 1 - RawData**:
- Source: Billing.Deposit INNER JOIN Customer.CustomerStatic (PlayerLevelID<>4) + Billing.Funding (FundingTypeID=34)
- OUTER APPLY on STS_AuditLoginHistoryActive to get ApplicationIdentifierFrom for the session
- LEFT JOIN Dictionary.ApplicationIdentifier + Dictionary.Platform to resolve PlatformID (2=iOS, 3=Android)
- BankName extracted from PaymentData XML: `(/Deposit/BankNameAsString)[1]`
- Filters: PaymentDate >= @StartDate AND PaymentDate <= @EndDate

**CTE 2 - AggregatedData**:
- GROUP BY PaymentDate, BankName
- Calculates 30+ metrics using IIF conditional sums:
  - Approved (PaymentStatusID=2) vs Declined (PaymentStatusID<>2)
  - By channel: 'retoro'=Web, 'retoroios'/'retoroandroid'=Mobile, PlatformID=2=iOS, PlatformID=3=Android
  - FTD (IsFTD=1) amounts and counts by channel

**CTE 3 - DataAndSumUnsorted**:
- First SELECT: individual bank rows with ISNULL defaults and approve ratio calculations
- UNION: 'SUM FOR ALL BANKS:' summary row - but `WHERE 1=0` in the AggregatedData reference means this UNION branch never returns rows (disabled totals)
- ApproveRatio = `CONVERT(DECIMAL(10,2), ApprovedCount / NULLIF(AllCount, 0))` ISNULL to 0

### 2.2 Channel Segmentation

**What**: Deposits are segmented by originating application identifier.

**Rules**:
- `ApplicationIdentifierFrom = 'retoro'` -> Web channel
- `ApplicationIdentifierFrom IN ('retoroios', 'retoroandroid')` -> Mobile channel (combined)
- `PlatformID = 2` -> iOS (from Dictionary.Platform)
- `PlatformID = 3` -> Android
- Note: 'retoro' (Web) vs PlatformID approach give slightly different segmentation - both are reported

### 2.3 Approve Ratio Calculation

**What**: Safe division with NULLIF to avoid division-by-zero.

**Rules**:
- `ISNULL(CONVERT(DECIMAL(10,2), CONVERT(FLOAT, Approved) / NULLIF(All, 0)), 0)`
- Returns 0 when no transactions (denominator = 0 -> NULLIF returns NULL -> ISNULL -> 0)
- Decimal(10,2) precision - ratio as 0.00-1.00

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Applied to Billing.Deposit.PaymentDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the reporting window (inclusive). Applied to Billing.Deposit.PaymentDate. |
| - | BankName | NVARCHAR(150) | YES | - | CODE-BACKED | iDEAL issuing bank name extracted from PaymentData XML (/Deposit/BankNameAsString). One row per bank per day. |
| - | PaymentDate | DATE | NO | - | CODE-BACKED | Date of the transactions (CAST of PaymentDate to DATE). |
| - | TotalApproved | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent sum of all approved deposits (PaymentStatusID=2) for this bank on this date. |
| - | TotalApprovedFromWeb | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent approved amount from Web channel ('retoro'). |
| - | TotalApprovedFromMobile | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent approved amount from Mobile channel ('retoroios' + 'retoroandroid'). |
| - | TotalApprovedFromIOS | DECIMAL | YES | - | CODE-BACKED | USD-equivalent approved amount from iOS (PlatformID=2). |
| - | TotalApprovedFromAndroid | DECIMAL | YES | - | CODE-BACKED | USD-equivalent approved amount from Android (PlatformID=3). |
| - | AllTransactionsCountTotal | INT | NO | - | CODE-BACKED | Total count of all iDEAL transactions (approved + declined) for this bank/date. |
| - | AllTransactionsCountWeb / Mobile / IOS / Android | INT | NO | - | CODE-BACKED | Transaction count by channel. |
| - | ApprovedTransactionsCountTotal / Web / Mobile / IOS / Android | INT | NO | - | CODE-BACKED | Approved transaction counts by channel. |
| - | DeclinedTransactionsCountTotal / Web / Mobile / IOS / Android | INT | NO | - | CODE-BACKED | Declined transaction counts (PaymentStatusID<>2) by channel. |
| - | CountFTD | INT | NO | - | CODE-BACKED | Count of approved First Time Deposits via iDEAL. |
| - | TotalFTD | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent sum of approved FTD amounts. |
| - | TotalFTDFromMobile / Web / IOS / Android | DECIMAL | YES | - | CODE-BACKED | FTD amounts by channel. |
| - | ApproveRatioTotal | DECIMAL(10,2) | NO | 0 | CODE-BACKED | Approved/Total transaction ratio (0.00-1.00). 0 if no transactions. |
| - | ApproveRatioWeb / Mobile / IOS / Android | DECIMAL(10,2) | NO | 0 | CODE-BACKED | Approve ratio by channel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=34, Amount, PaymentDate, IsFTD, PaymentStatusID, SessionID | Billing.Deposit | SELECT | iDEAL deposit records; filtered by date range and FundingTypeID=34 |
| CID, PlayerLevelID | Customer.CustomerStatic | INNER JOIN | Excludes test accounts (PlayerLevelID<>4) |
| FundingID, FundingTypeID | Billing.Funding | INNER JOIN | iDEAL type filter |
| SessionID | STS_AuditLoginHistoryActive | OUTER APPLY | Maps session to ApplicationIdentifierFrom (platform detection) |
| ApplicationIdentifierFrom | Dictionary.ApplicationIdentifier | LEFT JOIN | App identifier to PlatformID mapping |
| PlatformID | Dictionary.Platform | LEFT JOIN | Platform name/ID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payments operations reporting | @StartDate, @EndDate | EXEC | iDEAL bank approval rate monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.iDEALDepositApproveRatio (procedure)
+-- Billing.Deposit (table)
+-- Customer.CustomerStatic (table) [PlayerLevelID<>4 filter]
+-- Billing.Funding (table) [FundingTypeID=34]
+-- STS_AuditLoginHistoryActive (table) [session->app identifier]
+-- Dictionary.ApplicationIdentifier (table) [app->platform mapping]
+-- Dictionary.Platform (table) [platform ID lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source; FundingTypeID=34 iDEAL deposits in date range |
| Customer.CustomerStatic | Table | PlayerLevelID<>4 filter (exclude test accounts) |
| Billing.Funding | Table | FundingTypeID=34 filter |
| STS_AuditLoginHistoryActive | Table | OUTER APPLY - session to application identifier for channel detection |
| Dictionary.ApplicationIdentifier | Table | App identifier to PlatformID mapping |
| Dictionary.Platform | Table | PlatformID to platform resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payments operations team | External | iDEAL approval rate reports and bank performance monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID=34 | Design | iDEAL only; no other payment types |
| PlayerLevelID<>4 | Business rule | Excludes test/internal accounts from analytics |
| UNION totals disabled | Bug/Design | `WHERE 1=0` in the UNION branch means 'SUM FOR ALL BANKS:' totals row is NEVER returned |
| STS_AuditLoginHistoryActive | Performance | Full-text session lookup per deposit; potential performance concern on large date ranges |
| No NOLOCK on Funding/CustomerStatic | Concurrency | NOLOCK only on Deposit; Funding and CustomerStatic use default isolation |

---

## 8. Sample Queries

### 8.1 Run iDEAL approval rate report for a month

```sql
EXEC Billing.iDEALDepositApproveRatio
    @StartDate = '2026-01-01',
    @EndDate = '2026-01-31'
-- Returns: per-bank per-day approve ratios and volume stats
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: Referenced in sprint retrospective notes ("Retro Global/IL 02-11-20 - Sprint 125", /spaces/MG) suggesting iDEAL approve ratio monitoring was a team focus in late 2020.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (Sprint 125 retro) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.iDEALDepositApproveRatio | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.iDEALDepositApproveRatio.sql*
