# Customer.GetCustomerRelationExtBI

> BI-compatible variant of GetCustomerRelationExt: same duplicate account detection logic but returns MatchType as varchar(8000) instead of XML, enabling direct use in BI tools and data warehouse exports.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table-Valued Function (Multi-statement TVF) |
| **Key Identifier** | @CID int (returns 0..N related accounts) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCustomerRelationExtBI is the BI (Business Intelligence) variant of Customer.GetCustomerRelationExt. The function signatures and output schemas are identical except for one column: MatchType is `varchar(8000)` here instead of `xml` in GetCustomerRelationExt. This change makes the function compatible with BI tools, data warehouse ETL pipelines, and reporting systems that cannot consume SQL Server XML data types.

The function detects related accounts by email, migration origin (OriginalCID+OriginalProviderID), and shared payment methods. Unlike GetCustomerRelationExt, it does NOT include PersonalDetails matching (no FirstName+LastName+BirthDate+CountryID+Zip+Gender check). This makes it slightly less comprehensive but suitable for BI contexts where XML types and complex matching are not needed.

BI teams use this function to populate relationship graphs, populate compliance reports, and feed fraud-detection dashboards where multiple CSV exports or flat-file outputs are required.

---

## 2. Business Logic

### 2.1 Match Signals (Subset of GetCustomerRelationExt)

**What**: Detects related accounts by three signals - email match, migration origin match, and shared payment method.

**Columns/Parameters Involved**: `MatchType` (varchar(8000))

**Rules**:
- Email match: `ON (CCST.Email = MyCTE.Email AND CCST.CID <> MyCTE.CID)` - direct email string comparison (NOT using LowerEmail computed column, unlike GetCustomerRelationExt)
- OriginalCID+OriginalProviderID match: same as GetCustomerRelationExt
- Any payment method match (FundingID<>1): same as GetCustomerRelationExt
- **NO PersonalDetails match**: GetCustomerRelationExtBI omits the name/DOB/country/gender UNION branch that GetCustomerRelationExt includes

### 2.2 MatchType as varchar(8000)

**What**: The critical difference from GetCustomerRelationExt - MatchType is converted from XML to varchar.

**Columns/Parameters Involved**: `MatchType`

**Rules**:
- `CONVERT(VARCHAR(8000), (STUFF((SELECT ',' + MatchType FROM @AllRecords FOR XML PATH('')),1,1,'')))`
- The FOR XML PATH still generates XML internally but CONVERT wraps it into a plain string
- BI tools can directly use this as a string column in GROUP BY, WHERE LIKE, and string functions
- Possible values: 'Email', 'Email and Original ProviderID and OriginalCID', 'Original ProviderID and OriginalCID', or FundingType.Name (e.g., 'Visa', 'PayPal', 'Bank Transfer')
- Note: case differs from GetCustomerRelationExt - this function uses 'Email and Original...' (lowercase 'and') vs GetCustomerRelationExt uses 'Email And Original...' (title case 'And')

### 2.3 Email Comparison Difference from GetCustomerRelationExt

**What**: This function uses raw email comparison, not LowerEmail.

