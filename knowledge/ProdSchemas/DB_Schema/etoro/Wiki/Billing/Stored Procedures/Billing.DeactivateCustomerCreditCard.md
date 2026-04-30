# Billing.DeactivateCustomerCreditCard

> Deactivates a specific credit card payment method for a customer by setting its CustomerFundingStatusID to 0 (Deactivated) in CustomerToFunding, with validation that the funding is a credit card (FundingTypeID=1) and audit trail written to History.ActiveCustomerToFunding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID uniquely identify the CustomerToFunding row to deactivate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DeactivateCustomerCreditCard` marks a specific credit card payment method as deactivated for a given customer. It is a targeted, type-validated version of the more general `Billing.DeactivateFunding` procedure - the key difference is that it first verifies the target FundingID belongs to a credit card (`FundingTypeID=1`) before allowing the deactivation. If the FundingID exists but is not a credit card, the procedure raises an error rather than silently deactivating a non-credit card instrument.

When a credit card is deactivated (`CustomerFundingStatusID=0`), it is removed from the customer's active payment methods list. The card record still exists in `Billing.CustomerToFunding` (no delete), but it will no longer be returned for deposit or refund flows. It can be reactivated later via `Billing.CustomerToFunding_UpdateStatus`.

Every deactivation is fully audited: the pre-update row is captured via `OUTPUT DELETED.*` and written to `History.ActiveCustomerToFunding`. This audit trail is used for compliance review, fraud investigation, and payment operations support.

Created by Geri Reshef on 25/07/2017 (ticket 44744). Updated by Shay Oren on 23/01/2023 (PAYIL-5743) to include the `IsVerified` column in the OUTPUT clause and the History table INSERT.

---

## 2. Business Logic

### 2.1 Credit Card Type Validation

**What**: Before deactivating, validates that the target FundingID is a credit card. Prevents accidental deactivation of non-card instruments through this procedure.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `Billing.Funding.FundingTypeID`

**Rules**:
- IF EXISTS check: CID + FundingID must exist in CustomerToFunding AND the linked Funding must have FundingTypeID=1 (Credit Card)
- If the check fails (FundingID not found, or not a credit card): RAISERROR with message "Billing.DeactivateCustomerCreditCard Funding Doesn't exist", severity 16, state 1
- The error message is the same for both "not found" and "wrong type" - callers cannot distinguish between the two failure modes
- FundingTypeID=1 = Credit Card (per Dictionary.FundingType)

### 2.2 Deactivation with Full Audit Trail

**What**: Sets the credit card's status to deactivated and captures the pre-update state in the history table.

**Columns/Parameters Involved**: `Billing.CustomerToFunding.CustomerFundingStatusID`, `History.ActiveCustomerToFunding`

**Rules**:
- Single UPDATE: `SET CustomerFundingStatusID=0` - deactivated (removes from active payment methods)
- OUTPUT DELETED clause captures ALL columns from the pre-update row
- OUTPUT target: `History.ActiveCustomerToFunding` - temporal audit table for CustomerToFunding changes
- Columns written to history: CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID, IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription, IsVerified
- PAYIL-5743 (Jan 2023): IsVerified column added to both the OUTPUT clause and History INSERT

**Diagram**:
```
@CID, @FundingID
         |
    IF EXISTS (CID, FundingID, FundingTypeID=1)?
         |
    YES  |  NO
     |        |
  UPDATE     RAISERROR
  CTF SET    "Funding Doesn't exist"
  CustomerFundingStatusID=0
         |
  OUTPUT DELETED.* -> History.ActiveCustomerToFunding
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Identifies which customer's credit card link should be deactivated. Must exist in Billing.CustomerToFunding paired with @FundingID. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | FundingID of the credit card to deactivate. The linked Billing.Funding row must have FundingTypeID=1 (Credit Card). If the FundingID does not exist for this customer or is not a credit card, a RAISERROR is thrown. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID (validation) | Billing.CustomerToFunding | Read + Update | Validates existence and updates CustomerFundingStatusID=0 for the matching row. See [Billing.CustomerToFunding](../Tables/Billing.CustomerToFunding.md). |
| FundingTypeID=1 validation | Billing.Funding | Read | Joins to Billing.Funding to confirm the FundingID is a credit card (FundingTypeID=1). See [Billing.Funding](../Tables/Billing.Funding.md). |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write (cross-schema) | Captures the pre-deactivation row for audit history. Cross-schema dependency. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DeactivateCustomerCreditCard (procedure)
├── Billing.CustomerToFunding (table)
├── Billing.Funding (table)
└── History.ActiveCustomerToFunding (table) [cross-schema, write]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Read (IF EXISTS validation) + UPDATE (set CustomerFundingStatusID=0) + OUTPUT source |
| Billing.Funding | Table | Read JOIN for FundingTypeID=1 validation |
| History.ActiveCustomerToFunding | Table (cross-schema) | Write target for OUTPUT DELETED audit trail |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application cashier service | External | Calls this procedure when a customer requests credit card removal or when compliance deactivates a card |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Deactivate a specific credit card for a customer

```sql
EXEC Billing.DeactivateCustomerCreditCard
    @CID = 12345678,
    @FundingID = 9876543;
```

### 8.2 Check if a FundingID is a credit card before calling

```sql
SELECT ctf.CID,
       ctf.FundingID,
       ctf.CustomerFundingStatusID,
       f.FundingTypeID
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
    INNER JOIN Billing.Funding f WITH (NOLOCK)
        ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 12345678
  AND ctf.FundingID = 9876543;
-- Verify FundingTypeID=1 before calling DeactivateCustomerCreditCard
```

### 8.3 Review deactivation audit trail for a customer

```sql
SELECT *
FROM History.ActiveCustomerToFunding WITH (NOLOCK)
WHERE CID = 12345678
  AND FundingID = 9876543
ORDER BY [Occurred] DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DeactivateCustomerCreditCard | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DeactivateCustomerCreditCard.sql*
