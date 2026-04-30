# Billing.GetCustomerTestDepositCount

> Returns the count of all deposits for a customer that used FundingTypeID=18 (TestDeposit) - the internal testing payment type. Used to determine how many internal/test credits a customer has received, regardless of deposit status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (scalar COUNT output named "Result") |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerTestDepositCount` counts how many deposits a customer has received via the "TestDeposit" funding type (FundingTypeID=18). The TestDeposit type is an internal/administrative funding instrument used by eToro operations to add test credits to customer accounts - typically for QA purposes, internal demonstrations, or resolving customer issues.

The TestDeposit funding type is configured with `IsCashoutActive=false` and `IsRedeemable=false` - meaning funds added via this type cannot be withdrawn or redeemed. The count returned by this procedure helps determine:
- Whether a customer has ever received any internal test deposits.
- How many test deposits have been applied (useful for validating that a specific test deposit was processed, or auditing internal credit usage).

FundingTypeID=18 characteristics (from Dictionary.FundingType):
- Name: "TestDeposit"
- IsSingleFunding: true (one global funding instrument, not per-customer)
- IsNewStyle: true
- IsCashoutActive: false (cannot cashout via this method)
- IsRedeemable: false (cannot redeem via this method)
- DefaultCurrency: 1 (USD)

No status filter - counts ALL deposits via TestDeposit regardless of PaymentStatusID. Only VIEW DEFINITION granted to PROD_BIadmins; no explicit EXECUTE grant, called by application services.

---

## 2. Business Logic

### 2.1 Subquery-Based FundingType Filter

**What**: Counts Billing.Deposit records for @CID where the associated FundingID belongs to FundingTypeID=18.

**Columns/Parameters Involved**: `@CID`, `FundingID`, `FundingTypeID=18`

**Rules**:
- `WHERE FundingID IN (SELECT Funding.FundingID FROM Billing.Funding WHERE FundingTypeID=18)`: Subquery retrieves all FundingIDs of type TestDeposit. This is an IN-subquery rather than a JOIN - functionally equivalent but written as per the SP's original style.
- `AND CID = @CID`: Filters to the specific customer.
- No PaymentStatusID filter: counts ALL deposit records with this funding type regardless of status (New, Approved, Declined, etc.).
- `COUNT(*) AS Result`: Returns the count as a named column "Result" (unlike GetCustomerNumberOfPayments which returns an unnamed column).
- Both tables use NOLOCK: accepts dirty reads for this counting query.
- Comment in DDL: "This query Count how many records in Billing.Deposit that have to this CID and FundingType=18"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose TestDeposit count to retrieve. Filters Billing.Deposit.CID. |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Result | INTEGER | NO | CODE-BACKED | Count of ALL Billing.Deposit records for this CID where FundingID has FundingTypeID=18 (TestDeposit). Returns 0 if the customer has never received a test deposit. Counts all statuses (approved, declined, pending). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, FundingID | Billing.Deposit | Direct read (COUNT) | Source of deposit records for the customer |
| FundingID, FundingTypeID=18 | Billing.Funding | Subquery (IN filter) | Resolves FundingIDs of type TestDeposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | No explicit EXECUTE grant in UsersPermissions |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can view procedure definition but not execute directly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerTestDepositCount (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table - subquery for FundingTypeID=18 filter)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | COUNT(*) WHERE CID = @CID AND FundingID IN TestDeposit FundingIDs |
| Billing.Funding | Table | Subquery: SELECT FundingID WHERE FundingTypeID=18 (TestDeposit) |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| No status filter | Counts ALL deposit records including failed attempts via TestDeposit. |
| NOLOCK on both tables | Billing.Deposit and Billing.Funding both read with NOLOCK. |
| FundingTypeID=18 | "TestDeposit" - internal administrative funding type. IsSingleFunding=true (one global funding record per type). |
| Named output column | SELECT COUNT(*) AS Result - callers reference result by column name "Result". |

---

## 8. Sample Queries

### 8.1 Check test deposit count for a customer

```sql
-- Returns integer count (0 if no test deposits)
EXEC [Billing].[GetCustomerTestDepositCount] @CID = 1234567
```

### 8.2 Direct equivalent query

```sql
-- Direct query equivalent:
SELECT COUNT(*) AS Result
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE CID = 1234567
  AND FundingID IN (
      SELECT FundingID FROM [Billing].[Funding] WITH (NOLOCK)
      WHERE FundingTypeID = 18
  )
```

### 8.3 See actual test deposits (with details)

```sql
-- See the actual TestDeposit records for a customer:
SELECT d.DepositID, d.Amount, d.PaymentStatusID, d.PaymentDate
FROM [Billing].[Deposit] d WITH (NOLOCK)
JOIN [Billing].[Funding] f WITH (NOLOCK) ON d.FundingID = f.FundingID
WHERE d.CID = 1234567 AND f.FundingTypeID = 18
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerTestDepositCount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerTestDepositCount.sql*
