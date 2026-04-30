# Billing.GetFundingTransactionsForCustomer

> Returns each funding method associated with a customer along with its most recent transaction date and type (Withdraw, AlternativeMeansOfPayment, Deposit, or Added by BO user), plus block and verification status for each funding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a payment method activity summary for a customer - combining every funding method the customer has ever used (or had registered) with the context of when and how it was last used. Back-office agents and risk teams use this to understand a customer's full payment activity profile: which methods they deposit with, which they withdraw to, and which were added by a back-office operator but never transacted.

The "last transaction" concept is built from a 4-part UNION covering all paths through which a funding can be associated with a transaction:
1. **Withdraw via WithdrawToFunding**: The standard withdrawal path where the target funding is recorded in the link table
2. **AlternativeMeansOfPayment**: Withdrawals where FundingID is stored directly on the Withdraw record (not via WithdrawToFunding) - represents alternative payment methods
3. **Deposit**: Standard deposit path
4. **Added by BO user**: Fundings that exist in CustomerToFunding but have NO deposit or withdrawal history - added manually by back-office

The result includes both system-level and customer-level block flags for deposits (IsBlocked/IsRefundExcluded) and withdrawals (IsBlocked/IsRefundExcluded from both CustomerToFunding and Funding).

---

## 2. Business Logic

### 2.1 Four-Part Transaction History Union

**What**: Aggregates last transaction info for each FundingID across all transaction paths.

**Union parts**:
1. `Billing.Withdraw JOIN Billing.WithdrawToFunding` WHERE CID = @CID AND FundingID IS NOT NULL -> `LastTransactionType = 'Withdraw'`
2. `Billing.Withdraw` WHERE CID = @CID AND FundingID IS NOT NULL (direct FundingID on Withdraw row) -> `LastTransactionType = 'AlternativeMeansOfPayment'`
3. `Billing.Deposit` WHERE CID = @CID AND FundingID IS NOT NULL -> `LastTransactionType = 'Deposit'`
4. `Billing.CustomerToFunding JOIN Billing.Funding` WHERE CID = @CID AND FundingID NOT IN (Deposit FundingIDs) AND NOT IN (WithdrawToFunding FundingIDs) -> `LastTransactionType = 'Added by BO user'`

**Rules**:
- UNION ALL (not UNION) - all matching rows from all paths are included before grouping
- Each part uses MAX(ModificationDate) per FundingID as LastTransactionDate
- Part 4 uses BF1.DateCreated as LastTransactionDate (no transaction date exists)
- The subquery TRS is then JOINed to CTF (CustomerToFunding) on FundingID

### 2.2 Dual Block Perspective

**What**: Returns four separate block flags covering all deposit/withdrawal blocking scenarios.

**Rules**:
- `CTF.IsBlocked AS IsCidDepositBlock`: Customer-specific deposit block on this funding
- `BF.IsBlocked AS IsSystemDepositBlock`: System-wide funding block (affects all customers)
- `CTF.IsRefundExcluded AS IsCidWithdrawBlock`: Customer-specific withdrawal/refund exclusion
- `BF.IsRefundExcluded AS IsSystemWithdrawBlock`: System-wide withdrawal exclusion
- Callers should check all four flags to determine whether deposit or withdrawal is allowed

### 2.3 Verification Status

**What**: Indicates whether the funding method has been verified for this customer.

**Rules**:
- `CASE WHEN CTF.IsVerified = 1 THEN 'Yes' ELSE 'No' END AS IsVerified`
- Added in April 2020 - indicates the customer's funding method has passed verification checks
- Returned as string 'Yes'/'No' (not BIT)

### 2.4 Manager Tracking

**What**: Exposes both manager assignment and the manager who applied a block.

