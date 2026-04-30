# Dictionary.CustomerToFundingStatus

> Lookup table defining the visibility and availability states of a customer's saved payment methods (means of payment) within the billing system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CustomerFundingStatusID (PK) |
| **Partition** | No — PAGE compressed |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a customer saves a payment method (credit card, bank account, e-wallet, wire), the system creates a record in `Billing.CustomerToFunding` linking the customer to that funding source. This dictionary table defines the status of that link — whether the payment method is visible to the customer for deposits, hidden, removed entirely, removed only from the deposit flow, or disabled by the system.

Without this table, the billing system would have no way to control payment method availability. The status determines whether a customer can use a specific saved card for future deposits, whether it appears in their payment method list, and whether it has been blocked for compliance or risk reasons. Over 30 billing procedures reference this status through the `Billing.CustomerToFunding` table.

The status is set initially when a payment method is added (Visible) and can be changed by BackOffice operations (FundingBlock, DeactivateCustomerCreditCard), billing workflows (BlockAllRelatedMeansOfPayment), or automated processes. Status transitions are tracked in the history tables.

---

## 2. Business Logic

### 2.1 Payment Method Visibility Lifecycle

**What**: Payment methods transition through visibility states based on customer actions, risk blocks, and compliance decisions.

**Columns/Parameters Involved**: `CustomerFundingStatusID`, `Name`

**Rules**:
- Visible (1) is the default state — customer can see and use this payment method for deposits
- Invisible (0) means the payment method exists but is hidden from the customer's UI — may still be used for refunds/chargebacks
- Removed (2) means the payment method has been fully removed — not available for any operation
- RemovedFromDeposit (3) means the payment method cannot be used for new deposits but remains active for refund/chargeback processing
- Disable (4) means the payment method has been disabled by risk/compliance — blocked from all operations

**Diagram**:
```
Payment Method Added → Visible (1)
  ├─► Invisible (0)         [hidden from UI, still processable]
  ├─► RemovedFromDeposit (3) [can't deposit, can refund]
  ├─► Removed (2)           [fully removed]
  └─► Disable (4)           [risk/compliance block]
```

### 2.2 Funding Block Operations

**What**: Multiple procedures manage payment method blocking for risk and compliance.

**Columns/Parameters Involved**: `CustomerFundingStatusID`

**Rules**:
- `Billing.FundingBlock` and `Billing.BlockFundingUpdate` set status to Disable (4) or RemovedFromDeposit (3)
- `Billing.BlockAllRelatedMeansOfPayment` blocks all payment methods linked to a customer when a risk event occurs
- `Billing.BlockCurrentMeanOfPayment` blocks a single specific payment method
- `Billing.DeactivateCustomerCreditCard` and `Billing.DeactivateFunding` remove or disable specific methods
- `BackOffice.FundingBlockToCustomer` provides BackOffice UI access to funding blocks

---

## 3. Data Overview