**Rules**:
- GetCustomerRelationExt uses `CCST.LowerEmail = MyCTE.LowerEmail` (case-insensitive via computed column)
- GetCustomerRelationExtBI uses `CCST.Email = MyCTE.Email` (case sensitivity depends on column collation Latin1_General_CI_AI, which is CI = case-insensitive)
- In practice both should match the same emails, but GetCustomerRelationExt is more explicit about case normalization

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
| 2 | OriginalProviderID | int | YES | - | CODE-BACKED | Migration source provider ID. Relevant when MatchType includes 'Original ProviderID and OriginalCID'. 0 for native accounts. |
| 3 | OriginalCID | int | YES | - | CODE-BACKED | Migration source customer ID. Relevant when MatchType includes 'Original ProviderID and OriginalCID'. 0 for native accounts. |
| 4 | UserName | varchar(20) | YES | - | VERIFIED | Login username of the related account. Collation: Latin1_General_BIN. |
| 5 | Email | varchar(50) | YES | - | VERIFIED | Email address of the related account. Collation: Latin1_General_CI_AI. |
| 6 | FirstName | varchar(50) | YES | - | VERIFIED | First name of the related account holder. From Customer.Customer. Populated via UPDATE. |
| 7 | LastName | varchar(50) | YES | - | VERIFIED | Last name of the related account holder. From Customer.Customer. Populated via UPDATE. |
| 8 | CustomerStatus | varchar(50) | YES | - | CODE-BACKED | Player status name: Dictionary.PlayerStatus.Name. e.g., 'Active', 'Blocked'. Populated via UPDATE. |
| 9 | VerificationLevel | varchar(50) | YES | - | CODE-BACKED | KYC verification tier: BackOffice.Customer.VerificationLevelID stored as string. Higher=more verified. Populated via UPDATE. |
| 10 | TotalDeposit | decimal(34,4) | YES | - | CODE-BACKED | Lifetime deposits for the related account. From BackOffice.CustomerAllTimeAggregatedData. NULL if no BackOffice record. |
| 11 | MatchType | varchar(8000) | YES | - | CODE-BACKED | Comma-separated plain-text list of match reasons (BI-friendly version of GetCustomerRelationExt.MatchType XML). Values: 'Email', 'Email and Original ProviderID and OriginalCID', 'Original ProviderID and OriginalCID', or FundingType.Name. PersonalDetails is NOT a possible value in this variant. CONVERT(VARCHAR(8000), ...) wraps the FOR XML PATH output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Email, OriginalCID, OriginalProviderID, FirstName, LastName | Customer.Customer | FROM (CC alias) | Customer identity for both @CID and related accounts |
| (FundingIDs) | Billing.Deposit | JOIN on CID=@CID and on FundingID | Find @CID's payment instruments and other users |
| (FundingTypeID validation) | Billing.Funding | JOIN on FundingID, filter FundingID<>1 | Payment method type validation |
| (FundingName for MatchType) | Dictionary.FundingType | JOIN on FundingTypeID | Payment method name used as MatchType label |
| CustomerStatus | Dictionary.PlayerStatus | JOIN on PlayerStatusID | Player status name |
| VerificationLevel | BackOffice.Customer | JOIN on CID | KYC level |
| TotalDeposit | BackOffice.CustomerAllTimeAggregatedData | UPDATE join | Lifetime deposit totals |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by BI/reporting pipelines. See also Customer.GetCustomerRelationExt (XML version), Customer.GetCustomerRelation (simpler base).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerRelationExtBI (function)
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
| Customer.Customer | View | FROM - @CID profile and related account profiles |
| Billing.Deposit | Table (cross-schema) | JOIN to find @CID's funding instruments and other matching depositors |
| Billing.Funding | Table (cross-schema) | JOIN on FundingID; filter FundingID<>1 |
| Dictionary.FundingType | Table (cross-schema) | JOIN to get payment method Name for MatchType |
| Dictionary.PlayerStatus | Table (cross-schema) | UPDATE join to set CustomerStatus |
| BackOffice.Customer | Table (cross-schema) | UPDATE join to set VerificationLevel |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | UPDATE join to set TotalDeposit |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BD.CID <> @CID | Filter | Only OTHER customers returned |
| BF.FundingID <> 1 | Filter | Excludes unknown/null FundingID |
| No PersonalDetails branch | Design difference | Unlike GetCustomerRelationExt, this variant omits the FirstName+LastName+BirthDate+CountryID+Zip+Gender matching |
| CONVERT(VARCHAR(8000), ...) | Type conversion | XML->varchar for BI compatibility |

---

## 8. Sample Queries

### 8.1 Find related accounts with plain-text match type (BI usage)

```sql
SELECT CID, UserName, Email, CustomerStatus, VerificationLevel, TotalDeposit, MatchType
FROM Customer.GetCustomerRelationExtBI(12345) WITH (NOLOCK)
ORDER BY TotalDeposit DESC;
```

### 8.2 Filter by specific match type using string operations

```sql
SELECT CID, UserName, MatchType
FROM Customer.GetCustomerRelationExtBI(12345) WITH (NOLOCK)
WHERE MatchType LIKE '%Email%';
```

### 8.3 Export related account network for BI reporting

```sql
SELECT
    c.CID AS SourceCID,
    c.UserName AS SourceUserName,
    rel.CID AS RelatedCID,
    rel.UserName AS RelatedUserName,
    rel.CustomerStatus,
    rel.TotalDeposit,
    rel.MatchType
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetCustomerRelationExtBI(c.CID) rel
WHERE c.IsReal = 1
  AND rel.TotalDeposit > 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCustomerRelationExtBI | Type: Multi-statement TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCustomerRelationExtBI.sql*