**Rules**:
- `CTF.ManagerID`: The back-office user responsible for managing this customer-funding relationship
- `CTF.BlockManagerID`: The back-office user who applied the customer-level block (if blocked)
- Useful for audit trails on blocked fundings

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used in all four UNION parts and the outer CTF join. Returns only fundings associated with this customer. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | INT | NO | - | CODE-BACKED | Customer identifier from CustomerToFunding. Same as @CID. |
| R2 | FundingID | INT | NO | - | CODE-BACKED | Primary key of Billing.Funding. The funding method being described. |
| R3 | LastTransactionDate | DATETIME | YES | NULL | CODE-BACKED | MAX(ModificationDate) across all transaction records for this FundingID. For BO-added fundings (no transactions), this is Billing.Funding.DateCreated. |
| R4 | LastTransactionType | VARCHAR | NO | - | CODE-BACKED | Type of the most recent transaction. Values: 'Withdraw' (via WithdrawToFunding), 'AlternativeMeansOfPayment' (direct FundingID on Withdraw), 'Deposit', 'Added by BO user' (no transactions). |
| R5 | IsVerified | VARCHAR(3) | NO | - | CODE-BACKED | Whether the funding method is verified for this customer. Values: 'Yes' (CTF.IsVerified=1) or 'No' (CTF.IsVerified=0). Added April 2020. |
| R6 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type from Billing.Funding. Lookup: Dictionary.FundingType. |
| R7 | XmlData | XML | YES | NULL | CODE-BACKED | Billing.Funding.FundingData. Full XML payment method details (card number, IBAN, etc.). |
| R8 | IsCidDepositBlock | BIT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.IsBlocked. 1 = this customer is blocked from depositing with this funding. |
| R9 | IsSystemDepositBlock | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsBlocked. 1 = this funding is globally blocked (all customers cannot deposit with it). |
| R10 | IsCidWithdrawBlock | BIT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.IsRefundExcluded. 1 = this customer cannot withdraw/refund to this funding. |
| R11 | IsSystemWithdrawBlock | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = refunds/withdrawals are excluded for this funding system-wide. |
| R12 | ManagerID | INT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.ManagerID. Back-office user responsible for this customer-funding relationship. |
| R13 | BlockManagerID | INT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.BlockManagerID. The back-office user who applied a customer-level block, if any. Used for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.CustomerToFunding | JOIN | Customer-funding link; block/verify/manager flags |
| FundingID | Billing.Funding | LEFT JOIN | Full funding details, system-level blocks |
| @CID | Billing.Withdraw | UNION parts 1+2 | Withdrawal history for last transaction date |
| WithdrawID | Billing.WithdrawToFunding | UNION part 1 | Standard withdrawal-to-funding link |
| @CID | Billing.Deposit | UNION part 3 | Deposit history for last transaction date |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office customer profile | @CID | EXEC | Full payment method activity history with block status |
| Risk / compliance tooling | @CID | EXEC | Audit of customer funding methods and block state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingTransactionsForCustomer (procedure)
├── Billing.CustomerToFunding (table)
├── Billing.Funding (table)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Outer join - block/verify/manager columns; Part 4 UNION source |
| Billing.Funding | Table | LEFT JOIN - FundingTypeID, FundingData, system-level blocks |
| Billing.Withdraw | Table | UNION parts 1+2 - withdrawal transaction dates |
| Billing.WithdrawToFunding | Table | UNION part 1 - standard withdrawal-to-funding link |
| Billing.Deposit | Table | UNION part 3 - deposit transaction dates; Part 4 exclusion subquery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from back-office and application services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Result is ordered by `TRS.FundingID, TRS.LastTransactionDate DESC`.

---

## 8. Sample Queries

### 8.1 Get all funding activity for a customer

```sql
EXEC Billing.GetFundingTransactionsForCustomer @CID = 1234567;
```

### 8.2 Find all blocked fundings for a customer

```sql
-- After calling the procedure, filter for any block
SELECT FundingID, FundingTypeID, LastTransactionType,
       IsCidDepositBlock, IsSystemDepositBlock,
       IsCidWithdrawBlock, IsSystemWithdrawBlock
FROM (EXEC Billing.GetFundingTransactionsForCustomer @CID = 1234567) AS result
WHERE IsCidDepositBlock = 1 OR IsSystemDepositBlock = 1
   OR IsCidWithdrawBlock = 1 OR IsSystemWithdrawBlock = 1;
```

### 8.3 Direct equivalent for BO-added fundings (never transacted)

```sql
SELECT ctf.FundingID, bf.DateCreated, 'Added by BO user' AS TransactionType
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
INNER JOIN Billing.Funding bf WITH (NOLOCK) ON ctf.FundingID = bf.FundingID
WHERE ctf.CID = 1234567
  AND ctf.FundingID NOT IN (SELECT FundingID FROM Billing.Deposit WHERE CID = 1234567)
  AND ctf.FundingID NOT IN (
      SELECT bwtf.FundingID FROM Billing.WithdrawToFunding bwtf WITH (NOLOCK)
      INNER JOIN Billing.Withdraw bw WITH (NOLOCK) ON bwtf.WithdrawID = bw.WithdrawID
      WHERE bw.CID = 1234567);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingTransactionsForCustomer | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingTransactionsForCustomer.sql*
