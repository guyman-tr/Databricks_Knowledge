# Billing.GetCustomerRegulationByWithdrawId

> Resolves the regulatory jurisdiction for a withdrawal by checking whether the customer has any approved deposit - returning RegulationID if they do, or DesignatedRegulationID if they don't. CONTAINS A BUG: the LEFT JOIN condition `d.CID = d.CID` (self-comparison, always true) creates an accidental cartesian product with Billing.Deposit, causing the SP to always return RegulationID (never DesignatedRegulationID). Created PAYUA-2586.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerRegulationByWithdrawId` is intended to resolve which RegulationID applies to a withdrawal based on whether the customer has ever made an approved deposit:
- **Customer has deposited** -> return `BackOffice.Customer.RegulationID` (their confirmed regulatory jurisdiction from their deposit history)
- **Customer has NOT deposited** -> return `BackOffice.Customer.DesignatedRegulationID` (the default/designated regulatory jurisdiction assigned at registration)

The distinction matters for regulatory reporting: a customer who has deposited has an established regulatory relationship and must be processed under their actual RegulationID; a non-depositor is processed under their designated jurisdiction.

**BUG (present since creation, 2021-05-09)**: The LEFT JOIN condition reads `ON d.CID = d.CID` instead of `ON d.CID = c.CID`. This is a self-comparison that is always TRUE, causing a cartesian product of the customer row with ALL approved deposits in Billing.Deposit. Since Billing.Deposit contains millions of approved records, `d.DepositID IS NOT NULL` is always true, and the SP ALWAYS returns `RegulationID` (never `DesignatedRegulationID`). The `TOP 1` prevents the result set from exploding to millions of rows.

Called by `PayoutUser` and `SQL_SecurePay` services - same callers as `GetCustomerRegulationByDepositId`. Created as part of PAYUA-2586 (Ryta B., 2021-05-09).

---

## 2. Business Logic

### 2.1 Depositor-Based Regulation Switch (Intended Logic)

**What**: Determines RegulationID based on whether the customer has made a deposit.

**Columns/Parameters Involved**: `@WithdrawID`, `c.RegulationID`, `c.DesignatedRegulationID`, `d.DepositID`

**Intended Rules**:
- Look up the customer via `w.WithdrawID = @WithdrawID` -> `JOIN Billing.Withdraw w ON w.CID = c.CID`.
- LEFT JOIN Billing.Deposit WHERE CID = this customer AND PaymentStatusID = 2 (approved).
- If any approved deposit found (d.DepositID IS NOT NULL) -> return c.RegulationID.
- If no approved deposits (d.DepositID IS NULL) -> return c.DesignatedRegulationID.

**Actual Rules (as coded)**:
- LEFT JOIN condition is `d.CID = d.CID` (self-comparison) NOT `d.CID = c.CID`.
- This joins ALL Billing.Deposit rows with PaymentStatusID=2 to the customer row (cartesian product).
- `d.DepositID IS NOT NULL` is always true (Billing.Deposit has millions of approved rows).
- Result: ALWAYS returns `c.RegulationID`. The `DesignatedRegulationID` branch is unreachable.
- `TOP 1` limits the cartesian explosion to 1 row.

**Diagram of intended vs. actual behavior**:
```
INTENDED:                               ACTUAL (BUGGY):
@WithdrawID                             @WithdrawID
     |                                       |
Billing.Withdraw w -> c.CID            Billing.Withdraw w -> c.CID (correct)
     |                                       |
BackOffice.Customer c                  BackOffice.Customer c
     |                                       |
LEFT JOIN Billing.Deposit d            LEFT JOIN Billing.Deposit d
  ON d.CID = c.CID  <-- CORRECT          ON d.CID = d.CID  <-- BUG (always true)
  AND d.PaymentStatusID = 2               AND d.PaymentStatusID = 2
     |                                       |
CASE d.DepositID IS NOT NULL           d.DepositID ALWAYS NOT NULL (millions of rows)
  -> RegulationID (has deposited)      -> ALWAYS RegulationID
  -> DesignatedRegulationID (no dep)   -> DesignatedRegulationID UNREACHABLE
```

### 2.2 TOP 1 as a Safeguard Against the Cartesian Product

**What**: TOP 1 prevents the query from returning millions of rows due to the accidental cartesian join.

