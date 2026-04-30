# BackOffice.GetCustomersWithSameMeanOfPayment

> Identifies the most recent other customer who used the same payment method (FundingID) as a given deposit, excluding already-documented third-party relationships - used to detect new third-party funding situations for AML review.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns at most 1 CID (TOP 1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomersWithSameMeanOfPayment is an AML/fraud detection helper that identifies when a deposit was made using a payment method (FundingID) also used by a different customer. Given a CID and a DepositID, it resolves the deposit's FundingID, then searches `Billing.Deposit` for other customers who made a successful deposit using that same FundingID - but only returns hits that are NOT already recorded in `BackOffice.CustomerToThirdPartyFundings` (the approved third-party registry).

The procedure exists to power the third-party funding detection workflow in BackOffice. When a new deposit arrives, the system calls this procedure to check: "Has someone else used this payment method, and if so, is that relationship already known and approved?" A non-empty result means a NEW, unreviewed third-party funding situation has been detected, requiring a BackOffice agent to investigate (Is this a family member? A straw man? Fraud?) and then record the decision in `BackOffice.CustomerToThirdPartyFundings`.

The result is a single CID (most recent by PaymentDate) - the caller gets the most relevant "other customer" to investigate. A NULL/empty result means either no one else used this payment method, or all such relationships are already in the approved list.

---

## 2. Business Logic

### 2.1 Third-Party Funding Detection Algorithm

**What**: The procedure's two-step algorithm to identify new, unreviewed third-party funding relationships.

**Columns/Parameters Involved**: `@CID`, `@DepositID`, `Billing.Deposit.FundingID`, `Billing.Deposit.PaymentStatusID`, `BackOffice.CustomerToThirdPartyFundings`

**Rules**:
- Step 1: Resolve FundingID - `SELECT @FundingID = FundingID FROM Billing.Deposit WHERE DepositID = @DepositID`
- Step 2: Find other successful deposits with same FundingID: `WHERE CID <> @CID AND FundingID = @FundingID AND PaymentStatusID = 2`
  - PaymentStatusID=2 = successful/completed deposit
  - Excludes the calling customer's own CID
- Step 3: Exclude already-approved third-party relationships: `LEFT JOIN BackOffice.CustomerToThirdPartyFundings ... WHERE BCT3P.FundingID IS NULL`
  - The IS NULL check on the LEFT JOIN means: only return CIDs where this (FundingID, CID) pair does NOT exist in CustomerToThirdPartyFundings
- Step 4: Return TOP 1 most recent by `ORDER BY BDEP.PaymentDate DESC`

**Diagram**:
```
Given: @CID=1001, @DepositID=55555

Step 1: Billing.Deposit[55555].FundingID = 9999

Step 2: Other deposits with FundingID=9999 and PaymentStatusID=2
  CID=2002 (PaymentDate=2025-01-15) -> in CustomerToThirdPartyFundings? YES -> excluded
  CID=3003 (PaymentDate=2025-03-10) -> in CustomerToThirdPartyFundings? NO  -> RETURNED

Result: CID=3003 (new third-party funding relationship requiring review)
```

### 2.2 Integration with CustomerToThirdPartyFundings

**What**: This procedure is the detection step in a two-step workflow; `BackOffice.CustomerToThirdPartyFundingsAdd` is the approval step.

**Rules**:
- If this procedure returns a CID: BackOffice agent reviews the relationship, then calls `CustomerToThirdPartyFundingsAdd(@CID, @FundingID)` to record the approved pair in CustomerToThirdPartyFundings
- On subsequent calls for the same deposit/FundingID, the now-recorded relationship is excluded, preventing re-detection of the same pair
- The LEFT JOIN + IS NULL pattern ensures deterministic "not yet approved" detection

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer account ID whose deposit is being checked. Used as an exclusion filter - the procedure looks for OTHER customers using the same payment method, not the caller itself. |
| 2 | @DepositID | INT | NO | - | CODE-BACKED | The DepositID from Billing.Deposit being analyzed. Used to resolve the FundingID of the payment method in Step 1. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | YES | - | CODE-BACKED | The CID of the most recent other customer who used the same payment method (FundingID) and whose relationship has not yet been recorded in BackOffice.CustomerToThirdPartyFundings. NULL/empty result set means no new third-party funding situation detected. Only TOP 1 returned (most recent by PaymentDate). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | SELECT (Step 1) | Resolves FundingID for the given deposit |
| FundingID | Billing.Deposit | SELECT (Step 2) | Finds other customers with successful deposits using same FundingID |
| (FundingID, CID) | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN exclusion | Excludes already-documented third-party relationships |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the BackOffice application as part of the deposit review and third-party funding detection workflow. No stored procedure callers found in BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomersWithSameMeanOfPayment (procedure)
├── Billing.Deposit (table - cross-schema)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Step 1: resolve FundingID from DepositID. Step 2: find other successful deposits with same FundingID |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN exclusion - filters out already-approved third-party relationships |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (deposit review flow) | External | READER - detects new third-party funding situations on deposit processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Returns at most 1 row (TOP 1). If no third-party situation is detected, returns an empty result set (not NULL).

---

## 8. Sample Queries

### 8.1 Check for third-party funding on a specific deposit
```sql
EXEC BackOffice.GetCustomersWithSameMeanOfPayment
    @CID = 1001,
    @DepositID = 55555
-- Returns 0 or 1 row with the other customer's CID
```

### 8.2 Equivalent ad-hoc query for a given FundingID
```sql
DECLARE @FundingID INT = 9999  -- replace with actual FundingID

SELECT TOP 1 BDEP.CID
FROM Billing.Deposit BDEP WITH (NOLOCK)
LEFT JOIN BackOffice.CustomerToThirdPartyFundings BCT3P WITH (NOLOCK)
    ON BCT3P.FundingID = BDEP.FundingID
    AND BCT3P.CID = BDEP.CID
WHERE BDEP.CID <> 1001         -- replace with @CID
  AND BDEP.FundingID = @FundingID
  AND BDEP.PaymentStatusID = 2  -- successful deposits only
  AND BCT3P.FundingID IS NULL   -- not yet in approved list
ORDER BY BDEP.PaymentDate DESC
```

### 8.3 Review all known third-party relationships for a funding method
```sql
SELECT
    BCT3P.CID,
    BCT3P.FundingID,
    CC.UserName,
    BCT3P.CreationDate
FROM BackOffice.CustomerToThirdPartyFundings BCT3P WITH (NOLOCK)
JOIN Customer.Customer CC WITH (NOLOCK) ON CC.CID = BCT3P.CID
WHERE BCT3P.FundingID = 9999  -- replace with target FundingID
ORDER BY BCT3P.CreationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomersWithSameMeanOfPayment | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomersWithSameMeanOfPayment.sql*
