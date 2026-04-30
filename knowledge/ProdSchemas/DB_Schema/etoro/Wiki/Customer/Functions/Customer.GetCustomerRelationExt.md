# Customer.GetCustomerRelationExt

> Extended duplicate account detection: finds related accounts via email, migration origin, personal details (name+DOB+country), or any shared payment method - returning full profile enrichment including verification level and customer status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table-Valued Function (Multi-statement TVF) |
| **Key Identifier** | @CID int (returns 0..N related accounts) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCustomerRelationExt is the extended version of Customer.GetCustomerRelation. It adds three capabilities over the base function: (1) email-based matching using case-insensitive LowerEmail comparison, (2) personal details matching (FirstName+LastName+BirthDate+CountryID+Zip+Gender) to catch accounts that may have changed payment methods, and (3) any funding method match (not just credit cards and PayPal). It also enriches output with CustomerStatus (from Dictionary.PlayerStatus) and VerificationLevel (from BackOffice.Customer).

Created by Geri Reshef on 2017-09-12 for FB case 48789 "Multiple accounts - Phase 1 - Relations Tab", this function was built to power the "Relations" tab in the compliance back-office UI. Compliance officers use it to investigate whether a suspicious customer has created multiple eToro accounts, seeing both the match reason and the related account's verification status and player status.

---

## 2. Business Logic

### 2.1 Email Matching (Case-Insensitive)

**What**: Finds accounts sharing the same email address, using a case-insensitive normalized comparison.

**Columns/Parameters Involved**: `Email`, `MatchType` (value: 'Email')

**Rules**:
- Uses `LowerEmail` computed column: `LOWER(Email)` - ensures 'User@Test.com' matches 'user@test.com'
- UNION branch 1: `ON CCST.LowerEmail = MyCTE.LowerEmail AND CCST.CID <> MyCTE.CID`
- Unlike GetCustomerRelation (email removed), this function DOES match on email
- Match type: 'Email' or 'Email And Original ProviderID And OriginalCID' (compound match)

### 2.2 Migration Origin Matching

**What**: Finds accounts from the same migration source (same OriginalCID+OriginalProviderID).

**Columns/Parameters Involved**: `OriginalCID`, `OriginalProviderID`, `MatchType` (value: 'Original ProviderID And OriginalCID')

**Rules**:
- UNION branch 2: `ON CCST.OriginalCID = MyCTE.OriginalCID AND CCST.OriginalProviderID = MyCTE.OriginalProviderID AND CCST.CID <> MyCTE.CID`
- Same logic as GetCustomerRelation's migration match
- Combined match: 'Email And Original ProviderID And OriginalCID' when both email AND origin match

### 2.3 Personal Details Matching

**What**: Finds accounts with the same real-world identity (name, date of birth, country, postal code, gender).

**Columns/Parameters Involved**: `FirstName`, `LastName`, `MatchType` (value: 'PersonalDetails')

**Rules**:
- UNION branch 3: matches on FirstName + LastName + BirthDate + CountryID + Zip + Gender (all 6 must match)
- Catches cases where a person creates a second account with a different email and payment method
- All 6 fields must match exactly - high precision match to minimize false positives
- `MatchType = 'PersonalDetails'`

### 2.4 Any Payment Method Matching

**What**: Finds accounts sharing any funding instrument (not limited to credit cards and PayPal).

**Columns/Parameters Involved**: `MatchType` (value: FundingName from Dictionary.FundingType)

**Rules**:
- Uses `Dictionary.FundingType.Name` as MatchType (e.g., 'Visa', 'MasterCard', 'Bank Transfer', 'Skrill')
- Filter: `WHERE BF.FundingID <> 1` - excludes FundingID=1 (which appears to be a null/unknown funding record)
- Broader than GetCustomerRelation's credit+PayPal-only matching
- @SameFundingIds table variable collects these matches

### 2.5 Output Enrichment (Status + Verification)

**What**: Extends the base relation output with compliance-relevant account metadata.

**Columns/Parameters Involved**: `FirstName`, `LastName`, `CustomerStatus`, `VerificationLevel`