**Rules**:
- Without TOP 1, the buggy LEFT JOIN would return one row for each Billing.Deposit record with PaymentStatusID=2 (potentially millions of rows) per customer.
- TOP 1 with no explicit ORDER BY returns an arbitrary first row from the cartesian product.
- The CASE expression evaluates the same way for all rows (always RegulationID), so the choice of which row is returned by TOP 1 does not affect the output value.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Withdraw ID to resolve regulation for. Used to identify the customer via JOIN to Billing.Withdraw. |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | RegulationID | INT | YES | CODE-BACKED | Regulatory jurisdiction identifier. Due to the d.CID=d.CID bug, always returns BackOffice.Customer.RegulationID (never DesignatedRegulationID). Intended: conditionally return RegulationID (has deposits) or DesignatedRegulationID (no deposits). NULL if the customer row has no RegulationID set. Returns 0 rows if @WithdrawID does not exist in Billing.Withdraw. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID, CID | Billing.Withdraw | JOIN | Identifies the customer who owns the withdrawal |
| CID, RegulationID, DesignatedRegulationID | BackOffice.Customer | Direct read | Source of regulatory jurisdiction fields |
| CID (buggy join), PaymentStatusID=2 | Billing.Deposit | LEFT JOIN (cartesian due to bug) | Intended to check if customer has approved deposits; actually joins all deposits |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser | EXECUTE grant | Permission | Payout service resolves withdrawal regulation |
| SQL_SecurePay | EXECUTE grant | Permission | Secure payment service uses regulation lookup during payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerRegulationByWithdrawId (procedure)
├── BackOffice.Customer (table - RegulationID, DesignatedRegulationID)
├── Billing.Deposit (table - LEFT JOIN, buggy condition)
└── Billing.Withdraw (table - customer lookup by WithdrawID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Source of RegulationID and DesignatedRegulationID |
| Billing.Deposit | Table | LEFT JOIN to check deposit existence (buggy: d.CID=d.CID) |
| Billing.Withdraw | Table | JOIN to resolve customer from WithdrawID |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called directly by PayoutUser and SQL_SecurePay application services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| BUG: d.CID = d.CID | Line 14: `ON d.CID = d.CID` should be `ON d.CID = c.CID`. Creates cartesian product with Billing.Deposit making DesignatedRegulationID branch unreachable. Present since creation (2021-05-09). |
| TOP 1 | Required to prevent cartesian product from returning millions of rows. Without the bug, TOP 1 would be unnecessary (LEFT JOIN 1:1 with correct condition). |
| No ORDER BY with TOP 1 | Non-deterministic row selection from the cartesian product. However, since the CASE always evaluates the same way, the selected row does not affect the result. |
| NOLOCK | All three tables read with NOLOCK. |

---

## 8. Sample Queries

### 8.1 Resolve regulation for a withdrawal

```sql
-- Returns RegulationID (always, due to bug)
EXEC [Billing].[GetCustomerRegulationByWithdrawId] @WithdrawID = 7654321
```

### 8.2 Verify the bug and intended behavior

```sql
-- Correct logic (what the SP should do):
SELECT TOP 1
    CASE WHEN d.DepositID IS NOT NULL THEN c.RegulationID ELSE c.DesignatedRegulationID END AS RegulationID
FROM BackOffice.Customer c WITH (NOLOCK)
    LEFT JOIN Billing.Deposit d WITH (NOLOCK) ON d.CID = c.CID AND d.PaymentStatusID = 2  -- CORRECT: d.CID = c.CID
    JOIN Billing.Withdraw w WITH (NOLOCK) ON w.CID = c.CID
WHERE w.WithdrawID = 7654321

-- As-coded (buggy) - confirms it always returns RegulationID:
SELECT TOP 1
    CASE WHEN d.DepositID IS NOT NULL THEN c.RegulationID ELSE c.DesignatedRegulationID END AS RegulationID
FROM BackOffice.Customer c WITH (NOLOCK)
    LEFT JOIN Billing.Deposit d WITH (NOLOCK) ON d.CID = d.CID AND d.PaymentStatusID = 2  -- BUG: d.CID = d.CID
    JOIN Billing.Withdraw w WITH (NOLOCK) ON w.CID = c.CID
WHERE w.WithdrawID = 7654321
```

---

## 9. Atlassian Knowledge Sources

Jira ticket referenced in DDL comment:
- **PAYUA-2586** (2021-05-09, Ryta B.): Initial version - same ticket as `GetCustomerRegulationByDepositId`. Ukraine-specific regulatory determination for withdrawal and deposit processing.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comment) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerRegulationByWithdrawId | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerRegulationByWithdrawId.sql*
