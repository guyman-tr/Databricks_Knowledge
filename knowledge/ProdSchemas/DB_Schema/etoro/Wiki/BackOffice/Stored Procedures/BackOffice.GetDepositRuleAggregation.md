# BackOffice.GetDepositRuleAggregation

> Aggregates deposit history for a customer over a configurable time window, flagging each funding method as document-verified, trusted (3+ months old), and 3DS-verified - feeds the deposit risk rules engine (MOP block, velocity checks).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TWO result sets: per-deposit detail and per-funding aggregation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDepositRuleAggregation is the data provider for eToro's deposit risk rules engine. It computes a customer's deposit history over a configurable lookback window and enriches each deposit with three compliance flags: whether the funding method has a KYC document (IsDefinedCreditCard), whether it was used successfully 3+ months ago (IsTrustedFunding), and whether 3D Secure authentication was completed (IsFundingHasThreeDs). The result feeds risk rules like "TooManyCreditCards", "CreditCardVelocity", "TooManyPayPalAccounts", and similar MOP (Method of Payment) blocking rules.

The procedure produces two result sets: (1) the individual deposit-level detail with flags, enabling rules that evaluate per-deposit behavior, and (2) a per-funding aggregation with total deposit count and approved amount, enabling rules that evaluate funding method-level patterns (e.g., "customer has used 5 different credit cards in the last 30 days").

Originally created July 2020 (MIMOPSA-1713 / MIMOPSA-1322 "Too many PP & CC - MOP Block is working wrong"). Extensively enhanced over 2020-2023 to add trusted funding detection, 3DS flags, credit card country, and performance improvements. The CreditCardCountryId field (added Sep 2021, MIMOPSA-5077 / MIMOPSA-5075 "TooManyCreditCards Changes") supports country-based credit card blocking rules.

---

## 2. Business Logic

### 2.1 Lookback Window Calculation

**What**: The time window for deposit analysis is defined by a flexible @TimeFrame + @TimeFrameUnit combination, anchored either at the current time or at a specific deposit's PaymentDate.

**Columns/Parameters Involved**: `@TimeFrame`, `@TimeFrameUnit`, `@DepositID`, `@LastRuleTime`