**Rules**:
- `CustomerStatus = Dictionary.PlayerStatus.Name WHERE PlayerStatusID = CCST.PlayerStatusID` - e.g., 'Active', 'Blocked', 'Pending'
- `VerificationLevel = BackOffice.Customer.VerificationLevelID` - KYC tier number (1=unverified, higher=more verified)
- Note: VerificationLevel column type is NVarChar(50) but stores VerificationLevelID (a numeric value) as a string
- Populated via UPDATE after @AllRecords is assembled

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
| 2 | OriginalProviderID | int | YES | - | CODE-BACKED | Migration source provider ID. Relevant when MatchType includes 'Original ProviderID And OriginalCID'. 0 for native eToro accounts. |
| 3 | OriginalCID | int | YES | - | CODE-BACKED | Migration source customer ID. Relevant when MatchType includes 'Original ProviderID And OriginalCID'. 0 for native eToro accounts. |
| 4 | UserName | varchar(20) | YES | - | VERIFIED | Login username of the related account. Collation: Latin1_General_BIN (binary). |
| 5 | Email | varchar(50) | YES | - | VERIFIED | Email address of the related account (LowerEmail used for matching, Email stored in output). Collation: Latin1_General_CI_AI. |
| 6 | FirstName | varchar(50) | YES | - | VERIFIED | First name of the related account holder. From Customer.Customer. Populated via UPDATE after matching. |
| 7 | LastName | varchar(50) | YES | - | VERIFIED | Last name of the related account holder. From Customer.Customer. Populated via UPDATE after matching. |
| 8 | CustomerStatus | varchar(50) | YES | - | CODE-BACKED | Player status name of the related account: Dictionary.PlayerStatus.Name WHERE PlayerStatusID=CCST.PlayerStatusID. E.g., 'Active', 'Blocked', 'Pending Deletion'. Allows compliance to quickly see if the related account is still active. |
| 9 | VerificationLevel | varchar(50) | YES | - | CODE-BACKED | KYC verification tier of the related account: CONVERT from BackOffice.Customer.VerificationLevelID. Stored as string despite being a numeric level. Higher values indicate more complete KYC verification. |
| 10 | TotalDeposit | decimal(34,4) | YES | - | CODE-BACKED | Lifetime deposits for the related account. From BackOffice.CustomerAllTimeAggregatedData. Used to assess financial significance of the relationship. NULL if no BackOffice record. |
| 11 | MatchType | xml | YES | - | CODE-BACKED | XML-encoded comma-separated match reasons. Values: 'Email', 'Original ProviderID And OriginalCID', 'Email And Original ProviderID And OriginalCID', 'PersonalDetails', or FundingType.Name (e.g., 'Visa', 'Skrill'). Multiple reasons for same CID are comma-concatenated via FOR XML PATH('') + STUFF with OPTION(RECOMPILE). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Email, OriginalCID, OriginalProviderID, FirstName, LastName | Customer.Customer | FROM (NoLock) - both @CID profile and related accounts | Customer identity data |
| (FundingIDs) | Billing.Deposit | JOIN on CID=@CID, then JOIN on FundingID | Find @CID's payment methods, then find other users with same methods |
| (FundingTypeID validation) | Billing.Funding | JOIN on FundingID | Filter: FundingID<>1 |
| (FundingName for MatchType) | Dictionary.FundingType | JOIN on FundingTypeID | Provides payment method name as match type label |
| CustomerStatus | Dictionary.PlayerStatus | JOIN on PlayerStatusID | Player status name for output |
| VerificationLevel | BackOffice.Customer | JOIN on CID | KYC verification level |
| TotalDeposit | BackOffice.CustomerAllTimeAggregatedData | UPDATE join | Lifetime deposit totals |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by the compliance "Relations Tab" in back-office UI. See also Customer.GetCustomerRelationsWithPlayerStatuses (stored procedure).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerRelationExt (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Billing.Deposit (table) [cross-schema]
|-  Billing.Funding (table) [cross-schema]
|-  Dictionary.FundingType (table) [cross-schema]
|-  Dictionary.PlayerStatus (table) [cross-schema]
|-  BackOffice.Customer (table) [cross-schema]
`-  BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - @CID profile + related account profiles (including LowerEmail computed column) |
| Billing.Deposit | Table (cross-schema) | JOIN to find @CID's FundingIDs and other depositors using same IDs |
| Billing.Funding | Table (cross-schema) | JOIN on FundingID to access FundingTypeID; filter FundingID<>1 |
| Dictionary.FundingType | Table (cross-schema) | JOIN to get payment method Name for MatchType label |
| Dictionary.PlayerStatus | Table (cross-schema) | UPDATE join to set CustomerStatus (Name) |
| BackOffice.Customer | Table (cross-schema) | UPDATE join to set VerificationLevel (VerificationLevelID) |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | UPDATE join to set TotalDeposit |

### 6.2 Objects That Depend On This

Not analyzed in this phase. Related: Customer.GetCustomerRelation (simpler base), Customer.GetCustomerRelationExtBI (BI variant), Customer.GetCustomerRelation_Test (test variant).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BD.CID <> @CID | Filter | Only OTHER customers with same payment method returned |
| BF.FundingID <> 1 | Filter | Excludes FundingID=1 (null/unknown payment record) |
| All 6 personal fields must match | Precision | PersonalDetails match requires all of FirstName, LastName, BirthDate, CountryID, Zip, Gender |
| OPTION(RECOMPILE) | Performance hint | Added to final INSERT/SELECT to force query plan recompile per execution (addresses parameter sniffing on large tables) |
| UNION (not UNION ALL) | Deduplication | Email and OriginalCID match branches are UNION'd (deduplicates), then FundingID matches inserted separately |

---

## 8. Sample Queries

### 8.1 Find all related accounts with their match reasons

```sql
SELECT CID, UserName, FirstName, LastName, Email, CustomerStatus, VerificationLevel, TotalDeposit, MatchType
FROM Customer.GetCustomerRelationExt(12345) WITH (NOLOCK)
ORDER BY TotalDeposit DESC;
```

### 8.2 Related accounts still active - compliance triage

```sql
SELECT CID, UserName, Email, CustomerStatus, MatchType
FROM Customer.GetCustomerRelationExt(12345) WITH (NOLOCK)
WHERE CustomerStatus = 'Active';
```

### 8.3 Customers with personal-details matches (potential KYC fraud)

```sql
SELECT
    c.CID AS InputCID,
    c.UserName AS InputUser,
    rel.CID AS MatchedCID,
    rel.UserName AS MatchedUser,
    rel.MatchType
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetCustomerRelationExt(c.CID) rel
WHERE CAST(rel.MatchType AS VARCHAR(500)) LIKE '%PersonalDetails%'
  AND c.IsReal = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCustomerRelationExt | Type: Multi-statement TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCustomerRelationExt.sql*
