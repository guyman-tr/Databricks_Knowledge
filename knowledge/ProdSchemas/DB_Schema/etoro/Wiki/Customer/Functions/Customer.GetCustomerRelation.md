# Customer.GetCustomerRelation

> Fraud detection function: finds all other customer accounts that share the same credit card, PayPal account, or original migration identity as the given customer - used to identify duplicate or related accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table-Valued Function (Multi-statement TVF) |
| **Key Identifier** | @CID int (returns 0..N related accounts) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCustomerRelation finds all other customer accounts that are "related" to a given @CID through shared payment instruments or a shared migration origin. Relationship is detected by three independent signals: same credit card used for deposits, same PayPal account used for deposits, or same OriginalCID+OriginalProviderID pair (indicating migration from the same source account).

This function is the core of eToro's duplicate account detection system. Compliance, fraud, and KYC teams use it to investigate whether multiple eToro accounts belong to the same real-world individual. A customer with multiple accounts may be evading trading restrictions, withdrawing bonuses multiple times, or circumventing regulatory controls.

The function was originally written in November 2012 (FB case 14215) with a performance rewrite, and email comparison was explicitly removed on 2022-08-02 by Shay Oren (email is now unique per CID so email matching no longer adds value). The result set includes the type of match as XML, listing all match reasons comma-separated.

---

## 2. Business Logic

### 2.1 Match Detection by Shared Payment Instrument

**What**: Finds accounts that used the same credit card or PayPal account to make deposits.

**Columns/Parameters Involved**: `MatchType` (values: 'Credit', 'PayPal')

**Rules**:
- Credit card match: Billing.Deposit WHERE FundingTypeID=1 (credit/debit card) - finds all @CID's card FundingIDs, then finds other CIDs that used any of those same FundingIDs
- PayPal match: Billing.Deposit WHERE FundingTypeID=3 (PayPal) - same logic for PayPal accounts
- Matching is by FundingID (the unique ID of the payment method) - same physical card = same FundingID
- Only DISTINCT matches are returned

### 2.2 Match Detection by Migration Origin

**What**: Finds accounts migrated from the same source platform account.

**Columns/Parameters Involved**: `OriginalCID`, `OriginalProviderID`, `MatchType` (value: 'Original ProviderID and OriginalCID')

**Rules**:
- Matches on `CCST.OriginalCID = MyCTE.OriginalCID AND CCST.OriginalProviderID = MyCTE.OriginalProviderID`
- Both columns must match (prevents accidental matches on default values)
- This catches cases where two eToro accounts were created from the same legacy/provider account
- OriginalCID=0 AND OriginalProviderID=0 are native accounts - they should NOT match each other (though the code does not explicitly exclude them - this is a potential false-positive risk for native accounts)

### 2.3 Match Type Aggregation (XML)

**What**: A single returned account may match on multiple signals. MatchType aggregates all reasons.

**Columns/Parameters Involved**: `MatchType` (XML type)

**Rules**:
- `FOR XML PATH('')` with `STUFF` concatenates all MatchType values for the same CID
- Possible values: 'Credit', 'PayPal', 'Original ProviderID and OriginalCID', 'Email and Original ProviderID and OriginalCID' (legacy - email match removed 2022-08-02)
- Result is XML type; callers parse comma-separated values from XML wrapper
- MatchType = 'Credit,PayPal' means the related account shared BOTH a credit card AND PayPal

### 2.4 Email Match Removal (Historical Note)

**What**: Email matching was removed from this function on 2022-08-02.

**Rules**:
- Original function matched on email similarity (see commented-out code: `CCST.Email = MyCTE.Email`)
- Removed by Shay Oren (2022-08-02): "Remove email comparison because email is unique for CID"
- Email-based matching moved to GetCustomerRelationExt (which still uses LowerEmail)
- GetCustomerRelation now only matches payment instruments + migration origin

---

## 3. Data Overview