| CustomerFundingStatusID | Name | Meaning |
|---|---|---|
| 0 | Invisible | Payment method exists in the system but is not shown to the customer in their payment method list — used when the method should be retained for refund processing but not offered for new deposits |
| 1 | Visible | Payment method is active and available — the customer can see it in their UI and select it for deposits. This is the default state when a payment method is first saved |
| 2 | Removed | Payment method has been fully removed from the customer's account — cannot be used for deposits, refunds, or any other operation. Typically set when a customer explicitly deletes a payment method |
| 3 | RemovedFromDeposit | Payment method is blocked for new deposits only — it remains in the system for processing chargebacks, refunds, or reversals against previous transactions. Common when a card is flagged but has pending transactions |
| 4 | Disable | Payment method has been disabled by risk or compliance action — all operations are blocked. Set by automated risk systems or manual BackOffice blocks when fraud or suspicious activity is detected |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerFundingStatusID | int | NO | - | VERIFIED | Primary key identifying the funding status. 0=Invisible, 1=Visible, 2=Removed, 3=RemovedFromDeposit, 4=Disable. Referenced by Billing.CustomerToFunding.CustomerFundingStatusID in 30+ procedures. |
| 2 | Name | varchar(20) | YES | - | VERIFIED | Human-readable status label. Nullable in DDL but all 5 rows have values populated. Used in BackOffice UI and billing reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CustomerToFunding | CustomerFundingStatusID | Implicit | Main consumer — stores the current funding status for each customer-to-payment-method link |
| History.ActiveCustomerToFunding | CustomerFundingStatusID | Implicit | Historical audit of funding status changes |
| Billing.CustomerToFunding_UpdateStatus | @CustomerFundingStatusID | Implicit | Procedure that updates a payment method's status |
| Billing.CustomerToFunding_UpdateRecord | CustomerFundingStatusID | Implicit | Procedure that updates funding records including status |
| Billing.FundingBlock | CustomerFundingStatusID | Implicit | Procedure that blocks a funding method |
| Billing.BlockFundingUpdate | CustomerFundingStatusID | Implicit | Procedure that updates block status on funding methods |
| Billing.BlockFundingUpdate_v2 | CustomerFundingStatusID | Implicit | V2 of funding block update procedure |
| Billing.BlockAllRelatedMeansOfPayment | CustomerFundingStatusID | Implicit | Blocks all payment methods for a customer |
| Billing.BlockCurrentMeanOfPayment | CustomerFundingStatusID | Implicit | Blocks a specific current payment method |
| Billing.DeactivateCustomerCreditCard | CustomerFundingStatusID | Implicit | Deactivates a specific credit card |
| Billing.DeactivateFunding | CustomerFundingStatusID | Implicit | Deactivates a funding source |
| Billing.GetFundingForCustomer | CustomerFundingStatusID | Implicit | Retrieves available funding methods filtered by status |
| Billing.GetFundingForCustomerByCID | CustomerFundingStatusID | Implicit | Retrieves funding methods by CID filtered by status |
| Billing.GetSavedCreditCards | CustomerFundingStatusID | Implicit | Returns saved cards filtered by visibility status |
| BackOffice.FundingBlockToCustomer | CustomerFundingStatusID | Implicit | BackOffice UI procedure for managing funding blocks |
| BackOffice.GetCustomerCrediableMOP | CustomerFundingStatusID | Implicit | Returns creditworthy payment methods by status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CustomerToFundingStatus (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | References — stores funding status per payment method |
| Billing.CustomerToFunding_UpdateStatus | Procedure | Writer — updates funding status |
| Billing.FundingBlock | Procedure | Writer — blocks funding methods |
| Billing.BlockAllRelatedMeansOfPayment | Procedure | Writer — bulk blocks all customer methods |
| Billing.GetFundingForCustomer | Procedure | Reader — filters by status |
| Billing.GetSavedCreditCards | Procedure | Reader — filters saved cards by status |
| BackOffice.FundingBlockToCustomer | Procedure | Writer — BackOffice funding block |
| Billing.GetRecurringEligibility | Procedure | Reader — checks eligibility based on funding status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerToFundingStatus | CLUSTERED | CustomerFundingStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all customer funding statuses
```sql
SELECT  CustomerFundingStatusID,
        Name
FROM    Dictionary.CustomerToFundingStatus WITH (NOLOCK)
ORDER BY CustomerFundingStatusID
```

### 8.2 Count payment methods by status for a customer
```sql
SELECT  dfs.Name AS FundingStatus,
        COUNT(*) AS MethodCount
FROM    Billing.CustomerToFunding cf WITH (NOLOCK)
        JOIN Dictionary.CustomerToFundingStatus dfs WITH (NOLOCK) ON cf.CustomerFundingStatusID = dfs.CustomerFundingStatusID
WHERE   cf.CID = @CID
GROUP BY dfs.Name
```

### 8.3 Find all visible payment methods for a customer
```sql
SELECT  cf.FundingID,
        cf.FundingTypeID,
        dfs.Name AS Status
FROM    Billing.CustomerToFunding cf WITH (NOLOCK)
        JOIN Dictionary.CustomerToFundingStatus dfs WITH (NOLOCK) ON cf.CustomerFundingStatusID = dfs.CustomerFundingStatusID
WHERE   cf.CID = @CID
        AND cf.CustomerFundingStatusID = 1  -- Visible
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 16 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CustomerToFundingStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CustomerToFundingStatus.sql*
