# Billing.UpdateCustomerStatusReason

> Sets the reason code for a customer's current player status, recording why the account was blocked, closed, or flagged - used by Back Office operations and compliance workflows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets Customer.CustomerStatic.PlayerStatusReasonID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateCustomerStatusReason` records the reason why a customer's account has been placed in its current status (blocked, suspended, closed, under review). The `PlayerStatusReasonID` on `Customer.CustomerStatic` provides the "why" behind an account status change - compliance teams, risk operations, and back office staff use this to classify the cause when acting on an account.

Added in July 2018 (ticket 52107) as part of status reason tracking improvements. The reason codes cover compliance/AML closures, fraud/risk blocks, customer-initiated closures, KYC failures, and operational holds. Having a structured reason code (rather than free text) enables reporting, regulatory audit trails, and systematic case management.

The procedure is a single-statement UPDATE with no guard logic. No FK constraint is defined in the DDL between `Customer.CustomerStatic.PlayerStatusReasonID` and `Dictionary.PlayerStatusReasons`, though the lookup table governs the valid set of reason codes.

---

## 2. Business Logic

### 2.1 Status Reason Assignment

**What**: Updates the player status reason code on the customer's static record, classifying the cause of the current account status.

**Columns/Parameters Involved**: `@CID`, `@PlayerStatusReasonID`, `Customer.CustomerStatic.PlayerStatusReasonID`

**Rules**:
- `UPDATE Customer.CustomerStatic SET PlayerStatusReasonID = @PlayerStatusReasonID WHERE CID = @CID`
- No prior-state validation - unconditional assignment
- No FK constraint enforced at DB level; caller is responsible for using valid `PlayerStatusReasonID` values from `Dictionary.PlayerStatusReasons`
- If `@CID` does not exist, the UPDATE silently affects 0 rows
- `PlayerStatusReasonID = NULL` clears the reason (no specific reason assigned)
- Changes are tracked by the CustomerStatic trigger (which audits changes to PlayerStatusReasonID)

**PlayerStatusReasonID values** (from `Dictionary.PlayerStatusReasons`):

| ID | Name | Category |
|----|------|----------|
| 0 | None | No reason / reset |
| 1 | Failed Verification | KYC |
| 2 | Expired Document | KYC |
| 3 | CloseAccountByUser | Customer-initiated |
| 4 | Risk | Risk/Fraud |
| 5 | Chargeback | Financial |
| 6 | AML-Account Closed | AML/Compliance |
| 7 | HRC | Compliance (High Risk Country) |
| 8 | Underage | Compliance |
| 9 | Deceased | Compliance |
| 10 | AML | AML/Compliance |
| 11 | AML review | AML/Compliance |
| 12 | Off Market Abuse | Risk/Fraud |
| 13 | Overpayment | Financial |
| 14 | Risk Check | Risk/Fraud |
| 15 | 3rd Party | Fraud |
| 16 | PayPal Investigation | Financial |
| 17 | NOC/NOF/RFI | Compliance (Notices of Change/Funds/Returns) |
| 18 | WCH match | Compliance (Watchlist match) |
| 19 | Other | General |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID identifying which customer's status reason to update. Maps to `Customer.CustomerStatic.CID`. If the CID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @PlayerStatusReasonID | INT | YES | - | CODE-BACKED | The reason code for the customer's current status. FK (no constraint) to `Dictionary.PlayerStatusReasons`. See lookup table above for all valid values. 0=None, NULL=unset. Covers KYC failures, AML/compliance closures, risk blocks, customer-initiated closures, and fraud reasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE CID | Customer.CustomerStatic | UPDATE (cross-schema) | Target table; sets PlayerStatusReasonID for the specified customer |
| @PlayerStatusReasonID (logical) | Dictionary.PlayerStatusReasons | Logical FK (no constraint) | Governs valid reason codes; no DB-level FK enforced |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No SQL dependents found in SSDT. | - | - | Called externally by Back Office CRM/compliance tools when setting account status reasons |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCustomerStatusReason (procedure)
`- Customer.CustomerStatic (table) - UPDATE target
   `- Dictionary.PlayerStatusReasons (table) - logical FK (no constraint)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE - sets PlayerStatusReasonID WHERE CID=@CID (cross-schema write) |
| Dictionary.PlayerStatusReasons | Table | Logical lookup for valid @PlayerStatusReasonID values (no enforced FK) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Back Office / compliance tooling for account status reason management. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: `Customer.CustomerStatic.PlayerStatusReasonID INT NULL` - no DEFAULT value and no FK constraint enforced at the DB level. The CustomerStatic table has an audit trigger that tracks changes to this column in the history table.

---

## 8. Sample Queries

### 8.1 Set status reason to AML closure
```sql
-- Mark customer 12345 as closed for AML reasons
EXEC Billing.UpdateCustomerStatusReason @CID = 12345, @PlayerStatusReasonID = 6; -- AML-Account Closed
```

### 8.2 Set reason for KYC failure
```sql
-- Customer account blocked due to failed verification
EXEC Billing.UpdateCustomerStatusReason @CID = 12345, @PlayerStatusReasonID = 1; -- Failed Verification
```

### 8.3 Clear the status reason
```sql
-- Remove reason (account reactivated / reason no longer applies)
EXEC Billing.UpdateCustomerStatusReason @CID = 12345, @PlayerStatusReasonID = 0; -- None
```

### 8.4 Check current player status reason for a customer
```sql
SELECT cs.CID, cs.PlayerStatusReasonID, psr.Name AS ReasonName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
LEFT JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON psr.PlayerStatusReasonID = cs.PlayerStatusReasonID
WHERE cs.CID = 12345;
```

### 8.5 Distribution of active status reasons
```sql
SELECT psr.PlayerStatusReasonID, psr.Name, COUNT(*) AS CustomerCount
FROM Customer.CustomerStatic cs WITH (NOLOCK)
INNER JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON psr.PlayerStatusReasonID = cs.PlayerStatusReasonID
WHERE cs.PlayerStatusReasonID IS NOT NULL AND cs.PlayerStatusReasonID > 0
GROUP BY psr.PlayerStatusReasonID, psr.Name
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal ticket 52107 (July 2018) added `PlayerStatusReasonID` to `Customer.CustomerStatic`.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateCustomerStatusReason | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCustomerStatusReason.sql*
