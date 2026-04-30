# Billing.DeactivateFunding

> Deactivates any payment method (regardless of type) for a customer by setting its CustomerFundingStatusID to 0 in CustomerToFunding, with full audit trail written to History.ActiveCustomerToFunding and returns the affected row count.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID identify the CustomerToFunding row to deactivate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DeactivateFunding` marks any customer payment method as deactivated (`CustomerFundingStatusID=0`), removing it from the customer's active payment methods list. Unlike `Billing.DeactivateCustomerCreditCard`, which restricts deactivation to credit cards only (`FundingTypeID=1`), this procedure operates on any funding type: wire transfers, PayPal, Neteller, ACH, and all others.

This is the general-purpose deactivation operation. It is called when a payment method needs to be disabled for operational, compliance, or customer-requested reasons, regardless of what type of instrument it is. The procedure does NOT validate that the CID+FundingID combination exists before updating - if the combination doesn't exist, the UPDATE affects 0 rows and `RETURN(@@ROWCOUNT)` returns 0, allowing callers to detect a no-op without an error.

Every deactivation is fully audited via `OUTPUT DELETED.*` to `History.ActiveCustomerToFunding`, preserving the pre-deactivation state for compliance review, fraud investigation, and audit trails. The procedure returns the row count, enabling callers to verify that exactly one row was affected.

Updated by Shay Oren on 23/01/2023 (PAYIL-5743) to include the `IsVerified` column in the OUTPUT clause and History table INSERT, consistent with `Billing.DeactivateCustomerCreditCard`.

---

## 2. Business Logic

### 2.1 Type-Agnostic Deactivation

**What**: Deactivates any funding type without type validation - the caller is responsible for passing the correct CID + FundingID.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `Billing.CustomerToFunding.CustomerFundingStatusID`

**Rules**:
- No IF EXISTS / type validation - the UPDATE runs unconditionally
- If CID + FundingID does not exist in CustomerToFunding -> UPDATE affects 0 rows -> RETURN(0)
- If found -> SET CustomerFundingStatusID=0 (Deactivated) -> RETURN(1)
- No RAISERROR on zero rows - the return value is the caller's signal
- Contrast with DeactivateCustomerCreditCard: that procedure validates FundingTypeID=1 and raises an error on mismatch; this procedure silently returns 0 for non-matching records

### 2.2 Deactivation with Full Audit Trail

**What**: Captures the pre-deactivation CustomerToFunding state in History before the update is applied.

**Columns/Parameters Involved**: `Billing.CustomerToFunding.*`, `History.ActiveCustomerToFunding`

**Rules**:
- OUTPUT DELETED clause captures all columns: CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID (the OLD value before =0), IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription, IsVerified
- The captured CustomerFundingStatusID in history reflects the PREVIOUS status (before deactivation), enabling audit of what state the funding was in before it was deactivated
- History row records the change moment implicitly via Occurred (the original link timestamp, not the deactivation timestamp)
- PAYIL-5743 (Jan 2023): IsVerified column added to OUTPUT and History INSERT

**Diagram**:
```
@CID, @FundingID
         |
  UPDATE Billing.CustomerToFunding
  SET CustomerFundingStatusID=0
  WHERE CID=@CID AND FundingID=@FundingID
         |
  OUTPUT DELETED.* -> History.ActiveCustomerToFunding
         |
  RETURN(@@ROWCOUNT)
  (0=no row found, 1=deactivated)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Identifies which customer's payment method link to deactivate. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | FundingID of the payment method to deactivate. Any FundingTypeID is accepted. If the CID + FundingID combination does not exist in CustomerToFunding, the procedure returns 0 (no rows affected) without raising an error. |
| 3 | Return value | INT | NO | - | CODE-BACKED | @@ROWCOUNT from the UPDATE: 1 = one row deactivated successfully; 0 = no row found matching the CID + FundingID combination (no error raised, caller should check). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Update | Sets CustomerFundingStatusID=0 for the specified customer-funding link. See [Billing.CustomerToFunding](../Tables/Billing.CustomerToFunding.md). |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write (cross-schema) | Captures the pre-deactivation row for audit history. Cross-schema dependency. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DeactivateFunding (procedure)
├── Billing.CustomerToFunding (table)
└── History.ActiveCustomerToFunding (table) [cross-schema, write]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target (set CustomerFundingStatusID=0) + OUTPUT source for audit trail |
| History.ActiveCustomerToFunding | Table (cross-schema) | Write target for OUTPUT DELETED audit trail |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application payment service | External | Calls this procedure to deactivate any payment method type when a customer removes a saved method or compliance/ops actions require deactivation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Deactivate a payment method (any type)

```sql
DECLARE @RowCount INT;
EXEC @RowCount = Billing.DeactivateFunding
    @CID = 12345678,
    @FundingID = 9876543;
SELECT @RowCount AS RowsAffected;
-- 1 = deactivated; 0 = not found
```

### 8.2 Check a funding link before deactivating

```sql
SELECT ctf.CID,
       ctf.FundingID,
       ctf.CustomerFundingStatusID,
       f.FundingTypeID,
       ctf.Occurred,
       ctf.LastUsedDate
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
    INNER JOIN Billing.Funding f WITH (NOLOCK)
        ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 12345678
  AND ctf.FundingID = 9876543;
```

### 8.3 Review the deactivation audit history

```sql
SELECT *
FROM History.ActiveCustomerToFunding WITH (NOLOCK)
WHERE CID = 12345678
  AND FundingID = 9876543
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DeactivateFunding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DeactivateFunding.sql*