N/A for Multi-statement TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to investigate. All returned rows are OTHER accounts related to this customer. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | VERIFIED | Customer ID of the RELATED account (not the input @CID). |
| 2 | OriginalProviderID | int | YES | - | CODE-BACKED | Migration source provider ID for the related account. Matches @CID's OriginalProviderID when match type includes 'Original ProviderID and OriginalCID'. 0 for native eToro accounts. |
| 3 | OriginalCID | int | YES | - | CODE-BACKED | Migration source customer ID for the related account. Matches @CID's OriginalCID when match type includes 'Original ProviderID and OriginalCID'. 0 for native eToro accounts. |
| 4 | UserName | varchar(20) | YES | - | VERIFIED | Login username of the related account. Collation: Latin1_General_BIN (binary case-sensitive). |
| 5 | Email | varchar(50) | YES | - | VERIFIED | Email address of the related account. Collation: Latin1_General_CI_AI (case-insensitive). Used for display/investigation only - NOT used as a matching criterion since email is now unique per CID. |
| 6 | TotalDeposit | decimal(34,4) | YES | - | CODE-BACKED | Lifetime total deposits for the related account. From BackOffice.CustomerAllTimeAggregatedData. NULL if no BackOffice record. Used by compliance to assess the financial significance of the related account. |
| 7 | MatchType | xml | YES | - | CODE-BACKED | XML-encoded comma-separated list of all reasons this account matched @CID. Possible values: 'Credit' (shared credit card), 'PayPal' (shared PayPal), 'Original ProviderID and OriginalCID' (migration origin match). Multiple reasons are comma-separated via FOR XML PATH('') + STUFF pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OriginalProviderID, OriginalCID, UserName, Email | Customer.Customer | FROM (CCST alias) | Customer profiles for input and related accounts |
| (credit card FundingIDs) | Billing.Deposit | JOIN on CID=@CID for input, JOIN on FundingID for related | Find @CID's cards then other depositors using same cards |
| (FundingTypeID validation) | Billing.Funding | JOIN on FundingID | Filter by payment method type (1=Credit, 3=PayPal) |
| TotalDeposit | BackOffice.CustomerAllTimeAggregatedData | UPDATE join | Lifetime deposit amount for related accounts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. See stored procedure Customer.GetCustomerRelationsWithPlayerStatuses which likely calls this function family.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerRelation (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Billing.Deposit (table) [cross-schema]
|-  Billing.Funding (table) [cross-schema]
`-  BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - @CID profile (email, OriginalCID, OriginalProviderID) + related account profiles |
| Billing.Deposit | Table (cross-schema) | JOIN to find @CID's payment FundingIDs; JOIN again to find other depositors using same FundingIDs |
| Billing.Funding | Table (cross-schema) | JOIN to filter by FundingTypeID (1=credit card, 3=PayPal) |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | UPDATE to populate TotalDeposit for related accounts |

### 6.2 Objects That Depend On This

Not analyzed in this phase. Related: Customer.GetCustomerRelationExt (extended version), Customer.GetCustomerRelationExtBI (BI variant), Customer.GetCustomerRelation_Test (test variant).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BD.CID <> @CID | Filter | Only OTHER customers with the same payment method are returned, not @CID itself |
| FundingTypeID = 1 | Filter | Credit card match uses FundingTypeID=1 only |
| FundingTypeID = 3 | Filter | PayPal match uses FundingTypeID=3 only |
| OriginalCID AND OriginalProviderID both match | Dual condition | Both columns must match to prevent false positives on default values |
| Email comparison REMOVED (2022-08-02) | Historical | Original email matching commented out by Shay Oren; email is unique per CID so email matching became redundant |

---

## 8. Sample Queries

### 8.1 Find all accounts related to a customer

```sql
SELECT CID, UserName, Email, TotalDeposit, MatchType
FROM Customer.GetCustomerRelation(12345) WITH (NOLOCK)
ORDER BY TotalDeposit DESC;
```

### 8.2 Count related accounts with significant deposits (fraud risk assessment)

```sql
SELECT COUNT(*) AS RelatedAccountCount,
       SUM(TotalDeposit) AS TotalRelatedDeposits
FROM Customer.GetCustomerRelation(12345) WITH (NOLOCK)
WHERE TotalDeposit > 0;
```

### 8.3 Find customers with many related accounts (duplicate account suspects)

```sql
SELECT
    c.CID,
    c.UserName,
    c.Email,
    RelCount.NumberOfRelatedAccounts
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY (
    SELECT COUNT(*) AS NumberOfRelatedAccounts
    FROM Customer.GetCustomerRelation(c.CID) WITH (NOLOCK)
) RelCount
WHERE RelCount.NumberOfRelatedAccounts > 2
  AND c.IsReal = 1
ORDER BY RelCount.NumberOfRelatedAccounts DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCustomerRelation | Type: Multi-statement TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCustomerRelation.sql*
