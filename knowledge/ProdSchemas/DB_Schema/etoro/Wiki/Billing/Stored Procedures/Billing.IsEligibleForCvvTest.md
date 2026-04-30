# Billing.IsEligibleForCvvTest

> Returns the count of approved credit card deposits for a given customer and funding ID - a non-zero count indicates the customer-funding combination is eligible for CVV-free (instant) payment testing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar count (IsEligible) from Billing.Deposit + Billing.Funding |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.IsEligibleForCvvTest` determines whether a specific customer-credit card combination qualifies for CVV-free deposit processing. CVV-free (also called "instant payment" or CvvFree) is a payment mode where the customer's card is charged without requiring the 3-digit CVV security code on subsequent transactions - supported by card networks when the card has a prior successful transaction history. Before enabling CVV-free, the system must verify that this specific card (FundingID) has been used by this customer (CID) for at least one approved credit card deposit in the past.

The procedure is the eligibility check gate for the CVV-free deposit test (internal ticket 41252, Geri Reshef, Oct 2016). Without this check, the system would risk submitting CVV-free transactions for cards with no prior approval history, which would likely be declined by the card network.

Data flows: the deposit service calls this procedure with the customer ID and their credit card funding ID before deciding which deposit flow to use. If the count is greater than zero (the card has at least one prior approved deposit), the caller may proceed with CVV-free processing. A count of zero means the card has no approved history and must go through the standard CVV-required flow.

---

## 2. Business Logic

### 2.1 CVV-Free Eligibility Criteria

**What**: A customer-card combination is eligible for CVV-free testing if the card (FundingID) has at least one approved deposit (PaymentStatusID=2) recorded for that specific customer (CID) and the funding is a credit card type (FundingTypeID=1).

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `FundingTypeID`, `PaymentStatusID`

**Rules**:
- FundingTypeID=1 = Credit Card (only credit cards qualify; other payment methods are excluded)
- PaymentStatusID=2 = Approved (only approved deposits count; pending or declined deposits do not establish prior history)
- Both @CID and @FundingID must match the deposit record - prevents cross-customer card usage
- COUNT(*) returns 0 (not eligible) or a positive integer (eligible - count of qualifying prior approved deposits)
- Caller interprets: 0 = use standard CVV flow; >0 = may use CVV-free flow

**Diagram**:
```
Customer attempts deposit with CID=X, FundingID=Y (credit card)
        |
        v
EXEC IsEligibleForCvvTest @CID=X, @FundingID=Y
        |
        v
COUNT of (Billing.Deposit JOIN Billing.Funding)
  WHERE FundingTypeID=1 AND PaymentStatusID=2 AND CID=X AND FundingID=Y
        |
        +-- Count = 0: No prior approved CC deposits -> standard CVV flow
        +-- Count > 0: Has prior approved CC deposit -> eligible for CVV-free
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The eToro customer ID. Matched against Billing.Deposit.CID to ensure only this customer's deposit history is counted. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | The credit card funding record ID (Billing.Funding.FundingID). Both the Deposit and Funding tables are filtered by this ID to check prior approval history for this specific card. |

### Output Column

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | IsEligible | INT | CODE-BACKED | Count of approved credit card deposits for this customer-card pair. 0=not eligible (no approved history), 1+=eligible (has prior approved deposit). Callers treat any non-zero value as "eligible." |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM/JOIN | Billing.Deposit | READ | Queries deposit history filtered by CID, FundingID, and PaymentStatusID=2 (Approved) |
| JOIN | Billing.Funding | READ | Joined on FundingID to filter FundingTypeID=1 (Credit Card only) |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found in the Billing schema. Called from the application deposit service layer when determining which deposit flow to use for a returning credit card customer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.IsEligibleForCvvTest (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of deposit history; filtered to approved (PaymentStatusID=2) records for the CID |
| Billing.Funding | Table | JOINed on FundingID to filter to credit card type (FundingTypeID=1) |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Both tables use WITH (NOLOCK) for non-blocking reads on high-traffic deposit history
- INNER JOIN between Deposit and Funding on FundingID ensures only deposits using the specified card are counted
- The WHERE clause filters: `BF.FundingTypeID=1 AND BD.PaymentStatusID=2 AND CID=@CID AND BF.FundingID=@FundingID`
- COUNT(*) returns 0 for no matches (never NULL) - safe for numeric comparison by caller
- Author: Geri Reshef, 13/10/2016, ticket 41252 ("DB - Instant payment test data")

---

## 8. Sample Queries

### 8.1 Check CVV-free eligibility for a customer-card pair
```sql
EXEC Billing.IsEligibleForCvvTest
    @CID       = 7890123,
    @FundingID = 4567890
-- Returns IsEligible=0 (not eligible) or IsEligible=N (count of approved CC deposits)
```

### 8.2 Direct equivalent query
```sql
SELECT COUNT(*) AS IsEligible
FROM Billing.Deposit BD WITH (NOLOCK)
INNER JOIN Billing.Funding BF WITH (NOLOCK) ON BD.FundingID = BF.FundingID
WHERE BF.FundingTypeID = 1          -- Credit card
  AND BD.PaymentStatusID = 2        -- Approved
  AND BD.CID = 7890123
  AND BF.FundingID = 4567890
```

### 8.3 Find all cards eligible for CVV-free for a customer
```sql
SELECT BF.FundingID, COUNT(*) AS ApprovedDepositCount
FROM Billing.Deposit BD WITH (NOLOCK)
INNER JOIN Billing.Funding BF WITH (NOLOCK) ON BD.FundingID = BF.FundingID
WHERE BF.FundingTypeID = 1
  AND BD.PaymentStatusID = 2
  AND BD.CID = 7890123
GROUP BY BF.FundingID
ORDER BY ApprovedDepositCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.IsEligibleForCvvTest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.IsEligibleForCvvTest.sql*
