# Customer.RAFCompensationProcess_NogaJunk210725

> Core batch job for the Refer-a-Friend (RAF) program: evaluates referral pairs against multi-condition eligibility rules, detects fraud, and inserts eligible pairs into Customer.RafEligibleCustomers for downstream compensation processing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Debug INT - 0=Production, 1=Debug output, 2=Skip fraud check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RAFCompensationProcess_NogaJunk210725` is the central eligibility engine for eToro's Refer-a-Friend program. When a customer refers a friend who meets all conditions (verified identity, sufficient deposit, sufficient positions if required, waiting period elapsed, both in eligible countries), this procedure records the pair as eligible for compensation in `Customer.RafEligibleCustomers`.

The procedure was evolved from an earlier version that issued compensation directly; as of May 2023, compensation issuance was moved downstream - this procedure only determines eligibility. It was further refined in December 2024 to remove the History.Credit dependency (PART-3730) and in January 2025 to exclude Platinum/Platinum Plus/Diamond tier customers from fraud checks (PART-3907).

The procedure is an incremental batch job: it uses `Customer.RAFGiven` to find the last run time, then processes only customers who became newly eligible since that point. This delta approach keeps run time manageable even as the customer base grows.

---

## 2. Business Logic

### 2.1 Incremental Population Selection (18-Part Algorithm)

**What**: Multi-step population building that finds customers who may have become RAF-eligible since the last run.

**Rules**:
- `@StartTime` = last RAFGiven.RowInserted; defaults to 2019-01-01 if no previous run.
- `@EndTime` = GETUTCDATE() - 3ms (slightly before now to avoid boundary issues).
- Three INSERT patterns populate #Users:
  1. **VerificationLevel 3 change**: customers who newly reached VerificationLevelID=3 (fully verified) AND have a ReferralID AND registered after @StartTime.
  2. **First deposit approved**: customers with a confirmed FTD deposit (PaymentStatusID=2, IsFTD=1) in the detection window.
  3. **Minimum investment reached**: customers (both referred and referring) who hit the minimum position investment threshold defined in CountryRafConfiguration.
- Duplicate removal: customers already verified at level 3 before @StartTime are removed.

### 2.2 Multi-Condition Eligibility Check (Per-Pair)

**What**: Each referral pair is evaluated against country- and regulation-specific RAF configuration.

**Rules**:
- Both parties must be in countries with `Dictionary.Country.IsEligibleForRAFBonusCountry = 1`.
- RAF not already given: pair must not exist in Customer.RAFGiven.
- Referring party must have at least one confirmed deposit (PaymentStatusID=2).
- Both parties must have VerificationLevelID = 3 (fully KYC-verified).
- Country/regulation configuration (`Customer.CountryRafConfiguration`) provides per-pair thresholds:
  - Minimum FTD in cents for referring and referred parties.
  - Days to wait from FTD before compensation can be given.
  - Optional minimum positions amount in cents.
  - Date from which RAF counts (CountRAFFromDate).
- Referred must have registered after the later of the two parties' CountRAFFromDate.
- Eligible pairs are inserted into #Results, then into `Customer.RafEligibleCustomers` (deduplication against existing eligible and given records).

### 2.3 Fraud Detection

**What**: Known fraud customers and their referral pairs are excluded and recorded in Customer.RafFraudCustomers.

**Rules**:
- `Customer.CheckFraudUsers` is called (unless @Debug=2) to refresh the fraud detection tables.
- Pairs where either party is in `Customer.RafFraudCustomers` are deleted from #UsersToCheck.
- Pairs where either party is in `Customer.FraudUsers` with Main_Scoring >= 12 are inserted into #FraudCIDs.
- Fraud pairs are inserted into `Customer.RafFraudCustomers` and removed from consideration.
- As of PART-3907 (January 2025): Platinum/Platinum Plus/Diamond customers (PlayerLevelID 6, 7) are excluded from the fraud procedure check.

```
RAF Eligibility Flow:
  1. Build candidate population (#Users)
  2. Expand to referral pairs (#UsersToCheck)
  3. Filter: eligible countries, not already given, deposited, both verified
  4. Check fraud: run CheckFraudUsers, remove fraud pairs
  5. Per-pair: validate CountryRafConfiguration conditions
  6. Insert eligible pairs -> Customer.RafEligibleCustomers
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Debug | INT | YES | 0 | CODE-BACKED | Debug mode: 0=Production (fraud check runs, no debug output), 1=Debug (print diagnostic messages with timestamps and variable values), 2=No fraud (fraud detection skipped, used for testing eligibility logic without fraud filter). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (READ) | Customer.RAFGiven | Read | Gets last run timestamp; checks pairs already compensated |
| (READ) | History.BackOfficeCustomer | Read | Finds customers who newly reached VerificationLevelID=3 |
| (READ) | Customer.Customer | Read | Gets CID/ReferralID/country for referral pairs |
| (READ) | Customer.CustomerStatic | Read | Gets CountryID and registration date |
| (READ) | BackOffice.Customer | Read | Gets VerificationLevelID and DesignatedRegulationID |
| (READ) | Billing.Deposit | Read | Sums FTD deposits; checks deposit status |
| (READ) | BackOffice.CustomerAllTimeAggregatedData | Read | Gets TotalInvestment for minimum positions check |
| (READ) | BackOffice.CustomerDTDAggregatedData_1 | Read | (via position check logic) |
| (READ) | Customer.CountryRafConfiguration | Read | Per-country/regulation RAF thresholds and rules |
| (READ) | Dictionary.Country | Read | Checks IsEligibleForRAFBonusCountry |
| (READ) | Customer.RafFraudCustomers | Read + Insert | Reads known fraud pairs; inserts newly detected fraud |
| (READ) | Customer.FraudUsers | Read | Checks Main_Scoring >= 12 for fraud flag |
| (EXEC) | Customer.CheckFraudUsers | Callee | Refreshes fraud detection tables |
| (INSERT) | Customer.RafEligibleCustomers | Write | Inserts newly eligible referral pairs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the RAF scheduling job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RAFCompensationProcess_NogaJunk210725 (procedure)
├── Customer.RAFGiven (table) [READ - last run time + given pairs]
├── History.BackOfficeCustomer (table) [READ - verification level changes]
├── Customer.Customer (view) [READ - customer and referral data]
├── Customer.CustomerStatic (table) [READ - country + registration]
├── BackOffice.Customer (table) [READ - verification level + regulation]
├── Billing.Deposit (table) [READ - FTD deposits]
├── BackOffice.CustomerAllTimeAggregatedData (table) [READ - total investment]
├── Customer.CountryRafConfiguration (table) [READ - RAF configuration]
├── Dictionary.Country (table) [READ - country eligibility]
├── Customer.RafFraudCustomers (table) [READ + INSERT]
├── Customer.FraudUsers (table) [READ - fraud scoring]
├── Customer.CheckFraudUsers (procedure) [EXEC - fraud refresh]
└── Customer.RafEligibleCustomers (table) [INSERT - eligible pairs output]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RAFGiven | Table | READ - determines @StartTime (last job run) and deduplication |
| History.BackOfficeCustomer | Table | READ - temporal history of verification level changes |
| Customer.Customer | View | READ - referral relationships and country |
| Customer.CustomerStatic | Table | READ - CountryID, registration date |
| BackOffice.Customer | Table | READ - VerificationLevelID, DesignatedRegulationID |
| Billing.Deposit | Table | READ - FTD amounts and dates |
| BackOffice.CustomerAllTimeAggregatedData | Table | READ - total investment amounts |
| Customer.CountryRafConfiguration | Table | READ - per-country RAF thresholds |
| Dictionary.Country | Table | READ - IsEligibleForRAFBonusCountry |
| Customer.RafFraudCustomers | Table | READ (filter) + INSERT (new fraud pairs) |
| Customer.FraudUsers | Table | READ - Main_Scoring fraud flag |
| Customer.CheckFraudUsers | Procedure | EXEC - refreshes fraud tables |
| Customer.RafEligibleCustomers | Table | INSERT - output of eligible pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (RAF scheduling job) | External process | Calls this on a regular schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Incremental processing | Application | Uses MAX(RAFGiven.RowInserted) as @StartTime to process only new candidates |
| Both-parties KYC | Application | Both referring and referred must have VerificationLevelID=3 |
| Country eligibility | Application | Both parties' countries must have IsEligibleForRAFBonusCountry=1 in Dictionary.Country |
| Fraud exclusion | Application | Pairs involving customers in RafFraudCustomers or FraudUsers (Main_Scoring>=12) are excluded |
| Cursor-based per-pair evaluation | Application | FORWARD_ONLY cursor iterates eligible pairs for per-country-config condition checks |

---

## 8. Sample Queries

### 8.1 Check current RAF eligible pairs pending compensation

```sql
SELECT TOP 20
    re.ReferringCID,
    re.ReferredCID,
    re.ReferringRegulationId,
    re.ReferringCountryId,
    re.ReferringPlayerLevelId,
    re.CreatedDate
FROM Customer.RafEligibleCustomers re WITH (NOLOCK)
ORDER BY re.CreatedDate DESC
```

### 8.2 Verify RAF already given for a pair

```sql
SELECT
    ReferringCID,
    ReferredCID,
    ReferringCompensationAmount,
    ReferredCompensationAmount,
    RowInserted
FROM Customer.RAFGiven WITH (NOLOCK)
WHERE ReferringCID = 111111
   OR ReferredCID = 111111
ORDER BY RowInserted DESC
```

### 8.3 Check fraud pairs detected by the process

```sql
SELECT
    rf.ReferringCID,
    rf.ReferredCID,
    rf.HandledByRafServiceTime,
    fu.Main_Scoring AS ReferringFraudScore
FROM Customer.RafFraudCustomers rf WITH (NOLOCK)
LEFT JOIN Customer.FraudUsers fu WITH (NOLOCK) ON fu.CID = rf.ReferringCID
ORDER BY rf.ReferringCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RAFCompensationProcess_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RAFCompensationProcess_NogaJunk210725.sql*
