# BackOffice.CustomerToThirdPartyFundings

> Anti-fraud junction table recording approved third-party payment method usage - where a customer deposits using a funding method (card/payment account) that is also associated with another customer, indicating an explicitly reviewed and approved third-party funding relationship.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (FundingID, CID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.CustomerToThirdPartyFundings is an anti-fraud and AML compliance table that records when a customer is known to be using a third-party payment method - a funding instrument (credit card, e-wallet, bank account) that is registered to or also used by a different customer. Presence of a (FundingID, CID) pair here signals that BackOffice has reviewed and documented this relationship.

The scenario this table addresses: Customer A deposits using credit card FundingID=12345. Later, Customer B also deposits using FundingID=12345. Under AML/KYC rules, this "third-party funding" situation requires review - is it a family member sharing a card? A fraudster? Straw man funding? BackOffice agents explicitly record the (FundingID, CID) pairs after review.

The table is checked by cashout and withdrawal processing procedures (GetWithdrawRequests, GetCashOutRequests_Main) to flag or review withdrawals from customers with third-party funding relationships. GetCustomersWithSameMeanOfPayment identifies new third-party situations by finding deposits where the same FundingID was used by a different CID and the relationship is not yet in this table.

8,647 rows across 8,644 distinct customers as of 2026-03-17. 5,383 distinct FundingIDs - some FundingIDs appear for multiple customers, confirming the many-to-many nature.

---

## 2. Business Logic

### 2.1 Third-Party Funding Detection and Approval Workflow

**What**: The BackOffice process for identifying and recording third-party funding relationships.

**Columns Involved**: `FundingID`, `CID`

**Rules**:
- GetCustomersWithSameMeanOfPayment(@CID, @DepositID): given a new deposit, resolves its FundingID then searches Billing.Deposit for other CIDs that used the same FundingID with a successful deposit (PaymentStatusID=2), excluding pairs already in CustomerToThirdPartyFundings (LEFT JOIN + IS NULL check). Returns the most recent other CID using that funding method if not already documented as third-party.
- CustomerToThirdPartyFundingsAdd(@CID, @FundingID): simple INSERT - records the approved third-party relationship.
- CustomerToThirdPartyFundingsDelete(@CID, @FundingID): removes a specific (FundingID, CID) pair.
- GetCustomerToThirdPartyFundingsByFunding(@FundingID): checks whether any entry exists for a given FundingID (returns 1/0). Referenced in MIMOPSA-7300 for withdrawal service use.

### 2.2 Impact on Cashout Processing

**What**: Third-party funding status affects cashout and withdrawal request handling.

**Columns Involved**: `FundingID`, `CID`

**Rules**:
- GetWithdrawRequests, GetCashOutRequests_Main, GetPendingClosureAccountsByLastChangeDate, GetClosedAccountsByLastChangeDate, GetCashActivities: all reference this table in their query logic to surface third-party funding flags alongside cashout/withdrawal data.
- GetCustomerCrediableMOP (creditable means of payment): uses this table to determine whether a payment method can be credited back to a customer during chargeback or reversal scenarios.
- The presence of a (FundingID, CID) pair may restrict or require additional review for cashout requests involving that FundingID.

---

## 3. Data Overview

8,647 rows as of 2026-03-17:
- Distinct CIDs: 8,644 (3 CIDs appear twice, linked to 2 different third-party FundingIDs each)
- Distinct FundingIDs: 5,383 (meaning ~3,264 FundingIDs are linked to multiple customers)
- FundingID range: 1 to 4,146,829

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | VERIFIED | The third-party payment method being tracked. FK (WITH CHECK) to Billing.Funding(FundingID). Leading key of composite CLUSTERED PK. 5,383 distinct values; some FundingIDs appear multiple times (linked to multiple customers who have used that same payment method). |
| 2 | CID | int | NO | - | VERIFIED | The customer who has been approved to use this third-party funding method. FK (WITH CHECK) to BackOffice.Customer(CID). Part of composite CLUSTERED PK. 8,644 distinct values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | FK (WITH CHECK) | The shared/third-party payment method |
| CID | BackOffice.Customer | FK (WITH CHECK) | The customer using the third-party funding |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerToThirdPartyFundingsAdd | FundingID, CID | WRITER | Records a new approved third-party relationship |
| BackOffice.CustomerToThirdPartyFundingsDelete | FundingID, CID | DELETER | Removes a third-party relationship |
| BackOffice.GetCustomerToThirdPartyFundingsByFunding | FundingID | READER | Checks existence for a given FundingID |
| BackOffice.GetCustomersWithSameMeanOfPayment | FundingID, CID | READER (anti-join) | Detects undocumented third-party usages |
| BackOffice.GetWithdrawRequests | FundingID | READER | Surfaces third-party flag in withdrawal requests |
| BackOffice.GetCashOutRequests_Main | FundingID | READER | Surfaces third-party flag in cashout requests |
| BackOffice.GetCashActivities | FundingID | READER | Includes third-party context in cash activity report |
| BackOffice.GetCustomerCrediableMOP | FundingID | READER | Checks creditable means of payment |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | FundingID | READER | Includes third-party flag for pending closure accounts |
| BackOffice.GetClosedAccountsByLastChangeDate | FundingID | READER | Includes third-party flag for closed account report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToThirdPartyFundings (table)
- FK targets:
  |- Billing.Funding (table) - FundingID
  |- BackOffice.Customer (table) - CID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | FK on FundingID |
| BackOffice.Customer | Table | FK on CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToThirdPartyFundingsAdd | Procedure | WRITER |
| BackOffice.CustomerToThirdPartyFundingsDelete | Procedure | DELETER |
| BackOffice.GetCustomerToThirdPartyFundingsByFunding | Procedure | READER - existence check |
| BackOffice.GetCustomersWithSameMeanOfPayment | Procedure | READER - anti-join for detection |
| BackOffice.GetWithdrawRequests | Procedure | READER - cashout processing |
| BackOffice.GetCashOutRequests_Main | Procedure | READER - cashout processing |
| BackOffice.GetCashActivities | Procedure | READER - cash activity report |
| BackOffice.GetCustomerCrediableMOP | Procedure | READER - payment eligibility |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | Procedure | READER |
| BackOffice.GetClosedAccountsByLastChangeDate | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FundingToCustomer | CLUSTERED PK | FundingID ASC, CID ASC | - | - | Active (ON [PRIMARY]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FundingToCustomer | PK | Uniqueness of (FundingID, CID) |
| FK_FundingToCustomer_CID | FK (WITH CHECK) | CID -> BackOffice.Customer(CID) |
| FK_FundingToCustomer_FundingID | FK (WITH CHECK) | FundingID -> Billing.Funding(FundingID) |

---

## 8. Sample Queries

### 8.1 Check if a customer has any third-party funding relationships
```sql
SELECT FundingID
FROM BackOffice.CustomerToThirdPartyFundings WITH (NOLOCK)
WHERE CID = @CID
```

### 8.2 Find all customers sharing a specific funding method
```sql
SELECT CID
FROM BackOffice.CustomerToThirdPartyFundings WITH (NOLOCK)
WHERE FundingID = @FundingID
```

### 8.3 Detect new third-party situations for a deposit (as GetCustomersWithSameMeanOfPayment does)
```sql
DECLARE @FundingID INT
SELECT @FundingID = FundingID FROM Billing.Deposit WHERE DepositID = @DepositID

SELECT TOP 1 BDEP.CID
FROM Billing.Deposit BDEP
LEFT JOIN BackOffice.CustomerToThirdPartyFundings BCT3P
    ON BCT3P.FundingID = BDEP.FundingID AND BCT3P.CID = BDEP.CID
WHERE BDEP.CID <> @CID
  AND BDEP.FundingID = @FundingID
  AND BDEP.PaymentStatusID = 2
  AND BCT3P.FundingID IS NULL
ORDER BY BDEP.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. GetCustomerToThirdPartyFundingsByFunding references MIMOPSA-7300 (MIMO payment service area ticket) as origin of that procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToThirdPartyFundings | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerToThirdPartyFundings.sql*