**Rules**:
- If `@DepositID` is NULL: anchor point `@ToTime = GETUTCDATE()` (now)
- If `@DepositID` is set: `@ToTime = Billing.Deposit[DepositID].PaymentDate` (evaluate as of that deposit's time)
- `@TimeFrameUnit` values: 1=second, 2=minute, 3=hour, 4=day, 5=month, 6=year
- `@FromTime = DATEADD(@TimeFrameUnit, -@TimeFrame, @ToTime)` (e.g., @TimeFrame=30, @TimeFrameUnit=4 = last 30 days)
- `@LastRuleTime` override: If set and `> @FromTime`, use `@LastRuleTime` as `@FromTime` (allows the rules engine to specify an effective start that overrides the calculated window start)
- Deposits returned: all for `@CID` where `PaymentDate BETWEEN @FromTime AND @ToTime`

**Diagram**:
```
@DepositID=NULL: @ToTime=NOW()
@DepositID=X:   @ToTime=Deposit[X].PaymentDate

@ToTime - (@TimeFrame @TimeFrameUnit) = @FromTime
IF @LastRuleTime > @FromTime: @FromTime = @LastRuleTime

Window: [@FromTime, @ToTime]
Returns all deposits by @CID in this window
```

### 2.2 Funding Method Trust and Verification Flags

**What**: Each deposit in the window is enriched with three flags that the risk rules use to distinguish trusted vs untrusted payment methods.

**Columns/Parameters Involved**: `IsDefinedCreditCard`, `IsTrustedFunding`, `IsFundingHasThreeDs`

**Rules**:
- `IsDefinedCreditCard=1`: FundingID is in the result of `BackOffice.GetCustomerVerifiedCCFundings(@CID)` - the customer has a Credit Card KYC document linked to this funding method. Indicates document verification.
- `IsTrustedFunding=1`: FundingID has at least one successful deposit (`PaymentStatusID=2`) with `PaymentDate <= DATEADD(MONTH, -3, GETDATE())` - used successfully more than 3 months ago across ANY customer. Indicates an established, non-new payment method.
- `IsFundingHasThreeDs=1`: The FundingID (FundingTypeID=1 only - credit cards) has at least one prior deposit by this CID where `ThreeDsResponseType=1` in the deposit's PaymentData XML. Indicates 3D Secure was completed.
- These three flags together allow the rules engine to apply different thresholds: e.g., document-verified trusted CC cards with 3DS may be allowed higher deposit limits.

### 2.3 Two Result Sets

**What**: The procedure returns two result sets with different granularity.

**Rules**:
- **Result Set 1 (Per-Deposit)**: One row per deposit in the lookback window. Columns: DepositID, FundingTypeID, Amount (net = Amount * ExchangeRate - Commission), PaymentStatusID, PaymentDate, FundingDate, IsDefinedCreditCard, IsTrustedFunding, IsFundingHasThreeDs, FundingID
- **Result Set 2 (Per-Funding Aggregation)**: One row per FundingID used in the window. Columns: FundingID, FundingTypeID, IsDefinedCreditCard, IsTrustedFunding, DepositCount (count of deposits), ApprovedDepositAmount (sum of Amount where PaymentStatusID=2), CreditCardCountryId (BinCountryIDAsInteger from FundingData XML)
- Rules that count "how many credit cards" use RS2. Rules that evaluate deposit amounts over time use RS1.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID whose deposits are being aggregated. All Billing.Deposit records for this CID in the time window are analyzed. |
| 2 | @TimeFrame | INT | NO | - | CODE-BACKED | Numeric size of the lookback window. Combined with @TimeFrameUnit. E.g., value=30 with unit=4 (day) means "last 30 days". |
| 3 | @TimeFrameUnit | INT | NO | - | CODE-BACKED | Unit for the time frame: 1=second, 2=minute, 3=hour, 4=day, 5=month, 6=year. Drives DATEADD function selection. |
| 4 | @DepositID | INT | YES | NULL | CODE-BACKED | Optional anchor deposit. If set, the ToTime anchor is this deposit's PaymentDate instead of GETUTCDATE(). Allows evaluating "as of when this deposit occurred". Used when processing a specific deposit event. |
| 5 | @LastRuleTime | DATETIME | YES | NULL | CODE-BACKED | Optional override for the window start. If set and > the calculated @FromTime, replaces @FromTime. Allows the rules engine to specify an effective start that differs from the pure time-frame calculation (e.g., when a rule was last evaluated). |

**Result Set 1 - Per-Deposit Detail:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DepositID | int | NO | - | CODE-BACKED | Unique deposit identifier from Billing.Deposit. |
| R2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type (1=Credit Card, 2=Wire Transfer, etc.). From Billing.Funding. |
| R3 | Amount | money | NO | - | CODE-BACKED | Net deposit amount in USD: `Amount * ExchangeRate - Commission`. ISNULL -> 0. |
| R4 | PaymentStatusID | int | NO | - | CODE-BACKED | Status of the deposit: 2=approved/successful. From Billing.Deposit. |
| R5 | PaymentDate | datetime | NO | - | CODE-BACKED | When the deposit was processed. From Billing.Deposit. |
| R6 | FundingDate | datetime | YES | - | CODE-BACKED | When the funding method was created. From Billing.Funding.DateCreated. |
| R7 | IsDefinedCreditCard | bit | NO | - | VERIFIED | 1 if this FundingID has a Credit Card KYC document linked via GetCustomerVerifiedCCFundings. Indicates the customer uploaded a document verifying ownership of this card. |
| R8 | IsTrustedFunding | bit | NO | - | VERIFIED | 1 if this FundingID was successfully used (PaymentStatusID=2) more than 3 months ago. Indicates an established payment method, reducing risk score. |
| R9 | IsFundingHasThreeDs | bit | NO | - | VERIFIED | 1 if this credit card FundingID has ever had a 3DS response (ThreeDsResponseType=1) in any deposit by this CID. Only computed for FundingTypeID=1. |
| R10 | FundingID | int | NO | - | CODE-BACKED | Payment method identifier from Billing.Funding. Added Sep 2021 (OPSS-137). |

**Result Set 2 - Per-Funding Aggregation:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| A1 | FundingID | int | NO | - | CODE-BACKED | Payment method identifier. One row per distinct FundingID used in the window. |
| A2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. |
| A3 | IsDefinedCreditCard | bit | NO | - | VERIFIED | Document-verified credit card flag (same logic as RS1). |
| A4 | IsTrustedFunding | bit | NO | - | VERIFIED | Trusted (3+ months old) funding flag (same logic as RS1). |
| A5 | DepositCount | int | NO | - | CODE-BACKED | Total number of deposit attempts using this FundingID in the time window (all statuses). Used by velocity and count-based rules (e.g., TooManyCreditCards). |
| A6 | ApprovedDepositAmount | money | NO | - | CODE-BACKED | Sum of net Amount for approved deposits only (PaymentStatusID=2) using this FundingID in the window. Used for amount-based rules. |
| A7 | CreditCardCountryId | int | YES | - | VERIFIED | BIN country ID of the credit card, extracted from Billing.Funding.FundingData XML (BinCountryIDAsInteger). NULL for non-credit-card fundings. Added Sep 2021 (MIMOPSA-5077) for country-based credit card blocking rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BackOffice.GetCustomerVerifiedCCFundings | EXEC | Called to populate @DefinedCreditCards temp table |
| @CID | Billing.Deposit | SELECT | Main data source for deposit history in the time window |
| FundingID | Billing.Funding | INNER JOIN | Provides FundingTypeID, FundingData (BinCountry), FundingDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the deposit risk rules engine (automated MOP blocking system). No stored procedure callers found within BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDepositRuleAggregation (procedure)
├── BackOffice.GetCustomerVerifiedCCFundings (procedure)
│     ├── BackOffice.CustomerDocumentToDocumentType (table)
│     ├── BackOffice.CustomerDocument (table)
│     └── Billing.Funding (table)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerVerifiedCCFundings | Procedure | EXEC - populates @DefinedCreditCards with document-verified CC FundingIDs |
| Billing.Deposit | Table | Primary data source - deposits by @CID in the time window; also 3DS check |
| Billing.Funding | Table | FundingTypeID, DateCreated, FundingData (BinCountryIDAsInteger) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit rules engine (MOP blocking system) | External | READER - calls to get deposit aggregation for risk rule evaluation (TooManyCreditCards, CreditCardVelocity, etc.) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses temp table variables (@DefinedCreditCards, @TrustedFundings, @DepositIDs, @TempResult) for intermediate results. Performance note: @DepositIDs populated first to avoid repeated full-table scans on Billing.Deposit.

---

## 8. Sample Queries

### 8.1 Aggregate deposits for a customer in the last 30 days
```sql
EXEC BackOffice.GetDepositRuleAggregation
    @CID = 12345,
    @TimeFrame = 30,
    @TimeFrameUnit = 4  -- days
-- Returns 2 result sets: per-deposit detail and per-funding aggregation
```

### 8.2 Aggregate as of a specific deposit (point-in-time evaluation)
```sql
EXEC BackOffice.GetDepositRuleAggregation
    @CID = 12345,
    @TimeFrame = 24,
    @TimeFrameUnit = 3,   -- hours
    @DepositID = 55555    -- evaluate as of this deposit's payment date
```

### 8.3 Ad-hoc: check trusted fundings for a customer
```sql
-- Fundings used successfully more than 3 months ago
SELECT DISTINCT FundingID
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 12345
  AND PaymentStatusID = 2
  AND PaymentDate <= DATEADD(MONTH, -3, GETDATE())
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-1713](https://etoro-jira.atlassian.net/browse/MIMOPSA-1713) | Jira | Initial creation as part of "Too many PP & CC - MOP Block is working wrong" (MIMOPSA-1322) - Jul 2020 |
| [MIMOPSA-5077](https://etoro-jira.atlassian.net/browse/MIMOPSA-5077) | Jira | CreditCardCountryId added for country-based CC blocking rules as part of "TooManyCreditCards Changes" (MIMOPSA-5075) - Sep 2021 |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDepositRuleAggregation | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDepositRuleAggregation.sql*
