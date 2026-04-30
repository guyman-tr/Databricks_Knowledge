# Customer.GetCustomerRelation_Test

> Test/development variant of GetCustomerRelation: same duplicate account detection by credit card, PayPal, and migration origin, but also includes email matching - providing a broader detection set for testing new relation-detection logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table-Valued Function (Multi-statement TVF) |
| **Key Identifier** | @CID int (returns 0..N related accounts) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCustomerRelation_Test is a test/development variant of Customer.GetCustomerRelation. It has the same 7-column output schema and the same credit card (FundingTypeID=1), PayPal (FundingTypeID=3), and OriginalCID+OriginalProviderID matching logic. The key difference: email matching IS active in this variant (the email comparison that was removed from GetCustomerRelation in August 2022 is present here).

The "_Test" suffix indicates this function was created to test alternative or expanded matching logic before deciding which approach to use in production. The email+OriginalCID matching branch (commented out in GetCustomerRelation's production code) is active in this function. It serves as a sandbox for evaluating the impact of email-based relation detection.

---

## 2. Business Logic

### 2.1 Match Detection: Email + Migration Origin (Active in Test Variant)

**What**: Matches accounts that share the same email address OR share the same OriginalCID+OriginalProviderID.

**Columns/Parameters Involved**: `MatchType` (values: 'Email', 'Original ProviderID and OriginalCID', 'Email and Original ProviderID and OriginalCID')

**Rules**:
- `ON (CCST.Email = MyCTE.Email AND CCST.CID <> MyCTE.CID) OR (CCST.OriginalCID = MyCTE.OriginalCID AND CCST.OriginalProviderID = MyCTE.OriginalProviderID AND CCST.CID <> MyCTE.CID)`
- This is the EMAIL-INCLUDED version - unlike production GetCustomerRelation where email match is commented out
- Match type assigned by CASE: 'Email and Original ProviderID and OriginalCID', 'Original ProviderID and OriginalCID', or 'Email'

### 2.2 Match Detection: Credit Card and PayPal

**What**: Same as production GetCustomerRelation - finds accounts using the same credit card or PayPal account.

**Columns/Parameters Involved**: `MatchType` (values: 'Credit', 'PayPal')

**Rules**:
- Credit: FundingTypeID=1, same FundingID -> MatchType = 'Credit'
- PayPal: FundingTypeID=3, same FundingID -> MatchType = 'PayPal'
- Identical logic to production GetCustomerRelation

### 2.3 MatchType Aggregation

**What**: Same XML-encoded comma-separated concatenation as production GetCustomerRelation.

**Columns/Parameters Involved**: `MatchType` (XML)

**Rules**:
- `FOR XML PATH('') + STUFF` pattern aggregates all match reasons per related CID
- Result is XML type - same as GetCustomerRelation, different from GetCustomerRelationExtBI (varchar)
- Note: TotalDeposit fetching via BackOffice.CustomerAllTimeAggregatedData is still commented out in the INSERT statements (legacy commented code) but IS populated via the UPDATE at the end

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
| 1 | CID | int | YES | - | VERIFIED | Customer ID of the related account. |
| 2 | OriginalProviderID | int | YES | - | CODE-BACKED | Migration source provider ID. 0 for native eToro accounts. |
| 3 | OriginalCID | int | YES | - | CODE-BACKED | Migration source customer ID. 0 for native eToro accounts. |
| 4 | UserName | varchar(20) | YES | - | VERIFIED | Login username. Collation: Latin1_General_BIN. |
| 5 | Email | varchar(50) | YES | - | VERIFIED | Email address of the related account. Collation: Latin1_General_CI_AI. Also used as a MATCHING CRITERION in this variant (unlike production GetCustomerRelation). |
| 6 | TotalDeposit | decimal(34,4) | YES | - | CODE-BACKED | Lifetime deposits for the related account. From BackOffice.CustomerAllTimeAggregatedData. NULL if no BackOffice record. |
| 7 | MatchType | xml | YES | - | CODE-BACKED | XML-encoded comma-separated match reasons. Possible values: 'Email', 'Original ProviderID and OriginalCID', 'Email and Original ProviderID and OriginalCID', 'Credit', 'PayPal'. Email-based matches are unique to this test variant - production GetCustomerRelation excludes them. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Email, OriginalCID, OriginalProviderID, UserName | Customer.Customer | FROM (Customer.Customer NoLock) | Customer profiles for input and related accounts |
| (credit card FundingIDs) | Billing.Deposit | JOIN on CID=@CID and on FundingID | Find @CID's credit cards and other depositors |
| (PayPal FundingIDs) | Billing.Deposit | JOIN on CID=@CID and on FundingID | Find @CID's PayPal and other depositors |
| (FundingTypeID validation) | Billing.Funding | JOIN on FundingID | Type 1=Credit, Type 3=PayPal |
| TotalDeposit | BackOffice.CustomerAllTimeAggregatedData | UPDATE join | Lifetime deposit totals |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Test/development function - likely not called from production code paths.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerRelation_Test (function)
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
| Customer.Customer | View | FROM - @CID profile and related account profiles |
| Billing.Deposit | Table (cross-schema) | JOIN to find @CID's credit card and PayPal FundingIDs; find other users with same IDs |
| Billing.Funding | Table (cross-schema) | JOIN on FundingID to validate FundingTypeID (1=Credit, 3=PayPal) |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | UPDATE join to populate TotalDeposit |

### 6.2 Objects That Depend On This

Not analyzed in this phase. Test variant - not expected to have production dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BD.CID <> @CID | Filter | Only OTHER customers returned |
| FundingTypeID = 1 | Filter | Credit card matching |
| FundingTypeID = 3 | Filter | PayPal matching |
| Email matching ACTIVE | Difference from production | Unlike GetCustomerRelation, email comparison is NOT commented out |

---

## 8. Sample Queries

### 8.1 Test email-based matching alongside payment matching

```sql
-- This variant returns email matches that GetCustomerRelation would miss
SELECT CID, UserName, Email, TotalDeposit, MatchType
FROM Customer.GetCustomerRelation_Test(12345) WITH (NOLOCK)
ORDER BY TotalDeposit DESC;
```

### 8.2 Compare results between test and production variants

```sql
-- Production variant
SELECT CID, CAST(MatchType AS VARCHAR(500)) AS MatchType_Prod
FROM Customer.GetCustomerRelation(12345) WITH (NOLOCK);

-- Test variant (includes email matches)
SELECT CID, CAST(MatchType AS VARCHAR(500)) AS MatchType_Test
FROM Customer.GetCustomerRelation_Test(12345) WITH (NOLOCK);
```

### 8.3 Email-only matches found by test variant

```sql
SELECT t.CID, t.UserName, t.Email, CAST(t.MatchType AS VARCHAR(500)) AS MatchType
FROM Customer.GetCustomerRelation_Test(12345) t WITH (NOLOCK)
WHERE CAST(t.MatchType AS VARCHAR(500)) = 'Email'
  AND t.CID NOT IN (SELECT CID FROM Customer.GetCustomerRelation(12345) WITH (NOLOCK));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCustomerRelation_Test | Type: Multi-statement TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCustomerRelation_Test.sql*
